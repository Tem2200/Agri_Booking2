import 'dart:convert';
import 'package:agri_booking2/pages/contactor/DetailVehicle.dart';
import 'package:agri_booking2/pages/contactor/DetailWork.dart';
import 'package:agri_booking2/pages/contactor/PlanAndHistory.dart';
import 'package:agri_booking2/pages/contactor/addvehcle.dart';
import 'package:agri_booking2/pages/contactor/con_plan.dart';
import 'package:agri_booking2/pages/contactor/nonti.dart';
import 'package:agri_booking2/pages/editMem.dart';
import 'package:agri_booking2/pages/employer/homeEmp.dart';
import 'package:agri_booking2/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

//defjrogtgt
class HomePage extends StatefulWidget {
  final int mid;
  const HomePage({super.key, required this.mid});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<Map<String, dynamic>>? _memberDataFuture;
  // เพิ่ม Future สำหรับข้อมูลรถ เพื่อให้สามารถเรียก fetchVehicles ใหม่ได้ง่ายขึ้น
  Future<List<dynamic>>? _vehicleListFuture;
  Future<List<dynamic>>? _reviewFuture; // Future สำหรับข้อมูลรีวิว
  bool isLoading = true;
  late int _currentMid;
  String? error;
  @override
  void initState() {
    super.initState();
    _memberDataFuture = fetchCon(widget.mid);
    _vehicleListFuture = fetchVehicles(widget.mid); // โหลดข้อมูลรถครั้งแรก
    _reviewFuture = fetchReviews(widget.mid);
    print(_reviewFuture);
    _currentMid = widget.mid; // ✅ ตั้งค่าก่อน
  }

  // --- ฟังก์ชันสำหรับดึงข้อมูลรถ ---
  Future<List<dynamic>> fetchVehicles(int mid) async {
    final url = Uri.parse(
        'http://projectnodejs.thammadalok.com/AGribooking/get_vehicle/$mid');
    final response = await http.get(url);
    print(response.body);
    if (response.statusCode == 200) {
      if (response.body.isNotEmpty) {
        return jsonDecode(response.body);
      }
      return [];
    } else {
      print("Error fetching vehicles: ${response.statusCode}");
      return [];
    }
  }

