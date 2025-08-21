const express = require('express');
const router = express.Router();
const JournalEntry = require('../models/JournalEntry');

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
