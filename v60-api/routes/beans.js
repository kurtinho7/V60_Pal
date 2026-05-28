const express = require('express');
const router = express.Router();
const Beans = require('../models/Beans');
const JournalEntry = require('../models/JournalEntry');

function parseRating(value) {
  const numeric = typeof value === 'number' ? value : Number.parseFloat(value);
  return Number.isFinite(numeric) ? numeric : undefined;
}

function usefulString(value) {
  if (typeof value !== 'string') return undefined;
  const trimmed = value.trim();
  return trimmed ? trimmed : undefined;
}

function positiveNumber(value) {
  return typeof value === 'number' && Number.isFinite(value) && value > 0 ? value : undefined;
}

function parseDoseGrams(value) {
  if (typeof value === 'number') return Number.isFinite(value) && value > 0 ? value : undefined;
  if (typeof value !== 'string') return undefined;
  const match = value.match(/(\d+(?:\.\d+)?)/);
  if (!match) return undefined;
  const grams = Number.parseFloat(match[1]);
  return Number.isFinite(grams) && grams > 0 ? grams : undefined;
}

function brewRatio(entry) {
  const dose = parseDoseGrams(entry.coffeeDose);
  const water = positiveNumber(entry.waterWeightGrams);
  if (!dose || !water) return undefined;
  return `1:${Number((water / dose).toFixed(1))}`;
}

function compactObject(value) {
  return Object.fromEntries(
    Object.entries(value).filter(([, v]) => {
      if (v === undefined || v === null || v === '') return false;
      if (Array.isArray(v)) return v.length > 0;
      return !(v.constructor === Object && Object.keys(v).length === 0);
    })
  );
}

function uniqueValues(values, limit = 12) {
  return Array.from(new Set(values.filter((value) => value !== undefined && value !== null && value !== '')))
    .slice(0, limit);
}

function summarizeEntry(entry) {
  if (!entry) return null;
  return compactObject({
    id: entry._id.toString(),
    rating: parseRating(entry.rating),
    recipeName: usefulString(entry.recipe),
    notes: usefulString(entry.notes),
    tastingFeedback: entry.tastingFeedback,
    waterTempC: positiveNumber(entry.waterTemp),
    brewTimeSeconds: positiveNumber(entry.timeTaken),
    grindSetting: usefulString(entry.grindSetting),
    coffeeDose: usefulString(entry.coffeeDose),
    waterWeightGrams: positiveNumber(entry.waterWeightGrams),
    ratio: brewRatio(entry),
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
    drawdownTimeSeconds: positiveNumber(entry.drawdownTimeSeconds),
    aiFeedback: entry.aiFeedback,
    date: entry.date,
    createdAt: entry.createdAt,
  });
}

function buildTriedSummary(entries) {
  const ratings = entries
    .map((entry) => parseRating(entry.rating))
    .filter((rating) => rating !== undefined);
  const averageRating = ratings.length
    ? Number((ratings.reduce((sum, rating) => sum + rating, 0) / ratings.length).toFixed(1))
    : undefined;

  return compactObject({
    brewCount: entries.length,
    ratedBrewCount: ratings.length,
    averageRating,
    bestRating: ratings.length ? Math.max(...ratings) : undefined,
    recipes: uniqueValues(entries.map((entry) => usefulString(entry.recipe))),
    temperaturesC: uniqueValues(entries.map((entry) => positiveNumber(entry.waterTemp))),
    grindSettings: uniqueValues(entries.map((entry) => usefulString(entry.grindSetting))),
    brewTimesSeconds: uniqueValues(entries.map((entry) => positiveNumber(entry.timeTaken))),
    coffeeDoses: uniqueValues(entries.map((entry) => usefulString(entry.coffeeDose))),
    waterAmountsGrams: uniqueValues(entries.map((entry) => positiveNumber(entry.waterWeightGrams))),
    pourCounts: uniqueValues(entries.map((entry) => positiveNumber(entry.pourCount))),
    pourPatterns: uniqueValues(entries.map((entry) => usefulString(entry.pourPattern))),
    filterTypes: uniqueValues(entries.map((entry) => usefulString(entry.filterType))),
  });
}

function buildRecommendedNextBrew(lastBrew, bestRatedBrew) {
  const aiFeedback = lastBrew?.aiFeedback;
  if (aiFeedback?.nextBrewRecipe) {
    return compactObject({
      source: 'ai-feedback',
      recipe: aiFeedback.nextBrewRecipe,
      primaryAdjustment: aiFeedback.primaryAdjustment,
      reason: usefulString(aiFeedback.tasteDiagnosis) || usefulString(aiFeedback.summary),
      confidence: aiFeedback.confidence,
      sourceEntryId: lastBrew._id.toString(),
    });
  }

  if (bestRatedBrew) {
    return compactObject({
      source: 'best-rated-brew',
      recipe: summarizeEntry(bestRatedBrew),
      reason: 'No AI next brew is available yet, so the best-rated brew is the current baseline.',
      sourceEntryId: bestRatedBrew._id.toString(),
    });
  }

  return null;
}

// CREATE
router.post('/', async (req, res) => {
  const doc = await Beans.create({ ...req.body, owner: req.user.uid });
  res.status(201).json(doc);
});

// LIST (current user only)
router.get('/', async (req, res) => {
  const docs = await Beans.find({ owner: req.user.uid }).sort({ createdAt: -1 });
  res.json(docs);
});

// RECIPE MEMORY (current user, derived from journal entries)
router.get('/:id/memory', async (req, res) => {
  const bean = await Beans.findOne({ _id: req.params.id, owner: req.user.uid });
  if (!bean) return res.sendStatus(404);

  const entries = await JournalEntry.find({ owner: req.user.uid, beans: bean._id })
    .sort({ createdAt: -1 });

  const lastBrew = entries[0] || null;
  const ratedEntries = entries
    .map((entry) => ({ entry, rating: parseRating(entry.rating) }))
    .filter(({ rating }) => rating !== undefined)
    .sort((a, b) => {
      if (b.rating !== a.rating) return b.rating - a.rating;
      return new Date(b.entry.createdAt) - new Date(a.entry.createdAt);
    });
  const bestRatedBrew = ratedEntries[0]?.entry || null;

  res.json({
    bean,
    brewCount: entries.length,
    lastBrew: summarizeEntry(lastBrew),
    lastBrews: entries.slice(0, 3).map(summarizeEntry).filter(Boolean),
    bestRatedBrew: summarizeEntry(bestRatedBrew),
    recommendedNextBrew: buildRecommendedNextBrew(lastBrew, bestRatedBrew),
    tried: buildTriedSummary(entries),
  });
});

// READ one (must be owned)
router.get('/:id', async (req, res) => {
  const doc = await Beans.findOne({ _id: req.params.id, owner: req.user.uid });
  if (!doc) return res.sendStatus(404);
  res.json(doc);
});

// UPDATE (must be owned)
router.put('/:id', async (req, res) => {
  const doc = await Beans.findOneAndUpdate(
    { _id: req.params.id, owner: req.user.uid },
    req.body,
    { new: true }
  );
  if (!doc) return res.sendStatus(404);
  res.json(doc);
});

// DELETE (must be owned)
router.delete('/:id', async (req, res) => {
  const result = await Beans.deleteOne({ _id: req.params.id, owner: req.user.uid });
  if (!result.deletedCount) return res.sendStatus(404);
  res.sendStatus(204);
});

module.exports = router;
