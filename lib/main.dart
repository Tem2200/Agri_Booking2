import 'package:agri_booking2/pages/GenaralUser/tabbar.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agri_booking2/pages/employer/Tabbar.dart';
import 'package:agri_booking2/pages/contactor/Tabbar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
<<<<<<< HEAD
<<<<<<< HEAD

=======
>>>>>>> Whan
=======
>>>>>>> Whan
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
List<dynamic> bookings = [];
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
<<<<<<< HEAD
<<<<<<< HEAD
  await Firebase.initializeApp();
=======
>>>>>>> Whan
=======
>>>>>>> Whan
  await initializeDateFormatting('th_TH', null);
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
    if (mid != null && type != null) {
      if (type == 1) {
        Navigator.pushAndRemoveUntil(
          // ignore: use_build_context_synchronously
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
          // ignore: use_build_context_synchronously
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
        final prefs = await SharedPreferences.getInstance();
        // ดึงค่าหน้าเก่าสุด (default = Tabbar)
        final lastPage = prefs.getString('last_page') ?? 'Tabbar';

        if (lastPage == 'TabbarCar') {
          Navigator.pushAndRemoveUntil(
<<<<<<< HEAD
<<<<<<< HEAD
=======
            // ignore: use_build_context_synchronously
>>>>>>> Whan
=======
            // ignore: use_build_context_synchronously
>>>>>>> Whan
            context,
            MaterialPageRoute(
              builder: (context) => TabbarCar(
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
<<<<<<< HEAD
<<<<<<< HEAD
=======
            // ignore: use_build_context_synchronously
>>>>>>> Whan
=======
            // ignore: use_build_context_synchronously
>>>>>>> Whan
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
        }
      } else {
        Navigator.pushAndRemoveUntil(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(
              builder: (context) => const TabbarGenaralUser(value: 0)),
          (route) => false,
        );
      }
    } else {
      Navigator.pushAndRemoveUntil(
        // ignore: use_build_context_synchronously
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
