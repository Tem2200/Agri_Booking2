import 'package:agri_booking2/pages/employer/notification_detail_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

// ในไฟล์ lib/pages/employer/notification_screen.dart
class _NotificationScreenState extends State<NotificationScreen> {
  // สร้างตัวแปรสำหรับเก็บ token ของเครื่องนี้
  String? _deviceToken;

  @override
  void initState() {
    super.initState();
    // เรียกใช้ฟังก์ชันเริ่มต้น Firebase Messaging เมื่อ widget ถูกสร้างขึ้น
    _initFirebaseMessaging(); // เปลี่ยนชื่อให้ชัดเจนขึ้น
  }

  void _initFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 1. รับ Token ของเครื่องนี้
    String? token = await messaging.getToken();
    print("Firebase Messaging Token: $token");
    setState(() {
      _deviceToken = token; // เก็บ token ไว้ใน state เพื่อใช้งานในภายหลัง
    });

    // 2. สำหรับจัดการข้อความเมื่อแอปอยู่ในสถานะเบื้องหน้า (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.notification?.title ?? "No Title";
      final body = message.notification?.body ?? "No Body";
      print("Message received (Foreground): ${message.notification?.title}");

      // แสดง AlertDialog เมื่อได้รับข้อความใน Foreground
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title), // ใช้ title ที่ได้รับมา
          content: Text(
            body,
            maxLines: 2, // ควรเพิ่มบรรทัด เพื่อให้แสดงข้อความได้มากขึ้น
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // ปิด AlertDialog
                // คุณอาจจะนำทางไปหน้า detail screen ได้เลย หรือให้ผู้ใช้กดปุ่ม View Details
                // Navigator.push(
                //     context,
                //     MaterialPageRoute(
                //         builder: (context) => NotificationDetailScreen(
                //             title: title, body: body)));
              },
              child: const Text("ปิด"),
            ),
            TextButton(
              // เพิ่มปุ่มสำหรับดูรายละเอียด
              onPressed: () {
                Navigator.pop(context); // ปิด AlertDialog ก่อน
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => NotificationDetailScreen(
                            title: title, body: body)));
              },
              child: const Text("ดูรายละเอียด"),
            ),
          ],
        ),
      );
    });

    // 3. สำหรับจัดการข้อความเมื่อแอปถูกเปิดจากสถานะเบื้องหลัง (Background)
    // หรือถูกปิด (Terminated) โดยการแตะที่การแจ้งเตือน
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final title = message.notification?.title ?? "No Title";
      final body = message.notification?.body ?? "No Body";
      print(
          "Message opened app from background: ${message.notification?.title}");
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  NotificationDetailScreen(title: title, body: body)));
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        final title = message.notification?.title ?? "No Title";
        final body = message.notification?.body ?? "No Body";
        print(
            "Message opened app from terminated state: ${message.notification?.title}");
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    NotificationDetailScreen(title: title, body: body)));
      }
    });

    // ****** สำคัญ: ลบโค้ดซ้ำซ้อนนี้ออก! ******
    // FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    //   final title = message.notification?.title ?? "No Title";
    //   final body = message.notification?.body ?? "No Body";
    //   Navigator.push(
    //       context,
    //       MaterialPageRoute(
    //           builder: (context) =>
    //               NotificationDetailScreen(title: title, body: body)));
    // });
    // ****** ^^^^^^^^^^^^^^^^^^^^^^^^^^^ ******
  }

  @override
  Widget build(BuildContext context) {
    // โค้ด UI ของคุณ
    return Scaffold(
      backgroundColor: Colors.blue[100],
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: const Text(
          "Notifications",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // สามารถแสดง token ของเครื่องนี้ได้ที่นี่เพื่อการดีบัก
            if (_deviceToken != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Your FCM Token: $_deviceToken",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            // ปุ่มที่คุณจะใช้เรียก Cloud Function เพื่อส่งการแจ้งเตือน (ที่คุยกันไปก่อนหน้านี้)
            ElevatedButton(
              onPressed: () {
                // ตัวอย่าง: เรียก _sendNotificationToUser(token_ของ_ผู้รับ, "หัวข้อ", "เนื้อหา")
                // คุณจะต้องมี token ของผู้รับจากฐานข้อมูล หรือจากการเลือกผู้ใช้ใน UI
                // _sendNotificationToUser("SOME_OTHER_USER_FCM_TOKEN", "Hello", "This is a test notification!");
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'คุณยังไม่ได้เชื่อมต่อปุ่มนี้กับการส่งแจ้งเตือนผ่าน Cloud Functions')),
                );
              },
              child: const Text("ส่งแจ้งเตือน"),
            ),
          ],
        ),
      ),
    );
  }
}
