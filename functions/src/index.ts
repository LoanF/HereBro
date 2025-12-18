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
    document: "users/{receiverUid}/friend_requests/{senderUid}",
  },
  async (event) => {
    console.log(
      "TRIGGERED onFriendRequestCreated",
      JSON.stringify(event.params)
    );
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
    document: "users/{userUid}/contacts/{friendUid}",
  },
  async (event) => {
    const {userUid, friendUid} = event.params;
    const data = event.data?.data();

    if (!data) return;


    if (data.isSender === true) {
      return;
    }

    const requesterDoc = await admin
      .firestore()
      .doc(`users/${userUid}`)
      .get();

    const accepterDoc = await admin
      .firestore()
      .doc(`users/${friendUid}`)
      .get();

    if (!requesterDoc.exists || !accepterDoc.exists) return;

    const token = requesterDoc.data()?.fcmToken;
    if (!token) return;

    const accepterName =
      accepterDoc.data()?.displayName ?? "Un utilisateur";

    await admin.messaging().send({
      token,
      notification: {
        title: "Demande acceptée",
        body: `${accepterName} a accepté votre demande d’ami`,
      },
      data: {
        type: "friend_accept",
        uid: friendUid,
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
    document: "users/{receiverUid}/friend_requests/{senderUid}",
  },
  async (event) => {
    const {senderUid, receiverUid} = event.params;

    console.log(
      "TRIGGERED onFriendRefused",
      JSON.stringify(event.params)
    );

    const contactRef = admin
      .firestore()
      .doc(`users/${senderUid}/contacts/${receiverUid}`);

    const contactSnap = await contactRef.get();

    if (contactSnap.exists) {
      console.log(
        "SKIP onFriendRefused → contact already exists (accept flow)"
      );
      return;
    }

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
