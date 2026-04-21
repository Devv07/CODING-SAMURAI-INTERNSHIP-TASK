const { db } = require('../config/firebase');

const COLLECTION = 'products';

const applyFilters = (docs, { category, search, sortBy }) => {
  let result = docs;
  if (category && category !== 'All') {
    result = result.filter(p => p.category === category);
  }
  if (search) {
    const q = search.toLowerCase();
    result = result.filter(p =>
      p.name.toLowerCase().includes(q) ||
      p.category.toLowerCase().includes(q),
    );
  }
  if (sortBy === 'price_asc')  result.sort((a, b) => a.price  - b.price);
  if (sortBy === 'price_desc') result.sort((a, b) => b.price  - a.price);
  if (sortBy === 'rating')     result.sort((a, b) => b.rating - a.rating);
  return result;
};

//GET /api/products
const getProducts = async (req, res) => {
  try {
    const snapshot = await db.collection(COLLECTION)
      .where('isActive', '==', true).get();
    let docs = snapshot.docs.map(d => ({ id: d.id, ...d.data() }));
    docs = applyFilters(docs, req.query);
    res.json({ success: true, count: docs.length, data: docs });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

//GET /api/products/categories
const getCategories = async (req, res) => {
  try {
    const snapshot = await db.collection(COLLECTION)
      .where('isActive', '==', true).get();
    const cats = new Set(snapshot.docs.map(d => d.data().category));
    res.json({ success: true, data: ['All', ...cats] });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

//GET /api/products/:id
const getProductById = async (req, res) => {
  try {
    const doc = await db.collection(COLLECTION).doc(req.params.id).get();
    if (!doc.exists) {
      return res.status(404).json({ success: false, message: 'Product not found' });
    }
    res.json({ success: true, data: { id: doc.id, ...doc.data() } });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

//POST /api/products  (only for admin)
const createProduct = async (req, res) => {
  try {
    const { name, price, category, description,
      tag = null, imageEmoji = '🛍', colorHex = '#CCCCCC',
      rating = 0, reviews = 0 } = req.body;

    const missing = ['name', 'price', 'category', 'description'].filter(f => !req.body[f]);
    if (missing.length) {
      return res.status(400).json({ success: false,
        message: `Missing required fields: ${missing.join(', ')}` });
    }

    const product = {
      name: name.trim(), price: parseFloat(price),
      category: category.trim(), description: description.trim(),
      tag: tag || null, imageEmoji, colorHex,
      rating: parseFloat(rating), reviews: parseInt(reviews),
      isActive: true,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    const ref = await db.collection(COLLECTION).add(product);
    res.status(201).json({ success: true, data: { id: ref.id, ...product } });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

//PUT /api/products/:id  (only for admin)
const updateProduct = async (req, res) => {
  try {
    const ref = db.collection(COLLECTION).doc(req.params.id);
    const doc = await ref.get();
    if (!doc.exists) {
      return res.status(404).json({ success: false, message: 'Product not found' });
    }
    const allowed = ['name','price','category','description','tag',
                    'imageEmoji','colorHex','rating','reviews','isActive'];
    const updates = {};
    for (const key of allowed) {
      if (req.body[key] !== undefined) updates[key] = req.body[key];
    }
    updates.updatedAt = new Date().toISOString();
    await ref.update(updates);
    const updated = await ref.get();
    res.json({ success: true, data: { id: updated.id, ...updated.data() } });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

//DELETE /api/products/:id  (admin — soft delete)
const deleteProduct = async (req, res) => {
  try {
    const ref = db.collection(COLLECTION).doc(req.params.id);
    const doc = await ref.get();
    if (!doc.exists) {
      return res.status(404).json({ success: false, message: 'Product not found' });
    }
    await ref.update({ isActive: false, updatedAt: new Date().toISOString() });
    res.json({ success: true, message: 'Product deactivated' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

//GET /api/products/admin/all  (admin — includes inactive)
const getAllProductsAdmin = async (req, res) => {
  try {
    const snapshot = await db.collection(COLLECTION)
      .orderBy('createdAt', 'desc').get();
    let docs = snapshot.docs.map(d => ({ id: d.id, ...d.data() }));
    docs = applyFilters(docs, req.query);
    res.json({ success: true, count: docs.length, data: docs });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

module.exports = {
  getProducts, getProductById, getCategories,
  createProduct, updateProduct, deleteProduct, getAllProductsAdmin,
};
