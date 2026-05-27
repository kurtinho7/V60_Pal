const express = require('express');
const router = express.Router();
const OpenAI = require('openai');
const JournalEntry = require('../models/JournalEntry');
const UserBrewProfile = require('../models/UserBrewProfile');

const feedbackSchema = {
  type: 'object',
  additionalProperties: false,
  required: [
    'summary',
    'tasteDiagnosis',
    'recommendations',
    'nextBrewRecipe',
    'confidence',
  ],
  properties: {
    summary: { type: 'string' },
    tasteDiagnosis: { type: 'string' },
    recommendations: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['parameter', 'currentValue', 'suggestedChange', 'reason'],
        properties: {
          parameter: { type: 'string' },
          currentValue: { type: 'string' },
          suggestedChange: { type: 'string' },
          reason: { type: 'string' },
        },
      },
    },
    nextBrewRecipe: {
      type: 'object',
      additionalProperties: false,
      required: ['temperature', 'grindSize', 'brewTime', 'pours', 'coffeeDose', 'waterAmount'],
      properties: {
        temperature: { type: 'string' },
        grindSize: { type: 'string' },
        brewTime: { type: 'string' },
        pours: { type: 'string' },
        coffeeDose: { type: 'string' },
        waterAmount: { type: 'string' },
      },
    },
    confidence: { type: 'string', enum: ['low', 'medium', 'high'] },
  },
};

const profileUpdateSchema = {
  type: 'object',
  additionalProperties: false,
  required: [
    'tastePreferences',
    'successfulPatterns',
    'recurringIssues',
    'beanPreferences',
    'nextFocus',
    'confidence',
  ],
  properties: {
    tastePreferences: { type: 'array', items: { type: 'string' } },
    successfulPatterns: { type: 'array', items: { type: 'string' } },
    recurringIssues: { type: 'array', items: { type: 'string' } },
    beanPreferences: { type: 'array', items: { type: 'string' } },
    nextFocus: { type: 'string' },
    confidence: { type: 'string', enum: ['low', 'medium', 'high'] },
  },
};

const learningResponseSchema = {
  type: 'object',
  additionalProperties: false,
  required: ['feedback', 'profileUpdate'],
  properties: {
    feedback: feedbackSchema,
    profileUpdate: profileUpdateSchema,
  },
};

function compactObject(value) {
  return Object.fromEntries(
    Object.entries(value).filter(([, v]) => v !== undefined && v !== null && v !== '')
  );
}

function positiveNumber(value) {
  return typeof value === 'number' && Number.isFinite(value) && value > 0 ? value : undefined;
}

function usefulString(value) {
  if (typeof value !== 'string') return value;
  const trimmed = value.trim();
  return trimmed && trimmed !== '0' && trimmed !== '0g' ? trimmed : undefined;
}

function buildBrewContext(entry, recipeContext) {
  const bean = entry.beans;
  return compactObject({
    rating: entry.rating,
    tasteNotes: usefulString(entry.notes),
    recipeName: entry.recipe,
    waterTempC: positiveNumber(entry.waterTemp),
    brewTimeSeconds: positiveNumber(entry.timeTaken),
    grindSetting: usefulString(entry.grindSetting),
    coffeeDose: usefulString(entry.coffeeDose),
    waterWeightGrams: positiveNumber(entry.waterWeightGrams),
    recipeDefaults: recipeContext,
    beans: bean ? compactObject({
      name: usefulString(bean.name),
      origin: usefulString(bean.origin),
      roastLevel: usefulString(bean.roastLevel || bean.roastlevel),
      roastDate: bean.roastDate,
      notes: usefulString(bean.notes),
    }) : undefined,
  });
}

function cleanStringList(value, limit = 6) {
  if (!Array.isArray(value)) return [];
  return value
    .map(stripReasoningText)
    .filter((item) => typeof item === 'string' && item.trim())
    .slice(0, limit);
}

function buildProfileContext(profile) {
  if (!profile) return undefined;
  return compactObject({
    tastePreferences: cleanStringList(profile.tastePreferences),
    successfulPatterns: cleanStringList(profile.successfulPatterns),
    recurringIssues: cleanStringList(profile.recurringIssues),
    beanPreferences: cleanStringList(profile.beanPreferences),
    nextFocus: usefulString(profile.nextFocus),
    confidence: profile.confidence,
    updatedAt: profile.updatedAt,
  });
}

