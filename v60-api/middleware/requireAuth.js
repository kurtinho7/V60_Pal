// v60-api/middleware/requireAuth.js
const admin = require('../firebase');

async function requireAuth(req, res, next) {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) return res.status(401).send('Missing token');

  try {
    const decoded = await admin.auth().verifyIdToken(token);
    req.user = decoded;  // contains uid, email, etc
    next();
  } catch (err) {
    console.error('Auth failed:', err.message);
    res.status(401).send('Invalid token');
  }
}

module.exports = requireAuth;
