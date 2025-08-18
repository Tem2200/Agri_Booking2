import 'package:agri_booking2/pages/employer/homeEmp.dart';
import 'package:agri_booking2/pages/employer/plan_emp.dart';
import 'package:agri_booking2/pages/employer/search_emp.dart';
import 'package:flutter/material.dart';

class Tabbar extends StatefulWidget {
  final int value;
  final dynamic mid; // รับข้อมูลจาก Login
  final int month;
  final int year;

  const Tabbar({
    super.key,
    required this.value,
    required this.mid,
    required this.month,
    required this.year,
  });

  @override
  State<Tabbar> createState() => _TabbarCarState();
}

class _TabbarCarState extends State<Tabbar> {
  late int value;
  late Widget currentPage;
  late int _displayMonth;
  late int _displayYear;

  @override
  void initState() {
    super.initState();
    _displayMonth = widget.month;
    _displayYear = widget.year;
    value = widget.value;
    switchPage(value);
  }

  void switchPage(int index) {
    setState(() {
      value = index;
      if (index == 0) {
        currentPage = SearchEmp(mid: widget.mid);
      } else if (index == 1) {
        currentPage = PlanEmp(mid: widget.mid);
      } else if (index == 2) {
        currentPage = HomeEmpPage(mid: widget.mid);
      } else if (index == 3) {
        currentPage = HomeEmpPage(mid: widget.mid);
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
            icon: Icon(Icons.calendar_today),
            label: 'รถที่จอง',
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.chat),
          //   label: 'แจ้งเตือน',
          // ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'ฉัน',
          ),
        ],
        onTap: switchPage,
        selectedItemColor: const Color(0xFFEF6C00),
        unselectedItemColor: Colors.black,
      ),
    );
  }
}
