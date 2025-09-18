// import 'package:agri_booking2/pages/employer/notification_detail_screen.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// // ไม่จำเป็นต้อง import 'package:flutter/widgets.dart'; ซ้ำ เพราะ material.dart ได้รวมไว้แล้ว
// import 'package:flutter/foundation.dart'
//     show
//         defaultTargetPlatform,
//         kDebugMode,
//         kIsWeb; // ใช้ kDebugMode สำหรับการดีบักเท่านั้น และ defaultTargetPlatform สำหรับเช็คแพลตฟอร์ม

// class NotificationScreen extends StatefulWidget {
//   const NotificationScreen({super.key});

//   @override
//   State<NotificationScreen> createState() => _NotificationScreenState();
// }

// class _NotificationScreenState extends State<NotificationScreen> {
//   // สร้างตัวแปรสำหรับเก็บ token ของเครื่องนี้
//   String? _deviceToken;

//   @override
//   void initState() {
//     super.initState();
//     // เรียกใช้ฟังก์ชันเริ่มต้น Firebase Messaging เมื่อ widget ถูกสร้างขึ้น
//     _initializeFirebaseMessaging(); // เปลี่ยนชื่อให้ชัดเจนและเป็นสากลขึ้น
//   }

//   void _initializeFirebaseMessaging() async {
//     FirebaseMessaging messaging = FirebaseMessaging.instance;

//     // **ขั้นตอนที่ 1: ขออนุญาตการแจ้งเตือน (สำคัญมากสำหรับ iOS/Web)**
//     // ขั้นตอนนี้จะแสดงหน้าต่างขออนุญาตการแจ้งเตือนให้ผู้ใช้เห็น
//     // provisional: true ช่วยให้ผู้ใช้สามารถเลือกประเภทการแจ้งเตือนได้ในภายหลัง
//     NotificationSettings settings = await messaging.requestPermission(
//       alert: true,
//       announcement: false,
//       badge: true,
//       carPlay: false,
//       criticalAlert: false,
//       provisional:
//           true, // ทำให้ข้อความปรากฏใน Notification Center โดยไม่ต้องขออนุญาตทันที
//       sound: true,
//     );

//     if (kDebugMode) {
//       // จะแสดงผลลัพธ์ใน console เฉพาะตอนอยู่ในโหมด Debug
//       if (settings.authorizationStatus == AuthorizationStatus.authorized) {
//         print('User granted permission: Authorized');
//       } else if (settings.authorizationStatus ==
//           AuthorizationStatus.provisional) {
//         print('User granted provisional permission: Provisional');
//       } else {
//         print('User declined or has not accepted permission: Denied');
//       }
//     }

//     // **ขั้นตอนที่ 2: ดึงข้อมูล APNS Token (สำหรับ iOS/macOS)**
//     // สำหรับแพลตฟอร์ม Apple (iOS/macOS) ต้องแน่ใจว่าได้ APNS token ก่อนที่จะเรียกใช้ FCM API อื่นๆ
//     if (defaultTargetPlatform == TargetPlatform.iOS ||
//         defaultTargetPlatform == TargetPlatform.macOS) {
//       final apnsToken = await messaging.getAPNSToken();
//       if (apnsToken == null) {
//         if (kDebugMode) {
//           print(
//               'APNs Token is not available yet. Cannot proceed with FCM token retrieval on Apple platforms.');
//         }
//         // หาก APNS token ยังไม่พร้อม อาจต้องลองใหม่หรือแนะนำผู้ใช้ให้ไปที่การตั้งค่า
//         return; // ออกจากฟังก์ชันหาก APNS token ยังไม่พร้อม
//       } else {
//         if (kDebugMode) {
//           print('APNs Token: $apnsToken');
//         }
//       }
//     }

