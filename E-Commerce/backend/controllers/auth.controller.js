const { db, auth } = require('../config/firebase');

//GET /api/auth/profile
const getProfile = async (req, res) => {
  try {
    const doc = await db.collection('users').doc(req.user.uid).get();

    if (!doc.exists) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    res.json({ success: true, data: doc.data() });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

//POST /api/auth/profile
const upsertProfile = async (req, res) => {
  const { name, email } = req.body;
  try {
    const profile = {
      uid:   req.user.uid,
      name:  name  || req.user.name || email.split('@')[0],
      email: email || req.user.email,
      updatedAt: new Date().toISOString(),
    };

    await db.collection('users').doc(req.user.uid).set(profile, { merge: true });
    await auth.updateUser(req.user.uid, { displayName: profile.name });

    res.json({ success: true, data: profile });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

//DELETE /api/auth/profile
const deleteAccount = async (req, res) => {
  try {
    await db.collection('users').doc(req.user.uid).delete();
    await auth.deleteUser(req.user.uid);
    res.json({ success: true, message: 'Account deleted' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

module.exports = { getProfile, upsertProfile, deleteAccount };
