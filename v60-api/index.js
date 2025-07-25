const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const app = express();
app.use(express.json());
app.use(cors());

// 1) Connect to Atlas
const uri = 'mongodb+srv://kurthymanyk7:qzZVNLgQsXTqY8NC@cluster0.u3j6pyo.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0';
mongoose.connect(uri, { useNewUrlParser: true, useUnifiedTopology: true })
  .then(() => console.log('🗄️ MongoDB connected'))
  .catch(err => console.error(err));

// 2) Define a Recipe schema
const JournalEntry = require('./models/JournalEntry');

// GET all entries
app.get('/journalEntries', async (req, res) => {
  const entries = await JournalEntry.find()
    .populate('beans')
    .populate('recipe');
  res.json(entries);
});

// GET one
app.get('/journalEntries/:id', async (req, res) => {
  const e = await JournalEntry.findById(req.params.id)
    .populate('beans')
    .populate('recipe');
  if (!e) return res.status(404).send('Not found');
  res.json(e);
});

// POST new
app.post('/journalEntries', async (req, res) => {
  const newEntry = new JournalEntry(req.body);
  await newEntry.save();
  // optionally re‐fetch with populated refs:
  const full = await JournalEntry.findById(newEntry.id)
    .populate('beans')
    .populate('recipe');
  res.status(201).json(full);
});

// PUT update
app.put('/journalEntries/:id', async (req, res) => {
  const updated = await JournalEntry.findByIdAndUpdate(
    req.params.id,
    req.body,
    { new: true }
  )
    .populate('beans')
    .populate('recipe');
  res.json(updated);
});

// DELETE
app.delete('/journalEntries/:id', async (_req, res) => {
  await JournalEntry.findByIdAndDelete(_req.params.id);
  res.sendStatus(204);
});


// 4) Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`🚀 API running on http://localhost:${PORT}`));
