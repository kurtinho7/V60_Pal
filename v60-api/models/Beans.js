const mongoose = require('mongoose');

const beansSchema = new mongoose.Schema({
    name:        { type: String, required: true },
    origin:     { type: String, required: false },
    roastlevel:     { type: String, required: false },
    roastDate:  { type: Date, required: false },
    notes:         { type: String, default: '' },
    weight:         { type: Number, required: false },
    owner: { type: String, required: true, index: true } 
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
