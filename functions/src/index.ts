import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

export const onFriendRequestCreated = functions.firestore
  .document("users/{targetUid}/friend_requests/{senderUid}")
  .onCreate(async (snapshot, context) => {
    const {targetUid, senderUid} = context.params;

    const data = snapshot.data();
    if (!data) return;

    const targetUserSnap = await admin
      .firestore()
      .collection("users")
      .doc(targetUid)
      .get();

    if (!targetUserSnap.exists) return;

    const targetUser = targetUserSnap.data();
    const fcmToken = targetUser?.fcmToken;

    if (!fcmToken) {
      console.log("Pas de token FCM pour", targetUid);
      return;
    }

    const senderName = data.displayName ?? "Quelqu’un";

    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: "Nouvelle demande d’ami",
        body: `${senderName} souhaite vous ajouter`,
      },
      data: {
        type: "friend_request",
        senderUid: senderUid,
      },
    });

    console.log("Notification envoyée à", targetUid);
  });
