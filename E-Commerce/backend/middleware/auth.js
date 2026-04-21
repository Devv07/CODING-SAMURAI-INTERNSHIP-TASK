const { auth } = require('../config/firebase');

const verifyToken = async (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      success: false,
      message: 'Missing or invalid Authorization header. Expected: Bearer <idToken>',
    });
  }

  const idToken = authHeader.split('Bearer ')[1];

  try {
    const decoded = await auth.verifyIdToken(idToken);
    req.user = decoded;
    next();
  } catch (err) {
    console.error('[Auth Middleware]', err.code, err.message);
    return res.status(403).json({
      success: false,
      message: 'Token expired or invalid. Please sign in again.',
    });
  }
};

module.exports = { verifyToken };
