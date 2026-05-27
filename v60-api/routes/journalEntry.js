const express = require('express');
const router = express.Router();
const OpenAI = require('openai');
const JournalEntry = require('../models/JournalEntry');

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

function compactObject(value) {
  return Object.fromEntries(
    Object.entries(value).filter(([, v]) => v !== undefined && v !== null && v !== '')
  );
}

function buildBrewContext(entry, recipeContext) {
  const bean = entry.beans;
  return compactObject({
    rating: entry.rating,
    tasteNotes: entry.notes,
    recipeName: entry.recipe,
    waterTempC: entry.waterTemp,
    brewTimeSeconds: entry.timeTaken,
    grindSetting: entry.grindSetting,
    coffeeDose: entry.coffeeDose,
    waterWeightGrams: entry.waterWeightGrams,
    recipeDefaults: recipeContext,
    beans: bean ? compactObject({
      name: bean.name,
      origin: bean.origin,
      roastLevel: bean.roastLevel || bean.roastlevel,
      roastDate: bean.roastDate,
      notes: bean.notes,
    }) : undefined,
  });
}

function parseFeedback(response) {
  const text = response.output_text;
  if (!text) throw new Error('OpenAI returned an empty response');
  return JSON.parse(text);
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
  const brewContext = buildBrewContext(entry, req.body?.recipeContext);

  try {
    const response = await client.responses.create({
      model,
      input: [
        {
          role: 'developer',
          content: [
            'You are a practical V60 pour-over coffee coach.',
            'Use the brew data to give personalized advice for the next brew.',
            'Be concrete about temperature, grind, brew time, pours, dose, and water where relevant.',
            'Do not change every variable at once; prioritize the one or two changes most likely to help.',
            'Avoid pretending certainty. If notes are vague or data is missing, say so and lower confidence.',
          ].join(' '),
        },
        {
          role: 'user',
          content: JSON.stringify(brewContext),
        },
      ],
      text: {
        format: {
          type: 'json_schema',
          name: 'brew_feedback',
          strict: true,
          schema: feedbackSchema,
        },
      },
    });

    const aiFeedback = parseFeedback(response);
    entry.aiFeedback = aiFeedback;
    entry.aiFeedbackGeneratedAt = new Date();
    entry.aiFeedbackModel = model;
    await entry.save();

    const full = await JournalEntry.findById(entry._id)
      .populate('beans')
      .populate('recipe');
    res.json(full);
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
