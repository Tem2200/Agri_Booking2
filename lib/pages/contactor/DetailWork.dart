import 'dart:convert';
import 'package:agri_booking2/pages/contactor/Tabbar.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

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
  late IO.Socket socket;

  @override
  void initState() {
    super.initState();
    fetchDetail();
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final rsid = message.data["rsid"];
      if (rsid != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailWorkPage(rsid: int.parse(rsid)),
          ),
        );
      }
    });
    _pollProgress(); // เริ่ม long polling เมื่อ widget โหลด
    //_initSocket(); // 🔹 เรียก socket
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
        print(data);
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

//สถานะของปุ่ม
  Widget buildButtons(Map<String, dynamic> rs) {
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
    } else if (progress_status == 5) {
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        String getStatusText(int status) {
          switch (status) {
            case 1:
              return 'สถานะยืนยันการรับงาน';
            case 2:
              return 'กำลังเดินทางมา';
            case 3:
              return 'กำลังทำงาน';
            case 4:
              return 'ทำงานเสร็จเรียบร้อย';
            case 5:
              return 'รอผู้รับจ้างยกเลิกงาน';
            default:
              return 'สถานะยกเลิกการจอง';
          }
        }

        return AlertDialog(
          title: const Center(
            child: Text(
              'ยืนยันการเปลี่ยนสถานะ',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.indigo),
            ),
          ),
          content: Text(
            'คุณต้องการเปลี่ยนสถานะเป็น "${getStatusText(newStatus)}" ใช่หรือไม่?',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('ยกเลิก',
                  style: TextStyle(color: Colors.redAccent)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child:
                  const Text('ยืนยัน', style: TextStyle(color: Colors.green)),
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
        setState(() {
          progress_status = newStatus;
        });

        await fetchDetail();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('อัปเดตสถานะสำเร็จ')),
        );
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

  Future<void> _pollProgress() async {
    final url =
        Uri.parse('http://projectnodejs.thammadalok.com/AGribooking/long-poll');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['event'] == 'update_progress') {
          setState(() {
            progress_status = data['data']['progress_status'];
          });
        }
      }
    } catch (e) {
      print('❌ Long polling error: $e');
    } finally {
      // เรียกซ้ำเพื่อรอ event ใหม่
      Future.delayed(const Duration(milliseconds: 500), _pollProgress);
    }
  }

  Future<List<LatLng>> getRouteFromORS(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) async {
    const apiKey =
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
  String formatDateThai(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      DateTime utcDate = DateTime.parse(dateStr);
      DateTime localDate = utcDate.toUtc().add(const Duration(hours: 7));
      final formatter = DateFormat("d MMM yyyy 'เวลา' HH:mm น.", "th_TH");
      String formatted = formatter.format(localDate);
      // แปลงปี ค.ศ. → พ.ศ.
      String yearString = localDate.year.toString();
      String buddhistYear = (localDate.year + 543).toString();
      return formatted.replaceFirst(yearString, buddhistYear);
    } catch (e) {
      return '-';
    }
  }

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

      final formatter = DateFormat('dd/MM/yyyy เวลา HH:mm น.', "th_TH");

      String toBuddhistYearFormat(DateTime date) {
        String formatted = formatter.format(date);
        String yearString = date.year.toString();
        String buddhistYear = (date.year + 543).toString();
        return '${formatted.replaceFirst(yearString, buddhistYear)}  น.';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //backgroundColor: const Color.fromARGB(255, 255, 158, 60),
      appBar: AppBar(
        //backgroundColor: const Color(0xFF006000),
        backgroundColor: const Color.fromARGB(255, 18, 143, 9),
        //backgroundColor: const Color.fromARGB(255, 255, 158, 60),
        centerTitle: true,
        //automaticallyImplyLeading: false,
        title: const Text(
          'รายละเอียดงาน',
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
        leading: IconButton(
          color: Colors.white,
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
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
                    maxZoom: 18, // ✅ ป้องกันซูมเกิน
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.example.yourapp',
                    ),
                    //สัญลักษณ์ใหม่
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(data!['contractor_latitude'],
                              data!['contractor_longitude']),
                          width: 100,
                          height: 60,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'ผู้รับจ้าง',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              ),
                              const Icon(Icons.person_pin_circle,
                                  color: Colors.green, size: 32),
                            ],
                          ),
                        ),
                        Marker(
                          point: LatLng(data!['latitude'], data!['longitude']),
                          width: 100,
                          height: 60,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'ผู้จ้าง',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              ),
                              const Icon(Icons.person_pin_circle,
                                  color: Colors.orange, size: 32),
                            ],
                          ),
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

                //เข้าไปหน้าgoogle maps

                Positioned(
                  top: 16,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: () {
                      _openInGoogleMaps(data!['latitude'], data!['longitude']);
                    },
                    backgroundColor: Colors.blue,
                    tooltip: 'เปิด Google Maps',
                    child: const Icon(Icons.map),
                  ),
                ),
                // 📄 แผ่นข้อมูลแบบเลื่อน
                if (_distanceInKm != null)
                  Text(
                      'ระยะทางโดยประมาณ: ${_distanceInKm!.toStringAsFixed(2)} กม.'),

                //ข้อมูลการจอง
                DraggableScrollableSheet(
                  initialChildSize: 0.2, //ขนาดจอเมื่อเปิดมาครั้งแรก
                  minChildSize: 0.2, //ขนาดจอที่ย่อลงไปมากสุด
                  maxChildSize: 0.9, //ขนาดจอที่ดึงขึ้นได้มากสุด
                  builder: (context, scrollController) {
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
                        case '5':
                          return 'รอผู้รับจ้างยกเลิกงาน';
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
                          return const Color.fromARGB(255, 0, 169, 253);
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
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color.fromARGB(255, 255, 222, 122), // เหลืองเข้ม
                            Color.fromARGB(255, 255, 251, 236), // เหลืองอ่อน
                            Color.fromARGB(255, 253, 253, 252)
                          ],
                        ),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
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
                                      // ✅ ชื่องาน (แสดง 1 บรรทัด + ...)
                                      Expanded(
                                        child: Text(
                                          data!['name_rs'] ??
                                              'ไม่ระบุชื่อการจอง',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign
                                              .center, // ✅ ข้อความอยู่กลางในตัวมันเอง
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: Color(
                                                0xFF006400), // เขียวเข้ม ดูสุขุม
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // ✅ รูปรถ
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
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

                                  const SizedBox(height: 12),

                                  // ✅ ชื่อรถ
                                  Text(
                                    '🚗 รถ: ${data!['name_vehicle']}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),

                                  // ✅ ทะเบียนรถ
                                  Text(
                                    '📄 ทะเบียนรถ: ${data!['plate_number'] != null && data!['plate_number'].toString().isNotEmpty ? data!['plate_number'] : 'ไม่มี'}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black54,
                                      fontStyle: FontStyle.italic,
                                    ),
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
                                        backgroundColor:
                                            Color.fromARGB(255, 181, 115, 17),
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
                                              Text(
                                                data!['employee_email'] ??
                                                    'ไม่พบอีเมล',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                              const SizedBox(height: 20),
                                              Text(
                                                data!['employee_other'] ??
                                                    'ไม่พบช่องทางติดต่ออื่นๆ',
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
                                                      const Color.fromARGB(
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
                                  ),
                                  child: const Text('ข้อมูลผู้จ้าง'),
                                ),
                              ],
                            ),

                            // 📅 วันที่และเวลาจ้างงาน
                            const SizedBox(height: 16),
                            const Divider(
                              color: Colors.grey, // สีของเส้น
                              thickness: 1, // ความหนา
                              height: 20, // ความสูงของพื้นที่รอบเส้น
                            ),
                            Row(
                              children: [
                                const SizedBox(
                                  width: 70,
                                  child: Text(
                                    'เริ่มงาน:',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Text(
                                  formatDateThai(data![
                                      'date_start']), // ใช้ฟังก์ชันสำหรับวันเดียว
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const SizedBox(
                                  width: 70,
                                  child: Text(
                                    'สิ้นสุด:',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Text(
                                  formatDateThai(data![
                                      'date_end']), // ใช้ฟังก์ชันสำหรับวันเดียว
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                            const Divider(
                              color: Colors.grey, // สีของเส้น
                              thickness: 1, // ความหนา
                              height: 20, // ความสูงของพื้นที่รอบเส้น
                            ),
                            const SizedBox(height: 8),

                            // 📝 ข้อมูลเพิ่มเติม
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // พื้นที่
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.landscape,
                                        size: 18, color: Colors.green),
                                    const SizedBox(width: 8),
                                    const SizedBox(
                                      width: 45,
                                      child: Text(
                                        'พื้นที่:',
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '${data!['area_amount']} ${data!['unit_area']}',
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),

                                // ฟาร์ม
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.agriculture,
                                        size: 18, color: Colors.brown),
                                    const SizedBox(width: 8),
                                    const SizedBox(
                                      width: 45,
                                      child: Text(
                                        'ที่นา:',
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '${data!['name_farm']} (หมู่บ้าน${data!['village']} ต.${data!['subdistrict']} อ.${data!['district']} จ.${data!['province']})\n' +
                                            (data!['detail']?.isNotEmpty == true
                                                ? data!['detail']
                                                : ''),
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 6),

                                // ราคา
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.attach_money,
                                        size: 18, color: Colors.orange),
                                    const SizedBox(width: 8),
                                    const SizedBox(
                                      width: 45,
                                      child: Text(
                                        'ราคา:',
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '${data!['price']} ${data!['unit_price']}',
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // เบอร์โทร (ไม่มี SizedBox กว้าง)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.phone,
                                        size: 18, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'เบอร์โทร:',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${data!['employee_phone']}',
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.notes,
                                        size: 18, color: Colors.deepPurple),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text.rich(
                                        TextSpan(
                                          children: [
                                            const TextSpan(
                                              text: 'รายละเอียดงาน: ',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            TextSpan(
                                              text: data!['reserving_detail']
                                                          ?.isNotEmpty ==
                                                      true
                                                  ? data!['reserving_detail']
                                                  : 'ไม่มีรายละเอียด',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.normal,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                            const SizedBox(height: 8),
// 🔻 เส้นคั่น
                            const Divider(
                              color: Colors.grey,
                              thickness: 1,
                              height: 24,
                            ),

                            // 🔘 ปุ่มเปลี่ยนสถานะ
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                const Text(
                                  'กดปุ่มเพื่อเปลี่ยนสถานะการดำเนินงาน',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                                buildButtons(data!),
                              ],
                            ),
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
