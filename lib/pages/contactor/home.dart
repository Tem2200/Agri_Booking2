import 'dart:convert';
import 'package:agri_booking_app2/pages/contactor/DetailVehicle.dart';
import 'package:agri_booking_app2/pages/contactor/DetailWork.dart';
import 'package:agri_booking_app2/pages/contactor/PlanAndHistory.dart';
import 'package:agri_booking_app2/pages/contactor/addvehcle.dart';
import 'package:agri_booking_app2/pages/contactor/con_plan.dart';
import 'package:agri_booking_app2/pages/contactor/nonti.dart';
import 'package:agri_booking_app2/pages/editMem.dart';
import 'package:agri_booking_app2/pages/employer/homeEmp.dart';
import 'package:agri_booking_app2/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
  // ------------------------------------

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2, // มี 2 แท็บ: รายการรถ และ รีวิว
        child: Scaffold(
          appBar: AppBar(
            title: const Text('หน้าหลัก'),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'รายการรถ'),
                Tab(text: 'รีวิว'),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const Login()),
                    (route) => false,
                  );
                },
              )
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: TabBarView(
                  children: [
                    _buildVehicleTab(),
                    _buildReviewTab(),
                  ],
                ),
              ),

              // 🔽 ปุ่มที่ 1: ไปยังหน้า PlanPage พร้อมส่ง mid, month, year
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
                child: ElevatedButton.icon(
                  onPressed: () {
                    final now = DateTime.now();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlanAndHistory(
                          mid: widget.mid,
                          month: now.month,
                          year: now.year,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: const Text("งานทั้งหมด"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ),

              // 🔽 ปุ่มที่ 2: ไปยังหน้า NontiPage พร้อมส่ง mid
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NontiPage(mid: widget.mid),
                      ),
                    );
                  },
                  icon: const Icon(Icons.notifications),
                  label: const Text("ดูการแจ้งเตือน"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomePage(mid: widget.mid),
                      ),
                    );
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: const Text("ฉัน"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildVehicleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ส่วนแสดงข้อมูลเจ้าของ
          FutureBuilder<Map<String, dynamic>>(
            future: _memberDataFuture,
            builder: (context, snapshot) {
              // ... โค้ดของข้อมูลสมาชิกตามเดิม ...
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                );
              } else if (snapshot.hasError) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                      child: Text(
                          'ไม่สามารถโหลดข้อมูลสมาชิกได้: ${snapshot.error}')),
                );
              } else if (!snapshot.hasData || snapshot.data == null) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(child: Text('ไม่พบข้อมูลสมาชิก')),
                );
              }

              final member = snapshot.data!;
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  border: Border.all(color: Colors.blue),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    member['image'] != null &&
                            member['image'].toString().isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8)),
                            child: Image.network(
                              member['image'],
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
                        : Container(
                            height: 180,
                            color: Colors.grey[200],
                            alignment: Alignment.center,
                            child:
                                const Icon(Icons.image_not_supported, size: 48),
                          ),
                    const Text('ข้อมูลเจ้าของ',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('ชื่อผู้ใช้: ${member['username'] ?? '-'}'),
                    Text('โทรศัพท์: ${member['phone'] ?? '-'}'),
                    Text('อีเมล: ${member['email'] ?? '-'}'),
                    Text(
                        'ที่อยู่: ${member['detail_address'] ?? '-'} ต.${member['subdistrict']} อ.${member['district']} จ.${member['province']}'),
                  ],
                ),
              );
            },
          ),
          // ปุ่มเพิ่มรถ
          FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddVehicle(mid: widget.mid),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('เพิ่มรถ'),
            tooltip: 'เพิ่มรถ',
          ),

          FloatingActionButton.extended(
            onPressed: () async {
              try {
                final data = await fetchCon(widget.mid); // ✅ รอข้อมูลเสร็จ
                if (!mounted) return;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EditMemberPage(memberData: data), // ✅ ส่งข้อมูลจริง
                  ),
                );
              } catch (e) {
                print('เกิดข้อผิดพลาดในการโหลดข้อมูลสมาชิก: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ไม่สามารถโหลดข้อมูลสมาชิกได้')),
                );
              }
            },
            icon: const Icon(Icons.edit),
            label: const Text('แก้ไขข้อมูลส่วนตัว'),
            tooltip: 'แก้ไขข้อมูลส่วนตัว',
          ),

          FloatingActionButton.extended(
            onPressed: () async {
              try {
                // เรียก API เพื่ออัปเดต type_member
                final response = await updateTypeMember(widget.mid, 3);

                if (response['type_member'] == 3) {
                  if (!mounted) return;

                  // ไปหน้า HomeEmpPage ถ้าอัปเดตสำเร็จ
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
            },
            icon: const Icon(Icons.edit),
            label: const Text('โหมดผู้รับจ้าง'),
            tooltip: 'โหมดผู้รับจ้าง',
          ),

          const SizedBox(height: 16),
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
                  // ดึงค่าสถานะปัจจุบันของรถ
                  bool currentStatus = (vehicle['status_vehicle'] == 1);
                  int vid = vehicle['vid']; // ดึง vid ของรถ

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        border: Border.all(color: Colors.orange),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        // ใช้ Column เพื่อใส่ SwitchListTile และ ListTile
                        children: [
                          vehicle['image'] != null &&
                                  vehicle['image'].toString().isNotEmpty
                              ? ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(8)),
                                  child: Image.network(
                                    vehicle['image'],
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                      height: 180,
                                      color: Colors.grey[300],
                                      alignment: Alignment.center,
                                      child: const Icon(Icons.broken_image,
                                          size: 48),
                                    ),
                                  ),
                                )
                              : Container(
                                  height: 180,
                                  color: Colors.grey[200],
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.image_not_supported,
                                      size: 48),
                                ),
                          ListTile(
                            title:
                                Text(vehicle['name_vehicle'] ?? 'ไม่มีชื่อรถ'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'ราคา: ${vehicle['price']} / ${vehicle['unit_price']}'),
                                Text('รายละเอียด: ${vehicle['detail']}'),
                                Text(
                                    'ทะเบียน: ${vehicle['plate_number'] ?? 'ไม่มีข้อมูล'}'),
                              ],
                            ),
                            trailing: ElevatedButton(
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
                          // --- เพิ่ม SwitchListTile ที่นี่ ---
                          SwitchListTile(
                            title: const Text('สถานะรถ'),
                            subtitle: Text(
                              currentStatus ? 'พร้อมใช้งาน' : 'ไม่พร้อม',
                              style: TextStyle(
                                color:
                                    currentStatus ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            value: currentStatus,
                            onChanged: (bool newValue) {
                              // เมื่อสวิตช์ถูกเปลี่ยน ให้เรียกฟังก์ชันอัปเดตสถานะ
                              int newStatus = newValue ? 1 : 0;
                              updateVehicleStatus(vid, newStatus);
                            },
                          ),
                          // ------------------------------------
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
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final review = reviews[index];
            final reportedList =
                jsonDecode(review['reporters']) as List<dynamic>;
            final isReported = reportedList.contains(_currentMid);

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['text'],
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('คะแนน: ${review['point']}'),
                        Text(
                            'วันที่: ${review['date'].toString().substring(0, 10)}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (!isReported)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => _reportReview(review['rid']),
                          child: const Text('รายงานรีวิว'),
                        ),
                      )
                    else
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text('รายงานแล้ว',
                            style: TextStyle(color: Colors.grey)),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // return Scaffold(
  //   appBar: AppBar(
  //     title: const Text('หน้าหลัก'),
  //     actions: [
  //       IconButton(
  //         icon: const Icon(Icons.logout),
  //         onPressed: () {
  //           Navigator.pushAndRemoveUntil(
  //             context,
  //             MaterialPageRoute(builder: (context) => const Login()),
  //             (route) => false,
  //           );
  //         },
  //       )
  //     ],
  //   ),
  //   body: SingleChildScrollView(
  //     padding: const EdgeInsets.all(8),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         // 🔶 กล่องข้อมูลเจ้าของรถ (FutureBuilder สำหรับข้อมูลสมาชิก)
  //         FutureBuilder<Map<String, dynamic>>(
  //           future: _memberDataFuture,
  //           builder: (context, snapshot) {
  //             if (snapshot.connectionState == ConnectionState.waiting) {
  //               return Container(
  //                 padding: const EdgeInsets.all(12),
  //                 decoration: BoxDecoration(
  //                   color: Colors.blue[50],
  //                   border: Border.all(color: Colors.blue),
  //                   borderRadius: BorderRadius.circular(8),
  //                 ),
  //                 child: const Center(child: CircularProgressIndicator()),
  //               );
  //             } else if (snapshot.hasError) {
  //               return Container(
  //                 padding: const EdgeInsets.all(12),
  //                 decoration: BoxDecoration(
  //                   color: Colors.blue[50],
  //                   border: Border.all(color: Colors.blue),
  //                   borderRadius: BorderRadius.circular(8),
  //                 ),
  //                 child: Center(
  //                     child: Text(
  //                         'ไม่สามารถโหลดข้อมูลสมาชิกได้: ${snapshot.error}')),
  //               );
  //             } else if (!snapshot.hasData || snapshot.data == null) {
  //               return Container(
  //                 padding: const EdgeInsets.all(12),
  //                 decoration: BoxDecoration(
  //                   color: Colors.blue[50],
  //                   border: Border.all(color: Colors.blue),
  //                   borderRadius: BorderRadius.circular(8),
  //                 ),
  //                 child: const Center(child: Text('ไม่พบข้อมูลสมาชิก')),
  //               );
  //             }

  //             final member = snapshot.data!;
  //             return Container(
  //               padding: const EdgeInsets.all(12),
  //               decoration: BoxDecoration(
  //                 color: Colors.blue[50],
  //                 border: Border.all(color: Colors.blue),
  //                 borderRadius: BorderRadius.circular(8),
  //               ),
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   member['image'] != null &&
  //                           member['image'].toString().isNotEmpty
  //                       ? ClipRRect(
  //                           borderRadius: const BorderRadius.vertical(
  //                               top: Radius.circular(8)),
  //                           child: Image.network(
  //                             member['image'],
  //                             height: 180,
  //                             width: double.infinity,
  //                             fit: BoxFit.cover,
  //                             errorBuilder: (context, error, stackTrace) =>
  //                                 Container(
  //                               height: 180,
  //                               color: Colors.grey[300],
  //                               alignment: Alignment.center,
  //                               child:
  //                                   const Icon(Icons.broken_image, size: 48),
  //                             ),
  //                           ),
  //                         )
  //                       : Container(
  //                           height: 180,
  //                           color: Colors.grey[200],
  //                           alignment: Alignment.center,
  //                           child: const Icon(Icons.image_not_supported,
  //                               size: 48),
  //                         ),
  //                   const Text('ข้อมูลเจ้าของ',
  //                       style: TextStyle(
  //                           fontSize: 18, fontWeight: FontWeight.bold)),
  //                   const SizedBox(height: 8),
  //                   Text('ชื่อผู้ใช้: ${member['username'] ?? '-'}'),
  //                   Text('โทรศัพท์: ${member['phone'] ?? '-'}'),
  //                   Text('อีเมล: ${member['email'] ?? '-'}'),
  //                   Text(
  //                       'ที่อยู่: ${member['detail_address'] ?? '-'} ต.${member['subdistrict']} อ.${member['district']} จ.${member['province']}'),
  //                 ],
  //               ),
  //             );
  //           },
  //         ),
  //         FloatingActionButton.extended(
  //           onPressed: () {
  //             Navigator.push(
  //               context,
  //               MaterialPageRoute(
  //                 builder: (context) => AddVehicle(mid: widget.mid),
  //               ),
  //             );
  //           },
  //           icon: const Icon(Icons.add), // ถ้าไม่อยากได้ icon ก็ลบออกได้
  //           label: const Text('เพิ่มรถ'),
  //           tooltip: 'เพิ่มรถ',
  //         ),
  //         const SizedBox(height: 16),

  //         // 🔶 รายการรถ (FutureBuilder สำหรับข้อมูลรถ)
  //         FutureBuilder<List<dynamic>>(
  //           future:
  //               _vehicleListFuture, // ใช้ _vehicleListFuture ที่ประกาศไว้ใน State
  //           builder: (context, snapshot) {
  //             if (snapshot.connectionState == ConnectionState.waiting) {
  //               return const Center(child: CircularProgressIndicator());
  //             } else if (snapshot.hasError) {
  //               return const Center(
  //                   child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูลรถ'));
  //             } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
  //               return const Center(
  //                   child: Padding(
  //                 padding: EdgeInsets.all(20.0),
  //                 child:
  //                     Text('ไม่พบข้อมูลรถ', style: TextStyle(fontSize: 16)),
  //               ));
  //             }

  //             final vehicles = snapshot.data!;
  //             return Column(
  //               children: vehicles.map<Widget>((vehicle) {
  //                 // ดึงค่าสถานะปัจจุบันของรถ
  //                 bool currentStatus = (vehicle['status_vehicle'] == 1);
  //                 int vid = vehicle['vid']; // ดึง vid ของรถ

  //                 return Padding(
  //                   padding: const EdgeInsets.only(bottom: 12),
  //                   child: Container(
  //                     decoration: BoxDecoration(
  //                       color: Colors.orange[50],
  //                       border: Border.all(color: Colors.orange),
  //                       borderRadius: BorderRadius.circular(8),
  //                     ),
  //                     child: Column(
  //                       // ใช้ Column เพื่อใส่ SwitchListTile และ ListTile
  //                       children: [
  //                         vehicle['image'] != null &&
  //                                 vehicle['image'].toString().isNotEmpty
  //                             ? ClipRRect(
  //                                 borderRadius: const BorderRadius.vertical(
  //                                     top: Radius.circular(8)),
  //                                 child: Image.network(
  //                                   vehicle['image'],
  //                                   height: 180,
  //                                   width: double.infinity,
  //                                   fit: BoxFit.cover,
  //                                   errorBuilder:
  //                                       (context, error, stackTrace) =>
  //                                           Container(
  //                                     height: 180,
  //                                     color: Colors.grey[300],
  //                                     alignment: Alignment.center,
  //                                     child: const Icon(Icons.broken_image,
  //                                         size: 48),
  //                                   ),
  //                                 ),
  //                               )
  //                             : Container(
  //                                 height: 180,
  //                                 color: Colors.grey[200],
  //                                 alignment: Alignment.center,
  //                                 child: const Icon(Icons.image_not_supported,
  //                                     size: 48),
  //                               ),
  //                         ListTile(
  //                           title: Text(
  //                               vehicle['name_vehicle'] ?? 'ไม่มีชื่อรถ'),
  //                           subtitle: Column(
  //                             crossAxisAlignment: CrossAxisAlignment.start,
  //                             children: [
  //                               Text(
  //                                   'ราคา: ${vehicle['price']} / ${vehicle['unit_price']}'),
  //                               Text('รายละเอียด: ${vehicle['detail']}'),
  //                               Text(
  //                                   'ทะเบียน: ${vehicle['plate_number'] ?? 'ไม่มีข้อมูล'}'),
  //                             ],
  //                           ),
  //                           trailing: ElevatedButton(
  //                             child: const Text('รายละเอียดเพิ่มเติม'),
  //                             onPressed: () {
  //                               Navigator.push(
  //                                 context,
  //                                 MaterialPageRoute(
  //                                   builder: (context) =>
  //                                       Detailvehicle(vid: vid),
  //                                 ),
  //                               );
  //                             },
  //                           ),
  //                         ),
  //                         // --- เพิ่ม SwitchListTile ที่นี่ ---
  //                         SwitchListTile(
  //                           title: const Text('สถานะรถ'),
  //                           subtitle: Text(
  //                             currentStatus ? 'พร้อมใช้งาน' : 'ไม่พร้อม',
  //                             style: TextStyle(
  //                               color:
  //                                   currentStatus ? Colors.green : Colors.red,
  //                               fontWeight: FontWeight.bold,
  //                             ),
  //                           ),
  //                           value: currentStatus,
  //                           onChanged: (bool newValue) {
  //                             // เมื่อสวิตช์ถูกเปลี่ยน ให้เรียกฟังก์ชันอัปเดตสถานะ
  //                             int newStatus = newValue ? 1 : 0;
  //                             updateVehicleStatus(vid, newStatus);
  //                           },
  //                         ),
  //                         // ------------------------------------
  //                       ],
  //                     ),
  //                   ),
  //                 );
  //               }).toList(),
  //             );
  //           },
  //         ),
  //       ],
  //     ),
  //   ),
  // );
  // }
}
