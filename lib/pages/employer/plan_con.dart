import 'dart:convert';
import 'package:agri_booking2/pages/employer/reservingForNF.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

    // โหลดข้อมูลเจ้าของรถ
    _conFuture = fetchCon(widget.mid);

    // 👉 ตั้งค่า scheduleFuture ทันทีเลย
    _scheduleFuture =
        fetchSchedule(widget.mid, _displayMonth, _displayYear).then((list) {
      groupEventsByDay(list);
      return list;
    });

    // ตั้งค่า locale แยกออก ไม่ไปผูกกับ schedule
    initializeDateFormatting('th', null).then((_) {
      if (mounted) {
        setState(() {
          _isLocaleInitialized = true;
        });
      }
    });

    _startLongPolling();
  }

  void _startLongPolling() async {
    while (mounted) {
      try {
        final url = Uri.parse(
            'http://projectnodejs.thammadalok.com/AGribooking/long-poll');
        final response = await http.get(url);
        if (response.statusCode == 200 && response.body.isNotEmpty) {
          final data = jsonDecode(response.body);
          // เช็ค event ที่เกี่ยวข้อง
          if (data['event'] == 'reservation_added' ||
              data['event'] == 'update_progress') {
            // โหลดข้อมูลใหม่
            setState(() {
              _scheduleFuture =
                  fetchSchedule(widget.mid, _displayMonth, _displayYear)
                      .then((list) {
                groupEventsByDay(list);
                return list;
              });
            });
          }
        }
      } catch (e) {
        await Future.delayed(const Duration(seconds: 2)); // กัน spam server
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  // ... (โค้ด fetchCon, fetchSchedule, groupEventsByDay, _formatDateRange, _changeMonth ส่วนเดิม) ...
  Future<Map<String, dynamic>> fetchCon(int mid) async {
    final urlCon = Uri.parse(
        'http://projectnodejs.thammadalok.com/AGribooking/members/$mid');
    final response = await http.get(urlCon);

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

  // ฟังก์ชันแปลงวันที่ทั่วไป (ใช้กับ date_reserve)
  String formatDateReserveThai(String? dateReserve) {
    if (dateReserve == null || dateReserve.isEmpty) return '-';
    try {
      DateTime utcDate = DateTime.parse(dateReserve);
      DateTime localDate = utcDate.toUtc().add(const Duration(hours: 7));
      final formatter = DateFormat("d MMM yyyy เวลา HH:mm น. ", "th_TH");
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
    backgroundColor: Colors.blue,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    textStyle: GoogleFonts.mitr(
      fontSize: 20,
      fontWeight: FontWeight.w600,
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
              // const SizedBox(height: 10),
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
                  vihicleData?['image_vehicle'] != null &&
                          vihicleData!['image_vehicle'].toString().isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            vihicleData!['image_vehicle'],
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 40,
                            color: Colors.grey,
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

  // 💡 แก้ไข _buildPlanTab
  Widget _buildPlanTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 10),
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

          FutureBuilder<List<dynamic>>(
            future: _scheduleFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // 💡 ย้ายโค้ดปฏิทินมาที่นี่ เพื่อให้แสดงผลเสมอหลังจากโหลดเสร็จ
              // หากไม่มีข้อมูล, `allSchedules` จะเป็นรายการว่างเปล่า
              final allSchedules = snapshot.data ?? [];

              return TableCalendar(
                // ... (โค้ด TableCalendar ส่วนอื่น ๆ เหมือนเดิม) ...
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
                  weekendTextStyle:
                      TextStyle(fontSize: 14.0, color: Colors.red),
                  todayTextStyle:
                      TextStyle(fontSize: 14.0, color: Colors.white),
                  selectedTextStyle:
                      TextStyle(fontSize: 14.0, color: Colors.white),
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
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = DateTime(
                        selectedDay.year, selectedDay.month, selectedDay.day);
                  });
                },
                eventLoader: (day) {
                  // กรอง schedule ทั้งหมดในวันนั้น
                  final eventsForDay = allSchedules.where((item) {
                    final dateStart =
                        DateTime.parse(item['date_start']).toLocal();
                    final dateEnd = DateTime.parse(item['date_end']).toLocal();
                    final progressStatus = item['progress_status'];

                    final normalizedDateStart = DateTime(
                        dateStart.year, dateStart.month, dateStart.day);
                    final normalizedDateEnd =
                        DateTime(dateEnd.year, dateEnd.month, dateEnd.day);

                    final isInRange = (day.isAfter(normalizedDateStart) ||
                            isSameDay(day, normalizedDateStart)) &&
                        (day.isBefore(normalizedDateEnd) ||
                            isSameDay(day, normalizedDateEnd));

                    if (!isInRange) return false;

                    // ✅ กรองตามปุ่มสถานะ
                    if (_selectedStatus == StatusFilter.all) {
                      return true;
                    }
                    if (_selectedStatus == StatusFilter.pending) {
                      return progressStatus == null;
                    }
                    if (_selectedStatus == StatusFilter.notAvailable) {
                      return progressStatus != null &&
                          ['1', '2', '3', '5']
                              .contains(progressStatus.toString());
                    }
                    return false;
                  }).toList();

                  // จำนวน events จะถูกใช้กำหนด "จำนวนจุด" ที่ TableCalendar แสดง
                  return eventsForDay;
                },

                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isEmpty) return const SizedBox();

                    return Positioned(
                      bottom: 1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: events.map((e) {
                          final mapE = e as Map<String, dynamic>;
                          final color = getStatusColor(mapE['progress_status']);
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          _buildScheduleList(), // 💡 เปลี่ยนชื่อเป็น _buildScheduleList
        ],
      ),
    );
  }

  String getStatusText(dynamic status) {
    if (status != null && ['1', '2', '3', '5'].contains(status.toString())) {
      return 'ผู้รับจ้างไม่ว่าง';
    }
    if (status == null) {
      return 'รอยืนยันการจอง';
    }
    return '';
  }

  Color getStatusColor(dynamic status) {
    if (status != null && ['1', '2', '3', '5'].contains(status.toString())) {
      return const Color.fromARGB(255, 255, 0, 0);
    }
    if (status == null) {
      return const Color.fromARGB(255, 91, 91, 91);
    }
    return Colors.transparent;
  }

// 💡 แก้ไข _buildScheduleList
  Widget _buildScheduleList() {
    return FutureBuilder<List<dynamic>>(
      future: _scheduleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        // else if (snapshot.hasError) {
        //   return const Center(
        //       child: Text('ไม่สามารถโหลดข้อมูลได้, กรุณาลองใหม่'));
        // }
        else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('ไม่มีคิวงาน'));
        }

        final scheduleList = snapshot.data!;

<<<<<<< HEAD
<<<<<<< HEAD
        // 💡 แก้ไขเงื่อนไขการกรองข้อมูลใน filteredList
        // List<dynamic> filteredList = scheduleList.where((item) {
        //   final dateStart = DateTime.parse(item['date_start']).toLocal();
        //   final dateEnd = DateTime.parse(item['date_end']).toLocal();
        //   final progressStatus = item['progress_status'];

        //   final normalizedDateStart =
        //       DateTime(dateStart.year, dateStart.month, dateStart.day);
        //   final normalizedDateEnd =
        //       DateTime(dateEnd.year, dateEnd.month, dateEnd.day);

        //   // 💡 เงื่อนไขใหม่: ตรวจสอบว่าวันที่เลือก (_selectedDay) อยู่ในช่วงของงานหรือไม่
        //   final isSelectedDayInRage =
        //       (_selectedDay.isAfter(normalizedDateStart) ||
        //               isSameDay(_selectedDay, normalizedDateStart)) &&
        //           (_selectedDay.isBefore(normalizedDateEnd) ||
        //               isSameDay(_selectedDay, normalizedDateEnd));

        //   if (!isSelectedDayInRage) {
        //     return false;
        //   }

        //   // เงื่อนไขการกรองตามสถานะยังคงเหมือนเดิม
        //   if (_selectedStatus == StatusFilter.all) {
        //     return true;
        //   }
        //   if (_selectedStatus == StatusFilter.pending) {
        //     return progressStatus == null;
        //   }
        //   if (_selectedStatus == StatusFilter.notAvailable) {
        //     return progressStatus != null &&
        //         ['1', '2', '3', '5'].contains(progressStatus.toString());
        //   }

        //   return false;
        // }).toList();

=======
>>>>>>> Whan
=======
>>>>>>> Whan
        List<dynamic> filteredList = scheduleList.where((item) {
          final dateStart = DateTime.parse(item['date_start']).toLocal();
          final dateEnd = DateTime.parse(item['date_end']).toLocal();
          final progressStatus = item['progress_status'];

          // 💡 แก้ไข: ถ้าไม่ได้เลือกวัน (_selectedDay == null) ให้แสดงทั้งหมด
          bool isSelectedDayInRange = true;
          if (_selectedDay != null) {
            final normalizedDateStart =
                DateTime(dateStart.year, dateStart.month, dateStart.day);
            final normalizedDateEnd =
                DateTime(dateEnd.year, dateEnd.month, dateEnd.day);
            isSelectedDayInRange = (_selectedDay.isAfter(normalizedDateStart) ||
                    isSameDay(_selectedDay, normalizedDateStart)) &&
                (_selectedDay.isBefore(normalizedDateEnd) ||
                    isSameDay(_selectedDay, normalizedDateEnd));
          }

          if (!isSelectedDayInRange) return false;

          // กรองตามสถานะ
          if (_selectedStatus == StatusFilter.all) return true;
          if (_selectedStatus == StatusFilter.pending)
            return progressStatus == null;
          if (_selectedStatus == StatusFilter.notAvailable) {
            return progressStatus != null &&
                ['1', '2', '3', '5'].contains(progressStatus.toString());
          }
          return false;
        }).toList();

        // ... (โค้ดส่วนอื่น ๆ ของ _buildScheduleList เหมือนเดิม) ...
        if (filteredList.isEmpty) {
          return const Center(child: Text('วันนี้ไม่มีสถานะนี้'));
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredList.length,
          itemBuilder: (context, index) {
            final item = filteredList[index];

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
                        // ชื่อรายการ + สถานะ
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
                                Icon(
                                  Icons.circle,
                                  color:
                                      getStatusColor(item['progress_status']),
                                  size: 10,
                                ),
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
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // รถ
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

                        // ที่นา
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
                                item['subdistrict'] != null
                                    ? '${item['name_farm']} (ต.${item['subdistrict']} อ.${item['district']} จ.${item['province']})'
                                    : 'ไม่ระบุที่อยู่',
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
                    const SizedBox(height: 8),
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
                  ],
                ),
              ),
            );
          },
        );
      },
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
            'ตารางงานทั้งหมด',
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
