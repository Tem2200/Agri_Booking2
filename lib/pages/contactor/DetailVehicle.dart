import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/painting.dart';
import 'package:intl/intl.dart';

// import หน้า EditVehicle และ Home (แก้ path ตามจริงของคุณ)
import 'editvehicle.dart';
import 'home.dart';
import 'con_plan.dart'; // แก้เป็น con_plan.dart ตามที่คุณอัปเดต

class Detailvehicle extends StatefulWidget {
  final int vid;
  const Detailvehicle({super.key, required this.vid});

  @override
  State<Detailvehicle> createState() => _DetailvehicleState();
}

class _DetailvehicleState extends State<Detailvehicle> {
  Map<String, dynamic>? vehicleData;
  bool isLoading = true;
  String? error;
  late int _currentMid; // ตัวแปรสำหรับเก็บ mid
  Future<List<dynamic>>? _reviewFuture; // Future สำหรับข้อมูลรีวิว

  @override
  void initState() {
    super.initState();
    fetchVehicleDetail();
  }

  Future<void> fetchVehicleDetail() async {
    setState(() {
      isLoading = true; // ตั้งสถานะว่ากำลังโหลด
      error = null; // ล้างข้อผิดพลาดเก่า
    });
    try {
      // --- ล้างแคชรูปภาพของ Flutter เพื่อบังคับโหลดใหม่ ---
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      // ----------------------------------------------------

      final url = Uri.parse(
          'http://projectnodejs.thammadalok.com/AGribooking/get_vid/${widget.vid}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          setState(() {
            vehicleData = data[0];
            // กำหนดค่า _currentMid เมื่อข้อมูลรถถูกโหลดสำเร็จ
            _currentMid = vehicleData!['mid'] ?? 0;
            isLoading = false;

            // หลังจากได้ _currentMid แล้ว ให้เรียก fetchReviews
            if (_currentMid != 0) {
              _reviewFuture = fetchReviews(_currentMid);
            } else {
              _reviewFuture =
                  Future.value([]); // ถ้า mid เป็น 0 ถือว่าไม่มีรีวิว
            }
          });
        } else {
          setState(() {
            error = 'ไม่พบข้อมูลรถ';
            isLoading = false;
            _reviewFuture = Future.value([]); // ถ้าไม่พบข้อมูลรถ ก็ไม่มีรีวิว
          });
        }
      } else {
        setState(() {
          error = 'โหลดข้อมูลรถล้มเหลว: ${response.statusCode}';
          isLoading = false;
          _reviewFuture = Future.error(
              'Failed to load vehicle data'); // แจ้ง error กับ review future ด้วย
        });
      }
    } catch (e) {
      setState(() {
        error = 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e';
        isLoading = false;
        _reviewFuture = Future.error(e); // แจ้ง error กับ review future ด้วย
      });
    }
  }

  // ฟังก์ชันสำหรับดึงข้อมูลรีวิว
  Future<List<dynamic>> fetchReviews(int mid) async {
    final url = Uri.parse(
        'http://projectnodejs.thammadalok.com/AGribooking/get_reviewed/$mid');
    print('Fetching reviews from URL: $url'); // สำหรับ Debug

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          final List data = jsonDecode(response.body);
          print('Fetched review data: $data'); // สำหรับ Debug
          return data;
        } else {
          print('API returned empty body for reviews.');
          return []; // คืนค่า list ว่างเปล่าถ้าไม่มีข้อมูล
        }
      } else {
        print(
            'Failed to load reviews. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load reviews: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching reviews: $e');
      throw Exception('Failed to connect to review server: $e');
    }
  }

  // ฟังก์ชันช่วยจัดรูปแบบวันที่สำหรับรีวิว
  String _formatReviewDate(String? dateString) {
    if (dateString == null) return '-';
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(dateTime); // ตัวอย่าง: 05/07/2025
    } catch (e) {
      return '-';
    }
  }

  // ฟังก์ชันสำหรับรายงานรีวิวไม่เหมาะสม
  Future<void> _reportReview(int rid) async {
    final int midReporter = _currentMid; // mid ของผู้ใช้ปัจจุบัน

    // แสดง AlertDialog เพื่อยืนยันการรายงาน
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('ยืนยันการรายงาน'),
          content: const Text(
              'คุณแน่ใจหรือไม่ว่าต้องการรายงานรีวิวนี้ว่าไม่เหมาะสม?'),
          actions: <Widget>[
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(false), // ผู้ใช้ยกเลิก
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(true), // ผู้ใช้ยืนยัน
              child: const Text('รายงาน'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() {
        isLoading = true; // แสดง loading indicator ขณะกำลังรายงาน
      });
      try {
        final url = Uri.parse(
            'http://projectnodejs.thammadalok.com/AGribooking/reporter');
        final response = await http.put(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "rid": rid,
            "mid_reporter": midReporter,
          }),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('รายงานรีวิวสำเร็จ!')),
          );
          // รีเฟรชข้อมูลรีวิวเพื่ออัปเดต UI (ปุ่มรายงานจะหายไป)
          _reviewFuture = fetchReviews(_currentMid);
        } else {
          throw Exception('Failed to report review: ${response.body}');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการรายงาน: $e')),
        );
      } finally {
        setState(() {
          isLoading = false; // ซ่อน loading indicator
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // สร้าง URL รูปภาพพร้อม cache-buster
    String? displayImageUrl;
    if (vehicleData?['image_vehicle'] != null &&
        vehicleData!['image_vehicle'] is String &&
        (vehicleData!['image_vehicle'] as String).isNotEmpty) {
      final String imageUrlString = vehicleData!['image_vehicle'] as String;
      displayImageUrl =
          '$imageUrlString?t=${DateTime.now().millisecondsSinceEpoch}';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(vehicleData?['name_vehicle'] ?? 'รายละเอียดรถ'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (vehicleData != null && _currentMid != 0) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => HomePage(mid: _currentMid),
                ),
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'แก้ไขรถ',
            onPressed: () async {
              if (vehicleData != null) {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditVehicle(
                      initialVehicleData: vehicleData,
                    ),
                  ),
                );

                if (result == true || result == null) {
                  fetchVehicleDetail(); // เรียก fetchVehicleDetail อีกครั้งเพื่อรีเฟรชข้อมูล
                }
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ส่วนแสดงรูปภาพรถ
                      if (displayImageUrl != null)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8)),
                          child: Image.network(
                            displayImageUrl,
                            key: ValueKey(displayImageUrl),
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              height: 180,
                              color: Colors.grey[300],
                              alignment: Alignment.center,
                              child: const Icon(Icons.broken_image, size: 48),
                            ),
                          ),
                        )
                      else
                        Container(
                          height: 180,
                          color: Colors.grey[200],
                          alignment: Alignment.center,
                          child:
                              const Icon(Icons.image_not_supported, size: 48),
                        ),
                      // --- รายละเอียดรถ ---
                      const SizedBox(height: 16),
                      Text('ชื่อรถ: ${vehicleData?['name_vehicle'] ?? '-'}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                          'ราคา: ${vehicleData?['price'] ?? '-'} / ${vehicleData?['unit_price'] ?? '-'}',
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('รายละเอียด: ${vehicleData?['detail'] ?? '-'}'),
                      const SizedBox(height: 8),
                      Text('ทะเบียนรถ: ${vehicleData?['plate_number'] ?? '-'}'),
                      const SizedBox(height: 8),
                      Text(
                        'สถานะ: ${vehicleData?['status_vehicle'] == 1 ? 'พร้อมใช้งาน' : 'ไม่พร้อม'}',
                        style: TextStyle(
                          color: vehicleData?['status_vehicle'] == 1
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: 32),
                      // --- ข้อมูลเจ้าของรถ ---
                      const Text('ข้อมูลเจ้าของรถ',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('ชื่อผู้ใช้: ${vehicleData?['username'] ?? '-'}'),
                      const SizedBox(height: 4),
                      Text('อีเมล: ${vehicleData?['email'] ?? '-'}'),
                      const SizedBox(height: 4),
                      Text('โทรศัพท์: ${vehicleData?['phone'] ?? '-'}'),
                      const SizedBox(height: 4),
                      Text(
                          'ที่อยู่: ${vehicleData?['detail_address'] ?? '-'} ต.${vehicleData?['subdistrict'] ?? '-'} อ.${vehicleData?['district'] ?? '-'} จ.${vehicleData?['province'] ?? '-'}'),
                      const SizedBox(height: 24),

                      // --- ปุ่มตารางงาน ---
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            if (vehicleData != null && _currentMid != 0) {
                              final now = DateTime.now();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PlanPage(
                                    mid: _currentMid,
                                    month: now.month,
                                    year: now.year,
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'ไม่สามารถเข้าถึงตารางงานได้ เนื่องจากข้อมูลยังไม่พร้อม'),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 15),
                            textStyle: const TextStyle(fontSize: 18),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            elevation: 5,
                          ),
                          child: const Text('ตารางงาน'),
                        ),
                      ),
                      const Divider(height: 32),

                      // --- ส่วนแสดงรีวิว ---
                      const Text('รีวิว',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      FutureBuilder<List<dynamic>>(
                        future: _reviewFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(
                                child: Text(
                                    'เกิดข้อผิดพลาดในการโหลดรีวิว: ${snapshot.error}'));
                          } else if (!snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return const Center(child: Text('ไม่มีรีวิว'));
                          }

                          final reviewList = snapshot.data!;
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: reviewList.length,
                            itemBuilder: (context, index) {
                              final review = reviewList[index];
                              List<int> reporters = [];
                              // ตรวจสอบและแปลง 'reporters' จาก String JSON เป็น List<int>
                              if (review['reporters'] != null &&
                                  review['reporters'] is String) {
                                try {
                                  reporters = List<int>.from(
                                      jsonDecode(review['reporters']));
                                } catch (e) {
                                  print(
                                      'Error parsing reporters JSON for review ${review['rid']}: $e');
                                }
                              }

                              // ตรวจสอบว่าผู้ใช้ปัจจุบันได้รายงานรีวิวนี้ไปแล้วหรือยัง
                              bool hasReported =
                                  reporters.contains(_currentMid);

                              return Card(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                elevation: 1.0,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'คะแนน: ${review['point'] ?? '-'} / 5',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: review['point'] == 5
                                              ? Colors.amber[700]
                                              : Colors.orange,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text('ข้อความ: ${review['text'] ?? '-'}'),
                                      const SizedBox(height: 4),
                                      Text(
                                        'วันที่รีวิว: ${_formatReviewDate(review['date'])}',
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      ),
                                      if (review['image'] != null &&
                                          review['image'].isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8.0),
                                          child: Image.network(
                                            review['image'],
                                            height: 100,
                                            width: 100,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error,
                                                    stackTrace) =>
                                                const Icon(
                                                    Icons.image_not_supported),
                                          ),
                                        ),
                                      // แสดงปุ่มรายงานรีวิวไม่เหมาะสม
                                      // ถ้าผู้ใช้ปัจจุบันยังไม่ได้รายงาน และ mid ของผู้ใช้ถูกต้อง (ไม่เป็น 0)
                                      if (!hasReported && _currentMid != 0)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8.0),
                                          child: Align(
                                            alignment: Alignment.bottomRight,
                                            child: ElevatedButton(
                                              onPressed: isLoading
                                                  ? null
                                                  : () => _reportReview(
                                                      review['rid']),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.red, // สีปุ่มรายงาน
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6),
                                                textStyle: const TextStyle(
                                                    fontSize: 14),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8)),
                                              ),
                                              child: const Text(
                                                  'รายงานรีวิวไม่เหมาะสม'),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
    );
  }
}
