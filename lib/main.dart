import 'package:agri_booking2/pages/GenaralUser/tabbar.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'package:agri_booking2/pages/employer/Tabbar.dart';
import 'package:agri_booking2/pages/contactor/Tabbar.dart';
import 'package:google_fonts/google_fonts.dart';
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
List<dynamic> bookings = [];
late Timer _timer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agri Booking',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        textTheme: GoogleFonts.mitrTextTheme(),
      ),
      navigatorKey: navigatorKey,
      home: const CheckSessionPage(), // ✅ ให้เช็ค session ที่นี่
    );
  }
}

class CheckSessionPage extends StatefulWidget {
  const CheckSessionPage({super.key});

  @override
  State<CheckSessionPage> createState() => _CheckSessionPageState();
}

class _CheckSessionPageState extends State<CheckSessionPage> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final mid = prefs.getInt('mid');
    final type = prefs.getInt('type_member');

    int currentMonth = DateTime.now().month;
    int currentYear = DateTime.now().year;

//     if (mid != null && type != null) {
//       if (type == 1) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (context) => TabbarCar(
//               mid: mid,
//               value: 0,
//               month: currentMonth,
//               year: currentYear,
//             ),
//           ),
//         );
//       } else if (type == 2) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (context) => Tabbar(
//               mid: mid,
//               value: 0,
//               month: currentMonth,
//               year: currentYear,
//             ),
//           ),
//         );
//       } else if (type == 3) {
//   Navigator.pushReplacement(
//     context,
//     MaterialPageRoute(
//       builder: (context) => Tabbar(
//         mid: mid,
//         value: 0,
//         month: currentMonth,
//         year: currentYear,
//       ),
//     ),
//   );
// } else {
//   Navigator.pushReplacement(
//     context,
//     MaterialPageRoute(builder: (context) => const Login()),
//   );
// }
//     } else {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => const Login()),
//       );
//     }
    if (mid != null && type != null) {
      if (type == 1) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => TabbarCar(
              mid: mid,
              value: 0,
              month: currentMonth,
              year: currentYear,
            ),
          ),
          (route) => false, // เคลียร์ stack
        );
      } else if (type == 2) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => Tabbar(
              mid: mid,
              value: 0,
              month: currentMonth,
              year: currentYear,
            ),
          ),
          (route) => false,
        );
      } else if (type == 3) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => Tabbar(
              mid: mid,
              value: 0,
              month: currentMonth,
              year: currentYear,
            ),
          ),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => const TabbarGenaralUser(value: 0)),
          (route) => false,
        );
      }
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) => const TabbarGenaralUser(value: 0)),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}


// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();

//   final prefs = await SharedPreferences.getInstance();
//   final mid = prefs.getInt('mid');
//   final type = prefs.getInt('type_member');

//   Widget startPage;

//   int currentMonth = DateTime.now().month;
//   int currentYear = DateTime.now().year;

//   if (mid == null || type == null) {
//     // ยังไม่ login → ไปหน้า Login
//     startPage = const Login();
//   } else if (type == 1) {
//     startPage = TabbarCar(
//       mid: mid,
//       value: 0,
//       month: currentMonth,
//       year: currentYear,
//     );
//   } else if (type == 2) {
//     startPage = Tabbar(
//       mid: mid,
//       value: 0,
//       month: currentMonth,
//       year: currentYear,
//     );
//   } else {
//     startPage = const Login();
//   }

//   runApp(MyApp(home: startPage));
// }

// // class MyApp extends StatelessWidget {
// //   final Widget home;

// //   const MyApp({super.key, required this.home});

// //   @override
// //   Widget build(BuildContext context) {
// //     return MaterialApp(
// //       title: 'Agri Booking',
// //       theme: ThemeData(
// //         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
// //         useMaterial3: true,
// //         textTheme: GoogleFonts.mitrTextTheme(),
// //       ),
// //       home: home, // หน้าแรกของแอปตาม session
// //     );
// //   }
// // }

// class MyApp extends StatelessWidget {
//   final Widget home;

//   const MyApp({super.key, required this.home});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Agri Booking',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,

//         // ⬅️ ใช้ฟอนต์ Mitr ทั้งแอป
//         textTheme: GoogleFonts.mitrTextTheme(),
//       ),
//       navigatorKey: navigatorKey,
//       home: const CheckSessionPage(),
//     );
//     //const TabbarGenaralUser(value: 0)); //const SendEmailPage());
//     //
//   }
// }

// class CheckSessionPage extends StatefulWidget {
//   const CheckSessionPage({super.key});

//   @override
//   State<CheckSessionPage> createState() => _CheckSessionPageState();
// }

// class _CheckSessionPageState extends State<CheckSessionPage> {
//   @override
//   void initState() {
//     super.initState();
//     _checkLogin();
//   }

//   Future<void> _checkLogin() async {
//     final prefs = await SharedPreferences.getInstance();
//     final mid = prefs.getInt('mid');
//     final type = prefs.getInt('type_member');

//     if (mid != null && type != null) {
//       int currentMonth = DateTime.now().month;
//       int currentYear = DateTime.now().year;

//       if (type == 1) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (context) => TabbarCar(
//               mid: mid,
//               value: 0,
//               month: currentMonth,
//               year: currentYear,
//             ),
//           ),
//         );
//       } else if (type == 2) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (context) => Tabbar(
//               mid: mid,
//               value: 0,
//               month: currentMonth,
//               year: currentYear,
//             ),
//           ),
//         );
//       } else {
//         // type == 3 ให้กลับไป login ใหม่เพื่อเลือก
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => const Login()),
//         );
//       }
//     } else {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => const Login()),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Splash screen ตอนโหลด
//     return const Scaffold(
//       body: Center(child: CircularProgressIndicator()),
//     );
//   }
// }
