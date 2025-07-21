const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

/**
 * Triggers when a new message is added by an admin.
 * It sends a push notification to the user.
 */
exports.sendChatNotification = functions.firestore
    .document("chats/{chatId}/messages/{messageId}")
    .onCreate(async (snap, context) => {
        const messageData = snap.data();
        const chatId = context.params.chatId;

        if (messageData.authorId !== "admin") {
            console.log("Message is not from admin. No notification sent.");
            return null;
        }

        console.log(`New message from admin to user ${chatId}.`);

        const userDoc = await admin
            .firestore()
            .collection("users")
            .doc(chatId)
            .get();

        if (!userDoc.exists) {
            console.error(`User document for ${chatId} not found.`);
            return null;
        }

        const fcmToken = userDoc.data().fcmToken;
        if (!fcmToken) {
            console.log(`User ${chatId} does not have an FCM token.`);
            return null;
        }

        const payload = {
            notification: {
                title: "رد من  👨‍⚕️",
                body: messageData.text || "لديك رسالة جديدة.",
                sound: "default",
            },
            data: {
                "click_action": "FLUTTER_NOTIFICATION_CLICK",
                "chatId": chatId,
            },
        };

        try {
            await admin.messaging().sendToDevice(fcmToken, payload);
            console.log("Successfully sent message.");
            return null;
        } catch (error) {
            console.error("Error sending message:", error);
            return null;
        }
    });