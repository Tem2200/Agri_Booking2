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
  int _notificationCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _displayMonth = widget.month;
    _displayYear = widget.year;
    value = widget.value;
    switchPage(value);
    fetchData(); // เรียก fetchData ใน initState
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
        fetchData();
        currentPage = NontiPage(mid: widget.mid);
        // เรียก fetchData อีกครั้งเมื่อเปลี่ยนไปหน้านี้
      } else if (index == 2) {
        currentPage = HomePage(mid: widget.mid);
      }
    });
  }

  // 💡 แก้ไข fetchData() ให้เป็น Async และรอผลลัพธ์
  Future<void> fetchData() async {
    // 💡 ตั้งค่า isLoading เป็น true ก่อนเริ่มโหลด
    setState(() {
      _isLoading = true;
    });

    try {
      // 💡 ใช้ await เพื่อรอผลลัพธ์จาก fetchSchedule
      final schedules = await fetchSchedule(widget.mid);

      // 💡 กรองเฉพาะรายการที่ยังไม่ได้ยืนยัน
      final nonConfirmedSchedules = schedules.where((item) {
        // ตรวจสอบค่า progress_status ที่เป็น 0 หรือ null (รอการยืนยัน)
        return item['progress_status'] == null ||
            item['progress_status'] == '0';
      }).toList();

      // 💡 อัปเดต state เมื่อข้อมูลพร้อมใช้งาน
      setState(() {
        _notificationCount = nonConfirmedSchedules.length;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching schedule: $e');
      setState(() {
        _isLoading = false;
        _notificationCount = 0; // หากเกิดข้อผิดพลาด ให้จำนวนแจ้งเตือนเป็น 0
      });
    }
  }

  Future<List<dynamic>> fetchSchedule(int mid) async {
    print("Fetching schedule for mid: $mid");
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
              isLabelVisible: _notificationCount > 0 && !_isLoading,
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
