
require('dotenv').config({ path: '../.env' });
const { db } = require('../config/firebase');

const PRODUCTS = [
  { name: 'Structured Wool Coat',  price: 489, category: 'Outerwear',   tag: 'New',        rating: 4.8, reviews: 124, imageEmoji: '🧥', colorHex: '#D4C5B0', description: 'Tailored from Italian merino wool with a relaxed silhouette and hidden button closure.' },
  { name: 'Silk Slip Dress',       price: 228, category: 'Dresses',     tag: 'Bestseller', rating: 4.9, reviews: 341, imageEmoji: '👗', colorHex: '#C9B8C5', description: 'Pure silk charmeuse with adjustable straps and a bias-cut hem that skims the body beautifully.' },
  { name: 'Leather Chelsea Boots', price: 395, category: 'Footwear',    tag: 'New',        rating: 4.7, reviews: 89,  imageEmoji: '👢', colorHex: '#B8A898', description: 'Full-grain leather uppers with elastic side panels and a stacked heel. Hand-stitched sole.' },
  { name: 'Cashmere Turtleneck',   price: 185, category: 'Tops',        tag: null,         rating: 4.8, reviews: 512, imageEmoji: '🧶', colorHex: '#C5BFB0', description: 'Grade-A Mongolian cashmere in a relaxed fit. Garment-washed for an ultra-soft hand feel.' },
  { name: 'Tailored Trousers',     price: 265, category: 'Bottoms',     tag: 'Sale',       rating: 4.6, reviews: 78,  imageEmoji: '👖', colorHex: '#B0BAC5', description: 'Wide-leg silhouette in a wool-blend crepe. Features a high waist with a concealed zip fly.' },
  { name: 'Linen Blazer',          price: 345, category: 'Outerwear',   tag: null,         rating: 4.7, reviews: 156, imageEmoji: '🥼', colorHex: '#C5C0B0', description: 'Unlined Belgian linen blazer with patch pockets and natural horn buttons. Slight boyfriend fit.' },
  { name: 'Suede Bucket Bag',      price: 512, category: 'Accessories', tag: 'New',        rating: 4.9, reviews: 67,  imageEmoji: '👜', colorHex: '#C8B8A5', description: 'Italian suede with a drawstring closure, detachable shoulder strap, and suede interior lining.' },
  { name: 'Ribbed Tank Top',       price: 68,  category: 'Tops',        tag: null,         rating: 4.5, reviews: 289, imageEmoji: '👕', colorHex: '#BFC5C0', description: 'Cotton-modal blend with a close fit and wide armholes. The perfect wardrobe foundational piece.' },
];

async function seed() {
  console.log('🌱  Starting product seed...\n');

  const snapshot = await db.collection('products').get();
  if (!snapshot.empty) {
    console.log(`⚠️   Firestore already has ${snapshot.size} products.`);
    console.log('    Delete the collection first if you want a fresh seed.\n');
    process.exit(0);
  }

  const batch = db.batch();
  const now   = new Date().toISOString();

  for (const p of PRODUCTS) {
    const ref = db.collection('products').doc();
    batch.set(ref, {
      ...p,
      isActive:  true,
      createdAt: now,
      updatedAt: now,
    });
    console.log(`  + ${p.name}  ($${p.price})`);
  }

  await batch.commit();
  console.log(`\n✅  Seeded ${PRODUCTS.length} products into Firestore.`);
  process.exit(0);
}

seed().catch(err => {
  console.error('❌  Seed failed:', err.message);
  process.exit(1);
});
