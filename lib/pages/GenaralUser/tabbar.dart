import 'package:agri_booking2/pages/GenaralUser/home.dart';
import 'package:agri_booking2/pages/login.dart';
import 'package:flutter/material.dart';

class TabbarGenaralUser extends StatefulWidget {
  final int value;

  const TabbarGenaralUser({
    super.key,
    required this.value,
  });

  @override
  State<TabbarGenaralUser> createState() => _TabbarCarState();
}

class _TabbarCarState extends State<TabbarGenaralUser> {
  late int value;
  late Widget currentPage;

  @override
  void initState() {
    super.initState();
    value = widget.value;
    switchPage(value);
  }

  void switchPage(int index) {
    setState(() {
      value = index;
      if (index == 0) {
        currentPage = const HomeGe();
      } else if (index == 1) {
        currentPage = const Login();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: currentPage,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: value,
        type: BottomNavigationBarType.fixed, // 👉 เพิ่มบรรทัดนี้
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'หน้าแรก',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.login),
            label: 'เข้าสู่ระบบ',
          ),
        ],
        onTap: switchPage,
        selectedItemColor: const Color(0xFFEF6C00),
        unselectedItemColor: Colors.black,
      ),
    );
  }
}
