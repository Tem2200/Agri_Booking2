import 'dart:convert';

import 'package:agri_booking2/firebase_options.dart';
import 'package:agri_booking2/pages/GenaralUser/tabbar.dart';
import 'package:agri_booking2/pages/send_email.dart';
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:agri_booking2/pages/login.dart';
import 'package:agri_booking2/pages/employer/Tabbar.dart';
import 'package:agri_booking2/pages/contactor/Tabbar.dart';
import 'package:agri_booking2/pages/employer/DetailReserving.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
Future<void> _backgroundMessaginf(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

List<dynamic> bookings = [];
late Timer _timer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final prefs = await SharedPreferences.getInstance();
  final mid = prefs.getInt('mid');
  final type = prefs.getInt('type_member');

  if (type == 2 && mid != null) {
    // contractor subscribe topic
    await FirebaseMessaging.instance.subscribeToTopic("user_$mid");
  }

  Widget startPage;

  if (mid == null || type == null) {
    startPage = const Login();
  } else {
    int currentMonth = DateTime.now().month;
    int currentYear = DateTime.now().year;

    if (type == 1) {
      startPage = TabbarCar(
        mid: mid,
        value: 0,
        month: currentMonth,
        year: currentYear,
      );
    } else if (type == 2) {
      startPage = Tabbar(
        mid: mid,
        value: 0,
        month: currentMonth,
        year: currentYear,
      );
    } else {
      startPage = const Login();
    }
  }

  runApp(MyApp(home: startPage));
}

Future<void> initializeNotification(
    FlutterLocalNotificationsPlugin plugin) async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await plugin.initialize(
    initializationSettings,
  );
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("Handling background message: ${message.data}");
}

void _handleMessage(RemoteMessage message) {
  print("User tapped notification: ${message.data}");

  if (message.data.containsKey('rsid')) {
    final rsidStr = message.data['rsid'];
    final rsid = int.tryParse(rsidStr ?? '') ?? 0;

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => DetailReserving(rsid: rsid),
      ),
    );
  }
}

Future<void> _showNotification(
    FlutterLocalNotificationsPlugin plugin, RemoteMessage message) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'your_channel_id',
    'your_channel_name',
    importance: Importance.max,
    priority: Priority.high,
  );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await plugin.show(
    message.hashCode,
    message.notification?.title ?? '',
    message.notification?.body ?? '',
    platformChannelSpecifics,
    payload: jsonEncode(message.data),
  );
}

class MyApp extends StatelessWidget {
  final Widget home;

  const MyApp({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Agri Booking',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        navigatorKey: navigatorKey,
        home: TabbarGenaralUser(value: 0)); //const SendEmailPage());
    //
  }
}
