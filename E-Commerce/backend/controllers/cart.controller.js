const { db } = require('../config/firebase');

//GET /api/cart
const getCart = async (req, res) => {
  try {
    const doc = await db.collection('carts').doc(req.user.uid).get();
    const cart = doc.exists ? doc.data().items || [] : [];
    res.json({ success: true, data: cart });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

//POST /api/cart/sync
const syncCart = async (req, res) => {
  const { items } = req.body;
  if (!Array.isArray(items)) {
    return res.status(400).json({ success: false, message: 'items must be an array' });
  }
  try {
    await db.collection('carts').doc(req.user.uid).set({
      uid:       req.user.uid,
      items,
      updatedAt: new Date().toISOString(),
    });
    res.json({ success: true, message: 'Cart synced', data: items });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

//DELETE /api/cart
const clearCart = async (req, res) => {
  try {
    await db.collection('carts').doc(req.user.uid).delete();
    res.json({ success: true, message: 'Cart cleared' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

module.exports = { getCart, syncCart, clearCart };
