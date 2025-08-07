import 'dart:convert';
import 'package:agri_booking2/pages/contactor/DetailWork.dart';
import 'package:agri_booking2/pages/employer/reservingForNF.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';

class PlanPage extends StatefulWidget {
  final int mid;
  final int month;
  final int year;
  final int mid_employer;
  final int vid;
  final int? fid; // ✅ เพิ่มตรงนี้
  final dynamic farm; // ✅ เพิ่มตรงนี้
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

  // เพิ่มด้านบนใน Widget ของคุณ (นอก ListView)
  Map<String, bool> statusFilters = {
    '0': false,
    '1': false,
    '2': false,
    '3': false,
    '4': false,
    '5': false,
    'default': true, // กรณีสถานะอื่นหรือยังไม่ยืนยัน
  };

  @override
  void initState() {
    super.initState();
    _displayMonth = widget.month;
    _displayYear = widget.year;
    fetchCon(this.widget.mid);
    // ✅ เรียก initializeDateFormatting ก่อนโหลดข้อมูล
    initializeDateFormatting('th', null).then((_) {
      setState(() {
        _isLocaleInitialized = true;
        _scheduleFuture =
            fetchSchedule(widget.mid, _displayMonth, _displayYear);
      });
    });
  }

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
        'http://projectnodejs.thammadalok.com/AGribooking/get_ConReserving/$mid?month=$month&year=$year');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          print(response.body);
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

  Map<DateTime, List<dynamic>> eventsByDay = {};

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
  }

  //วันที่และเวลา
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

      _scheduleFuture = fetchSchedule(widget.mid, _displayMonth, _displayYear);
    });
  }

  // ปุ่มจองคิว
  final ButtonStyle bookingButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.blue,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    textStyle: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold, // ✅ ตัวหนา
    ),
  );

  DateTime? _selectedDay;

  Widget _buildPlanTab() {
    final String currentMonthName =
        DateFormat.MMMM('th').format(DateTime(_displayYear, _displayMonth));

    return Column(
      children: [
        Expanded(
          child: Column(
            children: [
              TableCalendar(
                locale: 'th_TH',
                focusedDay: DateTime(_displayYear, _displayMonth),
                firstDay: DateTime(_displayYear - 1),
                lastDay: DateTime(_displayYear + 1),
                startingDayOfWeek: StartingDayOfWeek.monday,

                // ✅ บอกว่า วันไหนถูกเลือก
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),

                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.orangeAccent.withOpacity(0.6),
                    shape: BoxShape.rectangle, // ไม่ต้องใช้ circle
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.rectangle,
                  ),
                  markerDecoration: BoxDecoration(), // ไม่จำเป็นอีกต่อไป
                  outsideDaysVisible: false,
                ),

                headerStyle: const HeaderStyle(
                  formatButtonVisible:
                      false, // ซ่อนปุ่มเลือก format เดือน/สัปดาห์
                  titleCentered: true,
                ),

                calendarBuilders: CalendarBuilders(
                  dowBuilder: (context, day) {
                    // ✅ ไม่ต้องเขียนอะไรเกี่ยวกับ week number
                    return null;
                  },
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
              const SizedBox(height: 8),
              if (_selectedDay != null)
                Text(
                  'วันที่เลือก: ${DateFormat('dd MMMM yyyy', 'th').format(_selectedDay!)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              const SizedBox(height: 16),
              Expanded(
                child: _buildScheduleTab(includeHistory: false),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleTab({required bool includeHistory}) {
    return FutureBuilder<List<dynamic>>(
      future: _scheduleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Text('ขออภัยค่ะ ขณะนี้ยังไม่มีการจองคิวรถในเดือนนี้'),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('ไม่มีคิวงาน'));
        }

        final scheduleList = snapshot.data!
            .where((item) => includeHistory
                ? item['progress_status'] == 4
                : item['progress_status'] != 4)
            .toList();

        groupEventsByDay(scheduleList); // เตรียมข้อมูลปฏิทิน

        if (scheduleList.isEmpty) {
          return const Center(child: Text('ไม่พบงานในหมวดนี้'));
        }

        // กรองรายการงานตามวันที่เลือก
        List<dynamic> filteredList;
        if (_selectedDay != null) {
          filteredList = scheduleList.where((item) {
            final dateStart = DateTime.parse(item['date_start']).toLocal();
            final itemDate =
                DateTime(dateStart.year, dateStart.month, dateStart.day);
            return itemDate == _selectedDay;
          }).toList();
        } else {
          filteredList = scheduleList; // ถ้าไม่เลือกวัน แสดงทั้งหมดในเดือน
        }

        if (filteredList.isEmpty) {
          return const Center(child: Text('ไม่มีคิวงานในวันที่เลือก'));
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
            case '4':
              return 'เสร็จสิ้น';
            case '5':
              return 'รอผู้รับจ้างยกเลิกงาน';
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
            case '5':
              return Color.fromARGB(255, 54, 28, 31);
            default:
              return Colors.black45;
          }
        }

        return Column(
          children: [
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: statusFilters.entries.map((entry) {
                String statusKey = entry.key;
                bool isSelected = entry.value;

                return FilterChip(
                  label: Text(getStatusText(statusKey)),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    setState(() {
                      statusFilters[statusKey] = selected;
                    });
                  },
                  selectedColor: getStatusColor(statusKey).withOpacity(0.2),
                  checkmarkColor: getStatusColor(statusKey),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            Expanded(
                child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
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
                                item['name_farm'] ?? '-',
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
            )),
          ],
        );

        // return ListView.builder(
        //   padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        //   itemCount: filteredList.length,
        //   itemBuilder: (context, index) {
        //     final item = filteredList[index];

        //     return Container(
        //       decoration: BoxDecoration(
        //         color: const Color(0xFFFFF3E0),
        //         borderRadius: BorderRadius.circular(12),
        //         border: Border.all(
        //           color: const Color(0xFFFFCC80),
        //           width: 1.5,
        //         ),
        //         boxShadow: [
        //           BoxShadow(
        //             color: Colors.orange.withOpacity(0.2),
        //             spreadRadius: 2,
        //             blurRadius: 8,
        //             offset: const Offset(0, 4),
        //           ),
        //         ],
        //       ),
        //       margin: const EdgeInsets.symmetric(vertical: 8),
        //       child: Padding(
        //         padding: const EdgeInsets.all(16.0),
        //         child: Column(
        //           crossAxisAlignment: CrossAxisAlignment.start,
        //           children: [
        //             Row(
        //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //               children: [
        //                 Flexible(
        //                   child: Text(
        //                     item['name_rs'] ?? '-',
        //                     style: const TextStyle(
        //                       fontSize: 18,
        //                       fontWeight: FontWeight.bold,
        //                       color: Colors.black87,
        //                     ),
        //                     overflow: TextOverflow.ellipsis,
        //                     maxLines: 1,
        //                   ),
        //                 ),
        //                 Row(
        //                   children: [
        //                     Icon(Icons.circle,
        //                         color: getStatusColor(item['progress_status']),
        //                         size: 10),
        //                     const SizedBox(width: 4),
        //                     Text(
        //                       getStatusText(item['progress_status']),
        //                       style: TextStyle(
        //                         fontSize: 13,
        //                         fontWeight: FontWeight.w500,
        //                         color: getStatusColor(item['progress_status']),
        //                       ),
        //                     ),
        //                   ],
        //                 )
        //               ],
        //             ),
        //             const SizedBox(height: 8),
        //             Row(
        //               children: [
        //                 const Icon(Icons.directions_car,
        //                     size: 16, color: Colors.blueGrey),
        //                 const SizedBox(width: 4),
        //                 Text(
        //                   'รถ: ${item['name_vehicle'] ?? '-'}',
        //                   style: const TextStyle(
        //                     fontSize: 14,
        //                     fontWeight: FontWeight.w500,
        //                   ),
        //                 ),
        //               ],
        //             ),
        //             const SizedBox(height: 4),
        //             Row(
        //               children: [
        //                 const Icon(Icons.location_on,
        //                     size: 16, color: Colors.orange),
        //                 const SizedBox(width: 4),
        //                 Expanded(
        //                   child: Text(
        //                     item['name_farm'] ?? '-',
        //                     style: const TextStyle(fontSize: 14),
        //                   ),
        //                 ),
        //               ],
        //             ),
        //             const SizedBox(height: 8),
        //             Row(
        //               crossAxisAlignment: CrossAxisAlignment.start,
        //               children: [
        //                 const Icon(Icons.access_time, size: 16),
        //                 const SizedBox(width: 4),
        //                 Expanded(
        //                   child: Text(
        //                     _formatDateRange(
        //                         item['date_start'], item['date_end']),
        //                     style: const TextStyle(
        //                       fontSize: 13,
        //                       fontWeight: FontWeight.bold,
        //                     ),
        //                   ),
        //                 ),
        //               ],
        //             ),
        //             const SizedBox(height: 8),
        //           ],
        //         ),
        //       ),
        //     );
        //   },
        // );
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
        //backgroundColor: const Color(0xFFFFCC99),
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 18, 143, 9),
          centerTitle: true,
          iconTheme: const IconThemeData(
            color: Colors.white, // ✅ ลูกศรย้อนกลับสีขาว
          ),
          title: const Text(
            'คิวงานทั้งหมด',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 255, 255, 255),
              //letterSpacing: 1,
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
            _buildPlanTab(), // แสดงปฏิทิน + งานที่ไม่ใช่ประวัติ
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
