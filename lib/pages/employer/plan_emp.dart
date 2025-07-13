import 'dart:convert';
import 'package:agri_booking2/pages/employer/DetailReserving.dart';
import 'package:flutter/material.dart';
import 'package:googleapis_auth/auth.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  Future<void> sendCancelNotification({
    required int contractorMid,
    required int rsid,
  }) async {
    final accountCredentials = ServiceAccountCredentials.fromJson({
      "type": "service_account",
      "project_id": "agribooking-9f958",
      "private_key_id": "3cb022d6380491ae267b5c4773c59fef246c6e17",
      "private_key":
          "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQDQGAAdplUmNmiv\nRoXrV421sEGUdEZV0XbtXX1oVN5SL+YdK7Z0rkRibMnJW48fQ+I0fx60JJR92CsO\n+9QOMqmniqHfwtXnsPk3Fdglkn0ty/Ie/esUINsGcVPCfdBtjrxJQ2qyGVULWEYw\n0tsD9+C4EQ4A1ijaLKJMYiFrI1MF9oH9q0d+hzcyWv8R1joUcahFpOOjE4h/ba2x\nrHsa1kgznmG7q2h2SJ3uQkuOTSR6BoVCHGBZPivzKC1DKGSVSQTod5Lab3fO8/kI\nM3VnqLnzKfUd1UP71O+9MQxHqgKL27zZO+qrm7RGqoXiUOIgpqz1uFJXmyYZBK8q\nKD+/PQPnAgMBAAECggEAATmTq1MxR8Hk3n6H0wDF410hSVSPKOKdzrv5jpiGv8R2\n3ftdHf4TV5xual+D6u6Dxdv4yrSUPHWVbR7VusMew7fYJRZ0j23O8EkdxLyrDmvp\nC7h5jS4ZPWkPRjSVHUaGrgZzKGDE+j/kF1Xv3L1BBW0Uoz+feU1MaaL2yMJBbUNp\nbb4fSuOr1yZpGFT+EXHyyJnnM9wL5hMEuQ3zJwEOy/bpE2bAlojg/YW3IxhFSxE5\nMIfzSLrdueQLIYsAlwaRvNvPJOUZKKQrAPMJCVLOFVx9v/+b3Z8E7/PhmylnivHh\n62F+iQkHgeaD12yHtCeQfWCVqDYf0AApM1TRM7jV3QKBgQD/Zheo1GpW4apQV3Tv\nxiQWbMTTYEgEPw7s+vhFvRDqoHSw2wwg/SVpz2x4Ns/vMneP5CDlOpVVbCoA+UX/\n/nTjTDWdbbLmUr1zw65MSfm5Jf/lLhPqoGnjNdvB4/p0Z1LjbvSdPAKM2qJbdeH8\niaOo930OXEuOM7Zy10xlgX6j4wKBgQDQlWa2dL83TjN1+teg8pBhrEJ/XFwCvQ/U\nABF9CSxEAucfdknNVKGSv90j2qwYu0FytbI+yxEFzfCs4TfRrEpCQ+gwgDZdO79O\nvoG7O4fC8iAvZ3p+dOwr4y59utJo1vFOVhDScEeAofriSDs7Z2qXvmp6ru41cuHA\n/TZKorUHLQKBgHrpczF5KMQvTnvj2w8Z2HxCVGc1yvLgNhqunZVSbDW+iuoiQTAP\nJFZL0PP5zRBcxVWmgH5RN1Uo/P4C+UE+AJrzLkpZZOObpjl0TwnAAEKumvx8tHES\nSmNipCQnx30FzMpPt8GEA+Ytwj0p+lxDEVRb5v9mQ6ZoFMIoA0hGjd/pAoGAY+HX\nMLIRSxOYkvuOvFTLjOonYcPBj9InPTbXKQ/2cY8OTEOhrcDEKnjUFbJGTQWGnr6h\nX25wdV4bzT2ANFiTqs3H50nOPrE4uCWEDDvClDjL7sdXoiytV4rPnYeT8H5VSVTv\nc0YvB0sJz8gVDSpFoeqeJKeWDGQ59OeMUws9MvUCgYBqMqbAYUXwmf0MCmBNd1Pf\nVq4UtW+JwFyNI8jZDIB+SvIf23TmCYozjhAEpnXvMdVOBGIaphM6TxPbdnSfKfbz\nhaecXGkO3/xDW/3HqL+qaWlAAfdDjG96v8UDJ6D3eIwmKPZedft6ai1wE43oNlax\nA5JmPqpZN2mZXloL8J/CUQ==\n-----END PRIVATE KEY-----\n",
      "client_email":
          "firebase-adminsdk-fbsvc@agribooking-9f958.iam.gserviceaccount.com",
      "token_uri": "https://oauth2.googleapis.com/token",
    });

    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
    final authClient =
        await clientViaServiceAccount(accountCredentials, scopes);

    final url = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/agribooking-9f958/messages:send');

    final message = {
      "message": {
        "topic": "user_$contractorMid",
        "notification": {
          "title": "แจ้งยกเลิกการจอง",
          "body": "มีการขอยกเลิกการจองหมายเลข $rsid",
        },
        "data": {
          "click_action": "FLUTTER_NOTIFICATION_CLICK",
          "rsid": rsid.toString(),
        }
      }
    };

    final response = await authClient.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(message),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ส่งแจ้งเตือนสำเร็จ")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ส่งแจ้งเตือนล้มเหลว: ${response.body}")),
      );
    }

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

        // แยกเป็น 2 กลุ่ม
        final current =
            data.where((item) => item['progress_status'] != 4).toList();
        final finished =
            data.where((item) => item['progress_status'] == 4).toList();

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

  String formatDateThai(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      DateTime utcDate = DateTime.parse(dateStr);
      DateTime localDate = utcDate.toUtc().add(const Duration(hours: 7));
      final formatter = DateFormat("d MMM yyyy 'เวลา' HH:mm", "th_TH");
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

  Widget buildList(List<dynamic> list) {
    if (list.isEmpty) {
      return const Center(child: Text('ไม่พบข้อมูลการจอง'));
    }

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final rs = list[index];
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
                  'midผู้รับจ้าง: ${rs['mid_contractor'] ?? '-'}',
                ),
                Text(
                    'พื้นที่: ${rs['area_amount'] ?? '-'} ${rs['unit_area'] ?? '-'}'),
                Text('รายละเอียด: ${rs['detail'] ?? '-'}'),
                Text(
                  'สถานะ: ${progressStatusText(rs['progress_status'])}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                if (progressStatusText(rs['progress_status']) ==
                    "รอผู้รับจ้างยืนยันการจอง")
                  ElevatedButton(
                    onPressed: () {
                      final contractorMid = rs['mid_contractor'];
                      final rsid = rs['rsid'];

                      print("contractor_mid = $contractorMid");
                      print("rsid = $rsid");

                      if (contractorMid != null && rsid != null) {
                        sendCancelNotification(
                          contractorMid: contractorMid,
                          rsid: rsid,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text("ไม่พบข้อมูล contractor_mid หรือ rsid")),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("แจ้งยกเลิกการจอง"),
                  ),
                const SizedBox(height: 8),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.orange,
          title: const Text("แผนการจองรถของฉัน"),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: "งานที่จอง"),
              Tab(text: "ประวัติการจ้างงาน"),
            ],
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  buildList(reservings),
                  buildList(history),
                ],
              ),
      ),
    );
  }
}