function buildLearningContext({ entry, recipeContext, profile, recentEntries }) {
  return compactObject({
    currentBrew: buildBrewContext(entry, recipeContext),
    learnedProfile: buildProfileContext(profile),
    recentBrews: recentEntries
      .filter((recentEntry) => recentEntry._id.toString() !== entry._id.toString())
      .map((recentEntry) => buildBrewContext(recentEntry))
      .filter((brew) => Object.keys(brew).length > 0),
  });
}

function stripReasoningText(value) {
  if (typeof value !== 'string') return value;
  return value
    .replace(/<think>[\s\S]*?<\/think>/gi, '')
    .split('\n')
    .filter((line) => !/^\s*(thinking|reasoning|chain[-\s]?of[-\s]?thought)\s*:/i.test(line))
    .join('\n')
    .replace(/\s+/g, ' ')
    .trim();
}

function hasUselessPlaceholderAdvice(value) {
  if (typeof value !== 'string') return false;
  return [
    /\b0\s*(c|°c|degrees?|deg)\b/i,
    /\bzero\s*(c|°c|degrees?|deg)\b/i,
    /\b0\s*g(rams?)?\b/i,
    /\b0\s*s(ec(onds?)?)?\b/i,
    /\bnot useful\b/i,
    /\buseless\b/i,
  ].some((pattern) => pattern.test(value));
}

function sanitizeFeedback(feedback) {
  const clean = {
    ...feedback,
    summary: stripReasoningText(feedback.summary),
    tasteDiagnosis: stripReasoningText(feedback.tasteDiagnosis),
    confidence: feedback.confidence,
  };

  clean.recommendations = Array.isArray(feedback.recommendations)
    ? feedback.recommendations
        .map((rec) => ({
          parameter: stripReasoningText(rec.parameter),
          currentValue: stripReasoningText(rec.currentValue),
          suggestedChange: stripReasoningText(rec.suggestedChange),
          reason: stripReasoningText(rec.reason),
        }))
        .filter((rec) => {
          const combined = Object.values(rec).join(' ');
          return !hasUselessPlaceholderAdvice(combined);
        })
    : [];

  clean.nextBrewRecipe = Object.fromEntries(
    Object.entries(feedback.nextBrewRecipe || {}).map(([key, value]) => [
      key,
      stripReasoningText(value),
    ])
  );

  return clean;
}

function sanitizeProfileUpdate(profileUpdate) {
  return {
    tastePreferences: cleanStringList(profileUpdate?.tastePreferences),
    successfulPatterns: cleanStringList(profileUpdate?.successfulPatterns),
    recurringIssues: cleanStringList(profileUpdate?.recurringIssues),
    beanPreferences: cleanStringList(profileUpdate?.beanPreferences),
    nextFocus: stripReasoningText(profileUpdate?.nextFocus || ''),
    confidence: ['low', 'medium', 'high'].includes(profileUpdate?.confidence)
      ? profileUpdate.confidence
      : 'low',
  };
}

function parseLearningResponse(response) {
  const text = response.output_text;
  if (!text) throw new Error('OpenAI returned an empty response');
  const parsed = JSON.parse(text);
  return {
    feedback: sanitizeFeedback(parsed.feedback),
    profileUpdate: sanitizeProfileUpdate(parsed.profileUpdate),
  };
}

// CREATE (owner from token)
router.post('/', async (req, res) => {
  const created = await JournalEntry.create({ ...req.body, owner: req.user.uid });
  // return populated
  const full = await JournalEntry.findById(created._id)
    .populate('beans')
    .populate('recipe');
  res.status(201).json(full);
});

// LIST (current user only)
router.get('/', async (req, res) => {
  const entries = await JournalEntry.find({ owner: req.user.uid })
    .sort({ createdAt: -1 })
    .populate('beans')
    .populate('recipe');
  res.json(entries);
});

