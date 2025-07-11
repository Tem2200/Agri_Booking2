import 'dart:convert';
import 'package:agri_booking2/pages/contactor/DetailWork.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class PlanPage extends StatefulWidget {
  final int mid;
  final int month;
  final int year;

  const PlanPage({
    super.key,
    required this.mid,
    required this.month,
    required this.year,
  });

  @override
  State<PlanPage> createState() => _PlanAndHistoryState();
}

class _PlanAndHistoryState extends State<PlanPage> {
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
          padding: const EdgeInsets.all(8.0),
          itemCount: scheduleList.length,
          itemBuilder: (context, index) {
            final item = scheduleList[index];

            // แปลง progress_status เป็นข้อความ
            String getStatusText(dynamic status) {
              switch (status.toString()) {
                case '0':
                  return 'ยกเลิก';
                case '1':
                  return 'ยืนยัน';
                case '2':
                  return 'กำลังเดินทาง';
                case '3':
                  return 'กำลังทำงาน';
                case '4':
                  return 'เสร็จสิ้น';
                default:
                  return 'ยังไม่ระบุ';
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
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
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
                        Text(
                          item['name_rs'] ?? '-',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
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

                    //รายละเอียด
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
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFCC99),
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 255, 187, 119),
          title: const Text('ตารางงาน'),
          centerTitle: true,
        ),
        body: TabBarView(
          children: [
            _buildPlanTab(), // แสดงปฏิทิน + งานที่ไม่ใช่ประวัติ
          ],
        ),
      ),
    );
  }
}
