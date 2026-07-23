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
    'primaryAdjustment',
    'recommendations',
    'nextBrewRecipe',
    'confidence',
  ],
  properties: {
    summary: { type: 'string' },
    tasteDiagnosis: { type: 'string' },
    primaryAdjustment: {
      type: 'object',
      additionalProperties: false,
      required: ['variable', 'direction', 'currentValue', 'targetValue', 'reason'],
      properties: {
        variable: { type: 'string', enum: ['grind', 'temperature', 'ratio', 'agitation', 'brewTime', 'pours', 'dose', 'water'] },
        direction: { type: 'string' },
        currentValue: { type: 'string' },
        targetValue: { type: 'string' },
        reason: { type: 'string' },
      },
    },
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
    Object.entries(value).filter(([, v]) => {
      if (v === undefined || v === null || v === '') return false;
      return !(v.constructor === Object && Object.keys(v).length === 0);
    })
  );
}

function positiveNumber(value) {
  return typeof value === 'number' && Number.isFinite(value) && value > 0 ? value : undefined;
}

function plausibleWaterTemp(value) {
  return typeof value === 'number' && Number.isFinite(value) && value >= 75 && value <= 100
    ? value
    : undefined;
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
    structuredTasteFeedback: entry.tastingFeedback,
    recipeName: entry.recipe,
    waterTempC: plausibleWaterTemp(entry.waterTemp),
    brewTimeSeconds: positiveNumber(entry.timeTaken),
    grindSetting: usefulString(entry.grindSetting),
    coffeeDose: usefulString(entry.coffeeDose),
    waterWeightGrams: positiveNumber(entry.waterWeightGrams),
    bloomTimeSeconds: positiveNumber(entry.bloomTimeSeconds),
    bloomWaterGrams: positiveNumber(entry.bloomWaterGrams),
    pourCount: positiveNumber(entry.pourCount),
    pourPattern: usefulString(entry.pourPattern),
    agitation: entry.agitation ? compactObject({
      swirled: entry.agitation.swirled,
      stirred: entry.agitation.stirred,
      notes: usefulString(entry.agitation.notes),
    }) : undefined,
    filterType: usefulString(entry.filterType),
    brewer: entry.brewer ? compactObject({
      size: usefulString(entry.brewer.size),
      material: usefulString(entry.brewer.material),
    }) : undefined,
    grinder: entry.grinder ? compactObject({
      model: usefulString(entry.grinder.model),
      burrs: usefulString(entry.grinder.burrs),
      grindScale: usefulString(entry.grinder.grindScale),
    }) : undefined,
    waterProfile: entry.water ? compactObject({
      source: usefulString(entry.water.source),
      profile: usefulString(entry.water.profile),
    }) : undefined,
    drawdownTimeSeconds: positiveNumber(entry.drawdownTimeSeconds),
    recipeDefaults: sanitizeRecipeContext(recipeContext),
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
    .map((item) => limitText(item, 80))
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

function limitText(value, maxLength) {
  if (typeof value !== 'string') return value;
  const trimmed = stripReasoningText(value);
  if (trimmed.length <= maxLength) return trimmed;
  const shortened = trimmed.slice(0, maxLength + 1);
  const lastSpace = shortened.lastIndexOf(' ');
  const cutAt = lastSpace > maxLength * 0.65 ? lastSpace : maxLength;
  return `${shortened.slice(0, cutAt).trim()}...`;
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
    summary: limitText(feedback.summary, 140),
    tasteDiagnosis: limitText(feedback.tasteDiagnosis, 160),
    confidence: feedback.confidence,
  };

  clean.primaryAdjustment = feedback.primaryAdjustment
    ? {
        variable: stripReasoningText(feedback.primaryAdjustment.variable),
        direction: limitText(feedback.primaryAdjustment.direction, 40),
        currentValue: limitText(feedback.primaryAdjustment.currentValue, 40),
        targetValue: limitText(feedback.primaryAdjustment.targetValue, 40),
        reason: limitText(feedback.primaryAdjustment.reason, 140),
      }
    : undefined;

  clean.recommendations = Array.isArray(feedback.recommendations)
    ? feedback.recommendations
        .map((rec) => ({
          parameter: limitText(rec.parameter, 40),
          currentValue: limitText(rec.currentValue, 40),
          suggestedChange: limitText(rec.suggestedChange, 60),
          reason: limitText(rec.reason, 120),
        }))
        .filter((rec) => {
          const combined = Object.values(rec).join(' ');
          return !hasUselessPlaceholderAdvice(combined);
        })
        .slice(0, 2)
    : [];

  clean.nextBrewRecipe = Object.fromEntries(
    Object.entries(feedback.nextBrewRecipe || {}).map(([key, value]) => [
      key,
      limitText(value, 40),
    ])
  );

  return clean;
}

