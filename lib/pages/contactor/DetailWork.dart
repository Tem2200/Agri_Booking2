import 'dart:convert';
import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailWorkPage extends StatefulWidget {
  final int rsid;
  const DetailWorkPage({super.key, required this.rsid});
  @override
  State<DetailWorkPage> createState() => _DetailWorkPageState();
}

class _DetailWorkPageState extends State<DetailWorkPage> {
  Map<String, dynamic>? data;
  int? progress_status; // อนุญาตให้เป็น null
  List<LatLng> _routePoints = [];
  double? _distanceInKm;

  @override
  void initState() {
    super.initState();
    fetchDetail();
  }

  Future<void> fetchDetail() async {
    final url = Uri.parse(
        'http://projectnodejs.thammadalok.com/AGribooking/get_DetailReserving/${widget.rsid}');
    final response = await http.get(url);
    print(response);
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      setState(() {
        data = jsonList.first;
        progress_status = data!['progress_status'];
      });

      // โหลดเส้นทางจริงจาก ORS
      try {
        final route = await getRouteFromORS(
          data!['contractor_latitude'],
          data!['contractor_longitude'],
          data!['latitude'],
          data!['longitude'],
        );
        setState(() {
          _routePoints = route;
        });
      } catch (e) {
        print('Error loading route: $e');
        // กรณีล้มเหลวจะยังแสดงเส้นตรงแบบเดิมหรือไม่แสดงเส้นก็ได้
      }
    }
  }

  // Widget buildButtons() {
  //   if (progress_status == null) {
  //     // progress_status == null ให้แสดงปุ่มยกเลิกและยืนยัน
  //     return Row(
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: [
  //         ElevatedButton(
  //           onPressed: () => _updateProgress(0), // ยกเลิก
  //           style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
  //           child: const Text('ยกเลิก'),
  //         ),
  //         const SizedBox(width: 20),
  //         ElevatedButton(
  //           onPressed: () => _updateProgress(1), // ยืนยัน
  //           style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
  //           child: const Text('ยืนยัน'),
  //         ),
  //       ],
  //     );
  //   }
  //   // กรณีอื่นๆ เช่น status อื่นๆ คุณสามารถเพิ่มปุ่มอื่นๆได้ที่นี่
  //   else if (progress_status == 1 ||
  //       progress_status == 2 ||
  //       progress_status == 3) {
  //     // แสดงปุ่มสถานะขั้นตอนถัดไป
  //     return Wrap(
  //       spacing: 8,
  //       children: [
  //         ElevatedButton(
  //           onPressed: () => _updateProgress(2),
  //           child: const Text('กำลังเดินทาง'),
  //         ),
  //         ElevatedButton(
  //           onPressed: () => _updateProgress(3),
  //           child: const Text('กำลังทำงาน'),
  //         ),
  //         ElevatedButton(
  //           onPressed: () => _updateProgress(4),
  //           child: const Text('ทำงานเสร็จเรียบร้อย'),
  //         ),
  //       ],
  //     );
  //   } else {
  //     // กรณีอื่นๆ ถ้ามี สามารถปรับเพิ่มได้
  //     return const Text('ทำงานเสร็จเรียบร้อย');
  //   }
  // }

//สถานะของปุ่ม
  Widget buildButtons() {
    if (progress_status == null) {
      // ยังไม่มีสถานะ → แสดงปุ่มยกเลิก และ ยืนยัน
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () => _updateProgress(0),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('ยกเลิก'),
          ),
          const SizedBox(width: 20),
          ElevatedButton(
            onPressed: () => _updateProgress(1),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('ยืนยัน'),
          ),
        ],
      );
    }

    // ถ้ามีสถานะแล้ว (1-3) → แสดงปุ่มต่อเนื่อง
    else if (progress_status == 1 ||
        progress_status == 2 ||
        progress_status == 3) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _statusButton(2, 'กำลังเดินทาง'),
            const SizedBox(width: 8),
            _statusButton(3, 'กำลังทำงาน'),
            const SizedBox(width: 8),
            _statusButton(4, 'เสร็จสิ้น'),
          ],
        ),
      );
    } else {
      // กรณีสถานะเป็น 0 (ยกเลิก) หรือ 4 (เสร็จ)
      return Text(
        progress_status == 0
            ? 'สถานะ: ยกเลิกแล้ว'
            : 'สถานะ: ทำงานเสร็จเรียบร้อย',
        style: const TextStyle(fontWeight: FontWeight.bold),
      );
    }
  }

  //สีของสถานะล่าสุดที่เลือก
  Widget _statusButton(int statusValue, String label) {
    final bool isSelected = progress_status == statusValue;

    return ElevatedButton(
      onPressed: () => _updateProgress(statusValue),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.green : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black87,
      ),
      child: Text(label),
    );
  }

  Future<void> _updateProgress(int newStatus) async {
    // ยืนยันก่อนส่ง
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        // แปลงสถานะตัวเลขเป็นข้อความ
        String getStatusText(int status) {
          switch (status) {
            case 2:
              return 'กำลังเดินทางมา';
            case 3:
              return 'กำลังทำงาน';
            case 4:
              return 'ทำงานเสร็จเรียบร้อย';
            default:
              return 'สถานะไม่รู้จัก ($status)';
          }
        }

        return AlertDialog(
          title: const Center(
            child: Text(
              'ยืนยันการเปลี่ยนสถานะ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.indigo, // สีหัวข้อสวยๆ
                letterSpacing: 1, // ระยะห่างตัวอักษร
              ),
            ),
          ),
          content: Text(
            'คุณต้องการเปลี่ยนสถานะเป็น "${getStatusText(newStatus)}" ใช่หรือไม่?',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'ยกเลิก',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.redAccent,
                ),
              ),
            ),
            SizedBox(width: 50),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'ยืนยัน',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final url = Uri.parse(
        'http://projectnodejs.thammadalok.com/AGribooking/update_progress');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'rsid': widget.rsid, 'progress_status': newStatus}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        Flushbar(
          message: data['message'] ?? 'อัปเดตสถานะสำเร็จ',
          icon: const Icon(Icons.check_circle, color: Colors.white),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.green,
          margin: const EdgeInsets.all(16),
          borderRadius: BorderRadius.circular(12),
          flushbarPosition: FlushbarPosition.TOP, // ⭐ แสดงด้านบน
          animationDuration: const Duration(milliseconds: 500),
          messageSize: 16,
        ).show(context);

        // รีโหลดข้อมูล หรือรีเฟรชหน้า
        await fetchDetail(); // เรียกโหลดข้อมูลใหม่
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('อัปเดตสถานะล้มเหลว')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  Future<List<LatLng>> getRouteFromORS(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) async {
    final apiKey =
        'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6ImMyOWE5ZDkxMmUyZDQzMDc4ODNlZWQ0MjQzZDQ2NTk1IiwiaCI6Im11cm11cjY0In0='; // <-- ใส่ API Key ของคุณที่นี่
    final url = Uri.parse(
      'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$apiKey&start=$startLng,$startLat&end=$endLng,$endLat',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // 📍 เก็บระยะทางจาก response (เป็นเมตร)
      final distanceMeters =
          data['features'][0]['properties']['segments'][0]['distance'];
      setState(() {
        _distanceInKm = (distanceMeters / 1000); // แปลงเป็นกิโลเมตร
      });

      // 📍 สร้างเส้นทาง
      List coords = data['features'][0]['geometry']['coordinates'];
      return coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
    } else {
      throw Exception('Failed to load route from ORS');
    }
  }

  void _openInGoogleMaps(double lat, double lng) async {
    final Uri url =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถเปิด Google Maps ได้')),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFFFCC99),
        title: const Text('รายละเอียดงาน'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // กลับหน้าก่อนหน้า
          },
        ),
      ),
      body: data == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // 🗺 แผนที่ด้านหลัง
                FlutterMap(
                  options: MapOptions(
                    center: LatLng(data!['latitude'], data!['longitude']),
                    zoom: 14,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: ['a', 'b', 'c'],
                      userAgentPackageName: 'com.example.yourapp',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(data!['contractor_latitude'],
                              data!['contractor_longitude']),
                          width: 40, // ต้องกำหนดความกว้าง
                          height: 40, // และความสูง
                          child: Icon(Icons.location_on, color: Colors.green),
                        ),
                        Marker(
                          point: LatLng(data!['latitude'], data!['longitude']),
                          width: 40, // ต้องกำหนดความกว้าง
                          height: 40, // และความสูง
                          child: Icon(Icons.location_on, color: Colors.green),
                        ),
                      ],
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _routePoints.isNotEmpty
                              ? _routePoints
                              : [
                                  LatLng(data!['contractor_latitude'],
                                      data!['contractor_longitude']),
                                  LatLng(data!['latitude'], data!['longitude']),
                                ],
                          strokeWidth: 4,
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: () {
                      _openInGoogleMaps(data!['latitude'], data!['longitude']);
                    },
                    backgroundColor: Colors.blue,
                    child: const Icon(Icons.map),
                    tooltip: 'เปิด Google Maps',
                  ),
                ),
                // 📄 แผ่นข้อมูลแบบเลื่อน
                if (_distanceInKm != null)
                  Text(
                      'ระยะทางโดยประมาณ: ${_distanceInKm!.toStringAsFixed(2)} กม.'),

                //ข้อมูลการจอง
                DraggableScrollableSheet(
                  initialChildSize: 0.4,
                  minChildSize: 0.2,
                  maxChildSize: 0.85,
                  builder: (context, scrollController) {
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
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, -3),
                          )
                        ],
                      ),
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                width: 40,
                                height: 5,
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: Colors.grey[400],
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                            //สถานะการดำเนินงาน
                            Align(
                              alignment: Alignment.centerRight,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.circle,
                                    color: getStatusColor(
                                        data!['progress_status']),
                                    size: 10,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    getStatusText(data!['progress_status']),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: getStatusColor(
                                          data!['progress_status']),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ส่วน Center -> Column
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // ชื่องาน + สถานะรถ (แสดงในแถวเดียว)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      // ชื่องาน
                                      Text(
                                        data!['name_rs'] ?? 'ไม่ระบุชื่อการจอง',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                    ],
                                  ),

                                  const SizedBox(height: 10),

                                  // รูปรถ
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: data!['image'] != null &&
                                            data!['image'].toString().isNotEmpty
                                        ? Image.network(
                                            data!['image'],
                                            height: 140,
                                            width: 140,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Container(
                                              height: 140,
                                              width: 140,
                                              color: Colors.grey[300],
                                              alignment: Alignment.center,
                                              child: const Icon(
                                                  Icons.broken_image,
                                                  size: 48),
                                            ),
                                          )
                                        : Container(
                                            height: 140,
                                            width: 140,
                                            color: Colors.grey[200],
                                            alignment: Alignment.center,
                                            child: const Icon(
                                                Icons.image_not_supported,
                                                size: 48),
                                          ),
                                  ),
                                  Text(
                                    'รถ: ${data!['name_vehicle']}',
                                  ),
                                  Text(
                                    'ทะเบียนรถ: ${data!['plate_number'] != null && data!['plate_number'].toString().isNotEmpty ? data!['plate_number'] : 'ไม่มี'}',
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 10),
                            Row(
                              children: [
                                // รูปผู้จ้างหรือไอคอน
                                data!['employee_image'] != null &&
                                        data!['employee_image'] != ''
                                    ? CircleAvatar(
                                        radius: 25,
                                        backgroundImage: NetworkImage(
                                            data!['employee_image']),
                                        backgroundColor: const Color.fromARGB(
                                            255, 238, 238, 238),
                                      )
                                    : const CircleAvatar(
                                        radius: 25,
                                        backgroundColor: Colors.amber,
                                        child: Icon(
                                          Icons.person,
                                          size: 30,
                                          color: Colors.white,
                                        ),
                                      ),

                                const SizedBox(width: 8),

                                // ชื่อผู้จ้าง
                                Text(
                                  data!['employee_username'] ?? '-',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const Spacer(),

                                // ปุ่มข้อมูลผู้จ้าง
                                ElevatedButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // รูปภาพในกรอบวงกลม
                                              CircleAvatar(
                                                radius: 50,
                                                backgroundImage: (data![
                                                                'employee_image'] !=
                                                            null &&
                                                        data!['employee_image'] !=
                                                            '')
                                                    ? NetworkImage(
                                                        data!['employee_image'])
                                                    : null,
                                                backgroundColor:
                                                    Colors.grey[300],
                                                child: (data!['employee_image'] ==
                                                            null ||
                                                        data!['employee_image'] ==
                                                            '')
                                                    ? const Icon(Icons.person,
                                                        size: 50,
                                                        color: Colors.white)
                                                    : null,
                                              ),
                                              const SizedBox(height: 16),

                                              // ชื่อ
                                              Text(
                                                data!['employee_username'] ??
                                                    'ไม่พบชื่อ',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 8),

                                              // เบอร์โทร
                                              Text(
                                                data!['employee_phone'] ??
                                                    'ไม่พบเบอร์โทร',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                              const SizedBox(height: 20),

                                              // ปุ่มปิด
                                              ElevatedButton.icon(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                //icon: const Icon(Icons.close),
                                                label: const Text("ปิด"),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Color.fromARGB(
                                                          255, 255, 203, 82),
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                    foregroundColor: Colors.black87,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    textStyle: const TextStyle(fontSize: 14),
                                  ),
                                  child: const Text('ข้อมูลผู้จ้าง'),
                                ),
                              ],
                            ),

                            //วันที่และเวลาจ้างงาน
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.access_time, size: 16),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _formatDateRange(
                                      data!['date_start'],
                                      data!['date_end'],
                                    ),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 10),

                                // พื้นที่
                                Row(
                                  children: [
                                    const Icon(Icons.landscape,
                                        size: 18, color: Colors.green),
                                    const SizedBox(width: 8),
                                    Text(
                                      'พื้นที่: ${data!['area_amount']} ${data!['unit_area']}',
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),

                                // ฟาร์ม
                                Row(
                                  children: [
                                    const Icon(Icons.agriculture,
                                        size: 18, color: Colors.brown),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'ฟาร์ม: ${data!['name_farm']} (${data!['village']}, ${data!['subdistrict']})',
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),

                                // ที่อยู่
                                Row(
                                  children: [
                                    const Icon(Icons.location_on,
                                        size: 18, color: Colors.redAccent),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'ที่อยู่: ${data!['district']} จ.${data!['province']}',
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),

                                // เบอร์โทร
                                Row(
                                  children: [
                                    const Icon(Icons.phone,
                                        size: 18, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Text(
                                      'เบอร์โทร: ${data!['employee_phone']}',
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),

                                // ราคา
                                Row(
                                  children: [
                                    const Icon(Icons.attach_money,
                                        size: 18, color: Colors.orange),
                                    const SizedBox(width: 8),
                                    Text(
                                      'ราคา: ${data!['price']} ${data!['unit_price']}',
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // รายละเอียด
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.notes,
                                        size: 18, color: Colors.deepPurple),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'รายละเอียด: ${data!['detail']}',
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(
                              color: Colors.grey, // สีของเส้น
                              thickness: 1, // ความหนา
                              height: 20, // ความสูงของพื้นที่รอบเส้น
                            ),

                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                Text('กดปุ่มเพื่อเปลี่ยนสถานะการดำเนินงาน'),
                                buildButtons(),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}
