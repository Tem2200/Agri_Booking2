import 'dart:convert';
import 'package:agri_booking2/pages/contactor/DetailWork.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class NontiPage extends StatefulWidget {
  final int mid;

  const NontiPage({super.key, required this.mid});

  @override
  State<NontiPage> createState() => _NontiPageState();
}

class _NontiPageState extends State<NontiPage> {
  Future<List<dynamic>>? _scheduleFuture;

  @override
  void initState() {
    super.initState();
    print("MID: ${widget.mid}");
    setState(() {
      _scheduleFuture = fetchSchedule(widget.mid); // ✅ แก้ตรงนี้
      print("_scheduleFuture: $_scheduleFuture");
      // ✅ ไม่ใช้ month/year แล้ว
    });
  }

  Future<List<dynamic>> fetchSchedule(int mid) async {
    final url = Uri.parse(
        'http://projectnodejs.thammadalok.com/AGribooking/get_ConReservingNonti/$mid');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        print("สถานะ NULLLLLLLLLLLL + ${response.body}");
        if (response.body.isNotEmpty) {
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

      final formatter = DateFormat('dd/MM/yyyy HH:mm', 'th_TH'); // ✅ เพิ่มเวลา

      return '${formatter.format(start)} ถึง ${formatter.format(end)}';
    } catch (e) {
      return 'รูปแบบวันที่ไม่ถูกต้อง';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //backgroundColor: const Color.fromARGB(255, 255, 158, 60),
      appBar: AppBar(
        //backgroundColor: const Color(0xFF006000),
        //backgroundColor: const Color.fromARGB(255, 255, 158, 60),
        backgroundColor: const Color.fromARGB(255, 18, 143, 9),
        centerTitle: true,
        automaticallyImplyLeading: false, // ✅ ลบปุ่มย้อนกลับ
        title: const Text(
          'การแจ้งเตือน',
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
      body: FutureBuilder<List<dynamic>>(
        future: _scheduleFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            //return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
            return Center(child: Text('ขณะนี้ยังไม่มีการแจ้งเตือนค่ะ'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('ไม่มีคิวงาน'));
          }

          final scheduleList = snapshot.data!
              .where((item) => item['progress_status'] != 4)
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: scheduleList.length,
            itemBuilder: (context, index) {
              final item = scheduleList[index];
              return GestureDetector(
                // 👈 เปลี่ยนตรงนี้
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailWorkPage(rsid: item['rsid']),
                    ),
                  );
                },
                child: Card(
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
                          'วันเวลานัดหมาย: ${_formatDateRange(item['date_start'], item['date_end'])}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'รถที่ใช้: ${item['name_vehicle'] ?? '-'}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'ฟาร์ม: ${item['name_farm'] ?? '-'}, ${item['farm_district'] ?? '-'}, ${item['farm_province'] ?? '-'}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'จำนวนการจ้างงาน: ${item['area_amount'] ?? '-'} ${item['unit_area'] ?? '-'}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        if (item['employee_username'] != null)
                          Text(
                            'ผู้รับจ้าง: ${item['employee_username']} (${item['employee_phone'] ?? '-'})',
                            style: const TextStyle(fontSize: 16),
                          ),
                        // ลบปุ่มออก
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
