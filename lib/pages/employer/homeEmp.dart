import 'dart:convert';
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
      appBar: AppBar(
        title: const Text('Home Employee'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchCon(widget.mid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("เกิดข้อผิดพลาด: ${snapshot.error}"));
          }

          final member = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(member['image'] ?? ''),
                ),
                const SizedBox(height: 16),
                Text(
                  member['username'] ?? '-',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(member['email'] ?? '-'),
                const SizedBox(height: 8),
                Text("โทร: ${member['phone'] ?? '-'}"),
                const SizedBox(height: 8),
                // Text("ที่อยู่: ${member['detail_address'] ?? '-'}"),
                // const SizedBox(height: 8),
                // Text(
                //   "จังหวัด: ${member['province'] ?? '-'} อำเภอ: ${member['district'] ?? '-'} ตำบล: ${member['subdistrict'] ?? '-'}",
                // ),
                // const SizedBox(height: 8),
                // Text("Lat: ${member['latitude']}, Lng: ${member['longitude']}"),
                // const SizedBox(height: 8),
                // Text("ประเภทสมาชิก: ${member['type_member']}"),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FarmsPage(mid: widget.mid),
                      ),
                    );
                  },
                  child: const Text('ไปที่หน้า Farms'),
                ),
                FloatingActionButton.extended(
                  onPressed: () async {
                    try {
                      final data =
                          await fetchCon(widget.mid); // ✅ รอข้อมูลเสร็จ
                      if (!mounted) return;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditMemberPage(
                              memberData: data), // ✅ ส่งข้อมูลจริง
                        ),
                      );
                    } catch (e) {
                      print('เกิดข้อผิดพลาดในการโหลดข้อมูลสมาชิก: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('ไม่สามารถโหลดข้อมูลสมาชิกได้')),
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
                            builder: (context) => HomePage(mid: widget.mid),
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
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SearchEmp(mid: widget.mid),
                      ),
                    );
                  },
                  child: const Text('หน้าแรก'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
