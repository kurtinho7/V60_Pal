const mongoose = require('mongoose');

const userBrewProfileSchema = new mongoose.Schema({
  owner: { type: String, required: true, unique: true, index: true },
  tastePreferences: [{ type: String }],
  successfulPatterns: [{ type: String }],
  recurringIssues: [{ type: String }],
  beanPreferences: [{ type: String }],
  nextFocus: { type: String, default: '' },
  confidence: { type: String, enum: ['low', 'medium', 'high'], default: 'low' },
  sourceEntryIds: [{ type: String }],
  model: { type: String, default: '' },
}, {
  timestamps: true,
});

userBrewProfileSchema.set('toJSON', {
  virtuals: true,
  versionKey: false,
  transform(_, ret) {
    ret.id = ret._id;
    delete ret._id;
  },
});

module.exports = mongoose.model('UserBrewProfile', userBrewProfileSchema);