//     // **ขั้นตอนที่ 3: รับ FCM Registration Token**
//     String? token;
//     if (kIsWeb) {
//       // สำหรับ Web คุณต้องใส่ VAPID Key Public Key ของคุณ
//       // คุณสามารถค้นหาได้ที่ Firebase Project settings -> Cloud Messaging tab.
//       // **โปรดแทนที่ "YOUR_VAPID_PUBLIC_KEY_HERE" ด้วย VAPID Public Key ของคุณจริง!**
//       try {
//         token =
//             await messaging.getToken(vapidKey: "YOUR_VAPID_PUBLIC_KEY_HERE");
//         if (kDebugMode) {
//           print('FCM Token (Web): $token');
//         }
//       } catch (e) {
//         if (kDebugMode) {
//           print('Error getting FCM token for Web: $e');
//         }
//       }
//     } else {
//       // สำหรับแพลตฟอร์มอื่นๆ (Android, iOS)
//       token = await messaging.getToken();
//       if (kDebugMode) {
//         print('FCM Token (Mobile): $token');
//       }
//     }

//     if (token != null) {
//       setState(() {
//         _deviceToken = token; // เก็บ token ไว้ใน state
//       });
//       // **แนวทางปฏิบัติที่ดีที่สุด (Best Practice) ที่สำคัญมาก:**
//       // คุณควรส่ง Token นี้ไปยังเซิร์ฟเวอร์ Backend ของคุณ
//       // เพื่อที่คุณจะสามารถส่งการแจ้งเตือนแบบเฉพาะเจาะจงไปยังผู้ใช้คนนี้ได้ในภายหลัง!
//       // ตัวอย่าง: YourApiClass.sendFCMTokenToBackend(token);
//       if (kDebugMode) {
//         print('FCM Token obtained: $_deviceToken');
//       }
//     } else {
//       if (kDebugMode) {
//         print('Failed to get FCM Token.');
//       }
//     }

//     // **ขั้นตอนที่ 4: ตรวจสอบการเปลี่ยนแปลง Token (Token Refresh)**
//     // Stream นี้จะทำงานเมื่อ Token มีการเปลี่ยนแปลง (เช่น ติดตั้งแอปใหม่, ลบข้อมูลแอป)
//     // คุณควรส่ง Token ใหม่นี้ไปยังเซิร์ฟเวอร์ Backend ของคุณด้วย!
//     messaging.onTokenRefresh.listen((newToken) {
//       if (kDebugMode) {
//         print('FCM Token refreshed: $newToken');
//       }
//       setState(() {
//         _deviceToken = newToken;
//       });
//       // ส่ง newToken นี้ไปยังเซิร์ฟเวอร์ Backend ของคุณทันที!
//       // YourApiClass.sendFCMTokenToBackend(newToken);
//     }).onError((error) {
//       if (kDebugMode) {
//         print('Error refreshing FCM token: $error');
//       }
//     });

//     // **ขั้นตอนที่ 5: จัดการข้อความเมื่อแอปอยู่ในสถานะเบื้องหน้า (Foreground)**
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       final title = message.notification?.title ?? "No Title";
//       final body = message.notification?.body ?? "No Body";
//       if (kDebugMode) {
//         print("Message received (Foreground): ${message.notification?.title}");
//         print("Message data (Foreground): ${message.data}");
//       }

