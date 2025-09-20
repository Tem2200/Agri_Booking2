import 'dart:convert';
import 'package:agri_booking2/pages/employer/DetailReserving.dart';
import 'package:agri_booking2/pages/employer/Tabbar.dart';
import 'package:agri_booking2/pages/employer/review_con.dart';
import 'package:flutter/material.dart';
import 'package:googleapis_auth/auth.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:io';

class PlanEmp extends StatefulWidget {
  final int mid;
  const PlanEmp({super.key, required this.mid});

  @override
  State<PlanEmp> createState() => _PlanEmpState();
}

class _PlanEmpState extends State<PlanEmp> with SingleTickerProviderStateMixin {
  List<dynamic> reservings = [];
  List<dynamic> history = [];
  bool isLoading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    Intl.defaultLocale = "th_TH";
    _tabController = TabController(length: 2, vsync: this);

    fetchReservings();
    _startLongPolling();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _startLongPolling() async {
    while (mounted) {
      try {
        final url = Uri.parse(
            'http://projectnodejs.thammadalok.com/AGribooking/long-poll');
        final response = await http.get(url);
        if (response.statusCode == 200 && response.body.isNotEmpty) {
          final data = jsonDecode(response.body);
          // เช็ค event ที่เกี่ยวข้องกับการจอง/อัปเดต
          if (data['event'] == 'update_progress' ||
              data['event'] == 'reservation_added') {
            fetchReservings(); // โหลดข้อมูลใหม่
          }
        }
      } catch (e) {
        await Future.delayed(const Duration(seconds: 2)); // กัน spam server
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<void> sendEmail(Map<String, dynamic> rs) async {
    await initializeDateFormatting('th_TH'); // ต้องเรียกก่อนใช้ format แบบไทย

    String formatThaiDate(String isoDate) {
      final date = DateTime.parse(isoDate).toLocal();
      final formatter = DateFormat('d MMMM yyyy', 'th_TH');
      return formatter.format(date);
    }

    final emailContractor = rs['email_contractor'];
    const fromName = 'ระบบจองคิว AgriBooking';
    const toName = 'ผู้รับจ้าง';

    final nameRs = rs['name_rs'];
    final areaAmount = rs['area_amount'];
    final unitArea = rs['unit_area'];
    final detail = rs['detail'];
    final dateReserve = formatThaiDate(rs['date_reserve']);
    final dateStart = formatThaiDate(rs['date_start']);
    final dateEnd = formatThaiDate(rs['date_end']);

    final vehicleName = rs['name_vehicle'];
    final farmName = rs['name_farm'];
    final farmLocation =
        '${rs['farm_subdistrict']} อ.${rs['farm_district']} จ.${rs['farm_province']}';

    final message = '''
เรียน $toName

ทางเราขอแจ้งยกเลิกการจองคิวรถสำหรับงาน "$nameRs"

รายละเอียดการจอง:
- พื้นที่ทำงาน: $areaAmount $unitArea
- รายละเอียดเพิ่มเติม: $detail
- วันที่จอง: $dateReserve
- วันที่เริ่มงาน: $dateStart
- วันที่สิ้นสุด: $dateEnd

ยานพาหนะที่เลือกใช้: $vehicleName
สถานที่ทำงาน: $farmName, $farmLocation
''';

    const serviceId = 'service_x7vmrvq';
    const templateId = 'template_1mrmj3e';
    const userId = '9pdBbRJwCa8veHOzy';

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    final response = await http.post(
      url,
      headers: {
        'origin': 'http://localhost',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': userId,
        'template_params': {
          'from_name': fromName,
          'to_name': toName,
          'message': message,
          'to_email': emailContractor ?? '',
        }
      }),
    );

    if (response.statusCode == 200) {
      showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text('ส่งสำเร็จ'),
          content: Text('ส่งอีเมลแจ้งยกเลิกเรียบร้อยแล้ว'),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text('เกิดข้อผิดพลาด'),
          content: Text('ไม่สามารถส่งอีเมลได้'),
        ),
      );
    }
  }

