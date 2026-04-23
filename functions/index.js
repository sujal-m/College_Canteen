const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.notifyAdminOnOrder = functions.firestore
  .document('orders/{orderId}')
  .onCreate(async (snap, context) => {
    const order = snap.data();
    const adminDoc = await admin.firestore()
      .collection('users')
      .where('role', '==', 'admin')
      .limit(1).get();

    if (adminDoc.empty) return;
    const adminToken = adminDoc.docs[0].data().fcmToken;
    if (!adminToken) return;

    return admin.messaging().send({
      token: adminToken,
      notification: {
        title: '🍽️ New Order Received!',
        body: `${order.userName} ordered ₹${order.total}`,
      },
      data: { orderId: context.params.orderId, type: 'new_order' },
    });
  });

exports.notifyUserOnStatusChange = functions.firestore
  .document('orders/{orderId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after  = change.after.data();
    if (before.status === after.status) return;

    const userDoc = await admin.firestore()
      .collection('users').doc(after.userId).get();
    const userToken = userDoc.data()?.fcmToken;
    if (!userToken) return;

    const statusEmoji = {
      'Preparing': '👨‍🍳',
      'Ready to Pick Up': '✅',
    }[after.status] || '📦';

    return admin.messaging().send({
      token: userToken,
      notification: {
        title: `${statusEmoji} Order Update`,
        body: `Your order is now: ${after.status}`,
      },
    });
  });