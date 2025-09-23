import 'dart:async';
import 'dart:convert';
import 'package:agri_booking2/pages/GenaralUser/tabbar.dart';
import 'package:agri_booking2/pages/contactor/DetailVehicle.dart';
import 'package:agri_booking2/pages/contactor/addvehcle.dart';
import 'package:agri_booking2/pages/editMem.dart';
import 'package:agri_booking2/pages/employer/Tabbar.dart';
import 'package:agri_booking2/pages/employer/addFarm3.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
  List<int> countReporter = [];
  late StreamController<List<dynamic>> _reviewStreamController;

  @override
  void initState() {
    super.initState();
    _memberDataFuture = fetchCon(widget.mid);
    _vehicleListFuture = fetchVehicles(widget.mid); // โหลดข้อมูลรถครั้งแรก
    _reviewFuture = fetchReviews(widget.mid);
    print(_reviewFuture);
    _currentMid = widget.mid; // ✅ ตั้งค่าก่อน
    _reviewStreamController = StreamController<List<dynamic>>.broadcast();

    // ✅ โหลดรีวิวแรก
    fetchReviews(widget.mid).then((reviews) {
      print("โหลดรีวิวครั้งแรก: $reviews"); // debug
      _reviewStreamController.add(reviews);
    });
    _startLongPolling();
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

  Future<void> updateVehicleStatus(int vid, int status) async {
    // 1️⃣ แสดง Dialog เพื่อถามผู้ใช้ก่อน
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Center(
            child: Text(
              'ยืนยันการเปลี่ยนสถานะ',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          content: Text(
            'คุณต้องการอัปเดตสถานะรถเป็น\n"${status == 1 ? 'ให้บริการ' : 'งดให้บริการ'}"\nสำหรับรถคันนี้ใช่หรือไม่?',
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
            const SizedBox(width: 12),
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

    // 2️⃣ ถ้าผู้ใช้กดยืนยัน ค่อยส่ง API
    if (confirm == true) {
      try {
        final url = Uri.parse(
            'http://projectnodejs.thammadalok.com/AGribooking/update_status_vehicle');
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

          Flushbar(
            title: 'สำเร็จ',
            message: status == 1 ? 'สถานะ: ให้บริการ' : 'สถานะ: งดให้บริการ',
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.green.shade600,
            flushbarPosition: FlushbarPosition.TOP,
            margin: const EdgeInsets.all(8),
            borderRadius: BorderRadius.circular(8),
            icon: const Icon(Icons.check_circle, color: Colors.white),
            shouldIconPulse: false,
            titleText: const Text(
              'สำเร็จ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            messageText: Text(
              status == 1 ? 'สถานะ:ให้บริการ' : 'สถานะ: งดให้บริการ',
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ).show(context);

          // โหลดข้อมูลรถใหม่
          setState(() {
            _vehicleListFuture = fetchVehicles(widget.mid);
          });
        } else {
          print(
            'Error updating status for VID: $vid. Status: ${response.statusCode}, Body: ${response.body}',
          );

          // แสดง Dialog แจ้งว่าปิดสถานะไม่ได้
          await showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'ไม่สามารถปิดให้บริการได้',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Image.network(
                      'https://symbl-cdn.com/i/webp/c1/d9d88630432cf61ad335df98ce37d6.webp',
                      height: 50,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'รถคันนี้ยังมีงานที่รอดำเนินการอยู่',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'กรุณาจัดการคิวงานให้เรียบร้อยก่อนจึงจะสามารถ "ปิดสถานะให้บริการ"ได้',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                actionsAlignment: MainAxisAlignment.center,
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'ตกลง',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
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
          title: const Center(
            child: Text(
              'ยืนยันการรายงาน',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.deepOrange,
              ),
            ),
          ),
          content: const Text(
            'คุณแน่ใจหรือไม่ว่าต้องการรายงานรีวิวนี้ว่าไม่เหมาะสม?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false), // ยกเลิก
              child: const Text(
                'ยกเลิก',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(width: 16),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true), // ยืนยัน
              child: const Text(
                'รายงาน',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.redAccent,
                ),
              ),
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
          Fluttertoast.showToast(
            msg: 'รายงานรีวิวเรียบร้อย',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.TOP,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0,
          );
          // รีเฟรชข้อมูลรีวิวเพื่ออัปเดต UI (ปุ่มรายงานจะหายไป)
          _reviewFuture = fetchReviews(_currentMid);
        } else {
          throw Exception('Failed to report review: ${response.body}');
        }
      } catch (e) {
        Fluttertoast.showToast(
          msg: 'เกิดข้อผิดพลาดในการรายงาน',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } finally {
        setState(() {
          isLoading = false; // ซ่อน loading indicator
        });
      }
    }
  }

  void _startLongPolling() async {
    while (mounted) {
      try {
        final url = Uri.parse(
            'http://projectnodejs.thammadalok.com/AGribooking/long-poll');
        final response = await http.get(url);
        if (response.statusCode == 200 && response.body.isNotEmpty) {
          final data = jsonDecode(response.body);
          print('Long poll data: $data'); // เพิ่มบรรทัดนี้
          // if (data['event'] == 'review_added' &&
          //     data['mid_reviewed'] == widget.mid) {
          //   final newReviews = await fetchReviews(widget.mid);
          //   print("รีวิวใหม่เข้ามา: $newReviews");
          //   _reviewStreamController.add(newReviews); // ✅ add เข้า stream
          // }
          setState(() {
            _reviewFuture = fetchReviews(widget.mid);
          });
        }
      } catch (e) {
        // อาจ log error ได้
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<List<dynamic>> fetchReviews(int mid) async {
    final url = Uri.parse(
        'http://projectnodejs.thammadalok.com/AGribooking/get_reviewed/$mid');
    print('Fetching reviews from URL: $url');

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
          print('Fetched review data: $data');

          // เรียงจาก rid มากไปน้อย (รีวิวล่าสุดไปรีวิวแรก)
          data.sort((a, b) => b['rid'].compareTo(a['rid']));

          return data;
        } else {
          print('API returned empty body for reviews.');
          return [];
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
        //backgroundColor: const Color.fromARGB(255, 255, 158, 60),
        appBar: AppBar(
          //backgroundColor: const Color.fromARGB(255, 255, 158, 60),
          backgroundColor: const Color.fromARGB(255, 18, 143, 9),
          centerTitle: true,
          automaticallyImplyLeading: false, // ✅ ลบปุ่มย้อนกลับ
          title: const Text(
            'ผู้รับจ้าง',
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

          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.menu, color: Colors.white),
              onSelected: (value) async {
                int currentMonth = DateTime.now().month;
                int currentYear = DateTime.now().year;

                if (value == 'edit') {
                  try {
                    final data = await fetchCon(widget.mid);
                    if (!context.mounted) return;

                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditMemberPage(memberData: data),
                      ),
                    );

                    // ✅ ถ้าหน้าแก้ไขส่ง true กลับมา ให้รีเฟรช
                    if (result == true) {
                      setState(() {
                        // โหลดข้อมูลใหม่
                        _memberDataFuture = fetchCon(widget.mid);
                      });
                    }
                  } catch (e) {
                    print('เกิดข้อผิดพลาดในการโหลดข้อมูลสมาชิก: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('ไม่สามารถโหลดข้อมูลสมาชิกได้')),
                    );
                  }
                } else if (value == 'mode') {
                  try {
                    final memberData = await fetchCon(widget.mid);
                    int currentType = memberData['type_member'];

                    if (!context.mounted) return;

                    // ถ้าเป็น type = 1 ให้ถามก่อนสมัคร
                    if (currentType != 3) {
                      bool? confirmChange = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: const Center(
                            child: Text(
                              'ยืนยันการสมัครสมาชิก',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.person_add_alt_1,
                                  color: Colors.deepPurple, size: 48),
                              SizedBox(height: 12),
                              Text(
                                'คุณต้องการสมัครสมาชิกเป็น "ผู้รับจ้าง" หรือไม่?',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          actionsAlignment: MainAxisAlignment.spaceEvenly,
                          actions: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                                foregroundColor: Colors.black,
                              ),
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('ยกเลิก'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('ตกลง'),
                            ),
                          ],
                        ),
                      );
                      if (confirmChange != true) return;
                    }

                    // อัปเดตเป็น type = 3
                    final response = await updateTypeMember(widget.mid, 3);
                    if (response['type_member'] == 3) {
                      Navigator.pushReplacement(
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
                    } else {
                      throw Exception('อัปเดตไม่สำเร็จ');
                    }
                  } catch (e) {
                    print('เกิดข้อผิดพลาดในการอัปเดต: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ไม่สามารถอัปเดตโหมดได้')),
                    );
                  }
                } else if (value == 'logout') {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const TabbarGenaralUser(value: 0)),
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
                PopupMenuItem(
                  value: 'mode',
                  child: FutureBuilder(
                    future: fetchCon(widget.mid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Row(
                          children: [
                            CircularProgressIndicator(strokeWidth: 2),
                            SizedBox(width: 8),
                            Text('กำลังโหลด...'),
                          ],
                        );
                      } else if (snapshot.hasError) {
                        return const Row(
                          children: [
                            Icon(Icons.error, color: Colors.red),
                            SizedBox(width: 8),
                            Text('เกิดข้อผิดพลาด'),
                          ],
                        );
                      } else {
                        final memberData =
                            snapshot.data as Map<String, dynamic>;
                        final type = memberData['type_member'];

                        return Row(
                          children: [
                            Icon(
                              type == 3 ? Icons.person : Icons.person_add,
                              color:
                                  type == 3 ? Colors.green : Colors.deepPurple,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              type == 3
                                  ? 'ไปโหมดผู้จ้าง'
                                  : 'สมัครเป็นผู้รับจ้าง',
                            ),
                          ],
                        );
                      }
                    },
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
                    color: const Color.fromARGB(255, 255, 255,
                        255), // สีพื้นอ่อนๆ เพื่อให้เห็นความนูนชัดเจน
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      // เงาสว่างด้านบนซ้าย
                      BoxShadow(
                        color: Color.fromARGB(209, 67, 66, 66),
                        offset: Offset(-4, -4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                      // เงามืดด้านล่างขวา
                      BoxShadow(
                        color: Color.fromARGB(209, 67, 66, 66),
                        offset: Offset(4, 4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.all(12),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
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
                              fontSize: 18,
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
                                      size: 20, color: Colors.blue),
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
                                  const Icon(Icons.chat,
                                      size: 20, color: Colors.deepOrange),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      (member['other'] != null &&
                                              member['other']
                                                  .toString()
                                                  .trim()
                                                  .isNotEmpty)
                                          ? member['other']
                                          : '-',
                                      softWrap: true,
                                    ),
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
                  ),
                );
              },
            ),

            Expanded(
              child: Column(
                children: [
                  // ✅ แถบแท็บนูนด้วย Card
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 6,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 8),
                        child: TabBar(
                          indicator: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                              colors: [
                                const Color.fromARGB(255, 190, 255, 189),
                                const Color.fromARGB(255, 37, 189, 35),
                                Colors.green[800]!,

                                // Color.fromARGB(255, 255, 244, 189)!,
                                // Color.fromARGB(255, 254, 187, 42)!,
                                // Color.fromARGB(255, 218, 140, 22)!,
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
                                width: 110,
                                child: Center(child: Text('รายการรถ')),
                              ),
                            ),
                            Tab(
                              child: SizedBox(
                                width: 110,
                                child: Center(child: Text('รีวิว')),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ✅ เนื้อหาภายในแต่ละแท็บ
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildVehicleTab(),
                        _buildReviewTab(),
                      ],
                    ),
                  ),
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
          //const SizedBox(height: 16),
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
            backgroundColor: const Color.fromARGB(255, 88, 196, 26),
            foregroundColor: const Color.fromARGB(255, 255, 255, 255),
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
                    // padding: const EdgeInsets.only(bottom: 25),
                    padding: const EdgeInsets.fromLTRB(
                        11, 0, 11, 25), // ซ้าย-ขวา-ล่าง
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        border: Border.all(color: Colors.orange),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange
                                .withOpacity(0.3), // เงาส้มอ่อนโปร่งใส
                            spreadRadius: 1,
                            blurRadius: 8,
                            offset: const Offset(0, 4), // เงาลงด้านล่างเล็กน้อย
                          ),
                        ],
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
                                    width: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                      height: 180,
                                      width: 120,
                                      color: Colors.grey[300],
                                      alignment: Alignment.center,
                                      child: const Icon(Icons.broken_image,
                                          size: 48),
                                    ),
                                  )
                                : Container(
                                    height: 180,
                                    width: 120,
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

                                // 🔹 รายละเอียดพร้อมไอคอน
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.description,
                                        size: 18, color: Colors.orange),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '${vehicle['detail']}',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 4),

                                // 🔹 ราคา พร้อมไอคอน
                                Row(
                                  children: [
                                    const Icon(Icons.attach_money,
                                        size: 18, color: Colors.green),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '${vehicle['price']} บาท/${vehicle['unit_price']}',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: Colors.green,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow
                                            .ellipsis, // ตัดเป็น ...
                                        maxLines: 1, // ให้แสดงแค่บรรทัดเดียว
                                        softWrap: false, // ไม่ตัดบรรทัด
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // ✅ ปุ่ม + สวิตช์ + สถานะด้านล่าง
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // 🔹 ปุ่มรายละเอียดเพิ่มเติมแบบนูน
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.white,
                                            offset: Offset(-2, -2),
                                            blurRadius: 4,
                                            spreadRadius: 1,
                                          ),
                                          BoxShadow(
                                            color: Colors.black26,
                                            offset: Offset(2, 2),
                                            blurRadius: 4,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          elevation: 0, // ปิดเงา ElevatedButton
                                          backgroundColor:
                                              const Color(0xFFF8A100),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 5, vertical: 5),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  Detailvehicle(vid: vid),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          'รายละเอียดเพิ่มเติม',
                                          style: GoogleFonts.mitr(
                                            fontSize: 12,
                                            fontWeight: FontWeight
                                                .w600, // ถ้าต้องการความหนา
                                            color: Colors
                                                .white, // ใช้สีเดียวกับ foregroundColor
                                          ),
                                        ),
                                      ),
                                    ),

                                    Column(
                                      children: [
                                        Transform.scale(
                                          scale:
                                              0.9, // ✅ ปรับขนาดเล็กลง (1.0 = ขนาดปกติ)
                                          child: Switch(
                                            value: currentStatus,
                                            onChanged: (bool newValue) {
                                              int newStatus = newValue ? 1 : 0;
                                              updateVehicleStatus(
                                                  vid, newStatus);
                                            },
                                            activeColor: Colors.white,
                                            activeTrackColor: Colors.green,
                                            inactiveThumbColor: Colors.white,
                                            inactiveTrackColor:
                                                Colors.red.shade200,
                                          ),
                                        ),
                                        // const SizedBox(height: 1),
                                        Text(
                                          currentStatus
                                              ? 'ให้บริการ'
                                              : 'งดให้บริการ',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: currentStatus
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        ),
                                      ],
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
      future: _reviewFuture, // ใช้ Future โดยตรง
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('ยังไม่มีรีวิว'));
        }

        final reviews = snapshot.data!;
        final points = reviews.map((r) => (r['point'] ?? 0) as num).toList();
        final avg = points.isNotEmpty
            ? (points.reduce((a, b) => a + b) / points.length)
                .toStringAsFixed(2)
            : '0.00';

        final reviewCount = reviews.length;

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: reviews.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'คะแนนรีวิว: $avg ($reviewCount รีวิว)',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
              );
            }

            final review = reviews[index - 1];
            final reportedList =
                jsonDecode(review['reporters'] ?? '[]') as List<dynamic>;
            final isReported = reportedList.contains(_currentMid);

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ดาว + คะแนน
                    Row(
                      children: [
                        const Icon(Icons.person, color: Colors.grey, size: 20),
                        const SizedBox(width: 6),
                        Row(
                          children: List.generate(5, (i) {
                            return Icon(
                              i < (review['point'] ?? 0)
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
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // ข้อความ
                    Text(
                      review['text'] ?? '-',
                      style: const TextStyle(fontSize: 16),
                    ),

                    const SizedBox(height: 8),

                    // วันที่
                    Text(
                      'วันที่รีวิว: ${review['date'].toString().substring(0, 10)}',
                      style: const TextStyle(color: Colors.grey),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('จำนวนรายงาน: ${reportedList.length} คน',
                            style: const TextStyle(color: Colors.grey)),
                      ],
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: isReported
                            ? null
                            : () => _reportReview(review['rid']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isReported ? Colors.grey : Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(isReported ? 'รายงานแล้ว' : 'รายงานรีวิว'),
                      ),
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
}