  Future<void> sendFCM() async {
    final accountCredentials = ServiceAccountCredentials.fromJson({
      "type": "service_account",
      "project_id": "agribooking-9f958",
      "private_key_id": "3cb022d6380491ae267b5c4773c59fef246c6e17",
      "private_key":
          "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQDQGAAdplUmNmiv\nRoXrV421sEGUdEZV0XbtXX1oVN5SL+YdK7Z0rkRibMnJW48fQ+I0fx60JJR92CsO\n+9QOMqmniqHfwtXnsPk3Fdglkn0ty/Ie/esUINsGcVPCfdBtjrxJQ2qyGVULWEYw\n0tsD9+C4EQ4A1ijaLKJMYiFrI1MF9oH9q0d+hzcyWv8R1joUcahFpOOjE4h/ba2x\nrHsa1kgznmG7q2h2SJ3uQkuOTSR6BoVCHGBZPivzKC1DKGSVSQTod5Lab3fO8/kI\nM3VnqLnzKfUd1UP71O+9MQxHqgKL27zZO+qrm7RGqoXiUOIgpqz1uFJXmyYZBK8q\nKD+/PQPnAgMBAAECggEAATmTq1MxR8Hk3n6H0wDF410hSVSPKOKdzrv5jpiGv8R2\n3ftdHf4TV5xual+D6u6Dxdv4yrSUPHWVbR7VusMew7fYJRZ0j23O8EkdxLyrDmvp\nC7h5jS4ZPWkPRjSVHUaGrgZzKGDE+j/kF1Xv3L1BBW0Uoz+feU1MaaL2yMJBbUNp\nbb4fSuOr1yZpGFT+EXHyyJnnM9wL5hMEuQ3zJwEOy/bpE2bAlojg/YW3IxhFSxE5\nMIfzSLrdueQLIYsAlwaRvNvPJOUZKKQrAPMJCVLOFVx9v/+b3Z8E7/PhmylnivHh\n62F+iQkHgeaD12yHtCeQfWCVqDYf0AApM1TRM7jV3QKBgQD/Zheo1GpW4apQV3Tv\nxiQWbMTTYEgEPw7s+vhFvRDqoHSw2wwg/SVpz2x4Ns/vMneP5CDlOpVVbCoA+UX/\n/nTjTDWdbbLmUr1zw65MSfm5Jf/lLhPqoGnjNdvB4/p0Z1LjbvSdPAKM2qJbdeH8\niaOo930OXEuOM7Zy10xlgX6j4wKBgQDQlWa2dL83TjN1+teg8pBhrEJ/XFwCvQ/U\nABF9CSxEAucfdknNVKGSv90j2qwYu0FytbI+yxEFzfCs4TfRrEpCQ+gwgDZdO79O\nvoG7O4fC8iAvZ3p+dOwr4y59utJo1vFOVhDScEeAofriSDs7Z2qXvmp6ru41cuHA\n/TZKorUHLQKBgHrpczF5KMQvTnvj2w8Z2HxCVGc1yvLgNhqunZVSbDW+iuoiQTAP\nJFZL0PP5zRBcxVWmgH5RN1Uo/P4C+UE+AJrzLkpZZOObpjl0TwnAAEKumvx8tHES\nSmNipCQnx30FzMpPt8GEA+Ytwj0p+lxDEVRb5v9mQ6ZoFMIoA0hGjd/pAoGAY+HX\nMLIRSxOYkvuOvFTLjOonYcPBj9InPTbXKQ/2cY8OTEOhrcDEKnjUFbJGTQWGnr6h\nX25wdV4bzT2ANFiTqs3H50nOPrE4uCWEDDvClDjL7sdXoiytV4rPnYeT8H5VSVTv\nc0YvB0sJz8gVDSpFoeqeJKeWDGQ59OeMUws9MvUCgYBqMqbAYUXwmf0MCmBNd1Pf\nVq4UtW+JwFyNI8jZDIB+SvIf23TmCYozjhAEpnXvMdVOBGIaphM6TxPbdnSfKfbz\nhaecXGkO3/xDW/3HqL+qaWlAAfdDjG96v8UDJ6D3eIwmKPZedft6ai1wE43oNlax\nA5JmPqpZN2mZXloL8J/CUQ==\n-----END PRIVATE KEY-----\n",
      "client_email":
          "firebase-adminsdk-fbsvc@agribooking-9f958.iam.gserviceaccount.com",
      "client_id": "106395285857648756377",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url":
          "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url":
          "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40agribooking-9f958.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com"
    });

    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

    // ขอ OAuth token
    final authClient =
        await clientViaServiceAccount(accountCredentials, scopes);

    final url = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/agribooking-9f958/messages:send');

    final message = {
      "message": {
        "token": "<YOUR_DEVICE_TOKEN>",
        "notification": {
          "title": "ทดสอบแจ้งเตือน",
          "body": "ข้อความจาก HTTP v1 API"
        }
      }
    };

    final response = await authClient.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(message),
    );

