import 'dart:convert';
import 'package:agri_booking2/pages/contactor/Tabbar.dart';
import 'package:agri_booking2/pages/contactor/home.dart';
import 'package:agri_booking2/pages/editMem.dart';
import 'package:agri_booking2/pages/employer/farms.dart';
import 'package:agri_booking2/pages/employer/search_emp.dart';
import 'package:agri_booking2/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HomeEmpPage extends StatefulWidget {
  final int mid;
  const HomeEmpPage({super.key, required this.mid});

  @override
  State<HomeEmpPage> createState() => _HomeEmpPageState();
}

class _HomeEmpPageState extends State<HomeEmpPage> {
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
                    0.50, // ประมาณ 35% ของจอ
                decoration: const BoxDecoration(
                  color: Colors.orange,
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
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.1,
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    try {
                                      final data = await fetchCon(widget.mid);
                                      if (!context.mounted) return;
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              EditMemberPage(memberData: data),
                                        ),
                                      );
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
                                    'แก้ไขข้อมูลไร่',
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => const Login()),
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
                                      final response =
                                          await updateTypeMember(widget.mid, 3);
                                      if (response['type_member'] == 3 &&
                                          context.mounted) {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => TabbarCar(
                                              mid: widget.mid,
                                              value: 0,
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
                                  child: buildMenuItem(
                                    'https://cdn-icons-png.flaticon.com/512/2911/2911161.png',
                                    'สลับโหมดผู้ใช้',
                                  ),
                                ),
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

  Widget buildMenuItem(String iconUrl, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.network(iconUrl, width: 50, height: 50),
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
