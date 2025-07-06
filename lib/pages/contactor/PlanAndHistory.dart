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

  String _formatDateRange(String? startDate, String? endDate) {
    if (startDate == null || endDate == null) return 'ไม่ระบุวันที่';
    try {
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);
      final formatter = DateFormat('dd/MM/yyyy');
      return '${formatter.format(start)} - ${formatter.format(end)}';
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
            child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
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

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: scheduleList.length,
          itemBuilder: (context, index) {
            final item = scheduleList[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              elevation: 2.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ชื่อการจอง: ${item['name_rs'] ?? '-'}',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'วันที่: ${_formatDateRange(item['date_start'], item['date_end'])}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      'รถที่ใช้: ${item['name_vehicle'] ?? '-'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      'ฟาร์ม: ${item['name_farm'] ?? '-'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      'พื้นที่: ${item['area_amount'] ?? '-'} ${item['unit_area'] ?? '-'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      'รายละเอียดงาน: ${item['detail'] ?? '-'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      'สถานะความคืบหน้า: ${item['progress_status'] ?? 'ยังไม่ระบุ'}',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.deepOrange),
                    ),
                    if (item['employee_username'] != null)
                      Text(
                        'ผู้รับจ้าง: ${item['employee_username']} (${item['employee_phone'] ?? '-'})',
                        style: const TextStyle(fontSize: 16),
                      ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DetailWorkPage(rsid: item['rsid']),
                            ),
                          );
                        },
                        child: const Text('รายละเอียดเพิ่มเติม'),
                      ),
                    )
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
          title: const Text('งานทั้งหมด'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'คิวงาน'),
              Tab(text: 'ประวัติ'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPlanTab(), // แสดงปฏิทิน + งานที่ไม่ใช่ประวัติ
            _buildScheduleTab(includeHistory: true), // งานที่จบแล้วเท่านั้น
          ],
        ),
      ),
    );
  }
}