    print(response.statusCode);
    print(response.body);

    authClient.close();
  }

  Future<void> fetchReservings() async {
    setState(() {
      isLoading = true;
    });

    try {
      final url = Uri.parse(
          'http://projectnodejs.thammadalok.com/AGribooking/get_Reserving/${widget.mid}');
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        print('นี่คือข้อมูล $data');
        // แยกเป็น 2 กลุ่ม
        final current = data
            .where((item) =>
                item['progress_status'] != 4 && item['progress_status'] != 0)
            .toList();
        final finished = data
            .where((item) =>
                item['progress_status'] == 4 || item['progress_status'] == 0)
            .toList();

        setState(() {
          reservings = current;
          history = finished;
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

  Future<void> updateProgressStatus(dynamic rsid) async {
    print(rsid);
    final url = Uri.parse(
      'http://projectnodejs.thammadalok.com/AGribooking/update_progress',
    );

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'rsid': rsid,
          'progress_status': 5,
        }),
      );

      if (response.statusCode == 200) {
        // โชว์ toast ที่ด้านบน
        Fluttertoast.showToast(
          msg: 'อัปเดตสถานะสำเร็จ',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          timeInSecForIosWeb: 2,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        // รีเฟรชหน้าหรือโหลดข้อมูลใหม่
        setState(() {
          // เรียกฟังก์ชันโหลดข้อมูลใหม่ เช่น
          fetchReservings(); // สมมุติชื่อฟังก์ชันโหลดข้อมูล
        });
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("อัปเดตล้มเหลว"),
            content: Text("รหัสสถานะ: ${response.statusCode}"),
          ),
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("เกิดข้อผิดพลาด"),
          content: Text("ไม่สามารถเชื่อมต่อ: $e"),
        ),
      );
    }
  }

  // ฟังก์ชันสำหรับวันที่จอง
  String formatReservationDateThai(String? dateReserve) {
    if (dateReserve == null || dateReserve.isEmpty) return '-';
    try {
      DateTime date =
          DateTime.parse(dateReserve).toUtc().add(const Duration(hours: 7));
      final formatter = DateFormat("d MMMM yyyy", "th_TH");
      String formatted = formatter.format(date);
      formatted = formatted.replaceFirst(
          date.year.toString(), (date.year + 543).toString());
      return formatted;
    } catch (e) {
      print('Error parsing reservation date: $e');
      return '-';
    }
  }

// แปลงวันจอง
  String formatReservationDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      DateTime utcDate = DateTime.parse(dateStr).toUtc();
      DateTime thaiDate = utcDate.add(const Duration(hours: 7));
      final formatter = DateFormat("d MMMM yyyy 'เวลา' HH:mm น.", "th_TH");
      String formatted = formatter.format(thaiDate);
      formatted = formatted.replaceFirst(
          thaiDate.year.toString(), (thaiDate.year + 543).toString());
      return formatted;
    } catch (e) {
      print('Error parsing reservation date: $e');
      return '-';
    }
  }

