import 'dart:convert';
import 'package:agri_booking2/pages/contactor/DetailWork.dart';
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

class _PlanAndHistoryState extends State<PlanAndHistory> {
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

  @override
  void initState() {
    super.initState();
    _displayMonth = widget.month;
    _displayYear = widget.year;
    _focusedDay = DateTime.now();

    initializeDateFormatting('th', null).then((_) {
      setState(() {
        _isLocaleInitialized = true;
        _scheduleFuture =
            fetchSchedule(widget.mid, _displayMonth, _displayYear).then((list) {
          _groupEventsByDay(list);
          return list;
        });
      });
    });
  }

  // 💡 สร้างฟังก์ชันสำหรับการรีเฟรชข้อมูล
  Future<void> _refreshSchedule() async {
    // ดึงข้อมูลใหม่
    final newSchedule =
        await fetchSchedule(widget.mid, _displayMonth, _displayYear);
    // อัปเดตสถานะของหน้า
    setState(() {
      _groupEventsByDay(newSchedule);
      _scheduleFuture = Future.value(newSchedule);
    });
  }

  Future<Map<String, dynamic>> fetchCon(int mid) async {
    final url_con = Uri.parse(
        'http://projectnodejs.thammadalok.com/AGribooking/members/$mid');
    final response = await http.get(url_con);
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

  // void _groupEventsByDay(List<dynamic> scheduleList) {
  //   eventsByDay.clear();
  //   for (var item in scheduleList) {
  //     final dateStart = DateTime.parse(item['date_start']).toLocal();
  //     final dateKey = DateTime(dateStart.year, dateStart.month, dateStart.day);
  //     if (eventsByDay[dateKey] == null) {
  //       eventsByDay[dateKey] = [item];
  //     } else {
  //       eventsByDay[dateKey]!.add(item);
  //     }
  //   }
  //   setState(() {});
  // }

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

  String _formatDateRange(
      String? date_reserve, String? startDate, String? endDate) {
    if (date_reserve == null || startDate == null || endDate == null)
      return 'ไม่ระบุวันที่';
    try {
      final reserveThai =
          DateTime.parse(date_reserve).add(const Duration(hours: 7));
      final startThai = DateTime.parse(startDate).add(const Duration(hours: 7));
      final endThai = DateTime.parse(endDate).add(const Duration(hours: 7));

      final formatter = DateFormat('dd/MM/yyyy \t\tเวลา HH:mm น.');
      return 'จองเข้ามา:${formatter.format(reserveThai)}\n เริ่มงาน: ${formatter.format(startThai)}\nสิ้นสุด: ${formatter.format(endThai)}';
    } catch (e) {
      return 'รูปแบบวันที่ไม่ถูกต้อง';
    }
  }

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
      return status == _selectedStatus;
    }).toList();

    if (filteredSchedule.isEmpty) {
      return [
        const Center(child: Text('ไม่พบงานในหมวดนี้สำหรับวันนี้')),
      ];
    }

    // สร้างรายการ Widget สำหรับ ListView.builder
    return List.generate(filteredSchedule.length, (index) {
      final item = filteredSchedule[index];
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
          case '4':
            return 'เสร็จสิ้น';
          default:
            return 'รอผู้รับจ้างยืนยันการจอง';
        }
      }

      Color getStatusColor(dynamic status) {
        switch (status.toString()) {
          case '0':
            return Colors.red;
          case '1':
            return Colors.blueGrey;
          case '2':
            return Colors.pinkAccent;
          case '3':
            return Colors.amber;
          case '4':
            return Colors.green;
          default:
            return Colors.black45;
        }
      }

      return Container(
        // decoration: BoxDecoration(
        //   color: const Color(0xFFFFF3E0),
        //   borderRadius: BorderRadius.circular(12),
        //   border: Border.all(
        //     color: const Color(0xFFFFCC80),
        //     width: 1.5,
        //   ),
        //   boxShadow: [
        //     BoxShadow(
        //       color: Colors.orange.withOpacity(0.2),
        //       spreadRadius: 2,
        //       blurRadius: 8,
        //       offset: const Offset(0, 4),
        //     ),
        //   ],
        // ),
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 255, 255, 255), // พื้นหลังโทนเดิม
          borderRadius: BorderRadius.circular(12), // มุมโค้ง
          boxShadow: [
            BoxShadow(
              color:
                  Color.fromARGB(255, 251, 229, 196).withOpacity(0.3), // สีเงา
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
                  const Icon(Icons.location_on, size: 16, color: Colors.orange),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'ที่อยู่: ต.${item['subdistrict'] ?? ''} อ.${item['district'] ?? ''} จ.${item['province'] ?? ''}',
                      style: const TextStyle(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
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
                      _formatDateRange(item['date_reserve'], item['date_start'],
                          item['date_end']),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
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
                    return eventsByDay[dateKey] ?? [];
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
                  calendarStyle: const CalendarStyle(
                    markerDecoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
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
              // decoration: BoxDecoration(
              //   color: const Color(0xFFFFF3E0),
              //   borderRadius: BorderRadius.circular(12),
              //   border: Border.all(
              //     color: const Color(0xFFFFCC80),
              //     width: 1.5,
              //   ),
              //   boxShadow: [
              //     BoxShadow(
              //       color: Colors.orange.withOpacity(0.2),
              //       spreadRadius: 2,
              //       blurRadius: 8,
              //       offset: const Offset(0, 4),
              //     ),
              //   ],
              // ),
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 255, 255, 255), // พื้นหลังโทนเดิม
                borderRadius: BorderRadius.circular(12), // มุมโค้ง
                boxShadow: [
                  BoxShadow(
                    color: Color.fromARGB(255, 251, 229, 196)
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Text(
                              //   item['name_farm'] ?? '-',
                              //   style: const TextStyle(fontSize: 14),
                              //   maxLines: 1,
                              //   overflow: TextOverflow.ellipsis,
                              //   softWrap: false,
                              // ),
                              Text(
                                'ที่อยู่: ต.${item['subdistrict'] ?? ''} อ.${item['district'] ?? ''} จ.${item['province'] ?? ''}',
                                style: const TextStyle(fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                              ),
                            ],
                          ),
                        )
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
                            _formatDateRange(item['date_reserve'],
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

  @override
  Widget build(BuildContext context) {
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
            'ตารางงานและประวัติการทำงาน',
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




































// // import 'dart:convert';
// // import 'package:agri_booking2/pages/contactor/DetailWork.dart';
// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:intl/intl.dart';
// // import 'package:intl/date_symbol_data_local.dart';

// // class PlanAndHistory extends StatefulWidget {
// //   final int mid;
// //   final int month;
// //   final int year;

// //   const PlanAndHistory({
// //     super.key,
// //     required this.mid,
// //     required this.month,
// //     required this.year,
// //   });

// //   @override
// //   State<PlanAndHistory> createState() => _PlanAndHistoryState();
// // }

// // class _PlanAndHistoryState extends State<PlanAndHistory> {
// //   Future<List<dynamic>>? _scheduleFuture;
// //   late int _displayMonth;
// //   late int _displayYear;
// //   bool _isLocaleInitialized = false;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _displayMonth = widget.month;
// //     _displayYear = widget.year;
// //     fetchCon(this.widget.mid);
// //     // ✅ เรียก initializeDateFormatting ก่อนโหลดข้อมูล
// //     initializeDateFormatting('th', null).then((_) {
// //       setState(() {
// //         _isLocaleInitialized = true;
// //         _scheduleFuture =
// //             fetchSchedule(widget.mid, _displayMonth, _displayYear);
// //       });
// //     });
// //   }

// //   Future<Map<String, dynamic>> fetchCon(int mid) async {
// //     final url_con = Uri.parse(
// //         'http://projectnodejs.thammadalok.com/AGribooking/members/$mid');
// //     final response = await http.get(url_con);

// //     if (response.statusCode == 200) {
// //       final data = jsonDecode(response.body);
// //       print("ข้อมูลเจ้าของรถ: $data");
// //       return data;
// //     } else {
// //       throw Exception('ไม่พบข้อมูลสมาชิก');
// //     }
// //   }

// //   Future<List<dynamic>> fetchSchedule(int mid, int month, int year) async {
// //     final url = Uri.parse(
// //         'http://projectnodejs.thammadalok.com/AGribooking/get_ConReserving/$mid?month=$month&year=$year');

// //     try {
// //       final response = await http.get(url);

// //       if (response.statusCode == 200) {
// //         if (response.body.isNotEmpty) {
// //           print(response.body);
// //           return jsonDecode(response.body);
// //         } else {
// //           return [];
// //         }
// //       } else {
// //         throw Exception('Failed to load schedule: ${response.statusCode}');
// //       }
// //     } catch (e) {
// //       throw Exception('Connection error: $e');
// //     }
// //   }

// //   //วันที่และเวลา
// //   String _formatDateRange(
// //       String? date_reserve, String? startDate, String? endDate) {
// //     if (date_reserve == null || startDate == null || endDate == null)
// //       return 'ไม่ระบุวันที่';
// //     try {
// //       final reserveUtc = DateTime.parse(date_reserve);
// //       final startUtc = DateTime.parse(startDate);
// //       final endUtc = DateTime.parse(endDate);

// //       final reservingThai = reserveUtc.add(const Duration(hours: 7));
// //       final startThai = startUtc.add(const Duration(hours: 7));
// //       final endThai = endUtc.add(const Duration(hours: 7));

// //       final formatter = DateFormat('dd/MM/yyyy \t\tเวลา HH:mm น.');

// //       return 'จองเข้ามา:${formatter.format(reservingThai)}\n เริ่มงาน: ${formatter.format(startThai)}\nสิ้นสุด: ${formatter.format(endThai)}';
// //     } catch (e) {
// //       return 'รูปแบบวันที่ไม่ถูกต้อง';
// //     }
// //   }

// //   void _changeMonth(int delta) {
// //     setState(() {
// //       _displayMonth += delta;
// //       if (_displayMonth > 12) {
// //         _displayMonth = 1;
// //         _displayYear++;
// //       } else if (_displayMonth < 1) {
// //         _displayMonth = 12;
// //         _displayYear--;
// //       }

// //       _scheduleFuture = fetchSchedule(widget.mid, _displayMonth, _displayYear);
// //     });
// //   }

// //   Widget _buildPlanTab() {
// //     final String currentMonthName =
// //         DateFormat.MMMM('th').format(DateTime(_displayYear, _displayMonth));

// //     return Column(
// //       children: [
// //         Padding(
// //           padding: const EdgeInsets.all(8.0),
// //           child: Row(
// //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //             children: [
// //               IconButton(
// //                 icon: const Icon(Icons.arrow_back_ios),
// //                 onPressed: () => _changeMonth(-1),
// //               ),
// //               Text(
// //                 '$currentMonthName $_displayYear',
// //                 style: const TextStyle(
// //                   fontSize: 20,
// //                   fontWeight: FontWeight.bold,
// //                 ),
// //               ),
// //               IconButton(
// //                 icon: const Icon(Icons.arrow_forward_ios),
// //                 onPressed: () => _changeMonth(1),
// //               ),
// //             ],
// //           ),
// //         ),
// //         Expanded(
// //           child: _buildScheduleTab(includeHistory: false),
// //         ),
// //       ],
// //     );
// //   }

// //   Widget _buildScheduleTab({required bool includeHistory}) {
// //     return FutureBuilder<List<dynamic>>(
// //       future: _scheduleFuture,
// //       builder: (context, snapshot) {
// //         if (snapshot.connectionState == ConnectionState.waiting) {
// //           return const Center(child: CircularProgressIndicator());
// //         } else if (snapshot.hasError) {
// //           return Center(
// //             // child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
// //             child: Text('ขณะนี้ยังไม่มีการจองคิวรถในเดือนนี้'),
// //           );
// //         } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
// //           return const Center(child: Text('ไม่มีคิวงาน'));
// //         }

// //         final scheduleList = snapshot.data!
// //             .where((item) => includeHistory
// //                 ? item['progress_status'] == 4
// //                 : item['progress_status'] != 4)
// //             .toList();

// //         if (scheduleList.isEmpty) {
// //           return const Center(child: Text('ไม่พบงานในหมวดนี้'));
// //         }

// //         //test ui
// //         return ListView.builder(
// //           padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), // ซ้าย-ขวา-ล่าง
// //           itemCount: scheduleList.length,
// //           itemBuilder: (context, index) {
// //             final item = scheduleList[index];

// //             // แปลง progress_status เป็นข้อความ
// //             String getStatusText(dynamic status) {
// //               switch (status.toString()) {
// //                 case '0':
// //                   return 'ผู้รับจ้างยกเลิกงาน';
// //                 case '1':
// //                   return 'ผู้รับจ้างยืนยันการจอง';
// //                 case '2':
// //                   return 'กำลังเดินทาง';
// //                 case '3':
// //                   return 'กำลังทำงาน';
// //                 case '4':
// //                   return 'เสร็จสิ้น';
// //                 default:
// //                   return 'รอผู้รับจ้างยืนยันการจอง';
// //               }
// //             }

// //             // กำหนดสีตามสถานะ
// //             Color getStatusColor(dynamic status) {
// //               switch (status.toString()) {
// //                 case '0':
// //                   return Colors.red;
// //                 case '1':
// //                   return Colors.blueGrey;
// //                 case '2':
// //                   return Colors.pinkAccent;
// //                 case '3':
// //                   return Colors.amber;
// //                 case '4':
// //                   return Colors.green;
// //                 default:
// //                   return Colors.black45;
// //               }
// //             }

// //             return Container(
// //               decoration: BoxDecoration(
// //                 color: const Color(0xFFFFF3E0), // สีพื้นหลังครีมอ่อน
// //                 borderRadius: BorderRadius.circular(12),
// //                 border: Border.all(
// //                   color: const Color(0xFFFFCC80), // สีส้มอ่อนเข้ากับพื้นหลัง
// //                   width: 1.5,
// //                 ),
// //                 boxShadow: [
// //                   BoxShadow(
// //                     color: Colors.orange.withOpacity(0.2), // เงาส้มอ่อนโปร่งใส
// //                     spreadRadius: 2,
// //                     blurRadius: 8,
// //                     offset: const Offset(0, 4), // เงาลงด้านล่างเล็กน้อย
// //                   ),
// //                 ],
// //               ),
// //               margin: const EdgeInsets.symmetric(vertical: 8),
// //               child: Padding(
// //                 padding: const EdgeInsets.all(16.0),
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     // ชื่อ + สถานะ
// //                     Row(
// //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                       children: [
// //                         Flexible(
// //                           child: Text(
// //                             item['name_rs'] ?? '-',
// //                             style: const TextStyle(
// //                               fontSize: 18,
// //                               fontWeight: FontWeight.bold,
// //                               color: Colors.black87,
// //                             ),
// //                             overflow: TextOverflow.ellipsis, // ✅ ตัดด้วย ...
// //                             maxLines: 1, // ✅ แสดงแค่บรรทัดเดียว
// //                           ),
// //                         ),
// //                         Row(
// //                           children: [
// //                             Icon(Icons.circle,
// //                                 color: getStatusColor(item['progress_status']),
// //                                 size: 10),
// //                             const SizedBox(width: 4),
// //                             Text(
// //                               getStatusText(item['progress_status']),
// //                               style: TextStyle(
// //                                 fontSize: 13,
// //                                 fontWeight: FontWeight.w500,
// //                                 color: getStatusColor(item['progress_status']),
// //                               ),
// //                             ),
// //                           ],
// //                         )
// //                       ],
// //                     ),

// //                     const SizedBox(height: 8),

// //                     // รุ่นรถ
// //                     Row(
// //                       children: [
// //                         const Icon(Icons.directions_car,
// //                             size: 16, color: Colors.blueGrey),
// //                         const SizedBox(width: 4),
// //                         Text(
// //                           'รถ: ${item['name_vehicle'] ?? '-'}',
// //                           style: const TextStyle(
// //                             fontSize: 14,
// //                             fontWeight: FontWeight.w500,
// //                           ),
// //                         ),
// //                       ],
// //                     ),

// //                     // ฟาร์ม
// //                     const SizedBox(height: 4),
// //                     Row(
// //                       children: [
// //                         const Icon(Icons.location_on,
// //                             size: 16, color: Colors.orange),
// //                         const SizedBox(width: 4),
// //                         Expanded(
// //                           child: Text(
// //                             item['name_farm'] ?? '-',
// //                             style: const TextStyle(fontSize: 14),
// //                           ),
// //                         ),
// //                       ],
// //                     ),

// //                     const SizedBox(height: 8),
// //                     Row(
// //                       crossAxisAlignment: CrossAxisAlignment.start,
// //                       children: [
// //                         const Icon(Icons.access_time, size: 16),
// //                         const SizedBox(width: 4),
// //                         Expanded(
// //                           child: Text(
// //                             _formatDateRange(item['date_reserve'],
// //                                 item['date_start'], item['date_end']),
// //                             style: const TextStyle(
// //                               fontSize: 13,
// //                               fontWeight: FontWeight.bold,
// //                             ),
// //                           ),
// //                         ),
// //                       ],
// //                     ),

// //                     const SizedBox(height: 8),
// //                     Row(
// //                       mainAxisAlignment: MainAxisAlignment.end,
// //                       children: [
// //                         ElevatedButton(
// //                           style: ElevatedButton.styleFrom(
// //                             backgroundColor:
// //                                 const Color(0xFF4CAF50), // เขียวธรรมชาติ
// //                             foregroundColor: Colors.white,
// //                             elevation: 4, // ✅ เพิ่มเงา
// //                             shadowColor: Color.fromARGB(
// //                                 208, 163, 160, 160), // ✅ เงานุ่มๆ
// //                             shape: RoundedRectangleBorder(
// //                               borderRadius:
// //                                   BorderRadius.circular(16), // ✅ มุมนุ่มขึ้น
// //                             ),
// //                             padding: const EdgeInsets.symmetric(
// //                                 horizontal: 24, vertical: 10), // ✅ ขนาดกำลังดี
// //                             textStyle: const TextStyle(
// //                               fontSize: 14,
// //                               fontWeight: FontWeight.w600,
// //                             ),
// //                           ),
// //                           onPressed: () {
// //                             Navigator.push(
// //                               context,
// //                               MaterialPageRoute(
// //                                 builder: (context) =>
// //                                     DetailWorkPage(rsid: item['rsid']),
// //                               ),
// //                             );
// //                           },
// //                           child: const Text('รายละเอียด'),
// //                         ),
// //                       ],
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             );
// //           },
// //         );
// //       },
// //     );
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return DefaultTabController(
// //       length: 2,
// //       child: Scaffold(
// //         // backgroundColor: const Color.fromARGB(255, 255, 158, 60),
// //         appBar: AppBar(
// //           // backgroundColor: const Color(0xFF006000),
// //           backgroundColor: const Color.fromARGB(255, 18, 143, 9),
// //           centerTitle: true,
// //           automaticallyImplyLeading: false,
// //           title: const Text(
// //             'คิวงานทั้งหมด',
// //             style: TextStyle(
// //               fontSize: 22,
// //               fontWeight: FontWeight.bold,
// //               color: Colors.white,
// //               shadows: [
// //                 Shadow(
// //                   color: Color.fromARGB(115, 253, 237, 237),
// //                   blurRadius: 3,
// //                   offset: Offset(1.5, 1.5),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),
// //         body: Column(
// //           children: [
// //             // ✅ แถบแท็บนูนด้วย Card
// //             Padding(
// //               padding: const EdgeInsets.all(16),
// //               child: Card(
// //                 shape: RoundedRectangleBorder(
// //                   borderRadius: BorderRadius.circular(16),
// //                 ),
// //                 elevation: 6,
// //                 child: Padding(
// //                   padding:
// //                       const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
// //                   child: TabBar(
// //                     // indicator: BoxDecoration(
// //                     //   borderRadius: BorderRadius.circular(8),
// //                     //   color: Colors.green[900],
// //                     //   boxShadow: [
// //                     //     BoxShadow(
// //                     //       color: Colors.black26,
// //                     //       blurRadius: 4,
// //                     //       offset: Offset(0, 2),
// //                     //     ),
// //                     //   ],
// //                     // ),
// //                     indicator: BoxDecoration(
// //                       borderRadius: BorderRadius.circular(8),
// //                       gradient: LinearGradient(
// //                         colors: [
// //                           Color.fromARGB(255, 190, 255, 189)!,
// //                           Color.fromARGB(255, 37, 189, 35)!,
// //                           Colors.green[800]!,

// //                           // Color.fromARGB(255, 255, 244, 189)!,
// //                           // Color.fromARGB(255, 254, 187, 42)!,
// //                           // Color.fromARGB(255, 218, 140, 22)!,
// //                         ],
// //                         begin: Alignment.topLeft,
// //                         end: Alignment.bottomRight,
// //                       ),
// //                       boxShadow: [
// //                         BoxShadow(
// //                           color: Colors.black26,
// //                           blurRadius: 4,
// //                           offset: Offset(0, 2),
// //                         ),
// //                       ],
// //                     ),
// //                     labelColor: Colors.white,
// //                     unselectedLabelColor: Colors.black87,
// //                     indicatorSize: TabBarIndicatorSize.tab,
// //                     labelStyle: const TextStyle(
// //                       fontSize: 14,
// //                       fontWeight: FontWeight.bold,
// //                     ),
// //                     tabs: const [
// //                       Tab(
// //                         child: SizedBox(
// //                           width: 120,
// //                           child: Center(child: Text('ตารางงาน')),
// //                         ),
// //                       ),
// //                       Tab(
// //                         child: SizedBox(
// //                           width: 120,
// //                           child: Center(child: Text('ประวัติการรับงาน')),
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //               ),
// //             ),

// //             Expanded(
// //               child: TabBarView(
// //                 children: [
// //                   // ตารางงาน - จัดกลางจอ
// //                   Center(
// //                     child: _buildPlanTab(),
// //                   ),

// //                   // ประวัติการรับงาน - จัดกลางจอ
// //                   Center(
// //                     child: _buildScheduleTab(includeHistory: true),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }

// // import 'dart:convert';
// // import 'package:agri_booking2/pages/contactor/DetailWork.dart';
// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:intl/intl.dart';
// // import 'package:intl/date_symbol_data_local.dart';
// // import 'package:table_calendar/table_calendar.dart'; // ✅ เพิ่ม import

// // class PlanAndHistory extends StatefulWidget {
// //   final int mid;
// //   final int month;
// //   final int year;

// //   const PlanAndHistory({
// //     super.key,
// //     required this.mid,
// //     required this.month,
// //     required this.year,
// //   });

// //   @override
// //   State<PlanAndHistory> createState() => _PlanAndHistoryState();
// // }

// // class _PlanAndHistoryState extends State<PlanAndHistory> {
// //   Future<List<dynamic>>? _scheduleFuture;
// //   late int _displayMonth;
// //   late int _displayYear;
// //   bool _isLocaleInitialized = false;

// //   // 💡 ตัวแปรใหม่สำหรับปฏิทินและรายการจอง
// //   DateTime _selectedDay = DateTime.now();
// //   Map<DateTime, List<dynamic>> eventsByDay = {};

// //   @override
// //   void initState() {
// //     super.initState();
// //     _displayMonth = widget.month;
// //     _displayYear = widget.year;
// //     fetchCon(this.widget.mid);

// //     initializeDateFormatting('th', null).then((_) {
// //       setState(() {
// //         _isLocaleInitialized = true;
// //         // ✅ โหลดข้อมูลและจัดกลุ่มทันทีที่เปิดหน้า
// //         _scheduleFuture =
// //             fetchSchedule(widget.mid, _displayMonth, _displayYear).then((list) {
// //           _groupEventsByDay(list); // จัดกลุ่มข้อมูลทันที
// //           return list;
// //         });
// //       });
// //     });
// //   }

// //   Future<Map<String, dynamic>> fetchCon(int mid) async {
// //     final url_con = Uri.parse(
// //         'http://projectnodejs.thammadalok.com/AGribooking/members/$mid');
// //     final response = await http.get(url_con);
// //     if (response.statusCode == 200) {
// //       return jsonDecode(response.body);
// //     } else {
// //       throw Exception('ไม่พบข้อมูลสมาชิก');
// //     }
// //   }

// //   Future<List<dynamic>> fetchSchedule(int mid, int month, int year) async {
// //     final url = Uri.parse(
// //       'http://projectnodejs.thammadalok.com/AGribooking/get_ConReserving/$mid?month=$month&year=$year',
// //     );
// //     try {
// //       final response = await http.get(url);
// //       if (response.statusCode == 200) {
// //         if (response.body.isNotEmpty) {
// //           return jsonDecode(response.body);
// //         } else {
// //           return [];
// //         }
// //       } else {
// //         throw Exception('Failed to load schedule: ${response.statusCode}');
// //       }
// //     } catch (e) {
// //       throw Exception('Connection error: $e');
// //     }
// //   }

// //   // 💡 สร้างฟังก์ชันสำหรับจัดกลุ่มข้อมูล
// //   void _groupEventsByDay(List<dynamic> scheduleList) {
// //     eventsByDay.clear();
// //     for (var item in scheduleList) {
// //       final dateStart = DateTime.parse(item['date_start']).toLocal();
// //       final dateKey = DateTime(dateStart.year, dateStart.month, dateStart.day);
// //       if (eventsByDay[dateKey] == null) {
// //         eventsByDay[dateKey] = [item];
// //       } else {
// //         eventsByDay[dateKey]!.add(item);
// //       }
// //     }
// //     setState(() {}); // อัปเดต UI หลังจากจัดกลุ่มเสร็จ
// //   }

// //   String _formatDateRange(
// //       String? date_reserve, String? startDate, String? endDate) {
// //     if (date_reserve == null || startDate == null || endDate == null)
// //       return 'ไม่ระบุวันที่';
// //     try {
// //       final reserveThai =
// //           DateTime.parse(date_reserve).add(const Duration(hours: 7));
// //       final startThai = DateTime.parse(startDate).add(const Duration(hours: 7));
// //       final endThai = DateTime.parse(endDate).add(const Duration(hours: 7));

// //       final formatter = DateFormat('dd/MM/yyyy \t\tเวลา HH:mm น.');
// //       return 'จองเข้ามา:${formatter.format(reserveThai)}\n เริ่มงาน: ${formatter.format(startThai)}\nสิ้นสุด: ${formatter.format(endThai)}';
// //     } catch (e) {
// //       return 'รูปแบบวันที่ไม่ถูกต้อง';
// //     }
// //   }

// //   // 💡 widget ที่แสดงปฏิทินและรายการจอง
// //   Widget _buildPlanTab() {
// //     return Column(
// //       children: [
// //         TableCalendar(
// //           locale: 'th_TH',
// //           focusedDay: _selectedDay,
// //           firstDay: DateTime(_displayYear - 1),
// //           lastDay: DateTime(_displayYear + 1),
// //           startingDayOfWeek: StartingDayOfWeek.monday,
// //           selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
// //           // ✅ marker แสดงจุดของทุกสถานะที่รับงาน
// //           eventLoader: (day) {
// //             final dateKey = DateTime(day.year, day.month, day.day);
// //             return eventsByDay[dateKey] ?? [];
// //           },
// //           onDaySelected: (selectedDay, focusedDay) {
// //             setState(() {
// //               _selectedDay = DateTime(
// //                   selectedDay.year, selectedDay.month, selectedDay.day);
// //             });
// //           },
// //           calendarStyle: const CalendarStyle(
// //             markerDecoration: BoxDecoration(
// //               color: Colors.redAccent,
// //               shape: BoxShape.circle,
// //             ),
// //           ),
// //         ),
// //         const SizedBox(height: 16),
// //         // ✅ แสดงรายการจองของวันปัจจุบัน (หรือวันที่เลือก)
// //         Expanded(
// //           child: SingleChildScrollView(
// //             child: _buildScheduleList(includeHistory: false),
// //           ),
// //         ),
// //       ],
// //     );
// //   }

// //   // 💡 widget ที่แสดงรายการจอง
// //   Widget _buildScheduleList({required bool includeHistory}) {
// //     // กรองรายการจองตามวันที่เลือก
// //     final dailySchedule = eventsByDay[DateTime(
// //           _selectedDay.year,
// //           _selectedDay.month,
// //           _selectedDay.day,
// //         )] ??
// //         [];

// //     if (dailySchedule.isEmpty) {
// //       return const Center(child: Text('ไม่มีคิวงานในวันนี้'));
// //     }

// //     final filteredSchedule = dailySchedule
// //         .where((item) => includeHistory
// //             ? item['progress_status'] == 4
// //             : item['progress_status'] != 4)
// //         .toList();

// //     if (filteredSchedule.isEmpty) {
// //       return const Center(child: Text('ไม่พบงานในหมวดนี้สำหรับวันนี้'));
// //     }

// //     return ListView.builder(
// //       padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
// //       shrinkWrap: true,
// //       physics: const NeverScrollableScrollPhysics(),
// //       itemCount: filteredSchedule.length,
// //       itemBuilder: (context, index) {
// //         final item = filteredSchedule[index];
// //         // แปลง progress_status เป็นข้อความ
// //         String getStatusText(dynamic status) {
// //           switch (status.toString()) {
// //             case '0':
// //               return 'ผู้รับจ้างยกเลิกงาน';
// //             case '1':
// //               return 'ผู้รับจ้างยืนยันการจอง';
// //             case '2':
// //               return 'กำลังเดินทาง';
// //             case '3':
// //               return 'กำลังทำงาน';
// //             case '4':
// //               return 'เสร็จสิ้น';
// //             default:
// //               return 'รอผู้รับจ้างยืนยันการจอง';
// //           }
// //         }

// //         // กำหนดสีตามสถานะ
// //         Color getStatusColor(dynamic status) {
// //           switch (status.toString()) {
// //             case '0':
// //               return Colors.red;
// //             case '1':
// //               return Colors.blueGrey;
// //             case '2':
// //               return Colors.pinkAccent;
// //             case '3':
// //               return Colors.amber;
// //             case '4':
// //               return Colors.green;
// //             default:
// //               return Colors.black45;
// //           }
// //         }

// //         return Container(
// //           decoration: BoxDecoration(
// //             color: const Color(0xFFFFF3E0),
// //             borderRadius: BorderRadius.circular(12),
// //             border: Border.all(
// //               color: const Color(0xFFFFCC80),
// //               width: 1.5,
// //             ),
// //             boxShadow: [
// //               BoxShadow(
// //                 color: Colors.orange.withOpacity(0.2),
// //                 spreadRadius: 2,
// //                 blurRadius: 8,
// //                 offset: const Offset(0, 4),
// //               ),
// //             ],
// //           ),
// //           margin: const EdgeInsets.symmetric(vertical: 8),
// //           child: Padding(
// //             padding: const EdgeInsets.all(10.0),
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Row(
// //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                   children: [
// //                     Flexible(
// //                       child: Text(
// //                         item['name_rs'] ?? '-',
// //                         style: const TextStyle(
// //                           fontSize: 18,
// //                           fontWeight: FontWeight.bold,
// //                           color: Colors.black87,
// //                         ),
// //                         overflow: TextOverflow.ellipsis,
// //                         maxLines: 1,
// //                       ),
// //                     ),
// //                     Row(
// //                       children: [
// //                         Icon(Icons.circle,
// //                             color: getStatusColor(item['progress_status']),
// //                             size: 10),
// //                         const SizedBox(width: 4),
// //                         Text(
// //                           getStatusText(item['progress_status']),
// //                           style: TextStyle(
// //                             fontSize: 13,
// //                             fontWeight: FontWeight.w500,
// //                             color: getStatusColor(item['progress_status']),
// //                           ),
// //                         ),
// //                       ],
// //                     )
// //                   ],
// //                 ),
// //                 const SizedBox(height: 8),
// //                 Row(
// //                   children: [
// //                     const Icon(Icons.directions_car,
// //                         size: 16, color: Colors.blueGrey),
// //                     const SizedBox(width: 4),
// //                     Text(
// //                       'รถ: ${item['name_vehicle'] ?? '-'}',
// //                       style: const TextStyle(
// //                         fontSize: 14,
// //                         fontWeight: FontWeight.w500,
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //                 const SizedBox(height: 4),
// //                 Row(
// //                   children: [
// //                     const Icon(Icons.location_on,
// //                         size: 16, color: Colors.orange),
// //                     const SizedBox(width: 4),
// //                     Expanded(
// //                       child: Text(
// //                         item['name_farm'] ?? '-',
// //                         style: const TextStyle(fontSize: 14),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //                 const SizedBox(height: 8),
// //                 Row(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     const Icon(Icons.access_time, size: 16),
// //                     const SizedBox(width: 4),
// //                     Expanded(
// //                       child: Text(
// //                         _formatDateRange(item['date_reserve'],
// //                             item['date_start'], item['date_end']),
// //                         style: const TextStyle(
// //                           fontSize: 13,
// //                           fontWeight: FontWeight.bold,
// //                         ),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //                 const SizedBox(height: 8),
// //                 Row(
// //                   mainAxisAlignment: MainAxisAlignment.end,
// //                   children: [
// //                     ElevatedButton(
// //                       style: ElevatedButton.styleFrom(
// //                         backgroundColor: const Color(0xFF4CAF50),
// //                         foregroundColor: Colors.white,
// //                         elevation: 4,
// //                         shadowColor: Color.fromARGB(208, 163, 160, 160),
// //                         shape: RoundedRectangleBorder(
// //                           borderRadius: BorderRadius.circular(16),
// //                         ),
// //                         padding: const EdgeInsets.symmetric(
// //                             horizontal: 24, vertical: 10),
// //                         textStyle: const TextStyle(
// //                           fontSize: 14,
// //                           fontWeight: FontWeight.w600,
// //                         ),
// //                       ),
// //                       onPressed: () {
// //                         Navigator.push(
// //                           context,
// //                           MaterialPageRoute(
// //                             builder: (context) =>
// //                                 DetailWorkPage(rsid: item['rsid']),
// //                           ),
// //                         );
// //                       },
// //                       child: const Text('รายละเอียด'),
// //                     ),
// //                   ],
// //                 ),
// //               ],
// //             ),
// //           ),
// //         );
// //       },
// //     );
// //   }

// //   // 💡 widget ที่แสดงประวัติการรับงาน (ไม่มีการเปลี่ยนแปลง)
// //   Widget _buildHistoryTab() {
// //     return FutureBuilder<List<dynamic>>(
// //       future: _scheduleFuture,
// //       builder: (context, snapshot) {
// //         if (snapshot.connectionState == ConnectionState.waiting) {
// //           return const Center(child: CircularProgressIndicator());
// //         } else if (snapshot.hasError) {
// //           return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
// //         } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
// //           return const Center(child: Text('ไม่มีคิวงาน'));
// //         }

// //         final scheduleList = snapshot.data!
// //             .where((item) => item['progress_status'] == 4)
// //             .toList();

// //         if (scheduleList.isEmpty) {
// //           return const Center(child: Text('ไม่พบงานในหมวดนี้'));
// //         }

// //         String getStatusText(dynamic status) {
// //           return 'เสร็จสิ้น';
// //         }

// //         Color getStatusColor(dynamic status) {
// //           return Colors.green;
// //         }

// //         return ListView.builder(
// //           padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
// //           itemCount: scheduleList.length,
// //           itemBuilder: (context, index) {
// //             final item = scheduleList[index];
// //             return Container(
// //               decoration: BoxDecoration(
// //                 color: const Color(0xFFFFF3E0),
// //                 borderRadius: BorderRadius.circular(12),
// //                 border: Border.all(
// //                   color: const Color(0xFFFFCC80),
// //                   width: 1.5,
// //                 ),
// //                 boxShadow: [
// //                   BoxShadow(
// //                     color: Colors.orange.withOpacity(0.2),
// //                     spreadRadius: 2,
// //                     blurRadius: 8,
// //                     offset: const Offset(0, 4),
// //                   ),
// //                 ],
// //               ),
// //               margin: const EdgeInsets.symmetric(vertical: 8),
// //               child: Padding(
// //                 padding: const EdgeInsets.all(16.0),
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     Row(
// //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                       children: [
// //                         Flexible(
// //                           child: Text(
// //                             item['name_rs'] ?? '-',
// //                             style: const TextStyle(
// //                               fontSize: 18,
// //                               fontWeight: FontWeight.bold,
// //                               color: Colors.black87,
// //                             ),
// //                             overflow: TextOverflow.ellipsis,
// //                             maxLines: 1,
// //                           ),
// //                         ),
// //                         Row(
// //                           children: [
// //                             Icon(Icons.circle,
// //                                 color: getStatusColor(item['progress_status']),
// //                                 size: 10),
// //                             const SizedBox(width: 4),
// //                             Text(
// //                               getStatusText(item['progress_status']),
// //                               style: TextStyle(
// //                                 fontSize: 13,
// //                                 fontWeight: FontWeight.w500,
// //                                 color: getStatusColor(item['progress_status']),
// //                               ),
// //                             ),
// //                           ],
// //                         )
// //                       ],
// //                     ),
// //                     const SizedBox(height: 8),
// //                     Row(
// //                       children: [
// //                         const Icon(Icons.directions_car,
// //                             size: 16, color: Colors.blueGrey),
// //                         const SizedBox(width: 4),
// //                         Text(
// //                           'รถ: ${item['name_vehicle'] ?? '-'}',
// //                           style: const TextStyle(
// //                             fontSize: 14,
// //                             fontWeight: FontWeight.w500,
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                     const SizedBox(height: 4),
// //                     Row(
// //                       children: [
// //                         const Icon(Icons.location_on,
// //                             size: 16, color: Colors.orange),
// //                         const SizedBox(width: 4),
// //                         Expanded(
// //                           child: Text(
// //                             item['name_farm'] ?? '-',
// //                             style: const TextStyle(fontSize: 14),
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                     const SizedBox(height: 8),
// //                     Row(
// //                       crossAxisAlignment: CrossAxisAlignment.start,
// //                       children: [
// //                         const Icon(Icons.access_time, size: 16),
// //                         const SizedBox(width: 4),
// //                         Expanded(
// //                           child: Text(
// //                             _formatDateRange(item['date_reserve'],
// //                                 item['date_start'], item['date_end']),
// //                             style: const TextStyle(
// //                               fontSize: 13,
// //                               fontWeight: FontWeight.bold,
// //                             ),
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                     const SizedBox(height: 8),
// //                     Row(
// //                       mainAxisAlignment: MainAxisAlignment.end,
// //                       children: [
// //                         ElevatedButton(
// //                           style: ElevatedButton.styleFrom(
// //                             backgroundColor: const Color(0xFF4CAF50),
// //                             foregroundColor: Colors.white,
// //                             elevation: 4,
// //                             shadowColor:
// //                                 const Color.fromARGB(208, 163, 160, 160),
// //                             shape: RoundedRectangleBorder(
// //                               borderRadius: BorderRadius.circular(16),
// //                             ),
// //                             padding: const EdgeInsets.symmetric(
// //                                 horizontal: 24, vertical: 10),
// //                             textStyle: const TextStyle(
// //                               fontSize: 14,
// //                               fontWeight: FontWeight.w600,
// //                             ),
// //                           ),
// //                           onPressed: () {
// //                             Navigator.push(
// //                               context,
// //                               MaterialPageRoute(
// //                                 builder: (context) =>
// //                                     DetailWorkPage(rsid: item['rsid']),
// //                               ),
// //                             );
// //                           },
// //                           child: const Text('รายละเอียด'),
// //                         ),
// //                       ],
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             );
// //           },
// //         );
// //       },
// //     );
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     if (!_isLocaleInitialized) {
// //       return const Scaffold(
// //         body: Center(child: CircularProgressIndicator()),
// //       );
// //     }
// //     return DefaultTabController(
// //       length: 2,
// //       child: Scaffold(
// //         appBar: AppBar(
// //           backgroundColor: const Color.fromARGB(255, 18, 143, 9),
// //           centerTitle: true,
// //           automaticallyImplyLeading: false,
// //           title: const Text(
// //             'คิวงานทั้งหมด',
// //             style: TextStyle(
// //               fontSize: 22,
// //               fontWeight: FontWeight.bold,
// //               color: Colors.white,
// //               shadows: [
// //                 Shadow(
// //                   color: Color.fromARGB(115, 253, 237, 237),
// //                   blurRadius: 3,
// //                   offset: Offset(1.5, 1.5),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),
// //         body: Column(
// //           children: [
// //             Padding(
// //               padding: const EdgeInsets.all(16),
// //               child: Card(
// //                 shape: RoundedRectangleBorder(
// //                   borderRadius: BorderRadius.circular(16),
// //                 ),
// //                 elevation: 6,
// //                 child: Padding(
// //                   padding:
// //                       const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
// //                   child: TabBar(
// //                     indicator: BoxDecoration(
// //                       borderRadius: BorderRadius.circular(8),
// //                       gradient: LinearGradient(
// //                         colors: [
// //                           const Color.fromARGB(255, 190, 255, 189),
// //                           const Color.fromARGB(255, 37, 189, 35),
// //                           Colors.green[800]!,
// //                         ],
// //                         begin: Alignment.topLeft,
// //                         end: Alignment.bottomRight,
// //                       ),
// //                       boxShadow: const [
// //                         BoxShadow(
// //                           color: Colors.black26,
// //                           blurRadius: 4,
// //                           offset: Offset(0, 2),
// //                         ),
// //                       ],
// //                     ),
// //                     labelColor: Colors.white,
// //                     unselectedLabelColor: Colors.black87,
// //                     indicatorSize: TabBarIndicatorSize.tab,
// //                     labelStyle: const TextStyle(
// //                       fontSize: 14,
// //                       fontWeight: FontWeight.bold,
// //                     ),
// //                     tabs: const [
// //                       Tab(
// //                         child: SizedBox(
// //                           width: 120,
// //                           child: Center(child: Text('ตารางงาน')),
// //                         ),
// //                       ),
// //                       Tab(
// //                         child: SizedBox(
// //                           width: 120,
// //                           child: Center(child: Text('ประวัติการรับงาน')),
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //               ),
// //             ),
// //             Expanded(
// //               child: TabBarView(
// //                 children: [
// //                   _buildPlanTab(),
// //                   _buildHistoryTab(),
// //                 ],
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }

// import 'dart:convert';
// import 'package:agri_booking2/pages/contactor/DetailWork.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';
// import 'package:intl/date_symbol_data_local.dart';
// import 'package:table_calendar/table_calendar.dart';

// class PlanAndHistory extends StatefulWidget {
//   final int mid;
//   final int month;
//   final int year;

//   const PlanAndHistory({
//     super.key,
//     required this.mid,
//     required this.month,
//     required this.year,
//   });

//   @override
//   State<PlanAndHistory> createState() => _PlanAndHistoryState();
// }

// class _PlanAndHistoryState extends State<PlanAndHistory> {
//   Future<List<dynamic>>? _scheduleFuture;
//   late int _displayMonth;
//   late int _displayYear;
//   bool _isLocaleInitialized = false;

//   // ตัวแปรสำหรับปฏิทินและรายการจอง
//   DateTime _selectedDay = DateTime.now();
//   late DateTime _focusedDay;
//   Map<DateTime, List<dynamic>> eventsByDay = {};

//   // ตัวแปรสำหรับการควบคุมการขยาย-ย่อของปฏิทิน
//   CalendarFormat _calendarFormat = CalendarFormat.month;

//   @override
//   void initState() {
//     super.initState();
//     _displayMonth = widget.month;
//     _displayYear = widget.year;
//     _focusedDay = DateTime.now();

//     initializeDateFormatting('th', null).then((_) {
//       setState(() {
//         _isLocaleInitialized = true;
//         _scheduleFuture =
//             fetchSchedule(widget.mid, _displayMonth, _displayYear).then((list) {
//           _groupEventsByDay(list);
//           return list;
//         });
//       });
//     });
//   }

//   Future<Map<String, dynamic>> fetchCon(int mid) async {
//     final url_con = Uri.parse(
//         'http://projectnodejs.thammadalok.com/AGribooking/members/$mid');
//     final response = await http.get(url_con);
//     if (response.statusCode == 200) {
//       return jsonDecode(response.body);
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

//   void _groupEventsByDay(List<dynamic> scheduleList) {
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
//     setState(() {});
//   }

//   String _formatDateRange(
//       String? date_reserve, String? startDate, String? endDate) {
//     if (date_reserve == null || startDate == null || endDate == null)
//       return 'ไม่ระบุวันที่';
//     try {
//       final reserveThai =
//           DateTime.parse(date_reserve).add(const Duration(hours: 7));
//       final startThai = DateTime.parse(startDate).add(const Duration(hours: 7));
//       final endThai = DateTime.parse(endDate).add(const Duration(hours: 7));

//       final formatter = DateFormat('dd/MM/yyyy \t\tเวลา HH:mm น.');
//       return 'จองเข้ามา:${formatter.format(reserveThai)}\n เริ่มงาน: ${formatter.format(startThai)}\nสิ้นสุด: ${formatter.format(endThai)}';
//     } catch (e) {
//       return 'รูปแบบวันที่ไม่ถูกต้อง';
//     }
//   }

//   // 💡 สร้าง List<Widget> สำหรับรายการจองของวันปัจจุบัน
//   List<Widget> _buildDailyScheduleList() {
//     final dailySchedule = eventsByDay[DateTime(
//           _selectedDay.year,
//           _selectedDay.month,
//           _selectedDay.day,
//         )] ??
//         [];

//     if (dailySchedule.isEmpty) {
//       return [const Center(child: Text('ไม่มีคิวงานในวันนี้'))];
//     }

//     final filteredSchedule =
//         dailySchedule.where((item) => item['progress_status'] != 4).toList();

//     if (filteredSchedule.isEmpty) {
//       return [const Center(child: Text('ไม่พบงานในหมวดนี้สำหรับวันนี้'))];
//     }

//     // สร้างรายการ Widget สำหรับ ListView.builder
//     return List.generate(filteredSchedule.length, (index) {
//       final item = filteredSchedule[index];
//       String getStatusText(dynamic status) {
//         switch (status.toString()) {
//           case '0':
//             return 'ผู้รับจ้างยกเลิกงาน';
//           case '1':
//             return 'ผู้รับจ้างยืนยันการจอง';
//           case '2':
//             return 'กำลังเดินทาง';
//           case '3':
//             return 'กำลังทำงาน';
//           case '4':
//             return 'เสร็จสิ้น';
//           default:
//             return 'รอผู้รับจ้างยืนยันการจอง';
//         }
//       }

//       Color getStatusColor(dynamic status) {
//         switch (status.toString()) {
//           case '0':
//             return Colors.red;
//           case '1':
//             return Colors.blueGrey;
//           case '2':
//             return Colors.pinkAccent;
//           case '3':
//             return Colors.amber;
//           case '4':
//             return Colors.green;
//           default:
//             return Colors.black45;
//         }
//       }

//       return Container(
//         decoration: BoxDecoration(
//           color: const Color(0xFFFFF3E0),
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(
//             color: const Color(0xFFFFCC80),
//             width: 1.5,
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.orange.withOpacity(0.2),
//               spreadRadius: 2,
//               blurRadius: 8,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
//         child: Padding(
//           padding: const EdgeInsets.all(10.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Flexible(
//                     child: Text(
//                       item['name_rs'] ?? '-',
//                       style: const TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.black87,
//                       ),
//                       overflow: TextOverflow.ellipsis,
//                       maxLines: 1,
//                     ),
//                   ),
//                   Row(
//                     children: [
//                       Icon(Icons.circle,
//                           color: getStatusColor(item['progress_status']),
//                           size: 10),
//                       const SizedBox(width: 4),
//                       Text(
//                         getStatusText(item['progress_status']),
//                         style: TextStyle(
//                           fontSize: 13,
//                           fontWeight: FontWeight.w500,
//                           color: getStatusColor(item['progress_status']),
//                         ),
//                       ),
//                     ],
//                   )
//                 ],
//               ),
//               const SizedBox(height: 8),
//               Row(
//                 children: [
//                   const Icon(Icons.directions_car,
//                       size: 16, color: Colors.blueGrey),
//                   const SizedBox(width: 4),
//                   Text(
//                     'รถ: ${item['name_vehicle'] ?? '-'}',
//                     style: const TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 4),
//               Row(
//                 children: [
//                   const Icon(Icons.location_on, size: 16, color: Colors.orange),
//                   const SizedBox(width: 4),
//                   Expanded(
//                     child: Text(
//                       item['name_farm'] ?? '-',
//                       style: const TextStyle(fontSize: 14),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Icon(Icons.access_time, size: 16),
//                   const SizedBox(width: 4),
//                   Expanded(
//                     child: Text(
//                       _formatDateRange(item['date_reserve'], item['date_start'],
//                           item['date_end']),
//                       style: const TextStyle(
//                         fontSize: 13,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF4CAF50),
//                       foregroundColor: Colors.white,
//                       elevation: 4,
//                       shadowColor: const Color.fromARGB(208, 163, 160, 160),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 24, vertical: 10),
//                       textStyle: const TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) =>
//                               DetailWorkPage(rsid: item['rsid']),
//                         ),
//                       );
//                     },
//                     child: const Text('รายละเอียด'),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       );
//     });
//   }

//   // 💡 สร้าง widget สำหรับหน้า "ตารางงาน" ที่สามารถเลื่อนได้
//   Widget _buildPlanTab() {
//     return CustomScrollView(
//       slivers: [
//         SliverToBoxAdapter(
//           child: TableCalendar(
//             locale: 'th_TH',
//             focusedDay: _focusedDay,
//             firstDay: DateTime.utc(2020, 1, 1),
//             lastDay: DateTime.utc(2030, 12, 31),
//             startingDayOfWeek: StartingDayOfWeek.monday,
//             selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
//             calendarFormat: _calendarFormat,
//             eventLoader: (day) {
//               final dateKey = DateTime(day.year, day.month, day.day);
//               return eventsByDay[dateKey] ?? [];
//             },
//             onDaySelected: (selectedDay, focusedDay) {
//               setState(() {
//                 if (!isSameDay(_selectedDay, selectedDay)) {
//                   _selectedDay = selectedDay;
//                   _focusedDay = focusedDay;
//                 }
//               });
//             },
//             onFormatChanged: (format) {
//               if (_calendarFormat != format) {
//                 setState(() {
//                   _calendarFormat = format;
//                 });
//               }
//             },
//             onPageChanged: (focusedDay) {
//               _focusedDay = focusedDay;
//             },
//             calendarStyle: const CalendarStyle(
//               markerDecoration: BoxDecoration(
//                 color: Colors.redAccent,
//                 shape: BoxShape.circle,
//               ),
//             ),
//             headerStyle: const HeaderStyle(
//               formatButtonVisible: false,
//               titleCentered: true,
//             ),
//           ),
//         ),
//         const SliverToBoxAdapter(
//           child: SizedBox(height: 16),
//         ),
//         SliverList(
//           delegate: SliverChildListDelegate(
//             _buildDailyScheduleList(),
//           ),
//         ),
//       ],
//     );
//   }

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

//         String getStatusText(dynamic status) {
//           return 'เสร็จสิ้น';
//         }

//         Color getStatusColor(dynamic status) {
//           return Colors.green;
//         }

//         return ListView.builder(
//           padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
//           itemCount: scheduleList.length,
//           itemBuilder: (context, index) {
//             final item = scheduleList[index];
//             return Container(
//               decoration: BoxDecoration(
//                 color: const Color(0xFFFFF3E0),
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(
//                   color: const Color(0xFFFFCC80),
//                   width: 1.5,
//                 ),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.orange.withOpacity(0.2),
//                     spreadRadius: 2,
//                     blurRadius: 8,
//                     offset: const Offset(0, 4),
//                   ),
//                 ],
//               ),
//               margin: const EdgeInsets.symmetric(vertical: 8),
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Flexible(
//                           child: Text(
//                             item['name_rs'] ?? '-',
//                             style: const TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.black87,
//                             ),
//                             overflow: TextOverflow.ellipsis,
//                             maxLines: 1,
//                           ),
//                         ),
//                         Row(
//                           children: [
//                             Icon(Icons.circle,
//                                 color: getStatusColor(item['progress_status']),
//                                 size: 10),
//                             const SizedBox(width: 4),
//                             Text(
//                               getStatusText(item['progress_status']),
//                               style: TextStyle(
//                                 fontSize: 13,
//                                 fontWeight: FontWeight.w500,
//                                 color: getStatusColor(item['progress_status']),
//                               ),
//                             ),
//                           ],
//                         )
//                       ],
//                     ),
//                     const SizedBox(height: 8),
//                     Row(
//                       children: [
//                         const Icon(Icons.directions_car,
//                             size: 16, color: Colors.blueGrey),
//                         const SizedBox(width: 4),
//                         Text(
//                           'รถ: ${item['name_vehicle'] ?? '-'}',
//                           style: const TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 4),
//                     Row(
//                       children: [
//                         const Icon(Icons.location_on,
//                             size: 16, color: Colors.orange),
//                         const SizedBox(width: 4),
//                         Expanded(
//                           child: Text(
//                             item['name_farm'] ?? '-',
//                             style: const TextStyle(fontSize: 14),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 8),
//                     Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Icon(Icons.access_time, size: 16),
//                         const SizedBox(width: 4),
//                         Expanded(
//                           child: Text(
//                             _formatDateRange(item['date_reserve'],
//                                 item['date_start'], item['date_end']),
//                             style: const TextStyle(
//                               fontSize: 13,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 8),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.end,
//                       children: [
//                         ElevatedButton(
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: const Color(0xFF4CAF50),
//                             foregroundColor: Colors.white,
//                             elevation: 4,
//                             shadowColor:
//                                 const Color.fromARGB(208, 163, 160, 160),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(16),
//                             ),
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 24, vertical: 10),
//                             textStyle: const TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                           onPressed: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) =>
//                                     DetailWorkPage(rsid: item['rsid']),
//                               ),
//                             );
//                           },
//                           child: const Text('รายละเอียด'),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           },
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
//       length: 2,
//       child: Scaffold(
//         appBar: AppBar(
//           backgroundColor: const Color.fromARGB(255, 18, 143, 9),
//           centerTitle: true,
//           automaticallyImplyLeading: false,
//           title: const Text(
//             'คิวงานทั้งหมด',
//             style: TextStyle(
//               fontSize: 22,
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
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
//         body: Column(
//           children: [
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: Card(
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 elevation: 6,
//                 child: Padding(
//                   padding:
//                       const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
//                   child: TabBar(
//                     indicator: BoxDecoration(
//                       borderRadius: BorderRadius.circular(8),
//                       gradient: LinearGradient(
//                         colors: [
//                           const Color.fromARGB(255, 190, 255, 189),
//                           const Color.fromARGB(255, 37, 189, 35),
//                           Colors.green[800]!,
//                         ],
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                       ),
//                       boxShadow: const [
//                         BoxShadow(
//                           color: Colors.black26,
//                           blurRadius: 4,
//                           offset: Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     labelColor: Colors.white,
//                     unselectedLabelColor: Colors.black87,
//                     indicatorSize: TabBarIndicatorSize.tab,
//                     labelStyle: const TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.bold,
//                     ),
//                     tabs: const [
//                       Tab(
//                         child: SizedBox(
//                           width: 120,
//                           child: Center(child: Text('ตารางงาน')),
//                         ),
//                       ),
//                       Tab(
//                         child: SizedBox(
//                           width: 120,
//                           child: Center(child: Text('ประวัติการรับงาน')),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//             Expanded(
//               child: TabBarView(
//                 children: [
//                   _buildPlanTab(),
//                   _buildHistoryTab(),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

