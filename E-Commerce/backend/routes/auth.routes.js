const router = require('express').Router();
const { verifyToken } = require('../middleware/auth');
const { getProfile, upsertProfile, deleteAccount } = require('../controllers/auth.controller');

router.get('/',    verifyToken, getProfile);       // GET  /api/auth/profile
router.post('/',   verifyToken, upsertProfile);    // POST /api/auth/profile
router.delete('/', verifyToken, deleteAccount);    // DELETE /api/auth/profile

module.exports = router;
