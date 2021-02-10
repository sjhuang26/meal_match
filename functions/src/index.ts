// https://github.com/firebase/functions-samples/blob/master/quickstarts/uppercase-firestore/functions/index.js
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

// // Start writing Firebase Functions
// // https://firebase.google.com/docs/functions/typescript
//
// export const helloWorld = functions.https.onRequest((request, response) => {
//   functions.logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

export const notificationForNewChatMessage = functions.firestore
  .document("/chatMessages/{id}")
  .onCreate(async (snap, _context) => {
    // https://github.com/firebase/functions-samples/blob/master/fcm-notifications/functions/index.js
    const snapData = snap.data();
    const snapMessage = snapData["message"] as string;
    const speakerUid = snapData["speakerUid"] as string;
    const requesterId = (snapData[
      "requester"
    ] as FirebaseFirestore.DocumentReference).id;
    const donatorId = (snapData[
      "donator"
    ] as FirebaseFirestore.DocumentReference).id;
    const receiverUid = donatorId === speakerUid ? requesterId : donatorId;
    const receiverPrivateCollection = admin
      .firestore()
      .collection(
        donatorId === speakerUid ? "privateRequesters" : "privateDonators"
      );
    const promiseReceiverToken = receiverPrivateCollection
      .doc(receiverUid)
      .get()
      .then((x) => (x.data()?.["notificationsDeviceToken"] as string) ?? null)
      .catch((x) => {
        console.log(`Error: ${x}`);
        return null;
      });
    const promiseSpeakerName = admin
      .firestore()
      .collection(donatorId === speakerUid ? "donators" : "requesters")
      .doc(speakerUid)
      .get()
      .then((x) => x.data()?.["name"] as string)
      .catch((x) => {
        console.log(`Error: ${x}`);
        return null;
      });
    // TODO also write to the receiver's notification list in the database
    Promise.all([promiseReceiverToken, promiseSpeakerName]).then(
      ([tokenRes, nameRes]) => {
        if (tokenRes !== null) {
          admin.messaging().sendToDevice(tokenRes, {
            notification: {
              title:
                nameRes === null
                  ? "MealMatch chat message"
                  : `MealMatch chat message from ${nameRes}`,
              body: snapMessage,
            },
          });
        }
      }
    );
  });
