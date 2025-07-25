import 'dart:convert';

import 'package:agri_booking2/pages/contactor/Tabbar.dart';
import 'package:agri_booking2/pages/contactor/home.dart';
import 'package:agri_booking2/pages/employer/Tabbar.dart';
import 'package:agri_booking2/pages/employer/homeEmp.dart';
import 'package:agri_booking2/pages/register.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:http/http.dart' as http;

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  String message = '';
  bool isFormValid = false;
  void initState() {
    super.initState();
    emailController.addListener(_validateForm);
    passwordController.addListener(_validateForm);
  }

  Future<void> login() async {
    setState(() {
      isLoading = true;
      message = '';
    });

    final url =
        Uri.parse('http://projectnodejs.thammadalok.com/AGribooking/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email_or_username': emailController.text,
          'password': passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final msg = data['message'];
        final user = data['user'];

        final int type = user['type_member'];
        final int mid = user['mid'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('mid', mid);
        await prefs.setInt('type_member', type);

        if (type == 3) {
          // แสดง pop-up ให้เลือก
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: const Text(
                  'ประเภทผู้ใช้งาน',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                ),
                content: const Text(
                  'กรุณาเลือกประเภทผู้ใช้งานที่ต้องการเข้าสู่ระบบ',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
                contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                actionsPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                actions: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0DA128),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          onPressed: () {
                            int currentMonth = DateTime.now().month;
                            int currentYear = DateTime.now().year;
                            Navigator.pop(context);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Tabbar(
                                  mid: mid,
                                  value: 0,
                                  month: currentMonth,
                                  year: currentYear,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'ผู้จ้าง',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0DA128),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          onPressed: () {
                            int currentMonth = DateTime.now().month;
                            int currentYear = DateTime.now().year;
                            Navigator.pop(context);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TabbarCar(
                                  mid: mid,
                                  value: 0,
                                  month: currentMonth,
                                  year: currentYear,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'ผู้รับจ้าง',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('ปิด'),
                    ),
                  ),
                ],
              );
            },
          );
        } else if (type == 1) {
          int currentMonth = DateTime.now().month;
          int currentYear = DateTime.now().year;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TabbarCar(
                mid: mid,
                value: 0,
                month: currentMonth,
                year: currentYear,
              ),
            ),
          );
        } else if (type == 2) {
          int currentMonth = DateTime.now().month;
          int currentYear = DateTime.now().year;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => Tabbar(
                mid: mid,
                value: 0,
                month: currentMonth,
                year: currentYear,
              ),
            ),
          );
        }

        setState(() {
          message = msg;
        });
      } else {
        setState(() {
          message = 'เข้าสู่ระบบล้มเหลว ข้อมูลผิดพลาด';
        });
      }
    } catch (e) {
      setState(() {
        message = 'เกิดข้อผิดพลาด: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _validateForm() {
    setState(() {
      isFormValid =
          emailController.text.isNotEmpty && passwordController.text.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // พื้นหลังภาพเต็มจอ
          Positioned.fill(
            child: Image.network(
              'https://i.ibb.co/nqF46GSm/Gemini-Generated-Image-xdz1e1xdz1e1xdz1-1.png',
              fit: BoxFit.cover,
            ),
          ),
          // เนื้อหาหลัก
          Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // โลโก้
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(
                          top: 40), // ขยับห่างจากขอบบนเล็กน้อย
                      child: Image.asset('images/logo.png', height: 200),
                    ),
                  ),

                  const Text(
                    'เข้าสู่ระบบ',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 25, 200, 13), // สีเขียวสด
                      fontFamily: 'Roboto',
                      shadows: [
                        Shadow(
                          offset: Offset(1.5, 1.5),
                          blurRadius: 3.0,
                          color: Color.fromARGB(221, 0, 0, 0),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // กรอบโปร่งรอบเฉพาะ input + ปุ่ม + ลิงก์
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 24, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            buildInnerShadowTextField(
                              controller: emailController,
                              label: 'ชื่อผู้ใช้ / อีเมล',
                            ),
                            const SizedBox(height: 16),
                            buildInnerShadowTextField(
                              controller: passwordController,
                              label: 'รหัสผ่าน',
                              obscureText: true,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor:
                                  WidgetStateProperty.resolveWith<Color>(
                                      (states) {
                                if (states.contains(MaterialState.disabled)) {
                                  return const Color.fromARGB(255, 7, 172,
                                      15); // สีเขียวอ่อนเวลาปุ่ม disable
                                }
                                return const Color.fromARGB(
                                    255, 7, 172, 15); // สีเขียวปกติ
                              }),
                              foregroundColor:
                                  WidgetStateProperty.all(Colors.white),
                              elevation: WidgetStateProperty.all(10),
                              shadowColor: WidgetStateProperty.all(
                                  const Color.fromARGB(255, 7, 172, 15)),
                              padding: WidgetStateProperty.all(
                                  const EdgeInsets.symmetric(vertical: 14)),
                              shape: WidgetStateProperty.all(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              textStyle: WidgetStateProperty.all(
                                const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                            ),
                            onPressed: isFormValid ? login : null,
                            child: const Text('เข้าสู่ระบบ'),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ลิงก์สมัครสมาชิกอยู่ข้างล่างสุดของกล่อง
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const Register()),
                            );
                          },
                          child: const Text(
                            'สมัครสมาชิก',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontStyle: FontStyle.italic,
                              color: Colors.black87,
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // แสดงข้อความผิดพลาด ถ้ามี
                  if (message.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInnerShadowTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
  }) {
    return Stack(
      children: [
        // Shadow layer
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color.fromARGB(255, 176, 171, 171),
                offset: Offset(-2, -2),
                blurRadius: 4,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Color.fromARGB(31, 87, 85, 85),
                offset: Offset(2, 2),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        // TextField layer
        TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              color: Colors.grey[700],
              fontSize: 16,
              fontFamily: 'Roboto',
            ),
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          ),
        ),
      ],
    );
  }
}

class FirstChoicePage extends StatelessWidget {
  final int mid;
  const FirstChoicePage({super.key, required this.mid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('หน้าแรก')),
      body: Center(child: Text('MID ของคุณคือ $mid')),
    );
  }
}

class SecondChoicePage extends StatelessWidget {
  final int mid;
  const SecondChoicePage({super.key, required this.mid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('หน้าที่สอง')),
      body: Center(child: Text('MID ของคุณคือ $mid')),
    );
  }
}