// Learned AI brew profile (current user only)
router.get('/ai-profile', async (req, res) => {
  const profile = await UserBrewProfile.findOne({ owner: req.user.uid });
  res.json(profile || null);
});

// AI feedback (must be owned)
router.post('/:id/ai-feedback', async (req, res) => {
  const entry = await JournalEntry.findOne({ _id: req.params.id, owner: req.user.uid })
    .populate('beans');
  if (!entry) return res.sendStatus(404);

  if (!process.env.OPENAI_API_KEY) {
    return res.status(500).json({ error: 'OPENAI_API_KEY is not configured' });
  }

  const model = process.env.OPENAI_MODEL || 'gpt-5.4';
  const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
  const [profile, recentEntries] = await Promise.all([
    UserBrewProfile.findOne({ owner: req.user.uid }),
    JournalEntry.find({ owner: req.user.uid })
      .sort({ createdAt: -1 })
      .limit(12)
      .populate('beans'),
  ]);
  const learningContext = buildLearningContext({
    entry,
    recipeContext: req.body?.recipeContext,
    profile,
    recentEntries,
  });

  try {
    const response = await client.responses.create({
      model,
      input: [
        {
          role: 'developer',
          content: [
            'You are a practical V60 pour-over coffee coach.',
            'Use the current brew, learned user profile, and recent brew history to give personalized advice for the next brew.',
            'Be concrete about temperature, grind, brew time, pours, dose, and water where relevant.',
            'Do not change every variable at once; prioritize the one or two changes most likely to help.',
            'Avoid pretending certainty. If notes are vague or data is missing, say so and lower confidence.',
            'Do not show hidden reasoning, chain-of-thought, scratchpad, or step-by-step thinking.',
            'Ignore missing placeholder values such as 0 C, 0 seconds, and 0 grams; do not criticize them.',
            'Only recommend changes based on real brew data or recipe defaults.',
            'Update the learned profile as a compact summary of durable preferences and patterns, not a transcript.',
          ].join(' '),
        },
        {
          role: 'user',
          content: JSON.stringify(learningContext),
        },
      ],
      text: {
        format: {
          type: 'json_schema',
          name: 'brew_learning_feedback',
          strict: true,
          schema: learningResponseSchema,
        },
      },
    });

    const { feedback: aiFeedback, profileUpdate } = parseLearningResponse(response);
    entry.aiFeedback = aiFeedback;
    entry.aiFeedbackGeneratedAt = new Date();
    entry.aiFeedbackModel = model;
    await entry.save();

    const sourceEntryIds = Array.from(new Set([
      entry._id.toString(),
      ...recentEntries.map((recentEntry) => recentEntry._id.toString()),
    ])).slice(0, 12);

    const savedProfile = await UserBrewProfile.findOneAndUpdate(
      { owner: req.user.uid },
      {
        ...profileUpdate,
        sourceEntryIds,
        model,
      },
      { new: true, upsert: true, setDefaultsOnInsert: true }
    );

    const full = await JournalEntry.findById(entry._id)
      .populate('beans')
      .populate('recipe');
    res.json({ entry: full, aiProfile: savedProfile });
  } catch (err) {
    console.error('AI feedback failed:', err);
    res.status(502).json({ error: 'AI feedback failed', detail: err.message });
  }
});

// READ one (must be owned)
router.get('/:id', async (req, res) => {
  const entry = await JournalEntry.findOne({ _id: req.params.id, owner: req.user.uid })
    .populate('beans')
    .populate('recipe');
  if (!entry) return res.sendStatus(404);
  res.json(entry);
});

// UPDATE (must be owned)
router.put('/:id', async (req, res) => {
  const updated = await JournalEntry.findOneAndUpdate(
    { _id: req.params.id, owner: req.user.uid },
    req.body,
    { new: true }
  )
    .populate('beans')
    .populate('recipe');
  if (!updated) return res.sendStatus(404);
  res.json(updated);
});

// DELETE (must be owned)
router.delete('/:id', async (req, res) => {
  const result = await JournalEntry.deleteOne({ _id: req.params.id, owner: req.user.uid });
  if (!result.deletedCount) return res.sendStatus(404);
  res.sendStatus(204);
});

module.exports = router;
