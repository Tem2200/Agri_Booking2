import 'dart:convert';
import 'package:agri_booking2/pages/contactor/DetailWork.dart';
import 'package:agri_booking2/pages/employer/reservingForNF.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';

// 💡 1. สร้าง enum เพื่อกำหนดสถานะการกรอง
enum StatusFilter { all, pending, notAvailable }

class PlanPage extends StatefulWidget {
  // ... (โค้ดส่วนเดิม) ...
  final int mid;
  final int month;
  final int year;
  final int mid_employer;
  final int vid;
  final int? fid;
  final dynamic farm;
  final dynamic vihicleData;

  const PlanPage({
    super.key,
    required this.mid,
    required this.month,
    required this.year,
    required this.mid_employer,
    required this.vid,
    this.fid,
    this.farm,
    this.vihicleData,
  });

  @override
  State<PlanPage> createState() => _PlanAndHistoryState();
}

class _PlanAndHistoryState extends State<PlanPage> {
  Future<List<dynamic>>? _scheduleFuture;
  late int _displayMonth;
  late int _displayYear;
  bool _isLocaleInitialized = false;
  Future<Map<String, dynamic>>? _conFuture;

  // 💡 1.1 เปลี่ยนมาใช้ตัวแปรเดียวสำหรับเก็บสถานะที่ถูกเลือก
  StatusFilter _selectedStatus = StatusFilter.all;

  DateTime _selectedDay = DateTime.now();
  Map<DateTime, List<dynamic>> eventsByDay = {};

  @override
  void initState() {
    super.initState();
    _displayMonth = widget.month;
    _displayYear = widget.year;
    print("vihicleData: ${widget.vihicleData}");
    _conFuture = fetchCon(this.widget.mid);
    initializeDateFormatting('th', null).then((_) {
      setState(() {
        _isLocaleInitialized = true;
        _scheduleFuture =
            fetchSchedule(widget.mid, _displayMonth, _displayYear).then((list) {
          groupEventsByDay(list);
          return list;
        });
      });
    });
  }