//       // แสดง AlertDialog เมื่อได้รับข้อความใน Foreground
//       showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: Text(title),
//           content: Text(
//             body,
//             maxLines: 3, // เพิ่มบรรทัดให้แสดงข้อความได้มากขึ้น
//             overflow: TextOverflow.ellipsis, // แสดงจุดไข่ปลาถ้าข้อความยาวเกิน
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context); // ปิด AlertDialog
//               },
//               child: const Text("ปิด"),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context); // ปิด AlertDialog ก่อน
//                 // คุณสามารถส่งข้อมูลทั้งหมดใน message.data ไปยังหน้า detail ได้ด้วย
//                 // เพื่อให้หน้า detail มีข้อมูลที่ครบถ้วนมากขึ้น
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => NotificationDetailScreen(
//                       title: title,
//                       body: body,
//                       // data: message.data, // หากต้องการส่งข้อมูลเพิ่มเติม
//                     ),
//                   ),
//                 );
//               },
//               child: const Text("ดูรายละเอียด"),
//             ),
//           ],
//         ),
//       );
//     });

//     // **ขั้นตอนที่ 6: จัดการข้อความเมื่อแอปถูกเปิดจากสถานะเบื้องหลัง (Background/Quit)**
//     // โดยการแตะที่การแจ้งเตือน
//     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//       final title = message.notification?.title ?? "No Title";
//       final body = message.notification?.body ?? "No Body";
//       if (kDebugMode) {
//         print(
//             "Message opened app from background/quit: ${message.notification?.title}");
//         print("Message data (onMessageOpenedApp): ${message.data}");
//       }
//       // นำทางไปยังหน้า detail
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => NotificationDetailScreen(
//             title: title,
//             body: body,
//             // data: message.data, // หากต้องการส่งข้อมูลเพิ่มเติม
//           ),
//         ),
//       );
//     });

//     // **ขั้นตอนที่ 7: จัดการข้อความเมื่อแอปถูกเปิดจากสถานะถูกปิด (Terminated)**
//     // โค้ดนี้จะทำงานเมื่อแอปปิดสนิทอยู่แล้ว และผู้ใช้แตะที่การแจ้งเตือนเพื่อเปิดแอปขึ้นมา
//     messaging.getInitialMessage().then((message) {
//       if (message != null) {
//         final title = message.notification?.title ?? "No Title";
//         final body = message.notification?.body ?? "No Body";
//         if (kDebugMode) {
//           print(
//               "App opened from terminated state by notification: ${message.notification?.title}");
//           print("Message data (getInitialMessage): ${message.data}");
//         }
//         // นำทางไปยังหน้า detail
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => NotificationDetailScreen(
//               title: title,
//               body: body,
//               // data: message.data, // หากต้องการส่งข้อมูลเพิ่มเติม
//             ),
//           ),
//         );
//       }
//     });

//     // โค้ดส่วนที่ซ้ำซ้อนที่คุณคอมเมนต์ไว้ ได้ถูกลบออกไปแล้วครับ!
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.blue[100],
//       appBar: AppBar(
//         backgroundColor: Colors.blue,
//         foregroundColor: Colors.white,
//         title: const Text(
//           "Notifications",
//           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
//         ),
//         centerTitle: true,
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // แสดง token ของเครื่องนี้เพื่อการดีบักและคัดลอกได้ง่าย
//             if (_deviceToken != null)
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: SelectableText(
//                   // ใช้ SelectableText เพื่อให้คัดลอก token ได้
//                   "Your FCM Token:\n$_deviceToken",
//                   textAlign: TextAlign.center,
//                   style: const TextStyle(fontSize: 12, color: Colors.black54),
//                 ),
//               ),
//             ElevatedButton(
//               onPressed: () {
//                 // **ย้ำอีกครั้ง:** การส่งการแจ้งเตือนควรทำจากเซิร์ฟเวอร์ที่เชื่อถือได้เท่านั้น
//                 // เช่น Cloud Functions for Firebase หรือเซิร์ฟเวอร์ backend ของคุณเอง
//                 // เพื่อความปลอดภัยและเสถียรภาพในการทำงาน
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(
//                     content: Text(
//                       'การส่งแจ้งเตือนต้องทำจากเซิร์ฟเวอร์ที่เชื่อถือได้ (เช่น Cloud Functions) เพื่อความปลอดภัยและเสถียรภาพ',
//                       style: TextStyle(color: Colors.white),
//                     ),
//                     backgroundColor: Colors.redAccent, // ใช้สีแดงเพื่อเน้นย้ำ
//                     duration: Duration(seconds: 5),
//                   ),
//                 );
//               },
//               child: const Text("ส่งแจ้งเตือน (ผ่านเซิร์ฟเวอร์)"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
