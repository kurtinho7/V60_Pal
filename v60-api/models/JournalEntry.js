// models/JournalEntry.js
const mongoose = require('mongoose');

const journalEntrySchema = new mongoose.Schema({
  rating:        { type: String, required: true },
  waterTemp:     { type: Number, required: true },
  timeTaken:     { type: Number, required: true },
  grindSetting:  { type: String, required: true },
  notes:         { type: String, default: '' },
  beans:         { type: mongoose.Schema.Types.ObjectId, ref: 'Beans', required: false },
  recipe:        { type: String, required: true },
  date:          { type: Date, required: true, default: Date.now},
  owner: { type: String, required: true, index: true } 
}, {
  timestamps: true
});

// expose `id` instead of `_id` in JSON
journalEntrySchema.set('toJSON', {
  virtuals: true,
  versionKey: false,
  transform(_, ret) {
    ret.id = ret._id;
    delete ret._id;
  }
});

module.exports = mongoose.model('JournalEntry', journalEntrySchema);
