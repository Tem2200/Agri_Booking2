import 'dart:convert';
import 'package:agri_booking2/pages/contactor/PlanAndHistory.dart';
import 'package:agri_booking2/pages/contactor/home.dart';
import 'package:agri_booking2/pages/contactor/nonti.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

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
  int _notificationCount = 0; // ตัวแปรสำหรับเก็บจำนวนแจ้งเตือน
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _displayMonth = widget.month;
    _displayYear = widget.year;
    value = widget.value;
    switchPage(value);
    fetchData(); // fetch ครั้งแรก
    _startLongPolling();
    _saveLastPage();
  }

  Future<void> _saveLastPage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_page', 'TabbarCar');
  }

  void _startLongPolling() async {
    while (mounted) {
      try {
        final url = Uri.parse(
            'http://projectnodejs.thammadalok.com/AGribooking/long-poll');
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print("Long Polling Data: $data");
          if (data['event'] == 'update_progress' ||
              data['event'] == 'reservation_added') {
            fetchData(); // ← เพิ่มบรรทัดนี้
          }
        }
      } catch (e) {
        // อาจ log error ได้
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<void> fetchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final schedules = await fetchSchedule(int.parse(widget.mid.toString()));

      final nonConfirmedSchedules = schedules.where((item) {
        final status = (item['progress_status'] ?? '').toString().trim();
        return status == '' || status == '5';
      }).toList();

      setState(() {
        _notificationCount = nonConfirmedSchedules.length;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching schedule: $e');
      setState(() {
        _isLoading = false;
        _notificationCount = 0;
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
          print("Fetched schedule: ${response.body}");
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

  void switchPage(int index) {
    setState(() {
      value = index;
      fetchData(); // เรียกทุกครั้งเมื่อเปลี่ยน tab
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
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'ตารางงาน',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: _notificationCount > 0, // ตัด !_isLoading ออก
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