function describeRating(rating) {
  const numeric = typeof rating === 'number' ? rating : Number.parseFloat(rating);
  return Number.isFinite(numeric)
    ? numeric.toFixed(numeric % 1 === 0 ? 0 : 1)
    : undefined;
}

function summarizeEntryForComparison(entry) {
  return compactObject({
    rating: describeRating(entry.rating),
    notes: usefulString(entry.notes),
    structuredTasteFeedback: entry.tastingFeedback,
    waterTempC: plausibleWaterTemp(entry.waterTemp),
    brewTimeSeconds: positiveNumber(entry.timeTaken),
    grindSetting: usefulString(entry.grindSetting),
    coffeeDose: usefulString(entry.coffeeDose),
    waterWeightGrams: positiveNumber(entry.waterWeightGrams),
    bloomTimeSeconds: positiveNumber(entry.bloomTimeSeconds),
    bloomWaterGrams: positiveNumber(entry.bloomWaterGrams),
    pourCount: positiveNumber(entry.pourCount),
    pourPattern: usefulString(entry.pourPattern),
    agitation: entry.agitation ? compactObject({
      swirled: entry.agitation.swirled,
      stirred: entry.agitation.stirred,
      notes: usefulString(entry.agitation.notes),
    }) : undefined,
    filterType: usefulString(entry.filterType),
    brewer: entry.brewer ? compactObject({
      size: usefulString(entry.brewer.size),
      material: usefulString(entry.brewer.material),
    }) : undefined,
    grinder: entry.grinder ? compactObject({
      model: usefulString(entry.grinder.model),
      burrs: usefulString(entry.grinder.burrs),
      grindScale: usefulString(entry.grinder.grindScale),
    }) : undefined,
    waterProfile: entry.water ? compactObject({
      source: usefulString(entry.water.source),
      profile: usefulString(entry.water.profile),
    }) : undefined,
    drawdownTimeSeconds: positiveNumber(entry.drawdownTimeSeconds),
  });
}

function buildComparisonResult(previousEntry, currentEntry, plannedAdjustment) {
  const parsedPreviousRating = Number.parseFloat(previousEntry.rating);
  const parsedCurrentRating = Number.parseFloat(currentEntry.rating);
  const previousRating = Number.isFinite(parsedPreviousRating) ? parsedPreviousRating : undefined;
  const currentRating = Number.isFinite(parsedCurrentRating) ? parsedCurrentRating : undefined;
  const ratingDelta = previousRating !== undefined && currentRating !== undefined
    ? Number((currentRating - previousRating).toFixed(1))
    : undefined;

  let outcome = 'unknown';
  if (ratingDelta !== undefined) {
    if (ratingDelta >= 0.5) outcome = 'improved';
    else if (ratingDelta <= -0.5) outcome = 'worse';
    else outcome = 'similar';
  }

  const variable = plannedAdjustment?.variable || 'planned variable';
  const nextStep = {
    improved: `Keep the ${variable} change for one more brew before changing anything else.`,
    worse: `Reverse the ${variable} change and keep the other variables steady.`,
    similar: `Hold the ${variable} change steady or make a smaller follow-up adjustment.`,
    unknown: 'Add a rating to make the comparison more useful.',
  }[outcome];

  return compactObject({
    sourceEntryId: previousEntry._id.toString(),
    changedVariable: variable,
    previous: summarizeEntryForComparison(previousEntry),
    current: summarizeEntryForComparison(currentEntry),
    ratingDelta,
    outcome,
    nextStep,
  });
}

