
// ต้อง import สองสิ่งนี้เสมอสำหรับ Cloud Functions
const functions = require("firebase-functions"); // สำหรับสร้าง Cloud Functions
const admin = require("firebase-admin"); // สำหรับ Admin SDK ที่จะใช้ส่ง FCM

// eslint-disable-next-line max-len
// เริ่มต้น Firebase Admin SDK (ถ้าไม่ได้ระบุ credentials มันจะหาเองจาก environment ของ Cloud Functions)
admin.initializeApp();

// นี่คือ Cloud Function ที่เราจะเรียกจาก Flutter ครับ
// 'https.onCall' คือฟังก์ชันที่สามารถเรียกได้โดยตรงจาก client (เช่น Flutter)
// โดย Firebase จะจัดการเรื่อง Authentication ให้เราโดยอัตโนมัติ
// eslint-disable-next-line max-len
exports.sendNotificationToUser = functions.https.onCall(async (data, context) => {
  // 1. ตรวจสอบว่าผู้เรียกฟังก์ชันนี้ล็อกอินอยู่หรือไม่
  // นี่คือ Best Practice เพื่อความปลอดภัย
  if (!context.auth) {
    // eslint-disable-next-line max-len
    throw new functions.https.HttpsError("unauthenticated", "User must be authenticated to send notifications.");
  }

  // 2. รับข้อมูลที่ส่งมาจาก Flutter
  const recipientUid = data.recipientUid; // UID ของผู้รับแจ้งเตือน
  const title = data.title;// หัวข้อของแจ้งเตือน
  const body = data.body;// เนื้อหาของแจ้งเตือน

  // ตรวจสอบข้อมูลเบื้องต้น
  if (!recipientUid || !title || !body) {
    // eslint-disable-next-line max-len
    throw new functions.https.HttpsError("invalid-argument", "The function must be called with \"recipientUid\", \"title\", and \"body\".");
  }

  // 3. ดึง FCM token ของผู้รับจาก Cloud Firestore
  // เราสมมติว่าคุณเก็บ token ไว้ใน collection 'fcmTokens'
  // eslint-disable-next-line max-len
  // และ Document ID เป็น UID ของผู้ใช้ (เช่น users/alovelace/fcmTokens/some_device_token_id)
  // หรือ อาจจะเก็บเป็น collection 'fcmTokens' แล้ว doc เป็น user ID เลย
  // ตัวอย่างนี้จะดึงจาก 'fcmTokens/{uid}'
  let recipientToken;
  try {
    // eslint-disable-next-line max-len
    const doc = await admin.firestore().collection("fcmTokens").doc(recipientUid).get();

    if (!doc.exists) {
      // eslint-disable-next-line max-len
      console.warn(`No FCM token found for user ${recipientUid}. Notification not sent.`);
      // eslint-disable-next-line max-len
      throw new functions.https.HttpsError("not-found", `No FCM token found for user ${recipientUid}`);
    }
    // eslint-disable-next-line max-len
    recipientToken = doc.data().token; // สมมติว่า field ที่เก็บ token ชื่อ 'token'

    if (!recipientToken) {
      // eslint-disable-next-line max-len
      console.warn(`FCM token field is empty for user ${recipientUid}. Notification not sent.`);
      // eslint-disable-next-line max-len
      throw new functions.https.HttpsError("internal", `FCM token field is empty for user ${recipientUid}.`);
    }
  } catch (error) {
    console.error(`Error fetching FCM token for ${recipientUid}:`, error);
    // eslint-disable-next-line max-len
    throw new functions.https.HttpsError("internal", "Error fetching recipient token.", error.message);
  }


  // 4. สร้าง Payload ของข้อความ (สิ่งที่จะส่งไปให้แอป)
  const payload = {
    notification: {
      title: title,
      body: body,
    },
    // สามารถเพิ่มข้อมูลเพิ่มเติม (data payload) ได้ที่นี่
    // ข้อมูลใน data payload จะถูกส่งไปยังแอปเสมอ ไม่ว่าแอปจะอยู่ในสถานะใด
    data: {
      // eslint-disable-next-line max-len
      type: "general_notification", // ตัวอย่าง: เพื่อให้แอปทราบว่าเป็นการแจ้งเตือนประเภทใด
      recipientId: recipientUid,
      // eslint-disable-next-line max-len
      // สามารถเพิ่มข้อมูลอื่นๆ ที่คุณต้องการให้แอปนำไปใช้ได้ เช่น ID ของโพสต์, URL
    },
  };

  // 5. ส่งข้อความแจ้งเตือนโดยใช้ Firebase Admin SDK
  try {
    // eslint-disable-next-line max-len
    const response = await admin.messaging().sendToDevice(recipientToken, payload);
    console.log("Successfully sent message:", response);

    // ตรวจสอบผลลัพธ์การส่งแต่ละรายการ (ถ้าส่งไปหลาย token)
    response.results.forEach((result, index) => {
      const error = result.error;
      if (error) {
        console.error("Failure sending notification to", recipientToken, error);
        // eslint-disable-next-line max-len
        // ถ้า token ไม่ถูกต้อง หรือหมดอายุ คุณอาจจะต้องลบ token นั้นออกจาก Firestore
        if (error.code === "messaging/invalid-registration-token" ||
                error.code === "messaging/registration-token-not-registered") {
          // eslint-disable-next-line max-len
          // ตัวอย่าง: admin.firestore().collection('fcmTokens').doc(recipientUid).delete();
          console.log(`Token for ${recipientUid} needs to be removed.`);
        }
      }
    });

    // eslint-disable-next-line max-len
    return {success: true, message: "Notification sent successfully!", results: response.results};
  } catch (error) {
    console.error("Error sending message:", error);
    // eslint-disable-next-line max-len
    throw new functions.https.HttpsError("internal", "Failed to send notification.", error.message);
  }
});


