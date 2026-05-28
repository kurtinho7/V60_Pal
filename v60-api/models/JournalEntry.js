// models/JournalEntry.js
const mongoose = require('mongoose');

const journalEntrySchema = new mongoose.Schema({
  rating:        { type: String, required: false },
  waterTemp:     { type: Number, required: false },
  timeTaken:     { type: Number, required: false },
  coffeeDose:    { type: String, required: false },
  waterWeightGrams: { type: Number, required: false },
  grindSetting:  { type: String, required: false },
  bloomTimeSeconds: { type: Number, required: false },
  bloomWaterGrams: { type: Number, required: false },
  pourCount: { type: Number, required: false },
  pourPattern: { type: String, required: false },
  agitation: {
    swirled: { type: Boolean, required: false },
    stirred: { type: Boolean, required: false },
    notes: { type: String, required: false },
  },
  filterType: { type: String, required: false },
  brewer: {
    size: { type: String, required: false },
    material: { type: String, required: false },
  },
  grinder: {
    model: { type: String, required: false },
    burrs: { type: String, required: false },
    grindScale: { type: String, required: false },
  },
  water: {
    source: { type: String, required: false },
    profile: { type: String, required: false },
  },
  drawdownTimeSeconds: { type: Number, required: false },
  notes:         { type: String, default: '', required: false },
  tastingFeedback: { type: mongoose.Schema.Types.Mixed, required: false },
  beans:         { type: mongoose.Schema.Types.ObjectId, ref: 'Beans', required: false },
  recipe:        { type: String, required: false },
  aiFeedback:    { type: mongoose.Schema.Types.Mixed, required: false },
  aiFeedbackGeneratedAt: { type: Date, required: false },
  aiFeedbackModel: { type: String, required: false },
  guidedAdjustment: { type: mongoose.Schema.Types.Mixed, required: false },
  plannedAdjustment: { type: mongoose.Schema.Types.Mixed, required: false },
  comparisonSourceEntryId: { type: mongoose.Schema.Types.ObjectId, ref: 'JournalEntry', required: false },
  comparisonResult: { type: mongoose.Schema.Types.Mixed, required: false },
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
