const {setGlobalOptions} = require("firebase-functions");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

setGlobalOptions({
  maxInstances: 10,
});

initializeApp();

const db = getFirestore();
const messaging = getMessaging();

// =========================================================
// AUTOMATIC MESSAGE NOTIFICATION
// =========================================================

exports.sendMessageNotification = onDocumentCreated(
  "chats/{chatId}/messages/{messageId}",
  async (event) => {
    const snapshot = event.data;

    if (!snapshot) {
      console.log("❌ Message snapshot missing");
      return;
    }

    const message = snapshot.data();

    const senderId = message.senderId;
    const receiverId = message.receiverId;
    const messageText = message.message || "";

    if (!senderId || !receiverId) {
      console.log("❌ senderId or receiverId missing");
      return;
    }

    console.log("📩 New message detected");
    console.log("Sender:", senderId);
    console.log("Receiver:", receiverId);
    console.log("Message:", messageText);

    // -------------------------------------------------------
    // Get receiver user document
    // -------------------------------------------------------

    const receiverDoc =
      await db.collection("users").doc(receiverId).get();

    if (!receiverDoc.exists) {
      console.log("❌ Receiver user not found");
      return;
    }

    const receiverData = receiverDoc.data();

    const fcmToken = receiverData.fcmToken;

    if (!fcmToken) {
      console.log("❌ Receiver FCM token not found");
      return;
    }

    // -------------------------------------------------------
    // Get sender information
    // -------------------------------------------------------

    const senderDoc =
      await db.collection("users").doc(senderId).get();

    const senderData =
      senderDoc.exists ? senderDoc.data() : {};

    const senderName =
      senderData.name || "NChat";

    // -------------------------------------------------------
    // Notification body
    // -------------------------------------------------------

    let notificationBody = messageText;

    if (message.type === "image") {
      notificationBody = "📷 Photo";
    }

    if (message.type === "audio") {
      notificationBody = "🎤 Voice message";
    }

    if (!notificationBody) {
      notificationBody = "New message";
    }

    // -------------------------------------------------------
    // Send FCM notification
    // -------------------------------------------------------

    try {
      const response = await messaging.send({
        token: fcmToken,

        notification: {
          title: senderName,
          body: notificationBody,
        },

        data: {
          type: "message",
          chatId: event.params.chatId,
          receiverId: receiverId,
          userName: senderName,
        },

        android: {
          priority: "high",
          notification: {
            channelId: "nchat_notifications",
          },
        },
      });

      console.log("✅ Notification sent:", response);
    } catch (error) {
      console.error(
        "❌ Notification sending failed:",
        error,
      );
    }
  },
);