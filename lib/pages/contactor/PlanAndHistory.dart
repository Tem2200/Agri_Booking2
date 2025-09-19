import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:agri_booking2/pages/contactor/DetailWork.dart';
import 'package:agri_booking2/pages/contactor/Tabbar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';

class PlanAndHistory extends StatefulWidget {
  final int mid;
  final int month;
  final int year;

  const PlanAndHistory({
    super.key,
    required this.mid,
    required this.month,
    required this.year,
  });

  @override
  State<PlanAndHistory> createState() => _PlanAndHistoryState();
}

class _PlanAndHistoryState extends State<PlanAndHistory> with RouteAware {
  Future<List<dynamic>>? _scheduleFuture;
  late int _displayMonth;
  late int _displayYear;
  bool _isLocaleInitialized = false;

  // ตัวแปรสำหรับปฏิทินและรายการจอง
  DateTime _selectedDay = DateTime.now();
  late DateTime _focusedDay;
  Map<DateTime, List<dynamic>> eventsByDay = {};

  // ตัวแปรสำหรับการควบคุมการขยาย-ย่อของปฏิทิน
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // 💡 ตัวแปรใหม่สำหรับสถานะการกรองงาน
  int? _selectedStatus = -1; // -1 หมายถึงดูทุกสถานะ
  final StreamController<List<dynamic>> _scheduleController =
      StreamController.broadcast();
  @override
  void initState() {
    print("เข้ามาแล้วจ้าาา");
    super.initState();
    _displayMonth = widget.month;
    _displayYear = widget.year;
    _focusedDay = DateTime.now();

    initializeDateFormatting('th', null).then((_) {
      setState(() {
        _isLocaleInitialized = true;
        _scheduleFuture =
            fetchSchedule(widget.mid, _displayMonth, _displayYear).then((list) {
          _scheduleController.add(list);
          _groupEventsByDay(list);
          return list;
        });
      });
    });
    _startLongPolling();

    // 2. ลบโค้ด socket.io ทั้งหมดด้านล่างนี้
    // _socket = IO.io(...);
    // _socket.connect();
    // _socket.on('progress_updated', ...);
    // _socket.onDisconnect(...);
  }

