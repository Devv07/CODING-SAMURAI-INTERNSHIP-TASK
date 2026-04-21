const { db } = require('../config/firebase');
const { v4: uuidv4 } = require('uuid');

//POST /api/orders
const placeOrder = async (req, res) => {
  const { items, shippingAddress, paymentMethod } = req.body;

  if (!items || !Array.isArray(items) || items.length === 0) {
    return res.status(400).json({ success: false, message: 'Order must contain at least one item' });
  }
  if (!shippingAddress) {
    return res.status(400).json({ success: false, message: 'Shipping address is required' });
  }

  try {
    const subtotal = items.reduce((sum, i) => sum + i.price * i.quantity, 0);
    const shipping = subtotal >= 200 ? 0 : 12;
    const total    = subtotal + shipping;

    const order = {
      id:              `ORD-${Date.now().toString().slice(-8)}`,
      uid:             req.user.uid,
      items,
      subtotal:        parseFloat(subtotal.toFixed(2)),
      shippingCost:    shipping,
      total:           parseFloat(total.toFixed(2)),
      shippingAddress,
      paymentMethod:   paymentMethod || 'card',
      status:          'processing',
      createdAt:       new Date().toISOString(),
    };

    await db
      .collection('users')
      .doc(req.user.uid)
      .collection('orders')
      .doc(order.id)
      .set(order);

    res.status(201).json({ success: true, data: order });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

//GET /api/orders
const getOrders = async (req, res) => {
  try {
    const snapshot = await db
      .collection('users')
      .doc(req.user.uid)
      .collection('orders')
      .orderBy('createdAt', 'desc')
      .get();

    const orders = snapshot.docs.map(doc => doc.data());
    res.json({ success: true, count: orders.length, data: orders });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

//GET /api/orders/:id
const getOrderById = async (req, res) => {
  try {
    const doc = await db
      .collection('users')
      .doc(req.user.uid)
      .collection('orders')
      .doc(req.params.id)
      .get();

    if (!doc.exists) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }

    res.json({ success: true, data: doc.data() });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

//PATCH /api/orders/:id/cancel
const cancelOrder = async (req, res) => {
  try {
    const ref = db
      .collection('users')
      .doc(req.user.uid)
      .collection('orders')
      .doc(req.params.id);

    const doc = await ref.get();
    if (!doc.exists) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }

    const order = doc.data();
    if (order.status !== 'processing') {
      return res.status(400).json({
        success: false,
        message: `Cannot cancel an order with status '${order.status}'`,
      });
    }

    await ref.update({ status: 'cancelled' });
    res.json({ success: true, message: 'Order cancelled' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

module.exports = { placeOrder, getOrders, getOrderById, cancelOrder };
