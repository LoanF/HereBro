import {
  onDocumentCreated,
  onDocumentDeleted,
} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

admin.initializeApp();

const REGION = "europe-west1";

/**
 * Notification : NOUVELLE demande d’ami
 */
export const onFriendRequestCreated = onDocumentCreated(
  {
    region: REGION,
    document: "users/{receiverUid}/friendRequests/{senderUid}",
  },
  async (event) => {
    const {senderUid, receiverUid} = event.params;

    const senderDoc = await admin
      .firestore()
      .doc(`users/${senderUid}`)
      .get();

    const receiverDoc = await admin
      .firestore()
      .doc(`users/${receiverUid}`)
      .get();

    if (!senderDoc.exists || !receiverDoc.exists) return;

    const receiverToken = receiverDoc.data()?.fcmToken;
    if (!receiverToken) return;

    const senderName =
      senderDoc.data()?.displayName ?? "Un utilisateur";

    await admin.messaging().send({
      token: receiverToken,
      notification: {
        title: "Nouvelle demande d’ami",
        body: `${senderName} vous a envoyé une demande d’ami`,
      },
      data: {
        type: "friend_request",
        uid: senderUid,
      },
    });
  }
);

/**
 * Demande d’ami ACCEPTÉE
 */
export const onFriendAccepted = onDocumentCreated(
  {
    region: REGION,
    document: "users/{senderUid}/contacts/{receiverUid}",
  },
  async (event) => {
    const {senderUid, receiverUid} = event.params;

    const senderDoc = await admin
      .firestore()
      .doc(`users/${senderUid}`)
      .get();

    const receiverDoc = await admin
      .firestore()
      .doc(`users/${receiverUid}`)
      .get();

    if (!senderDoc.exists || !receiverDoc.exists) return;

    const token = senderDoc.data()?.fcmToken;
    if (!token) return;

    const receiverName =
      receiverDoc.data()?.displayName ?? "Un utilisateur";

    await admin.messaging().send({
      token,
      notification: {
        title: "Demande acceptée",
        body: `${receiverName} a accepté votre demande`,
      },
      data: {
        type: "friend_accept",
        uid: receiverUid,
      },
    });
  }
);

/**
 * Demande d’ami REFUSÉE
 */
export const onFriendRefused = onDocumentDeleted(
  {
    region: REGION,
    document: "users/{receiverUid}/friendRequests/{senderUid}",
  },
  async (event) => {
    const {senderUid, receiverUid} = event.params;

    const senderDoc = await admin
      .firestore()
      .doc(`users/${senderUid}`)
      .get();

    const receiverDoc = await admin
      .firestore()
      .doc(`users/${receiverUid}`)
      .get();

    if (!senderDoc.exists || !receiverDoc.exists) return;

    const token = senderDoc.data()?.fcmToken;
    if (!token) return;

    const receiverName =
      receiverDoc.data()?.displayName ?? "Un utilisateur";

    await admin.messaging().send({
      token,
      notification: {
        title: "Demande refusée",
        body: `${receiverName} a refusé votre demande`,
      },
      data: {
        type: "friend_refuse",
        uid: receiverUid,
      },
    });
  }
);
