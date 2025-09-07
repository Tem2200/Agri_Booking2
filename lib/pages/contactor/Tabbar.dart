import 'dart:convert';
import 'package:agri_booking2/pages/contactor/PlanAndHistory.dart';
import 'package:agri_booking2/pages/contactor/home.dart';
import 'package:agri_booking2/pages/contactor/nonti.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

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
  //late WebSocket _ws;

  // @override
  // void initState() {
  //   super.initState();
  //   _displayMonth = widget.month;
  //   _displayYear = widget.year;
  //   value = widget.value;
  //   switchPage(value);
  //   connectWebSocket();
  //   fetchData(); // เรียก fetchData ใน initState
  // }
  @override
  void initState() {
    super.initState();
    _displayMonth = widget.month;
    _displayYear = widget.year;
    value = widget.value;
    switchPage(value);
    fetchData(); // fetch ครั้งแรก
    _startLongPolling();
    //connectWebSocket(); // เชื่อม WS
  }

  // @override
  // void dispose() {
  //   _ws.close();
  //   super.dispose();
  // }
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
  // void switchPage(int index) {
  //   setState(() {
  //     value = index;
  //     if (index == 0) {
  //       currentPage = PlanAndHistory(
  //         mid: widget.mid,
  //         month: widget.month,
  //         year: widget.year,
  //       );
  //     } else if (index == 1) {
  //       currentPage = NontiPage(mid: widget.mid);
  //     } else if (index == 2) {
  //       currentPage = HomePage(mid: widget.mid);
  //     }
  //   });
  // }

  // void connectWebSocket() async {
  //   try {
  //     // แก้ไข URL ให้ตรงกับเซิร์ฟเวอร์ Node.js
  //     _ws = await WebSocket.connect(
  //         'ws://projectnodejs.thammadalok.com:80/AGribooking'); // ✅ แก้ไขตรงนี้

  //     _ws.listen((message) {
  //       final data = jsonDecode(message);
  //       // ตรวจสอบ event ที่เซิร์ฟเวอร์ส่งมา
  //       if (data['event'] == 'con_reserving_update' &&
  //           data['mid'].toString() == widget.mid.toString()) {
  //         // ✅ ตรวจสอบ event และ mid
  //         final schedules = data['data'] as List<dynamic>;

  //         final nonConfirmedSchedules = schedules.where((item) {
  //           final status = (item['progress_status'] ?? '').toString().trim();
  //           return status == '' || status == '5';
  //         }).toList();

  //         print(
  //             'Received WebSocket message: ${data['event']} for mid: ${widget.mid}');
  //         setState(() {
  //           _notificationCount = nonConfirmedSchedules.length;
  //         });
  //       }
  //     }, onDone: () {
  //       print('WebSocket closed, retry in 5 sec');
  //       Future.delayed(const Duration(seconds: 5), connectWebSocket);
  //     }, onError: (e) {
  //       print('WebSocket error: $e, retry in 5 sec');
  //       Future.delayed(const Duration(seconds: 5), connectWebSocket);
  //     });

  //     // 💡 ส่งข้อมูลไปบอกเซิร์ฟเวอร์ว่า client นี้ต้องการรับการอัปเดตของ mid ไหน
  //     _ws.add(jsonEncode({
  //       "action": "subscribe",
  //       "mid": widget.mid,
  //     }));
  //   } catch (e) {
  //     print('WebSocket connection error: $e, retry in 5 sec');
  //     Future.delayed(const Duration(seconds: 5), connectWebSocket);
  //   }
  // }

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

//   void switchPage(int index) {
//     setState(() {
//       value = index;
//       if (index == 0) {
//         currentPage = PlanAndHistory(
//           mid: widget.mid,
//           month: widget.month,
//           year: widget.year,
//         );
//       } else if (index == 1) {
//         fetchData();
//         currentPage = NontiPage(mid: widget.mid);
//         // เรียก fetchData อีกครั้งเมื่อเปลี่ยนไปหน้านี้
//       } else if (index == 2) {
//         currentPage = HomePage(mid: widget.mid);
//       }
//     });
//   }

//   // 💡 แก้ไข fetchData() ให้เป็น Async และรอผลลัพธ์
//   Future<void> fetchData() async {
//     // 💡 ตั้งค่า isLoading เป็น true ก่อนเริ่มโหลด
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       // 💡 ใช้ await เพื่อรอผลลัพธ์จาก fetchSchedule
//       final schedules = await fetchSchedule(widget.mid);

//       // 💡 กรองเฉพาะรายการที่ยังไม่ได้ยืนยัน
//       final nonConfirmedSchedules = schedules.where((item) {
//         // ตรวจสอบค่า progress_status ที่เป็น 0 หรือ null (รอการยืนยัน)
//         return item['progress_status'] == null ||
//             item['progress_status'] == '0';
//       }).toList();

//       // 💡 อัปเดต state เมื่อข้อมูลพร้อมใช้งาน
//       setState(() {
//         _notificationCount = nonConfirmedSchedules.length;
//         _isLoading = false;
//       });
//     } catch (e) {
//       print('Error fetching schedule: $e');
//       setState(() {
//         _isLoading = false;
//         _notificationCount = 0; // หากเกิดข้อผิดพลาด ให้จำนวนแจ้งเตือนเป็น 0
//       });
//     }
//   }

//   Future<List<dynamic>> fetchSchedule(int mid) async {
//     print("Fetching schedule for mid: $mid");
//     final url = Uri.parse(
//         'http://projectnodejs.thammadalok.com/AGribooking/get_ConReservingNonti/$mid');
//     try {
//       final response = await http.get(url);
//       if (response.statusCode == 200) {
//         if (response.body.isNotEmpty) {
//           print("Fetched schedule: ${response.body}");
//           return jsonDecode(response.body);
//         } else {
//           return [];
//         }
//       } else {
//         throw Exception('Failed to load schedule: ${response.statusCode}');
//       }
//     } catch (e) {
//       throw Exception('Connection error: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: currentPage,
//       bottomNavigationBar: BottomNavigationBar(
//         backgroundColor: Colors.white,
//         currentIndex: value,
//         items: [
//           const BottomNavigationBarItem(
//             icon: Icon(Icons.calendar_today),
//             label: 'ตารางงาน',
//           ),
//           BottomNavigationBarItem(
//             icon: Badge(
//               // ใช้ Widget Badge หุ้มไอคอน
//               isLabelVisible: _notificationCount > 0 && !_isLoading,
//               label: Text('$_notificationCount'),
//               child: const Icon(Icons.chat),
//             ),
//             label: 'แจ้งเตือน',
//           ),
//           const BottomNavigationBarItem(
//             icon: Icon(Icons.person),
//             label: 'ฉัน',
//           ),
//         ],
//         onTap: switchPage,
//         selectedItemColor: const Color(0xFFEF6C00),
//         unselectedItemColor: Colors.black,
//       ),
//     );
//   }
// }
