const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const app = express();
app.use(express.json());
app.use(cors());

// 1) Connect to Atlas
const uri = 'YOUR_CONNECTION_STRING';
mongoose.connect(uri, { useNewUrlParser: true, useUnifiedTopology: true })
  .then(() => console.log('🗄️ MongoDB connected'))
  .catch(err => console.error(err));

// 2) Define a Recipe schema
const recipeSchema = new mongoose.Schema({
  name: String,
  waterWeightGrams: Number,
  coffeeDose: String,
  grindSize: String,
  brewTime: String,
  pourSteps: [Number],
  pourAmounts: [Number],
});
const Recipe = mongoose.model('Recipe', recipeSchema);

// 3) CRUD endpoints
// GET all recipes
app.get('/recipes', async (req, res) => {
  const recipes = await Recipe.find();
  res.json(recipes);
});

// GET one recipe by ID
app.get('/recipes/:id', async (req, res) => {
  const recipe = await Recipe.findById(req.params.id);
  if (!recipe) return res.status(404).send('Not found');
  res.json(recipe);
});

// POST a new recipe
app.post('/recipes', async (req, res) => {
  const newRecipe = new Recipe(req.body);
  await newRecipe.save();
  res.status(201).json(newRecipe);
});

// PUT to update a recipe
app.put('/recipes/:id', async (req, res) => {
  const updated = await Recipe.findByIdAndUpdate(req.params.id, req.body, { new: true });
  res.json(updated);
});

// DELETE a recipe
app.delete('/recipes/:id', async (req, res) => {
  await Recipe.findByIdAndDelete(req.params.id);
  res.sendStatus(204);
});

// 4) Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`🚀 API running on http://localhost:${PORT}`));
