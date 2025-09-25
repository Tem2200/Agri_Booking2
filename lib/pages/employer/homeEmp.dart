import 'dart:convert';
import 'package:agri_booking2/pages/GenaralUser/tabbar.dart';
import 'package:agri_booking2/pages/contactor/Tabbar.dart';
import 'package:agri_booking2/pages/contactor/home.dart';
import 'package:agri_booking2/pages/editMem.dart';
import 'package:agri_booking2/pages/employer/farms.dart';
import 'package:agri_booking2/pages/employer/search_emp.dart';
import 'package:agri_booking2/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HomeEmpPage extends StatefulWidget {
  final int mid;
  const HomeEmpPage({super.key, required this.mid});

  @override
  State<HomeEmpPage> createState() => _HomeEmpPageState();
}

class _HomeEmpPageState extends State<HomeEmpPage> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Home Employee'),
      // ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchCon(widget.mid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("เกิดข้อผิดพลาด: ${snapshot.error}"));
          }

          if (!snapshot.hasData) {
            return const Center(child: Text("ไม่พบข้อมูล"));
          }

          final member = snapshot.data!;

          return Stack(
            children: [
              // ส่วนหัวพื้นหลังโค้ง
              Container(
                width: double.infinity, // กว้างพอดีกับจอ
                height: MediaQuery.of(context).size.height *
                    0.40, // ประมาณ 35% ของจอ
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 18, 143, 9),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(40),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 70,
                      backgroundImage: NetworkImage(member['image'] ?? ''),
                    ),
                    const SizedBox(height: 10),
                    Text(
  member['username'] ?? '-',
  textAlign: TextAlign.center, // ✅
  style: const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w900,
    color: Colors.white,
    letterSpacing: 1.2,
    shadows: [
      Shadow(
        blurRadius: 3.0,
        color: Colors.black45,
        offset: Offset(1.5, 1.5),
      ),
    ],
  ),
),


                    const SizedBox(height: 4), // ระยะห่างเล็กน้อย
                    Text(
                      member['email'] ?? '-',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFFFF8E1), // สีขาวนวลตัดกับส้ม
                        letterSpacing: 0.5,
                        fontStyle: FontStyle.italic,
                        shadows: [
                          Shadow(
                            blurRadius: 2.0,
                            color: Colors.black26,
                            offset: Offset(1.0, 1.0),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4), // ระยะห่างเล็กน้อย
                    Text(
                      member['phone'] ?? '-',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFFFF8E1), // สีขาวนวลตัดกับส้ม
                        letterSpacing: 0.5,
                        fontStyle: FontStyle.italic,
                        shadows: [
                          Shadow(
                            blurRadius: 2.0,
                            color: Colors.black26,
                            offset: Offset(1.0, 1.0),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      height: MediaQuery.of(context).size.height *
                          0.45, // ปรับได้ตามต้องการ
                      child: Column(
                        children: [
                          const Text(
                            'ผู้จ้าง',
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFE65100), // ส้มเข้ม
                              letterSpacing: 1.2,
                              shadows: [
                                Shadow(
                                  blurRadius: 2.0,
                                  color: Colors.black26,
                                  offset: Offset(1.5, 1.5),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: GridView.count(
                              crossAxisCount: 2,
                              crossAxisSpacing: 5,
                              mainAxisSpacing: 5,
                              childAspectRatio: 1.3,
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    try {
                                      final data = await fetchCon(widget.mid);
                                      if (!context.mounted) return;
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              EditMemberPage(memberData: data),
                                        ),
                                      );
                                      // ✅ ถ้าหน้าแก้ไขส่ง true กลับมา ให้รีเฟรช
                                      if (result == true) {
                                        setState(() {
                                          // โหลดข้อมูลใหม่
                                          fetchCon(widget.mid);
                                        });
                                      }
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'ไม่สามารถโหลดข้อมูลสมาชิกได้'),
                                        ),
                                      );
                                    }
                                  },
                                  child: buildMenuItem(
                                    'https://cdn-icons-png.flaticon.com/512/7504/7504353.png',
                                    'แก้ไขข้อมูลส่วนตัว',
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            FarmsPage(mid: widget.mid),
                                      ),
                                    );
                                  },
                                  child: buildMenuItem(
                                    'https://cdn-icons-png.flaticon.com/512/854/854878.png',
                                    'ไร่นาของฉัน',
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    // เคลียร์ SharedPreferences
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    await prefs
                                        .clear(); // ลบ mid และ type_member
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const TabbarGenaralUser(
                                                  value: 0)),
                                      (route) => false,
                                    );
                                  },
                                  child: buildMenuItem(
                                    'https://cdn-icons-png.flaticon.com/512/4400/4400828.png',
                                    'ออกจากระบบ',
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    int currentMonth = DateTime.now().month;
                                    int currentYear = DateTime.now().year;

                                    try {
                                      // ดึงข้อมูลสมาชิกปัจจุบัน
                                      final memberData =
                                          await fetchCon(widget.mid);
                                      int currentType =
                                          memberData['type_member'];

                                      // ถ้ายังไม่เป็นทั้งสอง (ยังไม่สมัครเป็นผู้รับจ้าง)
                                      if (currentType != 3) {
                                        String currentRoleText =
                                            currentType == 2
                                                ? 'ผู้จ้าง'
                                                : 'สมาชิกทั่วไป';
                                        String targetRoleText = currentType == 2
                                            ? 'ทั้งผู้รับจ้างและผู้จ้าง'
                                            : 'ผู้รับจ้าง';

                                        bool? confirmChange =
                                            await showDialog<bool>(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
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
                                              children: [
                                                const Icon(
                                                  Icons.person_add_alt_1,
                                                  color: Colors.deepPurple,
                                                  size: 48,
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  'ตอนนี้คุณเป็น "$currentRoleText"\n'
                                                  'คุณต้องการสมัครเป็น "$targetRoleText" หรือไม่?',
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                      fontSize: 16),
                                                ),
                                              ],
                                            ),
                                            actionsAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            actions: [
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.grey[300],
                                                  foregroundColor: Colors.black,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 20,
                                                      vertical: 12),
                                                ),
                                                onPressed: () => Navigator.pop(
                                                    context, false),
                                                child: const Text('ยกเลิก'),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.deepPurple,
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 20,
                                                      vertical: 12),
                                                ),
                                                onPressed: () => Navigator.pop(
                                                    context, true),
                                                child: const Text('ตกลง'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirmChange != true) {
                                          return; // ถ้าไม่ตกลงก็หยุด
                                        }

                                        // อัปเดตเป็นโหมดทั้งสอง (3)
                                        final response = await updateTypeMember(
                                            widget.mid, 3);

                                        if (response['type_member'] == 3 &&
                                            context.mounted) {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => TabbarCar(
                                                mid: widget.mid,
                                                value: 2,
                                                month: currentMonth,
                                                year: currentYear,
                                              ),
                                            ),
                                          );
                                        }
                                      } else {
                                        // ถ้าเป็นทั้งสองแล้ว ไปหน้าโหมดผู้รับจ้างเลย
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => TabbarCar(
                                              mid: widget.mid,
                                              value: 2,
                                              month: currentMonth,
                                              year: currentYear,
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'ไม่สามารถอัปเดตโหมดผู้รับจ้างได้'),
                                        ),
                                      );
                                    }
                                  },
                                  child: FutureBuilder(
                                    future: fetchCon(widget.mid),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const CircularProgressIndicator();
                                      }

                                      if (snapshot.hasError ||
                                          !snapshot.hasData) {
                                        return buildMenuItem(
                                          'https://cdn-icons-png.flaticon.com/512/2911/2911161.png',
                                          'ไปโหมดผู้รับจ้าง',
                                        );
                                      }

                                      int type = snapshot.data!['type_member'];

                                      // ถ้ายังไม่เป็นทั้งสอง → แสดงปุ่มสมัคร
                                      if (type != 3) {
                                        return buildMenuItem(
                                          'https://cdn-icons-png.flaticon.com/128/14608/14608081.png', // ไอคอนสมัครสมาชิก
                                          'สมัครเป็นผู้รับจ้าง',
                                        );
                                      }

                                      // ถ้าเป็นทั้งสองแล้ว → ไปโหมดผู้รับจ้าง
                                      return buildMenuItem(
                                        'https://cdn-icons-png.flaticon.com/512/2911/2911161.png',
                                        'ไปโหมดผู้รับจ้าง',
                                      );
                                    },
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildMenuItem(String iconUrl, String label, {double iconSize = 50}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.network(
          iconUrl,
          width: iconSize,
          height: iconSize,
          fit: BoxFit.contain, // ให้รูปพอดีกรอบ
        ),
        const SizedBox(height: 10),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}
