// https://github.com/firebase/functions-samples/blob/master/quickstarts/uppercase-firestore/functions/index.js
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

const ERROR_CODE = 1;
const SUCCESS_CODE = 0;

// // Start writing Firebase Functions
// // https://firebase.google.com/docs/functions/typescript
//
// export const helloWorld = functions.https.onRequest((request, response) => {
//   functions.logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

// https://stackoverflow.com/questions/64887456/how-to-limit-instance-count-of-firebase-functions

export const notificationForNewChatMessage = functions
  .runWith({ memory: "128MB", timeoutSeconds: 2, maxInstances: 2 })
  .firestore.document("/chatMessages/{id}")
  .onCreate(async (snap, _context) => {
    // https://github.com/firebase/functions-samples/blob/master/fcm-notifications/functions/index.js
    const snapData = snap.data();
    const snapMessage: String = snapData["message"];
    if (typeof snapMessage !== "string") {
      console.log(`Error: snapMessage type is wrong`);
      return ERROR_CODE;
    }
    const speakerUid = snapData["speakerUid"];
    if (typeof speakerUid !== "string") {
      console.log(`Error: speakerUid type is wrong`);
      return ERROR_CODE;
    }
    const requesterId: String = snapData["requester"]?.id;
    if (typeof requesterId !== "string") {
      console.log(`Error: requesterId type is wrong`);
      return ERROR_CODE;
    }
    const donatorId: String = snapData["donator"]?.id;
    if (typeof donatorId !== "string") {
      console.log(`Error: donatorId type is wrong`);
      return ERROR_CODE;
    }

    // If the speaker is the donator, then the receiver is the requester,
    // and vice versa
    const isDonatorSpeaking = donatorId === speakerUid;

    const receiverUid = isDonatorSpeaking ? requesterId : donatorId;
    const receiverPrivateCollection = admin
      .firestore()
      .collection(isDonatorSpeaking ? "privateRequesters" : "privateDonators");
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
      .collection(isDonatorSpeaking ? "donators" : "requesters")
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
          console.log("Trying to send message");
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
    return SUCCESS_CODE;
  });
