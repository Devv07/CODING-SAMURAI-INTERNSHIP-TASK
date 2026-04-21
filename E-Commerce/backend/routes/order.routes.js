const router = require('express').Router();
const { verifyToken } = require('../middleware/auth');
const { placeOrder, getOrders, getOrderById, cancelOrder } = require('../controllers/order.controller');

router.post('/',              verifyToken, placeOrder);    // POST   /api/orders
router.get('/',               verifyToken, getOrders);     // GET    /api/orders
router.get('/:id',            verifyToken, getOrderById);  // GET    /api/orders/ORD-12345
router.patch('/:id/cancel',   verifyToken, cancelOrder);   // PATCH  /api/orders/ORD-12345/cancel

module.exports = router;