  // --- ฟังก์ชันสำหรับดึงข้อมูลสมาชิก ---
  Future<Map<String, dynamic>> fetchCon(int mid) async {
    final url_con = Uri.parse(
        'http://projectnodejs.thammadalok.com/AGribooking/members/$mid');
    final response = await http.get(url_con);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("ข้อมูลสมาชิก: $data");
      return data;
    } else {
      throw Exception('ไม่พบข้อมูลสมาชิก');
    }
  }

  // --- เพิ่มฟังก์ชันสำหรับอัปเดตสถานะรถ ---
  Future<void> updateVehicleStatus(int vid, int status) async {
    final url = Uri.parse(
        'http://projectnodejs.thammadalok.com/AGribooking/update_status_vehicle');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'vid': vid,
          'status_vehicle': status,
        }),
      );

      if (response.statusCode == 200) {
        print('อัปเดตสถานะรถ VID: $vid เป็นสถานะ: $status สำเร็จ');

        await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('สำเร็จ'),
              content: Text(
                'อัปเดตสถานะรถสำเร็จ: ${status == 1 ? 'พร้อมใช้งาน' : 'ไม่พร้อม'}',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('ตกลง'),
                ),
              ],
            );
          },
        );

        // โหลดข้อมูลรถใหม่
        setState(() {
          _vehicleListFuture = fetchVehicles(widget.mid);
        });
      } else {
        print(
          'Error updating status for VID: $vid. Status: ${response.statusCode}, Body: ${response.body}',
        );

        await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('เกิดข้อผิดพลาด'),
              content: Text('อัปเดตสถานะไม่สำเร็จ: ${response.body}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('ปิด'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print('Error sending update request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อ: $e')),
      );
    }
  }

  Future<Map<String, dynamic>> updateTypeMember(int mid, int typeMember) async {
    final url = Uri.parse(
        'http://projectnodejs.thammadalok.com/AGribooking/update_typeMem');

    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mid': mid,
        'type_member': typeMember,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('การอัปเดตล้มเหลว: ${response.statusCode}');
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // 2 แท็บ: รายการรถ และ รีวิว
      child: Scaffold(
        backgroundColor: const Color(0xFFFFCC99),
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 255, 187, 119),
          centerTitle: true,
          automaticallyImplyLeading: false, // ✅ ลบปุ่มย้อนกลับ
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.menu, color: Colors.black87),
              onSelected: (value) async {
                if (value == 'edit') {
                  try {
                    final data = await fetchCon(widget.mid);
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditMemberPage(memberData: data),
                      ),
                    );
                  } catch (e) {
                    print('เกิดข้อผิดพลาดในการโหลดข้อมูลสมาชิก: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('ไม่สามารถโหลดข้อมูลสมาชิกได้')),
                    );
                  }
                } else if (value == 'mode') {
                  try {
                    final response = await updateTypeMember(widget.mid, 3);
                    if (response['type_member'] == 3) {
                      if (!context.mounted) return;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomeEmpPage(mid: widget.mid),
                        ),
                      );
                    } else {
                      throw Exception('อัปเดตไม่สำเร็จ');
                    }
                  } catch (e) {
                    print('เกิดข้อผิดพลาดในการอัปเดต: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('ไม่สามารถอัปเดตโหมดผู้รับจ้างได้')),
                    );
                  }
                } else if (value == 'logout') {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const Login()),
                    (route) => false,
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('แก้ไขข้อมูลส่วนตัว'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'mode',
                  child: Row(
                    children: [
                      Icon(Icons.work, color: Colors.green),
                      SizedBox(width: 8),
                      Text('โหมดผู้รับจ้าง'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text('ออกจากระบบ'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            // 🔹 FutureBuilder: แสดงข้อมูลผู้รับจ้าง
            FutureBuilder<Map<String, dynamic>>(
              future: _memberDataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  );
                } else if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
                  );
                } else if (!snapshot.hasData || snapshot.data == null) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('ไม่พบข้อมูลสมาชิก'),
                  );
                }

                final member = snapshot.data!;
                return Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.all(12),
                    title: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center, // ✅ จัดให้อยู่ตรงกลางแนวนอน
                      children: [
                        ClipOval(
                          child: Image.network(
                            member['image'] ?? '',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.person, size: 48),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          member['username'] ?? '-',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.phone,
                                    size: 20, color: Colors.green),
                                const SizedBox(width: 6),
                                Text(member['phone'] ?? '-'),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.email,
                                    size: 20, color: Colors.redAccent),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(member['email'] ?? '-',
                                      softWrap: true),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on,
                                    size: 20, color: Colors.orange),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'ที่อยู่: ${member['detail_address'] ?? '-'} ต.${member['subdistrict'] ?? '-'} อ.${member['district'] ?? '-'} จ.${member['province'] ?? '-'}',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // 🔹 TabBar ใต้ข้อมูลผู้รับจ้าง
            const TabBar(
              labelColor: Colors.black,
              indicatorColor: Colors.orange,
              tabs: [
                Tab(text: 'รายการรถ'),
                Tab(text: 'รีวิว'),
              ],
            ),

            // 🔹 TabBarView อยู่ใน Expanded เพื่อให้ scroll ได้
            Expanded(
              child: TabBarView(
                children: [
                  _buildVehicleTab(), // รายการรถ
                  _buildReviewTab(), // รีวิว
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ปุ่มเพิ่มรถ
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddVehicle(mid: widget.mid),
                ),
              );
            },
            icon: const Icon(Icons.add, size: 14), // ไอคอนเล็กลง
            label: const Text(
              'เพิ่มรถ',
              style: TextStyle(fontSize: 14), // ตัวหนังสือเล็กลง
            ),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            tooltip: 'เพิ่มรถ',
            materialTapTargetSize:
                MaterialTapTargetSize.shrinkWrap, // ลดพื้นที่รอบปุ่ม
          ),

          const SizedBox(height: 20),

          // รายการรถ
          FutureBuilder<List<dynamic>>(
            future: _vehicleListFuture,
            builder: (context, snapshot) {
              // ... โค้ดแสดงรายการรถ ...

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return const Center(
                    child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูลรถ'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                    child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('ไม่พบข้อมูลรถ', style: TextStyle(fontSize: 16)),
                ));
              }

              final vehicles = snapshot.data!;
              return Column(
                children: vehicles.map<Widget>((vehicle) {
                  bool currentStatus = (vehicle['status_vehicle'] == 1);
                  int vid = vehicle['vid'];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        border: Border.all(color: Colors.orange),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ✅ รูปภาพทางซ้าย
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: vehicle['image'] != null &&
                                    vehicle['image'].toString().isNotEmpty
                                ? Image.network(
                                    vehicle['image'],
                                    height: 180,
                                    width: 140,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                      height: 180,
                                      width: 140,
                                      color: Colors.grey[300],
                                      alignment: Alignment.center,
                                      child: const Icon(Icons.broken_image,
                                          size: 48),
                                    ),
                                  )
                                : Container(
                                    height: 180,
                                    width: 140,
                                    color: Colors.grey[200],
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.image_not_supported,
                                        size: 48),
                                  ),
                          ),

                          const SizedBox(width: 12),

                          // ✅ ข้อมูลทางขวา
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize:
                                  MainAxisSize.min, // ขนาดพอดีกับเนื้อหา
                              children: [
                                Text(
                                  vehicle['name_vehicle'] ?? 'ไม่มีชื่อรถ',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                    'ราคา: ${vehicle['price']} / ${vehicle['unit_price']}'),
                                Text('รายละเอียด: ${vehicle['detail']}'),
                                Text(
                                    'ทะเบียน: ${vehicle['plate_number'] ?? 'ไม่มีข้อมูล'}'),
                                const SizedBox(height: 12),

                                // ✅ สถานะรถ
                                Row(
                                  children: [
                                    const Text('สถานะรถ:'),
                                    const SizedBox(width: 8),
                                    Text(
                                      currentStatus
                                          ? 'พร้อมใช้งาน'
                                          : 'ไม่พร้อม',
                                      style: TextStyle(
                                        color: currentStatus
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Switch(
                                  value: currentStatus,
                                  onChanged: (bool newValue) {
                                    int newStatus = newValue ? 1 : 0;
                                    updateVehicleStatus(vid, newStatus);
                                  },
                                ),

                                const SizedBox(height: 12),

                                // ✅ ปุ่มอยู่ล่าง
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      textStyle: const TextStyle(fontSize: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('รายละเอียดเพิ่มเติม'),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              Detailvehicle(vid: vid),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReviewTab() {
    return FutureBuilder<List<dynamic>>(
      future: _reviewFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('ยังไม่มีรีวิว'));
        }

        final reviews = snapshot.data!;
        final points = reviews.map((r) => (r['point'] ?? 0) as num).toList();
        final avg = points.isNotEmpty
            ? (points.reduce((a, b) => a + b) / points.length)
                .toStringAsFixed(2)
            : '0.00';

        final reviewCount = reviews.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Text(
                'คะแนนรีวิว: $avg ($reviewCount รีวิว)',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E7D32),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: reviews.length,
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  final reportedList =
                      jsonDecode(review['reporters'] ?? '[]') as List<dynamic>;
                  final isReported = reportedList.contains(_currentMid);

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // รูปภาพรีวิว (ถ้ามี)
                          if (review['image_url'] != null &&
                              review['image_url'].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Image.network(
                                review['image_url'],
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Text('โหลดรูปไม่สำเร็จ'),
                              ),
                            ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.person, // ไอคอนไม่ระบุตัวตน
                                color: Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(
                                  width: 6), // ช่องว่างระหว่างไอคอนกับดาว
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(5, (index) {
                                  return Icon(
                                    index < (review['point'] ?? 0)
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
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          // ข้อความรีวิว
                          Text(
                            review['text'] ?? '-',
                            style: const TextStyle(fontSize: 16),
                          ),

                          const SizedBox(height: 6),
                          if (review['image'] != null &&
                              review['image'].isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Image.network(
                                review['image'],
                                height: 100,
                                width: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.image_not_supported),
                              ),
                            ),
                          // คะแนน และ วันที่
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              //Text('คะแนน: ${review['point'] ?? '-'}'),
                              Text(
                                  'วันที่รีวิว: ${review['date'].toString().substring(0, 10)}'),
                            ],
                          ),

                          // ปุ่มรายงาน (หรือปุ่มถูกปิด)
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: isReported
                                  ? null
                                  : () => _reportReview(review['rid']),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isReported
                                    ? Colors.grey
                                    : Colors.red, // สีตามสถานะ
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                textStyle: const TextStyle(fontSize: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                  isReported ? 'รายงานแล้ว' : 'รายงานรีวิว'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
