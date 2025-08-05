import 'dart:convert';
import 'package:agri_booking2/pages/contactor/PlanAndHistory.dart';
import 'package:agri_booking2/pages/contactor/home.dart';
import 'package:agri_booking2/pages/contactor/nonti.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TabbarCar extends StatefulWidget {
  final int value;
  final dynamic mid; // รับข้อมูลจาก Login
  final int month;
  final int year;

  const TabbarCar({
    super.key,
    required this.value,
    required this.mid,
    required this.month,
    required this.year,
  });

  @override
  State<TabbarCar> createState() => _TabbarCarState();
}

class _TabbarCarState extends State<TabbarCar> {
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
        currentPage = PlanAndHistory(
          mid: widget.mid,
          month: widget.month,
          year: widget.year,
        );
      } else if (index == 1) {
        currentPage = NontiPage(mid: widget.mid);
      } else if (index == 2) {
        currentPage = HomePage(mid: widget.mid);
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'ตารางงาน',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'แจ้งเตือน',
          ),
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
