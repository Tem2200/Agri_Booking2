import 'dart:convert';
import 'package:agri_booking2/pages/employer/DetailReserving.dart';
import 'package:agri_booking2/pages/employer/reserving_emp.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class PlanEmp extends StatefulWidget {
  final int mid;
  const PlanEmp({super.key, required this.mid});

  @override
  State<PlanEmp> createState() => _PlanEmpState();
}

class _PlanEmpState extends State<PlanEmp> {
  List<dynamic> reservings = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // ตั้ง default locale เป็นภาษาไทย
    Intl.defaultLocale = "th_TH";
    fetchReservings();
  }

  Future<void> fetchReservings() async {
    setState(() {
      isLoading = true;
    });

    try {
      final url = Uri.parse(
        'http://projectnodejs.thammadalok.com/AGribooking/get_Reserving/${widget.mid}',
      );

      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          reservings = data;
        });
      } else {
        print('Error: ${res.body}');
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String formatDateThai(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      // parse เวลา (จะเป็น UTC)
      DateTime utcDate = DateTime.parse(dateStr);

      // แปลงเป็นเวลาไทย (+7 ชั่วโมง)
      DateTime localDate = utcDate.toUtc().add(const Duration(hours: 7));

      // กำหนด format → ตัวอย่าง "10 ก.ค. 2568 เวลา 06:58"
      final formatter = DateFormat("d MMM yyyy 'เวลา' HH:mm", "th_TH");

      // แปลงปี ค.ศ. → พ.ศ.
      String formatted = formatter.format(localDate);
      String yearString = localDate.year.toString();
      String buddhistYear = (localDate.year + 543).toString();

      formatted = formatted.replaceFirst(yearString, buddhistYear);

      return formatted;
    } catch (e) {
      return '-';
    }
  }

  String progressStatusText(int? status) {
    switch (status) {
      case 0:
        return "ผู้รับจ้างยกเลิกงาน";
      case 1:
        return "ผู้รับจ้างยืนยันการจอง";
      case 2:
        return "กำลังเดินทางมา";
      case 3:
        return "กำลังทำงาน";
      case 4:
        return "ทำงานเสร็จสิ้น";
      default:
        return "รอผู้รับจ้างยืนยันการจอง";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("แผนการจองรถของฉัน"),
        backgroundColor: Colors.orange,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : reservings.isEmpty
              ? const Center(child: Text('ไม่พบข้อมูลการจอง'))
              : ListView.builder(
                  itemCount: reservings.length,
                  itemBuilder: (context, index) {
                    final rs = reservings[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      child: ListTile(
                        leading: rs['vehicle_image'] != null
                            ? Image.network(
                                rs['vehicle_image'],
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.image_not_supported),
                              )
                            : const Icon(Icons.agriculture, size: 50),
                        title: Text(
                          rs['name_rs'] ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('รถ: ${rs['name_vehicle'] ?? '-'}'),
                            Text(
                              'ฟาร์ม: ${rs['name_farm'] ?? '-'}'
                              ' (${rs['farm_subdistrict'] ?? '-'},'
                              ' ${rs['farm_district'] ?? '-'},'
                              ' ${rs['farm_province'] ?? '-'})',
                            ),
                            Text(
                                'พื้นที่: ${rs['area_amount'] ?? '-'} ${rs['unit_area'] ?? '-'}'),
                            Text('รายละเอียด: ${rs['detail'] ?? '-'}'),
                            Text(
                                'วันที่จอง: ${formatDateThai(rs['date_reserve'])}'),
                            Text('เริ่ม: ${formatDateThai(rs['date_start'])}'),
                            Text('สิ้นสุด: ${formatDateThai(rs['date_end'])}'),
                            Text(
                              'สถานะ: ${progressStatusText(rs['progress_status'])}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetailReserving(
                                      rsid: rs['rsid'] ?? 0,
                                    ),
                                  ),
                                );
                              },
                              child: const Text('รายละเอียดเพิ่มเติม'),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }
}
