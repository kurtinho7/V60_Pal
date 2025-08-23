// models/JournalEntry.js
const mongoose = require('mongoose');

const journalEntrySchema = new mongoose.Schema({
  rating:        { type: String, required: false },
  waterTemp:     { type: Number, required: false },
  timeTaken:     { type: Number, required: false },
  grindSetting:  { type: String, required: false },
  notes:         { type: String, default: '', required: false },
  beans:         { type: mongoose.Schema.Types.ObjectId, ref: 'Beans', required: false },
  recipe:        { type: String, required: false },
  date:          { type: Date, required: false, default: Date.now},
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
