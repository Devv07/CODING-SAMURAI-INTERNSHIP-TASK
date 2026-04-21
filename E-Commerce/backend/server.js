require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const authRoutes    = require('./routes/auth.routes');
const productRoutes = require('./routes/product.routes');
const orderRoutes   = require('./routes/order.routes');
const cartRoutes    = require('./routes/cart.routes');

const app  = express();
const PORT = process.env.PORT || 3000;

//security & logging middleware
app.use(helmet());
app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));

//CORS
app.use(cors({
  origin: [
    'http://localhost:5000',
    'http://localhost:3000',
    process.env.ALLOWED_ORIGIN,
  ].filter(Boolean),
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

//Body parser
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

//Health check
app.get('/health', (_, res) => res.json({ status: 'ok', time: new Date() }));

//API routes
app.use('/api/auth',     authRoutes);
app.use('/api/products', productRoutes);
app.use('/api/orders',   orderRoutes);
app.use('/api/cart',     cartRoutes);

//404
app.use((req, res) => {
  res.status(404).json({ success: false, message: `Route ${req.path} not found` });
});

//Global error handler
app.use((err, req, res, next) => {
  console.error('[ERROR]', err.message);
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Internal server error',
  });
});

app.listen(PORT, () => {
  console.log(`🚀  Maison backend running on http://localhost:${PORT}`);
});
