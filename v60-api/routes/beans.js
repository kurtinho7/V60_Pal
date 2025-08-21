const express = require('express');
const router = express.Router();
const Beans = require('../models/Beans');

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
