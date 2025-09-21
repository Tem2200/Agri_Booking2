import 'dart:convert';
import 'package:agri_booking2/pages/employer/ProfileCon.dart';
import 'package:agri_booking2/pages/employer/plan_con.dart';
import 'package:agri_booking2/pages/employer/reservingForNF.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/painting.dart';
import 'package:intl/intl.dart';

class DetailvehcEmp extends StatefulWidget {
  final int vid;
  final int mid;
  final int fid;
  final dynamic farm;
  const DetailvehcEmp(
      {super.key,
      required this.vid,
      required this.mid,
      required this.fid,
      this.farm});

  @override
  State<DetailvehcEmp> createState() => _DetailvehcEmpState();
}

class _DetailvehcEmpState extends State<DetailvehcEmp> {
  Map<String, dynamic>? vehicleData;
  bool isLoading = true;
  String? error;
  late int _currentMid; // ตัวแปรสำหรับเก็บ mid
  Future<List<dynamic>>? _reviewFuture; // Future สำหรับข้อมูลรีวิว
  List<int> countReporter = [];
  bool _showAllReviews = false;
  @override
  void initState() {
    super.initState();
    fetchVehicleDetail();
    _startLongPolling();
  }

  void _startLongPolling() async {
    while (mounted) {
      try {
        final url = Uri.parse(
            'http://projectnodejs.thammadalok.com/AGribooking/long-poll');
        final response = await http.get(url);
        if (response.statusCode == 200 && response.body.isNotEmpty) {
          final data = jsonDecode(response.body);
          if (data['event'] == 'vehicle_added' ||
              data['event'] == 'vehicle_updated' ||
              data['event'] == 'review_added' ||
              data['event'] == 'review_updated') {
            // โหลดข้อมูลใหม่ (รีวิวและรายละเอียดรถ)
            fetchVehicleDetail();
          }
        }
      } catch (e) {
        await Future.delayed(const Duration(seconds: 2));
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
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
      print(widget.farm);
      final url = Uri.parse(
          'http://projectnodejs.thammadalok.com/AGribooking/get_vid/${widget.vid}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> dataList = jsonDecode(response.body);
        if (dataList.isNotEmpty) {
          setState(() {
            vehicleData = dataList[0]; // เอา element แรกเป็น map
            _currentMid = vehicleData!['mid'] ?? 0;
            isLoading = false;

            if (_currentMid != 0) {
              _reviewFuture = fetchReviews(_currentMid);
            } else {
              _reviewFuture = Future.value([]);
            }
          });
        } else {
          setState(() {
            error = 'ไม่พบข้อมูลรถ';
            isLoading = false;
            _reviewFuture = Future.value([]);
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
          this.countReporter = data
              .map<int>((review) {
                if (review['reporters'] != null &&
                    review['reporters'] is String) {
                  try {
                    final List<dynamic> reportersJson =
                        jsonDecode(review['reporters']);
                    return reportersJson.length;
                  } catch (e) {
                    print(
                        'Error parsing reporters JSON for review ${review['rid']}: $e');
                    return 0;
                  }
                }
                return 0;
              })
              .where((count) => count is int)
              .cast<int>()
              .toList();
          print('Fetched review data: $data'); // สำหรับ Debug
          print(
              'Count of reviews reported by current user ($_currentMid): $countReporter');
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

  Future<bool> _reportReview(int rid) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Center(
            child: Text(
              'ยืนยันการรายงาน',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.deepOrange,
              ),
            ),
          ),
          content: const Text(
            'คุณแน่ใจหรือไม่ว่าต้องการรายงานรีวิวนี้ว่าไม่เหมาะสม?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.4),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('ยกเลิก',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey)),
            ),
            const SizedBox(width: 16),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('รายงาน',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.redAccent)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return false; // ถ้าไม่ยืนยัน

    setState(() => isLoading = true);

    try {
      final url = Uri.parse(
          'http://projectnodejs.thammadalok.com/AGribooking/reporter');
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"rid": rid, "mid_reporter": this.widget.mid}),
      );

      if (response.statusCode == 200) {
        Fluttertoast.showToast(
          msg: 'รายงานรีวิวสำเร็จ!',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        _reviewFuture = fetchReviews(_currentMid); // รีเฟรชรีวิว
        return true; // คืนค่า success
      } else {
        throw Exception('Failed to report review: ${response.body}');
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'เกิดข้อผิดพลาดในการรายงาน: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return false;
    } finally {
      setState(() => isLoading = false);
    }
  }

// ปุ่มจองคิว
  final ButtonStyle bookingButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.blue,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    textStyle: GoogleFonts.mitr(
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
  );

  @override
  Widget build(BuildContext context) {
    // ✅ URL รูปภาพรถ
    String? displayImageUrl;
    if (vehicleData?['image_vehicle'] != null &&
        vehicleData!['image_vehicle'] is String &&
        (vehicleData!['image_vehicle'] as String).isNotEmpty) {
      final String imageUrlString = vehicleData!['image_vehicle'] as String;
      displayImageUrl =
          '$imageUrlString?t=${DateTime.now().millisecondsSinceEpoch}';
    }

    // ✅ URL รูปภาพสมาชิก (โปรไฟล์)
    String? memberImageUrl;
    if (vehicleData?['image_member'] != null &&
        vehicleData!['image_member'] is String &&
        (vehicleData!['image_member'] as String).isNotEmpty) {
      final String imageUrlString = vehicleData!['image_member'] as String;
      memberImageUrl =
          '$imageUrlString?t=${DateTime.now().millisecondsSinceEpoch}';
    }

    return Scaffold(
      appBar: AppBar(
        //title: Text(vehicleData?['name_vehicle'] ?? 'รายละเอียดรถ'),
        // backgroundColor: Color.fromARGB(255, 255, 158, 60),
        backgroundColor: const Color.fromARGB(255, 18, 143, 9),
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Colors.white, // ✅ ลูกศรย้อนกลับสีขาว
        ),
        title: const Text(
          'รายละเอียดรถ',
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
                      Center(
                        child: Text(
                          'ชื่อรถ: ${vehicleData?['name_vehicle'] ?? '-'}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),
                      const SizedBox(height: 8),
                      Text(
                          'ราคา: ${vehicleData?['price'] ?? '-'} / ${vehicleData?['unit_price'] ?? '-'}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          )),
                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black, // สีข้อความปกติของแอป
                          ),
                          children: [
                            const TextSpan(
                              text: 'รายละเอียด: ',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold), // ตัวหนา
                            ),
                            TextSpan(
                              text: vehicleData?['detail'] ?? '-',
                              style: const TextStyle(
                                  fontWeight: FontWeight.normal), // ตัวบาง
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black, // สีข้อความปกติของแอป
                          ),
                          children: [
                            const TextSpan(
                              text: 'ทะเบียนรถ: ',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold), // ตัวหนา
                            ),
                            TextSpan(
                              text: vehicleData?['plate_number'] ?? '-',
                              style: const TextStyle(
                                  fontWeight: FontWeight.normal), // ตัวบาง
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      const Divider(height: 32),

                      // --- ข้อมูลเจ้าของรถ ---
                      const Text(
                        'ข้อมูลเจ้าของรถ',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // รูปโปรไฟล์ (ด้านซ้าย)
                          if (memberImageUrl != null)
                            CircleAvatar(
                              radius: 20, // ลดขนาดลงเล็กน้อย
                              backgroundImage: NetworkImage(memberImageUrl),
                              backgroundColor: Colors.grey[300],
                            )
                          else
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.grey[300],
                              child: const Icon(Icons.person,
                                  size: 32, color: Colors.white),
                            ),

                          const SizedBox(
                              width: 12), // ระยะห่างระหว่างรูปกับชื่อ

                          // ชื่อผู้ใช้ (ขยายเต็มพื้นที่ที่เหลือ)
                          Expanded(
                            child: Text(
                              '${vehicleData?['username'] ?? '-'}',
                              style: const TextStyle(
                                  fontSize: 14), // ลดขนาดตัวหนังสือ
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          const SizedBox(width: 12), // ช่องว่างก่อนปุ่ม

                          // ปุ่มตารางงาน
                          ElevatedButton(
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
                                      mid_employer: widget.mid,
                                      vid: widget.vid,
                                      fid: widget.fid,
                                      farm: widget.farm,
                                      vihicleData: vehicleData,
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
                                  horizontal: 16, vertical: 8),
                              // ลดขนาดตัวหนังสือ
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              minimumSize:
                                  const Size(70, 36), // กำหนดขนาดปุ่มให้เล็กลง
                            ),
                            child: const Text('ตารางงาน'),
                          ),

                          const SizedBox(width: 5),
                          OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProfileCon(
                                    mid_con: _currentMid,
                                    mid_emp: widget.mid,
                                    farm: widget.farm,
                                  ),
                                ),
                              );
                            },
                            child: const Text('โปรไฟล์ผู้รับจ้าง'),
                          ), // ช่องว่างระหว่างปุ่ม
                        ],
                      ),

                      const SizedBox(height: 12),

                      //Text('ชื่อผู้ใช้: ${vehicleData?['username'] ?? '-'}'),
                      const SizedBox(height: 4),
                      // Text('อีเมล: ${vehicleData?['email'] ?? '-'}'),
                      // const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFFF8E1), // สีเหลืองอ่อนมาก (บน)
                              Color(0xFFFFD54F), // สีส้มอ่อน (ล่าง)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFFFC107), // ขอบสีส้มทอง
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.phone, color: Colors.black54),
                                const SizedBox(width: 8),
                                Text(
                                  'โทรศัพท์: ${vehicleData?['phone'] ?? '-'}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on,
                                    color: Colors.redAccent),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'ที่อยู่: ${vehicleData?['detail_address'] ?? '-'} ต.${vehicleData?['subdistrict'] ?? '-'} อ.${vehicleData?['district'] ?? '-'} จ.${vehicleData?['province'] ?? '-'}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      const Divider(height: 32),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                      'เกิดข้อผิดพลาดในการโหลดรีวิว: ${snapshot.error}'),
                                );
                              } else if (!snapshot.hasData ||
                                  snapshot.data!.isEmpty) {
                                return const Text(
                                  'รีวิว (ไม่มีข้อมูล)',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                );
                              }

                              final reviewList = snapshot.data!;
                              final totalPoints = reviewList.fold<num>(
                                0,
                                (sum, review) =>
                                    sum + ((review['point'] ?? 0) as num),
                              );
                              final average = (reviewList.isNotEmpty)
                                  ? (totalPoints / reviewList.length)
                                      .toStringAsFixed(2)
                                  : '0.00';
                              final totalReviews = reviewList.length;

                              // ✨ เพิ่มตัวแปรสถานะเพื่อจัดการการแสดงผล
                              final int displayCount = _showAllReviews
                                  ? totalReviews // ถ้า _showAllReviews เป็น true ให้แสดงทั้งหมด
                                  : (totalReviews > 3
                                      ? 3
                                      : totalReviews); // ถ้าเป็น false ให้แสดง 3 รีวิวแรก หรือทั้งหมดถ้ามีน้อยกว่า 3

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'รีวิว $average ($totalReviews รีวิว)',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // ✨ แก้ไข ListView.builder
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount:
                                        displayCount, // 👈 ใช้ตัวแปรที่แก้ไขแล้ว
                                    itemBuilder: (context, index) {
                                      final review = reviewList[index];
                                      List<int> reporters = [];
                                      if (review['reporters'] != null &&
                                          review['reporters'] is String) {
                                        try {
                                          final decoded =
                                              jsonDecode(review['reporters']);
                                          reporters = decoded
                                              .map<int>((e) =>
                                                  int.parse(e.toString()))
                                              .toList();
                                        } catch (e) {
                                          print(
                                              'Error parsing reporters JSON for review ${review['rid']}: $e');
                                        }
                                      }

                                      bool hasReported =
                                          reporters.contains(this.widget.mid);

                                      return Card(
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 4.0),
                                        elevation: 1.0,
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.person,
                                                    color: Colors.grey,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: List.generate(5,
                                                        (index) {
                                                      return Icon(
                                                        index <
                                                                (review['point'] ??
                                                                    0)
                                                            ? Icons.star
                                                            : Icons.star_border,
                                                        color: Colors.amber,
                                                        size: 20,
                                                      );
                                                    }),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    '${review['point'] ?? '-'} / 5',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                  'ข้อความ: ${review['text'] ?? '-'}'),
                                              if (review['image'] != null &&
                                                  review['image'].isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 8.0),
                                                  child: Image.network(
                                                    review['image'],
                                                    height: 100,
                                                    width: 100,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context,
                                                            error,
                                                            stackTrace) =>
                                                        const Icon(Icons
                                                            .image_not_supported),
                                                  ),
                                                ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'วันที่รีวิว: ${_formatReviewDate(review['date'])}',
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey),
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    'จำนวนคนรายงาน: ${reporters.length} คน',
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  const SizedBox(height: 4),
                                                  ElevatedButton(
                                                    onPressed: (isLoading ||
                                                            hasReported ||
                                                            _currentMid == 0)
                                                        ? null
                                                        : () async {
                                                            bool success =
                                                                await _reportReview(
                                                                    review[
                                                                        'rid']);
                                                            if (success) {
                                                              setState(() {
                                                                reporters.add(
                                                                    _currentMid);
                                                              });
                                                            }
                                                          },
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          hasReported
                                                              ? Colors.grey
                                                              : Colors.red,
                                                      foregroundColor:
                                                          Colors.white,
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 12,
                                                          vertical: 6),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      'รายงานรีวิว',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            color: Colors.white,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  // ✨ เพิ่มปุ่ม "ดูทั้งหมด" / "แสดงแบบย่อ" ถ้ามีรีวิวมากกว่า 3
                                  if (totalReviews > 3)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment
                                          .end, // ✨ เพิ่มบรรทัดนี้เพื่อจัดให้อยู่ขวาสุด
                                      children: [
                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              _showAllReviews =
                                                  !_showAllReviews; // สลับค่าสถานะ
                                            });
                                          },
                                          child: Text(
                                            _showAllReviews
                                                ? '▲ แสดงแบบย่อ'
                                                : '▼ ดูรีวิวทั้งหมด',
                                            style: const TextStyle(
                                              color: Colors.blue,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      )
                    ],
                  ),
                ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (widget.farm != null &&
                    widget.farm is Map &&
                    widget.farm.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReservingForNF(
                        mid: widget.mid,
                        vid: widget.vid,
                        fid: widget.fid,
                        farm: widget.farm,
                        vihicleData: vehicleData,
                      ),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReservingForNF(
                        mid: widget.mid,
                        vid: widget.vid,
                        vihicleData: vehicleData,
                      ),
                    ),
                  );
                }
              },
              style: bookingButtonStyle,
              child: const Text('จองคิวรถ'),
            ),
          ),
        ),
      ),
    );
  }
}
