import 'dart:convert';
import 'package:agri_booking2/pages/contactor/DetailWork.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

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

  Widget _buildPlanTab() {
    final String currentMonthName =
        DateFormat.MMMM('th').format(DateTime(_displayYear, _displayMonth));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () => _changeMonth(-1),
              ),
              Text(
                '$currentMonthName $_displayYear',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: () => _changeMonth(1),
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildScheduleTab(includeHistory: false),
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
            // child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
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

        if (scheduleList.isEmpty) {
          return const Center(child: Text('ไม่พบงานในหมวดนี้'));
        }

        //test ui
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), // ซ้าย-ขวา-ล่าง
          itemCount: scheduleList.length,
          itemBuilder: (context, index) {
            final item = scheduleList[index];

            // แปลง progress_status เป็นข้อความ
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

            // กำหนดสีตามสถานะ
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
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0), // สีพื้นหลังครีมอ่อน
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFFCC80), // สีส้มอ่อนเข้ากับพื้นหลัง
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.2), // เงาส้มอ่อนโปร่งใส
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 4), // เงาลงด้านล่างเล็กน้อย
                  ),
                ],
              ),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ชื่อ + สถานะ
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
                            overflow: TextOverflow.ellipsis, // ✅ ตัดด้วย ...
                            maxLines: 1, // ✅ แสดงแค่บรรทัดเดียว
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

                    // รุ่นรถ
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

                    // ฟาร์ม
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF4CAF50), // เขียวธรรมชาติ
                            foregroundColor: Colors.white,
                            elevation: 4, // ✅ เพิ่มเงา
                            shadowColor: Color.fromARGB(
                                208, 163, 160, 160), // ✅ เงานุ่มๆ
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(16), // ✅ มุมนุ่มขึ้น
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 10), // ✅ ขนาดกำลังดี
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        // backgroundColor: const Color.fromARGB(255, 255, 158, 60),
        appBar: AppBar(
          // backgroundColor: const Color(0xFF006000),
          backgroundColor: const Color.fromARGB(255, 18, 143, 9),
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: const Text(
            'คิวงานทั้งหมด',
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
            // ✅ แถบแท็บนูนด้วย Card
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
                    // indicator: BoxDecoration(
                    //   borderRadius: BorderRadius.circular(8),
                    //   color: Colors.green[900],
                    //   boxShadow: [
                    //     BoxShadow(
                    //       color: Colors.black26,
                    //       blurRadius: 4,
                    //       offset: Offset(0, 2),
                    //     ),
                    //   ],
                    // ),
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        colors: [
                          Color.fromARGB(255, 190, 255, 189)!,
                          Color.fromARGB(255, 37, 189, 35)!,
                          Colors.green[800]!,

                          // Color.fromARGB(255, 255, 244, 189)!,
                          // Color.fromARGB(255, 254, 187, 42)!,
                          // Color.fromARGB(255, 218, 140, 22)!,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
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
                    labelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
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
                          child: Center(child: Text('ประวัติการรับงาน')),
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
                  // ตารางงาน - จัดกลางจอ
                  Center(
                    child: _buildPlanTab(),
                  ),

                  // ประวัติการรับงาน - จัดกลางจอ
                  Center(
                    child: _buildScheduleTab(includeHistory: true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