  @override
  void dispose() {
    _scheduleController.close();
    // 3. ลบ _socket.dispose();
    final routeObserver = ModalRoute.of(context)!
        .navigator!
        .widget
        .observers
        .whereType<RouteObserver<PageRoute>>()
        .first;
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  // เรียกเมื่อกลับมาหน้านี้จาก pop
  @override
  void didPopNext() {
    super.didPopNext();
    _refreshSchedule();
  }

  // Future<void> _refreshSchedule() async {
  //   final newSchedule =
  //       await fetchSchedule(widget.mid, _displayMonth, _displayYear);
  //   setState(() {
  //     eventsByDay.clear();
  //     _groupEventsByDay(newSchedule);
  //     _scheduleFuture = fetchSchedule(
  //         widget.mid, _displayMonth, _displayYear); // สร้าง Future ใหม่
  //   });
  // }

  void _startLongPolling() async {
    while (mounted) {
      try {
        final url = Uri.parse(
            'http://projectnodejs.thammadalok.com/AGribooking/long-poll');
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['event'] == 'update_progress' ||
              data['event'] == 'reservation_added') {
            final newSchedule =
                await fetchSchedule(widget.mid, _displayMonth, _displayYear);
            eventsByDay.clear();
            _groupEventsByDay(newSchedule);
            _scheduleController.add(newSchedule);

            // 👇 เพิ่มบรรทัดนี้เพื่อให้ FutureBuilder อัปเดตด้วย
            setState(() {
              _scheduleFuture = Future.value(newSchedule);
            });
          }
        }
      } catch (e) {
        await Future.delayed(const Duration(seconds: 2));
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  // void _startLongPolling() async {
  //   while (mounted) {
  //     try {
  //       final url = Uri.parse(
  //           'http://projectnodejs.thammadalok.com/AGribooking/long-poll');
  //       final response = await http.get(url);
  //       if (response.statusCode == 200) {
  //         final data = jsonDecode(response.body);
  //         print("Long Polling Data: $data");
  //         if (data['event'] == 'update_progress' ||
  //             data['event'] == 'reservation_added') {
  //           final newSchedule =
  //               await fetchSchedule(widget.mid, _displayMonth, _displayYear);
  //           eventsByDay.clear();
  //           _groupEventsByDay(newSchedule);
  //           _scheduleController.add(newSchedule);
  //         }
  //       }
  //     } catch (e) {
  //       // อาจ log error ได้
  //     }
  //     await Future.delayed(const Duration(milliseconds: 500));
  //   }
  // }

  Future<void> _refreshSchedule() async {
    final newSchedule =
        await fetchSchedule(widget.mid, _displayMonth, _displayYear);

    eventsByDay.clear();
    _groupEventsByDay(newSchedule);

    // 🔥 ส่งข้อมูลใหม่เข้า stream
    _scheduleController.add(newSchedule);
  }

  Future<Map<String, dynamic>> fetchCon(int mid) async {
    final urlCon = Uri.parse(
        'http://projectnodejs.thammadalok.com/AGribooking/members/$mid');
    final response = await http.get(urlCon);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('ไม่พบข้อมูลสมาชิก');
    }
  }

  Future<List<dynamic>> fetchSchedule(int mid, int month, int year) async {
    final url = Uri.parse(
      'http://projectnodejs.thammadalok.com/AGribooking/get_ConReserving/$mid?month=$month&year=$year',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          print(response.body);
          return jsonDecode(response.body);
        } else {
          return [];
        }
      } else if (response.statusCode == 404) {
        // ถ้า status code เป็น 404 (Not Found) ก็ให้คืนค่า List ว่าง
        return [];
      } else {
        // สำหรับ status code อื่น ๆ ที่ไม่ใช่ 200 หรือ 404 ให้โยน Exception ตามปกติ
        throw Exception('Failed to load schedule: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  void _groupEventsByDay(List<dynamic> scheduleList) {
    eventsByDay.clear();
    for (var item in scheduleList) {
      final dateStart = DateTime.parse(item['date_start']).toLocal();
      final dateEnd = DateTime.parse(item['date_end']).toLocal();
      print(item);

      // วนลูปเพิ่มทุกวันในช่วงงาน
      for (DateTime date =
              DateTime(dateStart.year, dateStart.month, dateStart.day);
          !date.isAfter(dateEnd);
          date = date.add(const Duration(days: 1))) {
        if (eventsByDay[date] == null) {
          eventsByDay[date] = [item];
        } else {
          eventsByDay[date]!.add(item);
        }
      }
    }
    setState(() {});
  }

  // ฟังก์ชันแปลงวันที่ทั่วไป (ใช้กับ date_reserve)
  String formatDateReserveThai(String? dateReserve) {
    if (dateReserve == null || dateReserve.isEmpty) return '-';
    try {
      DateTime utcDate = DateTime.parse(dateReserve);
      DateTime localDate = utcDate.toUtc().add(const Duration(hours: 7));
      final formatter = DateFormat("d MMM yyyy เวลา HH:mm น.", "th_TH");
      String formatted = formatter.format(localDate);
      // แปลงปี ค.ศ. → พ.ศ.
      String yearString = localDate.year.toString();
      String buddhistYear = (localDate.year + 543).toString();
      return formatted.replaceFirst(yearString, buddhistYear);
    } catch (e) {
      return '-';
    }
  }

  // ฟังก์ชันแปลงช่วงวันที่เริ่ม-สิ้นสุดงาน
  String formatDateRangeThai(String? startDate, String? endDate) {
    if (startDate == null ||
        startDate.isEmpty ||
        endDate == null ||
        endDate.isEmpty) {
      return 'ไม่ระบุวันที่';
    }

    try {
      DateTime startUtc = DateTime.parse(startDate);
      DateTime endUtc = DateTime.parse(endDate);

      DateTime startThai = startUtc.toUtc().add(const Duration(hours: 7));
      DateTime endThai = endUtc.toUtc().add(const Duration(hours: 7));

      final formatter = DateFormat('dd/MM/yyyy เวลา HH:mm', "th_TH");

      String toBuddhistYearFormat(DateTime date) {
        String formatted = formatter.format(date);
        String yearString = date.year.toString();
        String buddhistYear = (date.year + 543).toString();
        return formatted.replaceFirst(yearString, buddhistYear);
      }

      const labelStart = 'เริ่มงาน:';
      const labelEnd = 'สิ้นสุด:';
      final maxLabelLength =
          [labelStart.length, labelEnd.length].reduce((a, b) => a > b ? a : b);

      String alignLabel(String label) {
        final spaces = ' ' * (maxLabelLength - label.length);
        return '$label$spaces';
      }

      return '${alignLabel(labelStart)} ${toBuddhistYearFormat(startThai)}\n'
          '${alignLabel(labelEnd)} ${toBuddhistYearFormat(endThai)}';
    } catch (e) {
      return 'กำลังโหลดข้อมูล...';
    }
  }

  String getStatusText(dynamic status) {
    switch (status.toString()) {
      case '0':
        return 'ผู้รับจ้างยกเลิกงาน';
      case '1':
        return 'ผู้รับจ้างยืนยันการจอง';
      case '2':
        return 'กำลังเดินทาง';
      case '3':
        return 'กำลังทำงาน';
      // case '4':
      //   return 'เสร็จสิ้น';
      default:
        return 'รอผู้รับจ้างยืนยันการจอง';
    }
  }

  Color getStatusColor(dynamic status) {
    switch (status.toString()) {
      case '0':
        return Colors.red;
      case '1':
        return const Color.fromARGB(255, 0, 169, 253);
      case '2':
        return Colors.pinkAccent;
      case '3':
        return Colors.amber;
      // case '4':
      //   return Colors.green;
      default:
        return Colors.black45;
    }
  }

// // 💡 แสดงตารางงานรายวันแบบ StreamBuilder
//   Widget _buildDailyScheduleList() {
//     return StreamBuilder<List<dynamic>>(
//       stream: _scheduleController.stream,
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const SliverToBoxAdapter(
//             child: Center(child: CircularProgressIndicator()),
//           );
//         } else if (snapshot.hasError) {
//           return SliverToBoxAdapter(
//             child: Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}')),
//           );
//         }

//         // ดึงข้อมูลของวันปัจจุบันจาก eventsByDay
//         final dailySchedule = eventsByDay[DateTime(
//               _selectedDay.year,
//               _selectedDay.month,
//               _selectedDay.day,
//             )] ??
//             [];

//         if (dailySchedule.isEmpty) {
//           return const SliverToBoxAdapter(
//             child: Center(child: Text('ไม่มีคิวงานในวันนี้')),
//           );
//         }

//         // 🔹 กรองงานตามสถานะ
//         final filteredSchedule = dailySchedule.where((item) {
//           final status = int.tryParse(item['progress_status'].toString());
//           if (_selectedStatus == -1) {
//             return status != 4; // ทั้งหมดยกเว้นเสร็จสิ้น
//           }
//           return status == _selectedStatus && status != 4;
//         }).toList();

//         if (filteredSchedule.isEmpty) {
//           return const SliverToBoxAdapter(
//             child: Center(child: Text('ไม่พบงานในหมวดนี้สำหรับวันนี้')),
//           );
//         }

//         // 🔹 แสดงรายการเป็น SliverList (card แต่ละงาน)
//         return SliverList(
//           delegate: SliverChildBuilderDelegate(
//             (context, index) {
//               final item = filteredSchedule[index];

//               return Container(
//                 decoration: BoxDecoration(
//                   color: const Color.fromARGB(255, 255, 255, 255),
//                   borderRadius: BorderRadius.circular(12),
//                   boxShadow: [
//                     BoxShadow(
//                       color: const Color.fromARGB(255, 251, 229, 196)
//                           .withOpacity(0.3),
//                       spreadRadius: 1,
//                       blurRadius: 6,
//                       offset: const Offset(0, 3),
//                     ),
//                   ],
//                 ),
//                 margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
//                 child: Padding(
//                   padding: const EdgeInsets.all(10.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // 🔹 หัวการ์ด (ชื่อ + สถานะ)
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Flexible(
//                             child: Text(
//                               item['name_rs'] ?? '-',
//                               style: const TextStyle(
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.black87,
//                               ),
//                               overflow: TextOverflow.ellipsis,
//                               maxLines: 1,
//                             ),
//                           ),
//                           Row(
//                             children: [
//                               Icon(Icons.circle,
//                                   color:
//                                       getStatusColor(item['progress_status']),
//                                   size: 10),
//                               const SizedBox(width: 4),
//                               Text(
//                                 getStatusText(item['progress_status']),
//                                 style: TextStyle(
//                                   fontSize: 13,
//                                   fontWeight: FontWeight.w500,
//                                   color:
//                                       getStatusColor(item['progress_status']),
//                                 ),
//                               ),
//                             ],
//                           )
//                         ],
//                       ),
//                       const SizedBox(height: 8),

//                       // 🔹 ข้อมูลผู้จ้าง
//                       Row(
//                         children: [
//                           const SizedBox(
//                             width: 65,
//                             child: Row(
//                               children: [
//                                 Icon(Icons.person,
//                                     size: 16, color: Colors.indigo),
//                                 SizedBox(width: 4),
//                                 Text(
//                                   'ผู้จ้าง:',
//                                   style: TextStyle(
//                                     fontSize: 14,
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           Expanded(
//                             child: Text(
//                               '${item['employee_username']} (${item['employee_phone'] ?? '-'})',
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                               style: const TextStyle(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 8),

//                       // 🔹 ข้อมูลรถ
//                       Row(
//                         children: [
//                           const SizedBox(
//                             width: 65,
//                             child: Row(
//                               children: [
//                                 Icon(Icons.directions_car,
//                                     size: 16, color: Colors.blueGrey),
//                                 SizedBox(width: 4),
//                                 Text(
//                                   'รถ:',
//                                   style: TextStyle(
//                                     fontSize: 14,
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           Expanded(
//                             child: Text(
//                               item['name_vehicle'] ?? '-',
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                               style: const TextStyle(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 4),

//                       // 🔹 ข้อมูลที่นา
//                       Row(
//                         children: [
//                           const SizedBox(
//                             width: 65,
//                             child: Row(
//                               children: [
//                                 Icon(Icons.location_on,
//                                     size: 16, color: Colors.orange),
//                                 SizedBox(width: 4),
//                                 Text(
//                                   'ที่นา:',
//                                   style: TextStyle(
//                                     fontSize: 14,
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           Expanded(
//                             child: Text(
//                               '${item['name_farm'] ?? ''} (ต.${item['subdistrict'] ?? ''} อ.${item['district'] ?? ''} จ.${item['province'] ?? ''})',
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                               style: const TextStyle(
//                                 fontSize: 14,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),

//                       const Divider(
//                           color: Colors.grey, thickness: 1, height: 24),

//                       // 🔹 วันที่จอง + เริ่มงาน + สิ้นสุด
//                       Row(
//                         children: [
//                           const SizedBox(
//                             width: 65,
//                             child: Text(
//                               'วันที่จอง:',
//                               style: TextStyle(
//                                 fontSize: 13,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.grey,
//                               ),
//                             ),
//                           ),
//                           Text(
//                             formatDateReserveThai(item['date_reserve']),
//                             style: const TextStyle(
//                               fontSize: 13,
//                               color: Colors.grey,
//                             ),
//                           ),
//                         ],
//                       ),
//                       Row(
//                         children: [
//                           const SizedBox(
//                             width: 65,
//                             child: Text(
//                               'เริ่มงาน:',
//                               style: TextStyle(
//                                   fontSize: 13, fontWeight: FontWeight.bold),
//                             ),
//                           ),
//                           Text(
//                             formatDateReserveThai(item['date_start']),
//                             style: const TextStyle(fontSize: 13),
//                           ),
//                         ],
//                       ),
//                       Row(
//                         children: [
//                           const SizedBox(
//                             width: 65,
//                             child: Text(
//                               'สิ้นสุด:',
//                               style: TextStyle(
//                                   fontSize: 13, fontWeight: FontWeight.bold),
//                             ),
//                           ),
//                           Text(
//                             formatDateReserveThai(item['date_end']),
//                             style: const TextStyle(fontSize: 13),
//                           ),
//                         ],
//                       ),

//                       const Divider(
//                           color: Colors.grey, thickness: 1, height: 24),

//                       // 🔹 ปุ่มรายละเอียด
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.end,
//                         children: [
//                           ElevatedButton(
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: const Color(0xFF4CAF50),
//                               foregroundColor: Colors.white,
//                               elevation: 4,
//                               shadowColor:
//                                   const Color.fromARGB(208, 163, 160, 160),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(16),
//                               ),
//                               padding: const EdgeInsets.symmetric(
//                                   horizontal: 24, vertical: 10),
//                               textStyle: const TextStyle(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                             onPressed: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) =>
//                                       DetailWorkPage(rsid: item['rsid']),
//                                 ),
//                               );
//                             },
//                             child: const Text('รายละเอียด'),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//             childCount: filteredSchedule.length,
//           ),
//         );
//       },
//     );
//   }

//   // 💡 หน้า "ตารางงาน"
//   Widget _buildPlanTab() {
//     return Column(
//       children: [
//         // ปุ่มกรองสถานะ
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//           child: SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: Row(
//               children: [
//                 _buildStatusChip('งานทั้งหมด', -1),
//                 _buildStatusChip('รอการยืนยัน', null),
//                 _buildStatusChip('ยืนยันการจอง', 1),
//                 _buildStatusChip('กำลังเดินทาง', 2),
//                 _buildStatusChip('กำลังทำงาน', 3),
//                 _buildStatusChip('งานที่ยกเลิก', 0),
//               ],
//             ),
//           ),
//         ),
//         Expanded(
//           child: CustomScrollView(
//             slivers: [
//               SliverToBoxAdapter(
//                 child: TableCalendar(
//                   locale: 'th_TH',
//                   focusedDay: _focusedDay,
//                   firstDay: DateTime.utc(2020, 1, 1),
//                   lastDay: DateTime.utc(2030, 12, 31),
//                   startingDayOfWeek: StartingDayOfWeek.monday,
//                   selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
//                   calendarFormat: _calendarFormat,
//                   eventLoader: (day) {
//                     final dateKey = DateTime(day.year, day.month, day.day);
//                     final eventsForDay = eventsByDay[dateKey] ?? [];

//                     return eventsForDay.where((e) {
//                       final status = e['progress_status'];
//                       if (status == 4) return false;
//                       if (_selectedStatus == -1) return true;
//                       if (_selectedStatus == null) return status == null;
//                       return status == _selectedStatus;
//                     }).toList();
//                   },
//                   onDaySelected: (selectedDay, focusedDay) {
//                     setState(() {
//                       if (!isSameDay(_selectedDay, selectedDay)) {
//                         _selectedDay = selectedDay;
//                         _focusedDay = focusedDay;
//                       }
//                     });
//                   },
//                   onFormatChanged: (format) {
//                     if (_calendarFormat != format) {
//                       setState(() {
//                         _calendarFormat = format;
//                       });
//                     }
//                   },
//                   onPageChanged: (focusedDay) {
//                     _focusedDay = focusedDay;
//                   },
//                   calendarBuilders: CalendarBuilders(
//                     markerBuilder: (context, date, events) {
//                       if (events.isEmpty) return const SizedBox();
//                       return Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: events.map((e) {
//                           final event = e as Map<String, dynamic>;
//                           final status = event['progress_status'];
//                           return Container(
//                             margin: const EdgeInsets.symmetric(horizontal: 1.5),
//                             width: 7,
//                             height: 7,
//                             decoration: BoxDecoration(
//                               color: getStatusColor(status),
//                               shape: BoxShape.circle,
//                             ),
//                           );
//                         }).toList(),
//                       );
//                     },
//                   ),
//                   headerStyle: const HeaderStyle(
//                     formatButtonVisible: false,
//                     titleCentered: true,
//                   ),
//                 ),
//               ),
//               const SliverToBoxAdapter(child: SizedBox(height: 16)),
//               _buildDailyScheduleList(), // 👈 ใช้ StreamBuilder ที่เขียนไว้
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   // ย้าย UI card ของแต่ละ item มาอยู่ในฟังก์ชันแยกเพื่อให้โค้ดสั้นลง
//   Widget _buildScheduleCard(dynamic item) {
//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: const Color.fromARGB(255, 251, 229, 196).withOpacity(0.3),
//             spreadRadius: 1,
//             blurRadius: 6,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(10.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // … 👉 ยก UI card ที่คุณทำไว้ทั้งหมดมาวางตรงนี้
//           ],
//         ),
//       ),
//     );
//   }

//   // 💡 สร้าง widget สำหรับปุ่มกรองสถานะ
//   Widget _buildStatusChip(String label, int? status) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 4.0),
//       child: FilterChip(
//         label: Text(label),
//         selected: _selectedStatus == status,
//         onSelected: (bool selected) {
//           setState(() {
//             // ⚠️ ลบเครื่องหมาย '!' ออกเพื่อไม่ให้เกิด Null check error
//             _selectedStatus = selected ? status : -1;
//           });
//         },
//         selectedColor: Colors.green[200],
//         checkmarkColor: Colors.white,
//         labelStyle: TextStyle(
//           color: _selectedStatus == status ? Colors.black : Colors.grey[800],
//         ),
//       ),
//     );
//   }

//   // 💡 หน้า "ประวัติ"
//   Widget _buildHistoryTab() {
//     return FutureBuilder<List<dynamic>>(
//       future: _scheduleFuture,
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         } else if (snapshot.hasError) {
//           return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
//         } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//           return const Center(child: Text('ไม่มีคิวงาน'));
//         }

//         final scheduleList = snapshot.data!
//             .where((item) => item['progress_status'] == 4)
//             .toList();

//         if (scheduleList.isEmpty) {
//           return const Center(child: Text('ไม่พบงานในหมวดนี้'));
//         }

//         return ListView.builder(
//           padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
//           itemCount: scheduleList.length,
//           itemBuilder: (context, index) {
//             final item = scheduleList[index];
//             return _buildScheduleCard(item); // 👈 ใช้ฟังก์ชันเดียวกัน
//           },
//         );
//       },
//     );
//   }

  // 💡 สร้าง List<Widget> สำหรับรายการจองของวันปัจจุบัน
  List<Widget> _buildDailyScheduleList() {
    final dailySchedule = eventsByDay[DateTime(
          _selectedDay.year,
          _selectedDay.month,
          _selectedDay.day,
        )] ??
        [];

    if (dailySchedule.isEmpty) {
      return [const Center(child: Text('ไม่มีคิวงานในวันนี้'))];
    }

    final filteredSchedule = dailySchedule.where((item) {
      final status = int.tryParse(item['progress_status'].toString());

      // 💡 เปลี่ยนเงื่อนไขการกรอง
      if (_selectedStatus == -1) {
        return status != 4; // ดูงานทั้งหมดที่ยังไม่เสร็จ (ไม่รวมสถานะเสร็จสิ้น)
      }
      return status == _selectedStatus &&
          status != 4; // กรองตามสถานะที่เลือก ยกเว้นสถานะเสร็จสิ้น
    }).toList();
    filteredSchedule.sort((a, b) => DateTime.parse(a['date_reserve'])
        .compareTo(DateTime.parse(b['date_reserve'])));
    if (filteredSchedule.isEmpty) {
      return [
        const Center(child: Text('ไม่พบงานในหมวดนี้สำหรับวันนี้')),
      ];
    }

    // สร้างรายการ Widget สำหรับ ListView.builder
    return List.generate(filteredSchedule.length, (index) {
      final item = filteredSchedule[index];

      return Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 255, 255, 255), // พื้นหลังโทนเดิม
          borderRadius: BorderRadius.circular(12), // มุมโค้ง
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 251, 229, 196)
                  .withOpacity(0.3), // สีเงา
              spreadRadius: 1, // กระจายเงา
              blurRadius: 6, // ความฟุ้งของเงา
              offset: const Offset(0, 3), // ตำแหน่งเงา
            ),
          ],
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      item['name_rs'] ?? '-',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.circle,
                          color: getStatusColor(item['progress_status']),
                          size: 10),
                      const SizedBox(width: 4),
                      Text(
                        getStatusText(item['progress_status']),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: getStatusColor(item['progress_status']),
                        ),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SizedBox(
                        width: 65,
                        child: Row(
                          children: [
                            Icon(Icons.person, size: 16, color: Colors.indigo),
                            SizedBox(width: 4),
                            Text(
                              'ผู้จ้าง:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${item['employee_username']} (${item['employee_phone'] ?? '-'})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const SizedBox(
                        width: 65,
                        child: Row(
                          children: [
                            Icon(Icons.directions_car,
                                size: 16, color: Colors.blueGrey),
                            SizedBox(width: 4),
                            Text(
                              'รถ:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item['name_vehicle'] ?? '-',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const SizedBox(
                        width: 65,
                        child: Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 16, color: Colors.orange),
                            SizedBox(width: 4),
                            Text(
                              'ที่นา:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${item['name_farm'] ?? ''} (ต.${item['subdistrict'] ?? ''} อ.${item['district'] ?? ''} จ.${item['province'] ?? ''})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(
                color: Colors.grey,
                thickness: 1,
                height: 24,
              ),
              Row(
                children: [
                  const SizedBox(
                    width: 65,
                    child: Text(
                      'วันที่จอง:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey, // กำหนดสีเทา
                      ),
                    ),
                  ),
                  Text(
                    formatDateReserveThai(item['date_reserve']),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey, // กำหนดสีเทา
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const SizedBox(
                    width: 65,
                    child: Text(
                      'เริ่มงาน:',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    formatDateReserveThai(
                        item['date_start']), // ใช้ฟังก์ชันที่รับ 1 ตัว
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
              Row(
                children: [
                  const SizedBox(
                    width: 65,
                    child: Text(
                      'สิ้นสุด:',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    formatDateReserveThai(
                        item['date_end']), // ใช้ฟังก์ชันที่รับ 1 ตัว
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
              const Divider(
                color: Colors.grey,
                thickness: 1,
                height: 24,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: const Color.fromARGB(208, 163, 160, 160),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 10),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DetailWorkPage(rsid: item['rsid']),
                        ),
                      );
                    },
                    child: const Text('รายละเอียด'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

// ย้าย UI card ของแต่ละ item มาอยู่ในฟังก์ชันแยกเพื่อให้โค้ดสั้นลง
  Widget _buildScheduleCard(dynamic item) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 251, 229, 196).withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // … 👉 ยก UI card ที่คุณทำไว้ทั้งหมดมาวางตรงนี้
          ],
        ),
      ),
    );
  }

  // 💡 สร้าง widget สำหรับหน้า "ตารางงาน" ที่สามารถเลื่อนได้
  Widget _buildPlanTab() {
    return Column(
      children: [
        // เพิ่มส่วนการกรองสถานะงาน
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusChip('งานทั้งหมด', -1),
                _buildStatusChip('รอการยืนยัน', null),
                _buildStatusChip('ยืนยันการจอง', 1),
                _buildStatusChip('กำลังเดินทาง', 2),
                _buildStatusChip('กำลังทำงาน', 3),
                _buildStatusChip('งานที่ยกเลิก', 0),
              ],
            ),
          ),
        ),
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: TableCalendar(
                  locale: 'th_TH',
                  focusedDay: _focusedDay,
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  calendarFormat: _calendarFormat,
                  eventLoader: (day) {
                    final dateKey = DateTime(day.year, day.month, day.day);
                    final eventsForDay = eventsByDay[dateKey] ?? [];

                    // 🔹 กรองตามปุ่มสถานะ
                    final filteredEvents = eventsForDay.where((e) {
                      final status = e['progress_status'];
                      if (status == 4) return false;
                      if (_selectedStatus == -1) return true; // งานทั้งหมด
                      if (_selectedStatus == null)
                        return status == null; // รอการยืนยัน
                      return status == _selectedStatus; // สถานะอื่น ๆ
                    }).toList();
                    filteredEvents.sort((a, b) =>
                        DateTime.parse(a['date_reserve'])
                            .compareTo(DateTime.parse(b['date_reserve'])));

                    return filteredEvents;
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      if (!isSameDay(_selectedDay, selectedDay)) {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      }
                    });
                  },
                  onFormatChanged: (format) {
                    if (_calendarFormat != format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    }
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      if (events.isEmpty) return const SizedBox();

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: events.map((e) {
                          final event =
                              e as Map<String, dynamic>; // 👈 cast ก่อน
                          final status = event['progress_status'];
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: getStatusColor(status),
                              shape: BoxShape.circle,
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 16),
              ),
              SliverList(
                delegate: SliverChildListDelegate(
                  _buildDailyScheduleList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 💡 สร้าง widget สำหรับปุ่มกรองสถานะ
  Widget _buildStatusChip(String label, int? status) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: FilterChip(
        label: Text(label),
        selected: _selectedStatus == status,
        onSelected: (bool selected) {
          setState(() {
            // ⚠️ ลบเครื่องหมาย '!' ออกเพื่อไม่ให้เกิด Null check error
            _selectedStatus = selected ? status : -1;
          });
        },
        selectedColor: Colors.green[200],
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: _selectedStatus == status ? Colors.black : Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return FutureBuilder<List<dynamic>>(
      future: _scheduleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('ไม่มีคิวงาน'));
        }

        final scheduleList = snapshot.data!
            .where((item) => item['progress_status'] == 4)
            .toList();
        scheduleList.sort((a, b) => DateTime.parse(b['date_reserve'])
            .compareTo(DateTime.parse(a['date_reserve'])));

        if (scheduleList.isEmpty) {
          return const Center(child: Text('ไม่พบงานในหมวดนี้'));
        }

        String getStatusText(dynamic status) {
          return 'เสร็จสิ้น';
        }

        Color getStatusColor(dynamic status) {
          return Colors.green;
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          itemCount: scheduleList.length,
          itemBuilder: (context, index) {
            final item = scheduleList[index];
            return Container(
              decoration: BoxDecoration(
                color:
                    const Color.fromARGB(255, 255, 255, 255), // พื้นหลังโทนเดิม
                borderRadius: BorderRadius.circular(12), // มุมโค้ง
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(255, 251, 229, 196)
                        .withOpacity(0.3), // สีเงา
                    spreadRadius: 1, // กระจายเงา
                    blurRadius: 6, // ความฟุ้งของเงา
                    offset: const Offset(0, 3), // ตำแหน่งเงา
                  ),
                ],
              ),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                item['name_rs'] ?? '-',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            Row(
                              children: [
                                Icon(Icons.circle,
                                    color:
                                        getStatusColor(item['progress_status']),
                                    size: 10),
                                const SizedBox(width: 4),
                                Text(
                                  getStatusText(item['progress_status']),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        getStatusColor(item['progress_status']),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                        const SizedBox(height: 8),
                        // ใช้ Row + SizedBox เพื่อให้หัวข้อและเนื้อหาจัดตรงกัน
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(
                              width: 65, // กำหนดความกว้างหัวข้อให้เท่ากัน
                              child: Row(
                                children: [
                                  Icon(Icons.person,
                                      size: 16, color: Colors.indigo),
                                  SizedBox(width: 6),
                                  Text(
                                    'ผู้จ้าง:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${item['employee_username']} (${item['employee_phone'] ?? '-'})',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(
                              width: 65,
                              child: Row(
                                children: [
                                  Icon(Icons.directions_car,
                                      size: 16, color: Colors.blueGrey),
                                  SizedBox(width: 4),
                                  Text(
                                    'รถ:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Text(
                                item['name_vehicle'] ?? '-',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(
                              width: 65,
                              child: Row(
                                children: [
                                  Icon(Icons.location_on,
                                      size: 16, color: Colors.orange),
                                  SizedBox(width: 4),
                                  Text(
                                    'ที่นา:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${item['name_farm'] ?? ''} (ต.${item['subdistrict'] ?? ''} อ.${item['district'] ?? ''} จ.${item['province'] ?? ''})',
                                style: const TextStyle(
                                  fontSize: 14,
                                ),
                                maxLines: 1, // จำกัด 1 บรรทัด
                                overflow: TextOverflow
                                    .ellipsis, // ถ้าเกินความกว้าง ตัดด้วย ...
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(
                      color: Colors.grey,
                      thickness: 1,
                      height: 24,
                    ),
                    Row(
                      children: [
                        const SizedBox(
                          width: 65,
                          child: Text(
                            'วันที่จอง:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey, // กำหนดสีเทา
                            ),
                          ),
                        ),
                        Text(
                          formatDateReserveThai(item['date_reserve']),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey, // กำหนดสีเทา
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const SizedBox(
                          width: 65,
                          child: Text(
                            'เริ่มงาน:',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          formatDateReserveThai(
                              item['date_start']), // ใช้ฟังก์ชันที่รับ 1 ตัว
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const SizedBox(
                          width: 65,
                          child: Text(
                            'สิ้นสุด:',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          formatDateReserveThai(
                              item['date_end']), // ใช้ฟังก์ชันที่รับ 1 ตัว
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    const Divider(
                      color: Colors.grey,
                      thickness: 1,
                      height: 24,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor:
                                const Color.fromARGB(208, 163, 160, 160),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 10),
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DetailWorkPage(rsid: item['rsid']),
                              ),
                            );
                          },
                          child: const Text('รายละเอียด'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- ฟังก์ชันสำหรับดึงข้อมูลสมาชิกใส่ appBar ---
  Future<Map<String, dynamic>> item(int mid) async {
    final urlCon = Uri.parse(
        'http://projectnodejs.thammadalok.com/AGribooking/members/$mid');
    final response = await http.get(urlCon);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("ข้อมูลสมาชิก: $data");
      return data;
    } else {
      throw Exception('ไม่พบข้อมูลสมาชิก');
    }
  }

  @override
  Widget build(BuildContext context) {
    // if (!_isLocaleInitialized) {
    //   return const Scaffold(
    //     body: Center(child: CircularProgressIndicator()),
    //   );
    // }
    if (!_isLocaleInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 18, 143, 9),
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: const Text(
            'ตารางงานทั้งหมด (ผู้รับจ้าง)',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Color.fromARGB(115, 253, 237, 237),
                  blurRadius: 3,
                  offset: Offset(1.5, 1.5),
                ),
              ],
            ),
          ),
          actions: [
            FutureBuilder<Map<String, dynamic>>(
              future: item(widget.mid), // ✅ ดึงข้อมูลสมาชิก
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.only(right: 12.0),
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  );
                }

                // ถ้า error หรือไม่มีข้อมูล -> ใช้ data = {}
                final data = snapshot.data ?? {};

                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: GestureDetector(
                    onTap: () {
                      int currentMonth = DateTime.now().month;
                      int currentYear = DateTime.now().year;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TabbarCar(
                            mid: widget.mid,
                            value: 2,
                            month: currentMonth,
                            year: currentYear,
                          ),
                        ),
                      );
                    },
                    child: ClipOval(
                      child: (data['image'] != null &&
                              data['image'].toString().isNotEmpty)
                          ? Image.network(
                              data['image'], // ✅ แสดงรูปจาก DB
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 40,
                              height: 40,
                              color: Colors.white24,
                              child: const Icon(
                                Icons.person,
                                size: 28,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                );
              },
            )
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 6,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: TabBar(
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        colors: [
                          const Color.fromARGB(255, 190, 255, 189),
                          const Color.fromARGB(255, 37, 189, 35),
                          Colors.green[800]!,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.black87,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelStyle:
                        Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                    unselectedLabelStyle:
                        Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontSize: 14,
                            ),
                    tabs: const [
                      Tab(
                        child: SizedBox(
                          width: 120,
                          child: Center(child: Text('ตารางงาน')),
                        ),
                      ),
                      Tab(
                        child: SizedBox(
                          width: 120,
                          child: Center(child: Text('ประวัติการทำงาน')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildPlanTab(),
                  _buildHistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
