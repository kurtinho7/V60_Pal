const mongoose = require('mongoose');

const beansSchema = new mongoose.Schema({
    name:        { type: String, required: true },
    origin:     { type: String, required: true },
    roastlevel:     { type: String, required: true },
    roastDate:  { type: Date, required: true },
    notes:         { type: String, default: '' },
    weight:         { type: Number, required: true },
  }, {
    timestamps: true
  });

beansSchema.set('toJSON', {
    virtuals: true,
    versionKey: false,
    transform(_, ret) {
      ret.id = ret._id;
      delete ret._id;
    }
  });

module.exports = mongoose.model('Beans', beansSchema);
