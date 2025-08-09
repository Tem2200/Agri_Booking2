import 'dart:convert';
import 'package:agri_booking2/pages/contactor/PlanAndHistory.dart';
import 'package:agri_booking2/pages/contactor/home.dart';
import 'package:agri_booking2/pages/contactor/nonti.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TabbarCar extends StatefulWidget {
  final int value;
  final dynamic mid;
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
  int _notificationCount = 0; // เพิ่มตัวแปรเก็บจำนวนการแจ้งเตือน
  bool _isLoading = true; // เพิ่มตัวแปรสถานะการโหลด

  @override
  void initState() {
    super.initState();
    _displayMonth = widget.month;
    _displayYear = widget.year;
    value = widget.value;
    switchPage(value);
    fetchData(); // เรียกใช้ fetchData เมื่อหน้าจอถูกสร้าง
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
        fetchData(); // เรียก fetchData อีกครั้งเมื่อเปลี่ยนไปหน้านี้
      } else if (index == 2) {
        currentPage = HomePage(mid: widget.mid);
      }
    });
  }

  // ฟังก์ชันที่คุณต้องการเพิ่ม
  Future<void> fetchData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final scheduleList = await fetchSchedule(widget.mid);
      setState(() {
        _notificationCount = scheduleList.length;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching schedule: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<dynamic>> fetchSchedule(int mid) async {
    final url = Uri.parse(
        'http://projectnodejs.thammadalok.com/AGribooking/get_ConReservingNonti/$mid');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          return jsonDecode(response.body);
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to load schedule: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: currentPage,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: value,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'ตารางงาน',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              // ใช้ Widget Badge หุ้มไอคอน
              isLabelVisible:
                  _notificationCount > 0, // แสดงเมื่อมีตัวเลขมากกว่า 0
              label: Text('$_notificationCount'),
              child: const Icon(Icons.chat),
            ),
            label: 'แจ้งเตือน',
          ),
          const BottomNavigationBarItem(
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
