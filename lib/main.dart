import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agri_booking2/pages/login.dart';
import 'package:agri_booking2/pages/employer/Tabbar.dart';
import 'package:agri_booking2/pages/contactor/Tabbar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  final mid = prefs.getInt('mid');
  final type = prefs.getInt('type_member');

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
      // type 3 ให้กลับไป login เพื่อเลือก role ใหม่ทุกครั้ง
      startPage = const Login();
    }
  }

  runApp(MyApp(home: startPage));
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
      home: home,
    );
  }
}
