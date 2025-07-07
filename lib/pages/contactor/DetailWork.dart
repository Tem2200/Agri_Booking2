import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
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

  Widget buildButtons() {
    if (progress_status == null) {
      // progress_status == null ให้แสดงปุ่มยกเลิกและยืนยัน
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () => _updateProgress(0), // ยกเลิก
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ยกเลิก'),
          ),
          const SizedBox(width: 20),
          ElevatedButton(
            onPressed: () => _updateProgress(1), // ยืนยัน
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('ยืนยัน'),
          ),
        ],
      );
    }
    // กรณีอื่นๆ เช่น status อื่นๆ คุณสามารถเพิ่มปุ่มอื่นๆได้ที่นี่
    else if (progress_status == 1 ||
        progress_status == 2 ||
        progress_status == 3) {
      // แสดงปุ่มสถานะขั้นตอนถัดไป
      return Wrap(
        spacing: 8,
        children: [
          ElevatedButton(
            onPressed: () => _updateProgress(2),
            child: const Text('กำลังเดินทาง'),
          ),
          ElevatedButton(
            onPressed: () => _updateProgress(3),
            child: const Text('กำลังทำงาน'),
          ),
          ElevatedButton(
            onPressed: () => _updateProgress(4),
            child: const Text('ทำงานเสร็จเรียบร้อย'),
          ),
        ],
      );
    } else {
      // กรณีอื่นๆ ถ้ามี สามารถปรับเพิ่มได้
      return const Text('ทำงานเสร็จเรียบร้อย');
    }
  }

  Future<void> _updateProgress(int newStatus) async {
    // ยืนยันก่อนส่ง
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ยืนยันการเปลี่ยนสถานะ'),
          content: Text('คุณต้องการเปลี่ยนสถานะเป็น $newStatus ใช่หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('ยืนยัน'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'อัปเดตสถานะสำเร็จ')),
        );
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

                DraggableScrollableSheet(
                  initialChildSize: 0.4,
                  minChildSize: 0.2,
                  maxChildSize: 0.85,
                  builder: (context, scrollController) {
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
                            Text(
                              data!['name_rs'] ?? 'ไม่ระบุชื่อการจอง',
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.person),
                                const SizedBox(width: 5),
                                Text(
                                  data!['employee_username'] ?? '-',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const Spacer(),
                                ElevatedButton(
                                  onPressed: () {
                                    // TODO: show more info
                                  },
                                  child: const Text('ข้อมูลผู้จ้าง'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'วันที่: ${data!['date_start']?.split("T").first ?? "-"} ถึง ${data!['date_end']?.split("T").first ?? "-"}',
                            ),
                            Text(
                              'พื้นที่: ${data!['area_amount']} ${data!['unit_area']}',
                            ),
                            Text(
                              'ฟาร์ม: ${data!['name_farm']} (${data!['village']}, ${data!['subdistrict']})',
                            ),
                            Text(
                              'ที่อยู่: ${data!['district']} จ.${data!['province']}',
                            ),
                            Text(
                                'ราคา: ${data!['price']} ${data!['unit_price']}'),
                            const SizedBox(height: 10),
                            Text('รายละเอียด: ${data!['detail']}'),
                            const SizedBox(height: 20),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
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