// แปลงวันเริ่มงาน
  String formatStartDate(String? startDate) {
    if (startDate == null || startDate.isEmpty) return '-';
    try {
      DateTime utcDate = DateTime.parse(startDate).toUtc();
      DateTime thaiDate = utcDate.add(const Duration(hours: 7));
      final formatter = DateFormat("d MMMM yyyy 'เวลา' HH:mm น.", "th_TH");
      String formatted = formatter.format(thaiDate);
      formatted = formatted.replaceFirst(
          thaiDate.year.toString(), (thaiDate.year + 543).toString());
      return formatted;
    } catch (e) {
      print('Error parsing start date: $e');
      return '-';
    }
  }

// แปลงวันสิ้นสุดงาน
  String formatEndDate(String? endDate) {
    if (endDate == null || endDate.isEmpty) return '-';
    try {
      DateTime utcDate = DateTime.parse(endDate).toUtc();
      DateTime thaiDate = utcDate.add(const Duration(hours: 7));
      final formatter = DateFormat("d MMMM yyyy 'เวลา' HH:mm น.", "th_TH");
      String formatted = formatter.format(thaiDate);
      formatted = formatted.replaceFirst(
          thaiDate.year.toString(), (thaiDate.year + 543).toString());
      return formatted;
    } catch (e) {
      print('Error parsing end date: $e');
      return '-';
    }
  }

  // แปลง progress_status เป็นข้อความ
  String progressStatusText(int? status) {
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
        return 'รอผู้รับจ้างยกเลิกการจอง';
      default:
        return 'รอผู้รับจ้างยืนยันการจอง';
    }
  }

  // กำหนดสีตามสถานะ
  Color getStatusColor(dynamic status) {
    switch (status.toString()) {
      case '0':
        return Colors.red; // ยกเลิกงาน
      case '1':
        return Colors.blue; // ยืนยันการจอง
      case '2':
        return Colors.purple; // กำลังเดินทาง
      case '3':
        return Colors.orange; // กำลังทำงาน
      case '4':
        return Colors.green; // เสร็จสิ้น
      case '5':
        return Colors.brown; // รอผู้รับจ้างยกเลิก
      default:
        return Colors.grey; // รอยืนยัน
    }
  }

  Widget buildList(List<dynamic> list) {
    if (list.isEmpty) {
      return RefreshIndicator(
        onRefresh: fetchReservings, // ดึงข้อมูลใหม่เมื่อรีเฟรช
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(), // บังคับให้เลื่อนแม้ไม่มีข้อมูล
          children: const [
            SizedBox(
                height: 300, child: Center(child: Text('ไม่พบข้อมูลการจอง'))),
          ],
        ),
      );
    }
    return RefreshIndicator(
        onRefresh: fetchReservings,
        child: ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, index) {
            final rs = list[index];

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 25),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 12),

                    // ✅ ข้อมูล
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // งาน + สถานะ
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  rs['name_rs'] ?? '-',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Text(
                              //   progressStatusText(rs['progress_status']),
                              //   style: const TextStyle(
                              //     fontWeight: FontWeight.bold,
                              //     fontSize: 14,
                              //     color: Colors.orange,
                              //   ),
                              // ),
                              Text(
                                progressStatusText(rs['progress_status']),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: getStatusColor(rs[
                                      'progress_status']), // ✅ สีเปลี่ยนตามสถานะ
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ผู้รับจ้าง
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(
                                    width: 85,
                                    child: Row(
                                      children: [
                                        Icon(Icons.person,
                                            size: 16, color: Colors.indigo),
                                        SizedBox(width: 6),
                                        Text(
                                          'ผู้รับจ้าง:',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // '${rs['contractor_username']} (${rs['phone'] ?? '-'})',
                                  Expanded(
                                    child: Text(
                                      '${rs['username_contractor']}',
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
                                        SizedBox(width: 6),
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
                                      rs['name_vehicle'] ?? '-',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),

                              // ฟาร์ม
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(
                                    width: 65,
                                    child: Row(
                                      children: [
                                        Icon(Icons.agriculture,
                                            size: 16, color: Colors.green),
                                        SizedBox(width: 6),
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
                                      '${rs['name_farm'] ?? '-'} (ต.${rs['farm_subdistrict'] ?? '-'}, อ.${rs['farm_district'] ?? '-'}, จ.${rs['farm_province'] ?? '-'})',
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

                          //วันที่และเวลาจ้างงาน

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
                                formatReservationDateThai(rs['date_reserve']),
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
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              Text(
                                formatStartDate(rs[
                                    'date_start']), // ใช้ฟังก์ชันสำหรับวันเดียว
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
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              Text(
                                formatEndDate(rs[
                                    'date_end']), // ใช้ฟังก์ชันสำหรับวันเดียว
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                          const Divider(
                            color: Colors.grey,
                            thickness: 1,
                            height: 24,
                          ),

                          // ปุ่ม
                          Row(
                            children: [
                              // ปุ่มแจ้งยกเลิก
                              if (progressStatusText(rs['progress_status']) ==
                                  "รอผู้รับจ้างยืนยันการจอง")
                                ElevatedButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Center(
                                          child: Text('ยืนยันการยกเลิก'),
                                        ),
                                        content: const Text(
                                            'คุณแน่ใจหรือไม่ว่าต้องการยกเลิกการจองนี้?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(
                                                context), // ยกเลิก
                                            child: const Text('ไม่'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.pop(
                                                  context); // ปิด dialog ก่อน

                                              if (rs['rsid'] != null) {
                                                updateProgressStatus(
                                                    rs['rsid']);
                                              } else {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) =>
                                                      const AlertDialog(
                                                    title:
                                                        Text("เกิดข้อผิดพลาด"),
                                                    content: Text(
                                                        "ไม่พบข้อมูล rsid"),
                                                  ),
                                                );
                                              }
                                            },
                                            child: const Text('ใช่'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  label: const Text("แจ้งยกเลิกการจอง"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color.fromARGB(255, 225, 49, 18),
                                    foregroundColor: Colors.white,
                                    elevation: 4,
                                    shadowColor: const Color.fromARGB(
                                        208, 163, 160, 160),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                    textStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),

                              // กรณีสถานะเสร็จสิ้น ให้ปุ่มรีวิวแสดงข้างปุ่มรายละเอียด
                              if (progressStatusText(rs['progress_status']) ==
                                  "เสร็จสิ้น") ...[
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ReviewCon(
                                          midContractor:
                                              rs['mid_contractor'] ?? 0,
                                        ),
                                      ),
                                    );
                                  },
                                  label: const Text("   รีวิวผู้รับจ้าง   "),
                                  style: ElevatedButton.styleFrom(
                                    elevation: 4,
                                    shadowColor: const Color.fromARGB(
                                        208, 163, 160, 160),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 10),
                                    textStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                    width: 10), // เว้นช่องว่างระหว่างปุ่ม
                              ],
                              const SizedBox(width: 16),
                              // ปุ่มรายละเอียดเพิ่มเติม (แสดงทุกกรณี)
                              ElevatedButton.icon(
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
                                label: const Text("รายละเอียดเพิ่มเติม"),
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
                                      horizontal: 16, vertical: 10),
                                  textStyle: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ));
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 18, 143, 9),
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: const Text(
            //'แผนการจองคิวทั้งหมด (ผู้จ้าง)', //คำยาวไป
            'การจองของฉัน (ผู้จ้าง)',
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
                          builder: (context) => Tabbar(
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
                    controller: _tabController, // ✅ ใส่ตรงนี้
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
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
                          height: 48,
                          child: Center(child: Text('รถที่จอง')),
                        ),
                      ),
                      Tab(
                        child: SizedBox(
                          height: 48,
                          child: Center(child: Text('ประวัติการจ้าง')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController, // ✅ ย้ายมาตรงนี้
                children: [
                  Center(child: buildList(reservings)),
                  Center(child: buildList(history)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
