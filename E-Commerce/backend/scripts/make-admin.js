
require('dotenv').config({ path: '../.env' });
const { auth } = require('../config/firebase');

const email = process.argv[2];

if (!email) {
  console.error('Usage: node scripts/make-admin.js <email>');
  process.exit(1);
}

async function makeAdmin() {
  try {
    const user = await auth.getUserByEmail(email);
    await auth.setCustomUserClaims(user.uid, { isAdmin: true });
    console.log(`✅  ${email} (${user.uid}) is now an admin.`);
    console.log('    User must sign out and sign back in for the change to take effect.');
    process.exit(0);
  } catch (err) {
    console.error('❌  Failed:', err.message);
    process.exit(1);
  }
}

makeAdmin();
