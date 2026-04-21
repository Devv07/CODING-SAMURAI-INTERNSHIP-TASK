const router = require('express').Router();
const { verifyToken }    = require('../middleware/auth');
const { requireAdmin }   = require('../middleware/admin');
const {
  getProducts, getProductById, getCategories,
  createProduct, updateProduct, deleteProduct, getAllProductsAdmin,
} = require('../controllers/product.controller');

//Public routes (no auth)
router.get('/',              getProducts);         // GET /api/products
router.get('/categories',    getCategories);       // GET /api/products/categories

//Admin routes (token + isAdmin claim)
router.get('/admin/all',     verifyToken, requireAdmin, getAllProductsAdmin);
router.post('/',             verifyToken, requireAdmin, createProduct);
router.put('/:id',           verifyToken, requireAdmin, updateProduct);
router.delete('/:id',        verifyToken, requireAdmin, deleteProduct);

//Public single product (must come after /admin/all and /categories)
router.get('/:id',           getProductById);      // GET /api/products/:id

module.exports = router;