function sanitizeProfileUpdate(profileUpdate) {
  return {
    tastePreferences: cleanStringList(profileUpdate?.tastePreferences, 4),
    successfulPatterns: cleanStringList(profileUpdate?.successfulPatterns, 4),
    recurringIssues: cleanStringList(profileUpdate?.recurringIssues, 4),
    beanPreferences: cleanStringList(profileUpdate?.beanPreferences, 4),
    nextFocus: limitText(profileUpdate?.nextFocus || '', 100),
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

function sanitizeRecipeContext(recipeContext) {
  if (!recipeContext || typeof recipeContext !== 'object') return undefined;
  const clean = { ...recipeContext };
  const temp = plausibleWaterTemp(clean.waterTemp);
  if (temp === undefined) delete clean.waterTemp;
  else clean.waterTemp = temp;
  return compactObject(clean);
}

function sanitizeJournalBody(body) {
  const clean = { ...body };
  for (const key of [
    'waterTemp',
    'timeTaken',
    'waterWeightGrams',
    'bloomTimeSeconds',
    'bloomWaterGrams',
    'pourCount',
    'drawdownTimeSeconds',
  ]) {
    if (clean[key] === 0 || clean[key] === '0' || clean[key] === '') {
      delete clean[key];
    }
  }
  if (plausibleWaterTemp(clean.waterTemp) === undefined) delete clean.waterTemp;
  for (const key of ['beans', 'comparisonSourceEntryId']) {
    if (clean[key] === '') delete clean[key];
  }
  return clean;
}

// CREATE (owner from token)
router.post('/', async (req, res) => {
  const body = sanitizeJournalBody(req.body || {});
  const sourceId = body.comparisonSourceEntryId;
  const plannedAdjustment = body.plannedAdjustment;
  const created = await JournalEntry.create({
    ...body,
    guidedAdjustment: body.guidedAdjustment || plannedAdjustment,
    owner: req.user.uid,
  });

  if (sourceId) {
    const previousEntry = await JournalEntry.findOne({ _id: sourceId, owner: req.user.uid });
    if (previousEntry) {
      created.comparisonResult = buildComparisonResult(previousEntry, created, plannedAdjustment);
      await created.save();
    }
  }

  // return populated
  const full = await JournalEntry.findById(created._id)
    .populate('beans');
  res.status(201).json(full);
});

// LIST (current user only)
router.get('/', async (req, res) => {
  const entries = await JournalEntry.find({ owner: req.user.uid })
    .sort({ createdAt: -1 })
    .populate('beans');
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
      max_output_tokens: 1000,
      input: [
        {
          role: 'developer',
          content: [
            'You are a practical V60 pour-over coffee coach.',
            'Use the current brew, learned user profile, and recent brew history to give personalized advice for the next brew.',
            'Make the feedback succinct, skimmable, and non-repetitive.',
            'summary: one short sentence about the cup result only.',
            'tasteDiagnosis: one short sentence naming the likely taste cause only; do not repeat the next action.',
            'Recommend exactly one primary variable to change for the next brew: grind, temperature, ratio, agitation, brew time, pours, dose, or water.',
            'Keep every other variable the same unless the current data is missing or impossible.',
            'primaryAdjustment.reason: one concise reason, no more than 18 words, and do not restate summary or tasteDiagnosis.',
            'recommendations: include only optional non-primary cleanup items; use an empty array if they would repeat the primary adjustment.',
            'nextBrewRecipe: list final target values only, with no explanation.',
            'Treat structuredTasteFeedback as higher-signal taste data than star rating alone, especially sour, sweet, bitter, thin, heavy, dry, clean, weak, intense, astringent, muddy, and hollow markers.',
            'Avoid pretending certainty. If notes are vague or data is missing, say so and lower confidence.',
            'Do not show hidden reasoning, chain-of-thought, scratchpad, or step-by-step thinking.',
            'Ignore missing placeholder values such as 0 C, 0 seconds, and 0 grams; do not criticize them.',
            'Only recommend changes based on real brew data or recipe defaults.',
            'Update the learned profile as compact durable patterns only; do not add one-off details or repeat the current primary adjustment as nextFocus.',
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
    entry.guidedAdjustment = aiFeedback.primaryAdjustment;
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
      .populate('beans');
    res.json({ entry: full, aiProfile: savedProfile });
  } catch (err) {
    console.error('AI feedback failed:', err);
    res.status(502).json({ error: 'AI feedback failed', detail: err.message });
  }
});

// READ one (must be owned)
router.get('/:id', async (req, res) => {
  const entry = await JournalEntry.findOne({ _id: req.params.id, owner: req.user.uid })
    .populate('beans');
  if (!entry) return res.sendStatus(404);
  res.json(entry);
});

// UPDATE (must be owned)
router.put('/:id', async (req, res) => {
  const updated = await JournalEntry.findOneAndUpdate(
    { _id: req.params.id, owner: req.user.uid },
    sanitizeJournalBody(req.body || {}),
    { new: true }
  )
    .populate('beans');
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
