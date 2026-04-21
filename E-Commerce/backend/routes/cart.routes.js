const router = require('express').Router();
const { verifyToken } = require('../middleware/auth');
const { getCart, syncCart, clearCart } = require('../controllers/cart.controller');

router.get('/',      verifyToken, getCart);    // GET    /api/cart
router.post('/sync', verifyToken, syncCart);   // POST   /api/cart/sync
router.delete('/',   verifyToken, clearCart);  // DELETE /api/cart

module.exports = router;