  // ... (โค้ด fetchCon, fetchSchedule, groupEventsByDay, _formatDateRange, _changeMonth ส่วนเดิม) ...
  Future<Map<String, dynamic>> fetchCon(int mid) async {
    final url_con = Uri.parse(
        'http://projectnodejs.thammadalok.com/AGribooking/members/$mid');
    final response = await http.get(url_con);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("ข้อมูลเจ้าของรถ: $data");
      return data;
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
          final List<dynamic> data = jsonDecode(response.body);

          final filteredData = data.where((item) {
            final status = item['progress_status'];
            return status != 4 && status != 0; // กรองไม่เอา 0 และ 4
          }).toList();

          return filteredData;
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

  void groupEventsByDay(List<dynamic> scheduleList) {
    eventsByDay.clear();
    for (var item in scheduleList) {
      final dateStart = DateTime.parse(item['date_start']).toLocal();
      final dateKey = DateTime(dateStart.year, dateStart.month, dateStart.day);

      if (eventsByDay[dateKey] == null) {
        eventsByDay[dateKey] = [item];
      } else {
        eventsByDay[dateKey]!.add(item);
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  String _formatDateRange(String? startDate, String? endDate) {
    if (startDate == null || endDate == null) return 'ไม่ระบุวันที่';
    try {
      final startUtc = DateTime.parse(startDate);
      final endUtc = DateTime.parse(endDate);

      final startThai = startUtc.add(const Duration(hours: 7));
      final endThai = endUtc.add(const Duration(hours: 7));

      final formatter = DateFormat('dd/MM/yyyy \t\tเวลา HH:mm น.');

      return 'เริ่มงาน: ${formatter.format(startThai)}\nสิ้นสุด: ${formatter.format(endThai)}';
    } catch (e) {
      return 'รูปแบบวันที่ไม่ถูกต้อง';
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _displayMonth += delta;
      if (_displayMonth > 12) {
        _displayMonth = 1;
        _displayYear++;
      } else if (_displayMonth < 1) {
        _displayMonth = 12;
        _displayYear--;
      }

      _scheduleFuture =
          fetchSchedule(widget.mid, _displayMonth, _displayYear).then((list) {
        groupEventsByDay(list);
        return list;
      });
    });
  }

  final ButtonStyle bookingButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Color.fromARGB(255, 33, 148, 255),
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    textStyle: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  );
  // สร้าง Widget ใหม่สำหรับแสดงข้อมูลเจ้าของรถและข้อมูลรถ
  Widget _buildConAndVehicleInfo() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _conFuture,
      builder: (context, snapshot) {
        // โค้ดแสดงสถานะการโหลดหรือข้อผิดพลาด
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('ไม่สามารถโหลดข้อมูลเจ้าของรถได้'));
        }
        if (!snapshot.hasData) {
          return const Center(child: Text('ไม่พบข้อมูลเจ้าของรถ'));
        }

        final conData = snapshot.data!;
        final vihicleData = widget.vihicleData;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Text(
                conData['username'] ?? 'ไม่ระบุชื่อ',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      vihicleData?['image_vehicle'] ??
                          'https://via.placeholder.com/150',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vihicleData?['name_vehicle'] ?? 'ไม่ระบุชื่อรถ',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          vihicleData?['detail'] ?? 'ไม่มีรายละเอียด',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlanTab() {
    return SingleChildScrollView(
      // 💡 ห่อหุ้มด้วย SingleChildScrollView
      child: Column(
        children: [
          _buildConAndVehicleInfo(),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatusButton(
                  text: 'ทั้งหมด',
                  status: StatusFilter.all,
                  onPressed: () {
                    setState(() {
                      _selectedStatus = StatusFilter.all;
                    });
                  },
                ),
                _buildStatusButton(
                  text: 'ผู้รับจ้างไม่ว่าง',
                  status: StatusFilter.notAvailable,
                  onPressed: () {
                    setState(() {
                      _selectedStatus = StatusFilter.notAvailable;
                    });
                  },
                ),
                _buildStatusButton(
                  text: 'รอการยืนยัน',
                  status: StatusFilter.pending,
                  onPressed: () {
                    setState(() {
                      _selectedStatus = StatusFilter.pending;
                    });
                  },
                ),
              ],
            ),
          ),
          TableCalendar(
            locale: 'th_TH',
            focusedDay: _selectedDay,
            firstDay: DateTime(_displayYear - 1),
            lastDay: DateTime(_displayYear + 1),
            startingDayOfWeek: StartingDayOfWeek.monday,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarStyle: const CalendarStyle(
              cellMargin: EdgeInsets.all(5.0),
              markerSize: 8.0,
              cellAlignment: Alignment.center,
              defaultTextStyle: TextStyle(fontSize: 14.0),
              weekendTextStyle: TextStyle(fontSize: 14.0, color: Colors.red),
              todayTextStyle: TextStyle(fontSize: 14.0, color: Colors.white),
              selectedTextStyle: TextStyle(fontSize: 14.0, color: Colors.white),
              outsideDaysVisible: false,
              todayDecoration: BoxDecoration(
                color: Colors.orangeAccent,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle:
                  TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              leftChevronIcon: Icon(Icons.chevron_left, size: 24.0),
              rightChevronIcon: Icon(Icons.chevron_right, size: 24.0),
            ),
            eventLoader: (day) =>
                eventsByDay[DateTime(day.year, day.month, day.day)] ?? [],
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = DateTime(
                    selectedDay.year, selectedDay.month, selectedDay.day);
              });
            },
          ),
          const SizedBox(height: 10),
          _buildScheduleTab(), // 💡 เรียกใช้ _buildScheduleTab โดยตรง
        ],
      ),
    );
  }

  Widget _buildStatusButton({
    required String text,
    required StatusFilter status,
    required VoidCallback onPressed,
  }) {
    final bool isSelected = status == _selectedStatus;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isSelected ? Colors.green.shade300 : Colors.grey.shade300,
            foregroundColor: Colors.black87,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              if (isSelected) ...{
                const Icon(Icons.check, color: Colors.white, size: 20),
                const SizedBox(width: 8),
              },
              Flexible(
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleTab() {
    return FutureBuilder<List<dynamic>>(
      future: _scheduleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(
              child: Text('ไม่สามารถโหลดข้อมูลได้, กรุณาลองใหม่'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('ไม่มีคิวงาน'));
        }

        final scheduleList = snapshot.data!;

        // 💡 3. แก้ไขเงื่อนไขการกรองข้อมูลตามสถานะที่เลือก
        List<dynamic> filteredList = scheduleList.where((item) {
          final isSelectedDay = isSameDay(
              DateTime.parse(item['date_start']).toLocal(), _selectedDay);
          final progressStatus = item['progress_status'];

          if (!isSelectedDay) {
            return false;
          }

          if (_selectedStatus == StatusFilter.all) {
            // แสดงทั้งหมด
            return true;
          }
          if (_selectedStatus == StatusFilter.pending) {
            // สถานะ 'รอยืนยันการจอง' คือ progress_status เป็น null
            return progressStatus == null;
          }
          if (_selectedStatus == StatusFilter.notAvailable) {
            // สถานะ 'ผู้รับจ้างไม่ว่าง' คือ progress_status เป็น 1, 2, 3 หรือ 5
            return progressStatus != null &&
                ['1', '2', '3', '5'].contains(progressStatus.toString());
          }

          return false;
        }).toList();

        if (filteredList.isEmpty) {
          return const Center(child: Text('วันนี้ไม่มีสถานะนี้'));
        }

        String getStatusText(dynamic status) {
          if (status != null &&
              ['1', '2', '3', '5'].contains(status.toString())) {
            return 'ผู้รับจ้างไม่ว่าง';
          }
          if (status == null) {
            return 'รอยืนยันการจอง';
          }
          return '';
        }

        Color getStatusColor(dynamic status) {
          if (status != null &&
              ['1', '2', '3', '5'].contains(status.toString())) {
            return Colors.green;
          }
          if (status == null) {
            return const Color.fromARGB(255, 255, 0, 0);
          }
          return Colors.transparent;
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          shrinkWrap: true, // 💡 สำคัญ: ต้องใส่ shrinkWrap: true
          physics:
              const NeverScrollableScrollPhysics(), // 💡 สำคัญ: ต้องใส่ NeverScrollableScrollPhysics()
          itemCount: filteredList.length,
          itemBuilder: (context, index) {
            final item = filteredList[index];

            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFFCC80),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
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
                    Row(
                      children: [
                        const Icon(Icons.directions_car,
                            size: 16, color: Colors.blueGrey),
                        const SizedBox(width: 4),
                        Text(
                          'รถ: ${item['name_vehicle'] ?? '-'}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 16, color: Colors.orange),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item['subdistrict'] != null
                                ? '${item['subdistrict']} ${item['district']} ${item['province']}'
                                : 'ไม่ระบุที่อยู่',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.access_time, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _formatDateRange(
                                item['date_start'], item['date_end']),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLocaleInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return DefaultTabController(
      length: 1,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 18, 143, 9),
          centerTitle: true,
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),
          title: const Text(
            'คิวงานทั้งหมด',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 255, 255, 255),
              shadows: [
                Shadow(
                  color: Color.fromARGB(115, 253, 237, 237),
                  blurRadius: 3,
                  offset: Offset(1.5, 1.5),
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildPlanTab(),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (widget.farm != null &&
                      widget.farm is Map &&
                      widget.farm.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReservingForNF(
                          mid: widget.mid_employer,
                          vid: widget.vid,
                          fid: widget.fid,
                          farm: widget.farm,
                          vihicleData: widget.vihicleData,
                        ),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReservingForNF(
                          mid: widget.mid_employer,
                          vid: widget.vid,
                          vihicleData: widget.vihicleData,
                        ),
                      ),
                    );
                  }
                },
                style: bookingButtonStyle,
                child: const Text('จองคิวรถ'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}



















// import 'dart:convert';
// import 'package:agri_booking2/pages/contactor/DetailWork.dart';
// import 'package:agri_booking2/pages/employer/reservingForNF.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';
// import 'package:intl/date_symbol_data_local.dart';
// import 'package:table_calendar/table_calendar.dart';

// class PlanPage extends StatefulWidget {
//   final int mid;
//   final int month;
//   final int year;
//   final int mid_employer;
//   final int vid;
//   final int? fid; // ✅ เพิ่มตรงนี้
//   final dynamic farm; // ✅ เพิ่มตรงนี้
//   final dynamic vihicleData;

//   const PlanPage({
//     super.key,
//     required this.mid,
//     required this.month,
//     required this.year,
//     required this.mid_employer,
//     required this.vid,
//     this.fid,
//     this.farm,
//     this.vihicleData,
//   });

//   @override
//   State<PlanPage> createState() => _PlanAndHistoryState();
// }

// class _PlanAndHistoryState extends State<PlanPage> {
//   Future<List<dynamic>>? _scheduleFuture;
//   late int _displayMonth;
//   late int _displayYear;
//   bool _isLocaleInitialized = false;
//   int statusFilter = 2;

//   // เพิ่มด้านบนใน Widget ของคุณ (นอก ListView)
//   Map<String, bool> statusFilters = {
//     '0': false,
//     '1': false,
//     '2': false,
//     '3': false,
//     '4': false,
//     '5': false,
//     'default': true, // กรณีสถานะอื่นหรือยังไม่ยืนยัน
//   };

//   @override
//   void initState() {
//     super.initState();
//     _displayMonth = widget.month;
//     _displayYear = widget.year;
//     fetchCon(this.widget.mid);
//     // ✅ เรียก initializeDateFormatting ก่อนโหลดข้อมูล
//     initializeDateFormatting('th', null).then((_) {
//       setState(() {
//         _isLocaleInitialized = true;
//         _scheduleFuture =
//             fetchSchedule(widget.mid, _displayMonth, _displayYear);
//       });
//     });
//   }

//   Future<Map<String, dynamic>> fetchCon(int mid) async {
//     final url_con = Uri.parse(
//         'http://projectnodejs.thammadalok.com/AGribooking/members/$mid');
//     final response = await http.get(url_con);

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       print("ข้อมูลเจ้าของรถ: $data");
//       return data;
//     } else {
//       throw Exception('ไม่พบข้อมูลสมาชิก');
//     }
//   }

//   // Future<List<dynamic>> fetchSchedule(int mid, int month, int year) async {
//   //   final url = Uri.parse(
//   //       'http://projectnodejs.thammadalok.com/AGribooking/get_ConReserving/$mid?month=$month&year=$year');

//   //   try {
//   //     final response = await http.get(url);

//   //     if (response.statusCode == 200) {
//   //       if (response.body.isNotEmpty) {
//   //         print(response.body);
//   //         return jsonDecode(response.body);
//   //       } else {
//   //         return [];
//   //       }
//   //     } else {
//   //       throw Exception('Failed to load schedule: ${response.statusCode}');
//   //     }
//   //   } catch (e) {
//   //     throw Exception('Connection error: $e');
//   //   }
//   // }

//   Future<List<dynamic>> fetchSchedule(int mid, int month, int year) async {
//     final url = Uri.parse(
//       'http://projectnodejs.thammadalok.com/AGribooking/get_ConReserving/$mid?month=$month&year=$year',
//     );

//     try {
//       final response = await http.get(url);

//       if (response.statusCode == 200) {
//         if (response.body.isNotEmpty) {
//           final List<dynamic> data = jsonDecode(response.body);

//           // กรองข้อมูล ไม่เอา progress_status = 0 หรือ 4
//           final filteredData = data.where((item) {
//             final status = item['progress_status'];
//             return status != 0 && status != 4;
//           }).toList();

//           return filteredData;
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

//   Map<DateTime, List<dynamic>> eventsByDay = {};

//   void groupEventsByDay(List<dynamic> scheduleList) {
//     eventsByDay.clear();
//     for (var item in scheduleList) {
//       final dateStart = DateTime.parse(item['date_start']).toLocal();
//       final dateKey = DateTime(dateStart.year, dateStart.month, dateStart.day);

//       if (eventsByDay[dateKey] == null) {
//         eventsByDay[dateKey] = [item];
//       } else {
//         eventsByDay[dateKey]!.add(item);
//       }
//     }
//   }

//   //วันที่และเวลา
//   String _formatDateRange(String? startDate, String? endDate) {
//     if (startDate == null || endDate == null) return 'ไม่ระบุวันที่';
//     try {
//       final startUtc = DateTime.parse(startDate);
//       final endUtc = DateTime.parse(endDate);

//       final startThai = startUtc.add(const Duration(hours: 7));
//       final endThai = endUtc.add(const Duration(hours: 7));

//       final formatter = DateFormat('dd/MM/yyyy \t\tเวลา HH:mm น.');

//       return 'เริ่มงาน: ${formatter.format(startThai)}\nสิ้นสุด: ${formatter.format(endThai)}';
//     } catch (e) {
//       return 'รูปแบบวันที่ไม่ถูกต้อง';
//     }
//   }

//   void _changeMonth(int delta) {
//     setState(() {
//       _displayMonth += delta;
//       if (_displayMonth > 12) {
//         _displayMonth = 1;
//         _displayYear++;
//       } else if (_displayMonth < 1) {
//         _displayMonth = 12;
//         _displayYear--;
//       }

//       _scheduleFuture = fetchSchedule(widget.mid, _displayMonth, _displayYear);
//     });
//   }

//   // ปุ่มจองคิว
//   final ButtonStyle bookingButtonStyle = ElevatedButton.styleFrom(
//     backgroundColor: Colors.blue,
//     foregroundColor: Colors.white,
//     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//     shape: RoundedRectangleBorder(
//       borderRadius: BorderRadius.circular(10),
//     ),
//     textStyle: const TextStyle(
//       fontSize: 20,
//       fontWeight: FontWeight.bold, // ✅ ตัวหนา
//     ),
//   );

//   DateTime? _selectedDay;

//   Widget _buildPlanTab() {
//     final String currentMonthName =
//         DateFormat.MMMM('th').format(DateTime(_displayYear, _displayMonth));

//     return Column(
//       children: [
//         Expanded(
//           child: Column(
//             children: [
//               TableCalendar(
//                 locale: 'th_TH',
//                 focusedDay: DateTime(_displayYear, _displayMonth),
//                 firstDay: DateTime(_displayYear - 1),
//                 lastDay: DateTime(_displayYear + 1),
//                 startingDayOfWeek: StartingDayOfWeek.monday,

//                 // ✅ บอกว่า วันไหนถูกเลือก
//                 selectedDayPredicate: (day) => isSameDay(_selectedDay, day),

//                 calendarStyle: CalendarStyle(
//                   todayDecoration: BoxDecoration(
//                     color: Colors.orangeAccent.withOpacity(0.6),
//                     shape: BoxShape.rectangle, // ไม่ต้องใช้ circle
//                   ),
//                   selectedDecoration: BoxDecoration(
//                     color: Colors.green,
//                     shape: BoxShape.rectangle,
//                   ),
//                   markerDecoration: BoxDecoration(), // ไม่จำเป็นอีกต่อไป
//                   outsideDaysVisible: false,
//                 ),

//                 headerStyle: const HeaderStyle(
//                   formatButtonVisible:
//                       false, // ซ่อนปุ่มเลือก format เดือน/สัปดาห์
//                   titleCentered: true,
//                 ),

//                 calendarBuilders: CalendarBuilders(
//                   dowBuilder: (context, day) {
//                     // ✅ ไม่ต้องเขียนอะไรเกี่ยวกับ week number
//                     return null;
//                   },
//                 ),

//                 eventLoader: (day) =>
//                     eventsByDay[DateTime(day.year, day.month, day.day)] ?? [],

//                 onDaySelected: (selectedDay, focusedDay) {
//                   setState(() {
//                     _selectedDay = DateTime(
//                         selectedDay.year, selectedDay.month, selectedDay.day);
//                   });
//                 },
//               ),
//               const SizedBox(height: 8),
//               if (_selectedDay != null)
//                 Text(
//                   'วันที่เลือก: ${DateFormat('dd MMMM yyyy', 'th').format(_selectedDay!)}',
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black87,
//                   ),
//                 ),
//               const SizedBox(height: 16),
//               Expanded(
//                 child: _buildScheduleTab(includeHistory: false),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildScheduleTab({required bool includeHistory}) {
//     return FutureBuilder<List<dynamic>>(
//       future: _scheduleFuture,
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         } else if (snapshot.hasError) {
//           return Center(
//             child: Text('ยังไม่มีการจองคิวรถในเดือนนี้'),
//           );
//         } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//           return const Center(child: Text('ไม่มีคิวงาน'));
//         }

//         final scheduleList = snapshot.data!
//             .where((item) => includeHistory
//                 ? item['progress_status'] == 4
//                 : item['progress_status'] != 4)
//             .toList();

//         groupEventsByDay(scheduleList); // เตรียมข้อมูลปฏิทิน

//         if (scheduleList.isEmpty) {
//           return const Center(child: Text('ไม่พบงานในหมวดนี้'));
//         }

//         // กรองรายการงานตามวันที่เลือก
//         List<dynamic> filteredList;
//         if (_selectedDay != null) {
//           filteredList = scheduleList.where((item) {
//             final dateStart = DateTime.parse(item['date_start']).toLocal();
//             final itemDate =
//                 DateTime(dateStart.year, dateStart.month, dateStart.day);
//             return itemDate == _selectedDay;
//           }).toList();
//         } else {
//           filteredList = scheduleList; // ถ้าไม่เลือกวัน แสดงทั้งหมดในเดือน
//         }

//         if (filteredList.isEmpty) {
//           return const Center(child: Text('ไม่มีคิวงานในวันที่เลือก'));
//         }

//         // String getStatusText(dynamic status) {
//         //   switch (status.toString()) {
//         //     case '0':
//         //       return 'ผู้รับจ้างยกเลิกงาน';
//         //     case '1':
//         //       return 'ผู้รับจ้างยืนยันการจอง';
//         //     case '2':
//         //       return 'กำลังเดินทาง';
//         //     case '3':
//         //       return 'กำลังทำงาน';
//         //     case '4':
//         //       return 'เสร็จสิ้น';
//         //     case '5':
//         //       return 'รอผู้รับจ้างยกเลิกงาน';
//         //     default:
//         //       return 'รอผู้รับจ้างยืนยันการจอง';
//         //   }
//         // }

//         // Color getStatusColor(dynamic status) {
//         //   switch (status.toString()) {
//         //     case '0':
//         //       return Colors.red;
//         //     case '1':
//         //       return Colors.blueGrey;
//         //     case '2':
//         //       return Colors.pinkAccent;
//         //     case '3':
//         //       return Colors.amber;
//         //     case '4':
//         //       return Colors.green;
//         //     case '5':
//         //       return Color.fromARGB(255, 54, 28, 31);
//         //     default:
//         //       return Colors.black45;
//         //   }
//         // }

//         String getStatusText(dynamic status) {
//           if (['1', '2', '3', '5'].contains(status.toString())) {
//             return 'ผู้รับจ้างไม่ว่าง';
//           }
//           // ถ้าเป็น 0 หรือ 4 จะไม่แสดง
//           return 'รอผู้รับจ้างยืนยันการจอง';
//         }

//         Color getStatusColor(dynamic status) {
//           if (['1', '2', '3', '5'].contains(status.toString())) {
//             return Colors.green;
//           }
//           return const Color.fromARGB(115, 255, 0, 0);
//         }

//         return Column(
//           children: [
//             const SizedBox(height: 10),

//             // Wrap(
//             //   spacing: 8,
//             //   children: statusFilters.entries.map((entry) {
//             //     String statusKey = entry.key;
//             //     bool isSelected = entry.value;

//             //     final text = getStatusText(statusKey);

//             //     if (text != 'รอผู้รับจ้างยืนยันการจอง' &&
//             //         text != 'ผู้รับจ้างไม่ว่าง') {
//             //       return const SizedBox.shrink(); // ไม่แสดง
//             //     }

//             //     return FilterChip(
//             //       label: Text(text),
//             //       selected: isSelected,
//             //       onSelected: (bool selected) {
//             //         setState(() {
//             //           statusFilters[statusKey] = selected;
//             //         });
//             //       },
//             //       selectedColor: getStatusColor(statusKey).withOpacity(0.2),
//             //       checkmarkColor: getStatusColor(statusKey),
//             //     );
//             //   }).toList(),
//             // ),
//             const SizedBox(height: 10),
//             Expanded(
//                 child: ListView.builder(
//               padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
//               itemCount: filteredList.length,
//               itemBuilder: (context, index) {
//                 final item = filteredList[index];

//                 return Container(
//                   decoration: BoxDecoration(
//                     color: const Color(0xFFFFF3E0),
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(
//                       color: const Color(0xFFFFCC80),
//                       width: 1.5,
//                     ),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.orange.withOpacity(0.2),
//                         spreadRadius: 2,
//                         blurRadius: 8,
//                         offset: const Offset(0, 4),
//                       ),
//                     ],
//                   ),
//                   margin: const EdgeInsets.symmetric(vertical: 8),
//                   child: Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Flexible(
//                               child: Text(
//                                 item['name_rs'] ?? '-',
//                                 style: const TextStyle(
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.black87,
//                                 ),
//                                 overflow: TextOverflow.ellipsis,
//                                 maxLines: 1,
//                               ),
//                             ),
//                             Row(
//                               children: [
//                                 Icon(Icons.circle,
//                                     color:
//                                         getStatusColor(item['progress_status']),
//                                     size: 10),
//                                 const SizedBox(width: 4),
//                                 Text(
//                                   getStatusText(item['progress_status']),
//                                   style: TextStyle(
//                                     fontSize: 13,
//                                     fontWeight: FontWeight.w500,
//                                     color:
//                                         getStatusColor(item['progress_status']),
//                                   ),
//                                 ),
//                               ],
//                             )
//                           ],
//                         ),
//                         const SizedBox(height: 8),
//                         Row(
//                           children: [
//                             const Icon(Icons.directions_car,
//                                 size: 16, color: Colors.blueGrey),
//                             const SizedBox(width: 4),
//                             Text(
//                               'รถ: ${item['name_vehicle'] ?? '-'}',
//                               style: const TextStyle(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 4),
//                         Row(
//                           children: [
//                             const Icon(Icons.location_on,
//                                 size: 16, color: Colors.orange),
//                             const SizedBox(width: 4),
//                             Expanded(
//                               child: Text(
//                                 item['name_farm'] ?? '-',
//                                 style: const TextStyle(fontSize: 14),
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 8),
//                         Row(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Icon(Icons.access_time, size: 16),
//                             const SizedBox(width: 4),
//                             Expanded(
//                               child: Text(
//                                 _formatDateRange(
//                                     item['date_start'], item['date_end']),
//                                 style: const TextStyle(
//                                   fontSize: 13,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 8),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             )),
//           ],
//         );

//         // return ListView.builder(
//         //   padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
//         //   itemCount: filteredList.length,
//         //   itemBuilder: (context, index) {
//         //     final item = filteredList[index];

//         //     return Container(
//         //       decoration: BoxDecoration(
//         //         color: const Color(0xFFFFF3E0),
//         //         borderRadius: BorderRadius.circular(12),
//         //         border: Border.all(
//         //           color: const Color(0xFFFFCC80),
//         //           width: 1.5,
//         //         ),
//         //         boxShadow: [
//         //           BoxShadow(
//         //             color: Colors.orange.withOpacity(0.2),
//         //             spreadRadius: 2,
//         //             blurRadius: 8,
//         //             offset: const Offset(0, 4),
//         //           ),
//         //         ],
//         //       ),
//         //       margin: const EdgeInsets.symmetric(vertical: 8),
//         //       child: Padding(
//         //         padding: const EdgeInsets.all(16.0),
//         //         child: Column(
//         //           crossAxisAlignment: CrossAxisAlignment.start,
//         //           children: [
//         //             Row(
//         //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         //               children: [
//         //                 Flexible(
//         //                   child: Text(
//         //                     item['name_rs'] ?? '-',
//         //                     style: const TextStyle(
//         //                       fontSize: 18,
//         //                       fontWeight: FontWeight.bold,
//         //                       color: Colors.black87,
//         //                     ),
//         //                     overflow: TextOverflow.ellipsis,
//         //                     maxLines: 1,
//         //                   ),
//         //                 ),
//         //                 Row(
//         //                   children: [
//         //                     Icon(Icons.circle,
//         //                         color: getStatusColor(item['progress_status']),
//         //                         size: 10),
//         //                     const SizedBox(width: 4),
//         //                     Text(
//         //                       getStatusText(item['progress_status']),
//         //                       style: TextStyle(
//         //                         fontSize: 13,
//         //                         fontWeight: FontWeight.w500,
//         //                         color: getStatusColor(item['progress_status']),
//         //                       ),
//         //                     ),
//         //                   ],
//         //                 )
//         //               ],
//         //             ),
//         //             const SizedBox(height: 8),
//         //             Row(
//         //               children: [
//         //                 const Icon(Icons.directions_car,
//         //                     size: 16, color: Colors.blueGrey),
//         //                 const SizedBox(width: 4),
//         //                 Text(
//         //                   'รถ: ${item['name_vehicle'] ?? '-'}',
//         //                   style: const TextStyle(
//         //                     fontSize: 14,
//         //                     fontWeight: FontWeight.w500,
//         //                   ),
//         //                 ),
//         //               ],
//         //             ),
//         //             const SizedBox(height: 4),
//         //             Row(
//         //               children: [
//         //                 const Icon(Icons.location_on,
//         //                     size: 16, color: Colors.orange),
//         //                 const SizedBox(width: 4),
//         //                 Expanded(
//         //                   child: Text(
//         //                     item['name_farm'] ?? '-',
//         //                     style: const TextStyle(fontSize: 14),
//         //                   ),
//         //                 ),
//         //               ],
//         //             ),
//         //             const SizedBox(height: 8),
//         //             Row(
//         //               crossAxisAlignment: CrossAxisAlignment.start,
//         //               children: [
//         //                 const Icon(Icons.access_time, size: 16),
//         //                 const SizedBox(width: 4),
//         //                 Expanded(
//         //                   child: Text(
//         //                     _formatDateRange(
//         //                         item['date_start'], item['date_end']),
//         //                     style: const TextStyle(
//         //                       fontSize: 13,
//         //                       fontWeight: FontWeight.bold,
//         //                     ),
//         //                   ),
//         //                 ),
//         //               ],
//         //             ),
//         //             const SizedBox(height: 8),
//         //           ],
//         //         ),
//         //       ),
//         //     );
//         //   },
//         // );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (!_isLocaleInitialized) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }

//     return DefaultTabController(
//       length: 2,
//       child: Scaffold(
//         //backgroundColor: const Color(0xFFFFCC99),
//         appBar: AppBar(
//           backgroundColor: const Color.fromARGB(255, 18, 143, 9),
//           centerTitle: true,
//           iconTheme: const IconThemeData(
//             color: Colors.white, // ✅ ลูกศรย้อนกลับสีขาว
//           ),
//           title: const Text(
//             'คิวงานทั้งหมด',
//             style: TextStyle(
//               fontSize: 22,
//               fontWeight: FontWeight.bold,
//               color: Color.fromARGB(255, 255, 255, 255),
//               //letterSpacing: 1,
//               shadows: [
//                 Shadow(
//                   color: Color.fromARGB(115, 253, 237, 237),
//                   blurRadius: 3,
//                   offset: Offset(1.5, 1.5),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         body: TabBarView(
//           children: [
//             _buildPlanTab(), // แสดงปฏิทิน + งานที่ไม่ใช่ประวัติ
//           ],
//         ),

//         bottomNavigationBar: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.all(12.0),
//             child: SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () {
//                   if (widget.farm != null &&
//                       widget.farm is Map &&
//                       widget.farm.isNotEmpty) {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => ReservingForNF(
//                           mid: widget.mid_employer,
//                           vid: widget.vid,
//                           fid: widget.fid,
//                           farm: widget.farm,
//                           vihicleData: widget.vihicleData,
//                         ),
//                       ),
//                     );
//                   } else {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => ReservingForNF(
//                           mid: widget.mid_employer,
//                           vid: widget.vid,
//                           vihicleData: widget.vihicleData,
//                         ),
//                       ),
//                     );
//                   }
//                 },
//                 style: bookingButtonStyle,
//                 child: const Text('จองคิวรถ'),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// import 'dart:convert';
// import 'package:agri_booking2/pages/contactor/DetailWork.dart';
// import 'package:agri_booking2/pages/employer/reservingForNF.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';
// import 'package:intl/date_symbol_data_local.dart';
// import 'package:table_calendar/table_calendar.dart';

// class PlanPage extends StatefulWidget {
//   final int mid;
//   final int month;
//   final int year;
//   final int mid_employer;
//   final int vid;
//   final int? fid;
//   final dynamic farm;
//   final dynamic vihicleData;

//   const PlanPage({
//     super.key,
//     required this.mid,
//     required this.month,
//     required this.year,
//     required this.mid_employer,
//     required this.vid,
//     this.fid,
//     this.farm,
//     this.vihicleData,
//   });

//   @override
//   State<PlanPage> createState() => _PlanAndHistoryState();
// }

// class _PlanAndHistoryState extends State<PlanPage> {
//   Future<List<dynamic>>? _scheduleFuture;
//   late int _displayMonth;
//   late int _displayYear;
//   bool _isLocaleInitialized = false;

//   bool _showNotAvailable = true;
//   bool _showPending = true;

//   // 💡 ประกาศตัวแปร _selectedDay และกำหนดค่าเริ่มต้นเป็นวันปัจจุบัน
//   DateTime? _selectedDay = DateTime.now();

//   @override
//   void initState() {
//     super.initState();
//     _displayMonth = widget.month;
//     _displayYear = widget.year;
//     fetchCon(this.widget.mid);
//     initializeDateFormatting('th', null).then((_) {
//       setState(() {
//         _isLocaleInitialized = true;
//         _scheduleFuture =
//             fetchSchedule(widget.mid, _displayMonth, _displayYear);
//       });
//     });
//   }

//   Future<Map<String, dynamic>> fetchCon(int mid) async {
//     final url_con = Uri.parse(
//         'http://projectnodejs.thammadalok.com/AGribooking/members/$mid');
//     final response = await http.get(url_con);

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       print("ข้อมูลเจ้าของรถ: $data");
//       return data;
//     } else {
//       throw Exception('ไม่พบข้อมูลสมาชิก');
//     }
//   }

//   Future<List<dynamic>> fetchSchedule(int mid, int month, int year) async {
//     final url = Uri.parse(
//       'http://projectnodejs.thammadalok.com/AGribooking/get_ConReserving/$mid?month=$month&year=$year',
//     );

//     try {
//       final response = await http.get(url);

//       if (response.statusCode == 200) {
//         if (response.body.isNotEmpty) {
//           final List<dynamic> data = jsonDecode(response.body);

//           final filteredData = data.where((item) {
//             final status = item['progress_status'];
//             return status != 4; // กรองสถานะ 4 ออกเท่านั้น
//           }).toList();

//           return filteredData;
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

//   Map<DateTime, List<dynamic>> eventsByDay = {};

//   void groupEventsByDay(List<dynamic> scheduleList) {
//     eventsByDay.clear();
//     for (var item in scheduleList) {
//       final dateStart = DateTime.parse(item['date_start']).toLocal();
//       final dateKey = DateTime(dateStart.year, dateStart.month, dateStart.day);

//       if (eventsByDay[dateKey] == null) {
//         eventsByDay[dateKey] = [item];
//       } else {
//         eventsByDay[dateKey]!.add(item);
//       }
//     }
//   }

//   String _formatDateRange(String? startDate, String? endDate) {
//     if (startDate == null || endDate == null) return 'ไม่ระบุวันที่';
//     try {
//       final startUtc = DateTime.parse(startDate);
//       final endUtc = DateTime.parse(endDate);

//       final startThai = startUtc.add(const Duration(hours: 7));
//       final endThai = endUtc.add(const Duration(hours: 7));

//       final formatter = DateFormat('dd/MM/yyyy \t\tเวลา HH:mm น.');

//       return 'เริ่มงาน: ${formatter.format(startThai)}\nสิ้นสุด: ${formatter.format(endThai)}';
//     } catch (e) {
//       return 'รูปแบบวันที่ไม่ถูกต้อง';
//     }
//   }

//   void _changeMonth(int delta) {
//     setState(() {
//       _displayMonth += delta;
//       if (_displayMonth > 12) {
//         _displayMonth = 1;
//         _displayYear++;
//       } else if (_displayMonth < 1) {
//         _displayMonth = 12;
//         _displayYear--;
//       }

//       _scheduleFuture = fetchSchedule(widget.mid, _displayMonth, _displayYear);
//     });
//   }

//   final ButtonStyle bookingButtonStyle = ElevatedButton.styleFrom(
//     backgroundColor: Colors.blue,
//     foregroundColor: Colors.white,
//     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//     shape: RoundedRectangleBorder(
//       borderRadius: BorderRadius.circular(10),
//     ),
//     textStyle: const TextStyle(
//       fontSize: 20,
//       fontWeight: FontWeight.bold,
//     ),
//   );

//   Widget _buildPlanTab() {
//     return Column(
//       children: [
//         TableCalendar(
//           locale: 'th_TH',
//           focusedDay: _selectedDay ?? DateTime(_displayYear, _displayMonth),
//           firstDay: DateTime(_displayYear - 1),
//           lastDay: DateTime(_displayYear + 1),
//           startingDayOfWeek: StartingDayOfWeek.monday,
//           selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
//           calendarStyle: const CalendarStyle(
//             cellMargin: EdgeInsets.all(5.0),
//             markerSize: 8.0,
//             cellAlignment: Alignment.center,
//             defaultTextStyle: TextStyle(fontSize: 14.0),
//             weekendTextStyle: TextStyle(fontSize: 14.0, color: Colors.red),
//             todayTextStyle: TextStyle(fontSize: 14.0, color: Colors.white),
//             selectedTextStyle: TextStyle(fontSize: 14.0, color: Colors.white),
//             outsideDaysVisible: false,
//             todayDecoration: BoxDecoration(
//               color: Colors.orangeAccent,
//               shape: BoxShape.circle,
//             ),
//             selectedDecoration: BoxDecoration(
//               color: Colors.green,
//               shape: BoxShape.circle,
//             ),
//           ),
//           headerStyle: const HeaderStyle(
//             titleCentered: true,
//             formatButtonVisible: false,
//             titleTextStyle:
//                 TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
//             leftChevronIcon: Icon(Icons.chevron_left, size: 24.0),
//             rightChevronIcon: Icon(Icons.chevron_right, size: 24.0),
//           ),
//           eventLoader: (day) =>
//               eventsByDay[DateTime(day.year, day.month, day.day)] ?? [],
//           onDaySelected: (selectedDay, focusedDay) {
//             setState(() {
//               _selectedDay = DateTime(
//                   selectedDay.year, selectedDay.month, selectedDay.day);
//             });
//           },
//         ),
//         const SizedBox(height: 16),
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16.0),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               _buildStatusButton(
//                 text: 'ผู้รับจ้างไม่ว่าง',
//                 isSelected: _showPending,
//                 onPressed: () {
//                   setState(() {
//                     _showPending = !_showPending;
//                   });
//                 },
//               ),
//               _buildStatusButton(
//                 text: 'รอยืนยันการจอง',
//                 isSelected: _showNotAvailable,
//                 onPressed: () {
//                   setState(() {
//                     _showNotAvailable = !_showNotAvailable;
//                   });
//                 },
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 10),
//         Expanded(
//           child: SingleChildScrollView(
//             child: _buildScheduleTab(),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildStatusButton({
//     required String text,
//     required bool isSelected,
//     required VoidCallback onPressed,
//   }) {
//     return ElevatedButton(
//       onPressed: onPressed,
//       style: ElevatedButton.styleFrom(
//         backgroundColor: isSelected ? Colors.blue : Colors.grey,
//         foregroundColor: Colors.white,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(20),
//         ),
//       ),
//       child: Text(text),
//     );
//   }

//   Widget _buildScheduleTab() {
//     return FutureBuilder<List<dynamic>>(
//       future: _scheduleFuture,
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         } else if (snapshot.hasError) {
//           return const Center(
//               child: Text('ไม่สามารถโหลดข้อมูลได้, กรุณาลองใหม่'));
//         } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//           return const Center(child: Text('ไม่มีคิวงาน'));
//         }

//         final scheduleList = snapshot.data!;
//         groupEventsByDay(scheduleList);

//         // 💡 ปรับปรุงเงื่อนไขการกรองข้อมูล
//         final filteredList = scheduleList.where((item) {
//           final isPending = item['progress_status'] == null;
//           final isNotAvailable = ['1', '2', '3', '5']
//               .contains(item['progress_status']?.toString());
//           final isSelectedDay = _selectedDay == null ||
//               isSameDay(
//                   DateTime.parse(item['date_start']).toLocal(), _selectedDay!);

//           return isSelectedDay &&
//               ((_showNotAvailable && isNotAvailable) ||
//                   (_showPending && isPending));
//         }).toList();

//         if (filteredList.isEmpty) {
//           return const Center(child: Text('วันนี้ไม่มีสถานะนี้'));
//         }

//         String getStatusText(dynamic status) {
//           if (['1', '2', '3', '5'].contains(status?.toString())) {
//             return 'ผู้รับจ้างไม่ว่าง';
//           }
//           if (status == null) {
//             return 'รอผู้จ้างยืนยันการจอง';
//           }
//           return '';
//         }

//         Color getStatusColor(dynamic status) {
//           if (['1', '2', '3', '5'].contains(status?.toString())) {
//             return Colors.green;
//           }
//           if (status == null) {
//             return const Color.fromARGB(255, 255, 0, 0);
//           }
//           return Colors.transparent;
//         }

//         return Column(
//           children: [
//             ListView.builder(
//               padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               itemCount: filteredList.length,
//               itemBuilder: (context, index) {
//                 final item = filteredList[index];

//                 return Container(
//                   decoration: BoxDecoration(
//                     color: const Color(0xFFFFF3E0),
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(
//                       color: const Color(0xFFFFCC80),
//                       width: 1.5,
//                     ),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.orange.withOpacity(0.2),
//                         spreadRadius: 2,
//                         blurRadius: 8,
//                         offset: const Offset(0, 4),
//                       ),
//                     ],
//                   ),
//                   margin: const EdgeInsets.symmetric(vertical: 8),
//                   child: Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Flexible(
//                               child: Text(
//                                 item['name_rs'] ?? '-',
//                                 style: const TextStyle(
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.black87,
//                                 ),
//                                 overflow: TextOverflow.ellipsis,
//                                 maxLines: 1,
//                               ),
//                             ),
//                             Row(
//                               children: [
//                                 Icon(Icons.circle,
//                                     color:
//                                         getStatusColor(item['progress_status']),
//                                     size: 10),
//                                 const SizedBox(width: 4),
//                                 Text(
//                                   getStatusText(item['progress_status']),
//                                   style: TextStyle(
//                                     fontSize: 13,
//                                     fontWeight: FontWeight.w500,
//                                     color:
//                                         getStatusColor(item['progress_status']),
//                                   ),
//                                 ),
//                               ],
//                             )
//                           ],
//                         ),
//                         const SizedBox(height: 8),
//                         Row(
//                           children: [
//                             const Icon(Icons.directions_car,
//                                 size: 16, color: Colors.blueGrey),
//                             const SizedBox(width: 4),
//                             Text(
//                               'รถ: ${item['name_vehicle'] ?? '-'}',
//                               style: const TextStyle(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 4),
//                         Row(
//                           children: [
//                             const Icon(Icons.location_on,
//                                 size: 16, color: Colors.orange),
//                             const SizedBox(width: 4),
//                             Expanded(
//                               child: Text(
//                                 item['name_farm'] ?? '-',
//                                 style: const TextStyle(fontSize: 14),
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 8),
//                         Row(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Icon(Icons.access_time, size: 16),
//                             const SizedBox(width: 4),
//                             Expanded(
//                               child: Text(
//                                 _formatDateRange(
//                                     item['date_start'], item['date_end']),
//                                 style: const TextStyle(
//                                   fontSize: 13,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 8),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (!_isLocaleInitialized) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }

//     return DefaultTabController(
//       length: 1,
//       child: Scaffold(
//         appBar: AppBar(
//           backgroundColor: const Color.fromARGB(255, 18, 143, 9),
//           centerTitle: true,
//           iconTheme: const IconThemeData(
//             color: Colors.white,
//           ),
//           title: const Text(
//             'คิวงานทั้งหมด',
//             style: TextStyle(
//               fontSize: 22,
//               fontWeight: FontWeight.bold,
//               color: Color.fromARGB(255, 255, 255, 255),
//               shadows: [
//                 Shadow(
//                   color: Color.fromARGB(115, 253, 237, 237),
//                   blurRadius: 3,
//                   offset: Offset(1.5, 1.5),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         body: TabBarView(
//           children: [
//             _buildPlanTab(),
//           ],
//         ),
//         bottomNavigationBar: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.all(12.0),
//             child: SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () {
//                   if (widget.farm != null &&
//                       widget.farm is Map &&
//                       widget.farm.isNotEmpty) {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => ReservingForNF(
//                           mid: widget.mid_employer,
//                           vid: widget.vid,
//                           fid: widget.fid,
//                           farm: widget.farm,
//                           vihicleData: widget.vihicleData,
//                         ),
//                       ),
//                     );
//                   } else {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => ReservingForNF(
//                           mid: widget.mid_employer,
//                           vid: widget.vid,
//                           vihicleData: widget.vihicleData,
//                         ),
//                       ),
//                     );
//                   }
//                 },
//                 style: bookingButtonStyle,
//                 child: const Text('จองคิวรถ'),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }