import 'dart:convert';

import 'package:agri_booking2/pages/contactor/Tabbar.dart';
import 'package:agri_booking2/pages/contactor/home.dart';
import 'package:agri_booking2/pages/employer/Tabbar.dart';
import 'package:agri_booking2/pages/employer/homeEmp.dart';
import 'package:agri_booking2/pages/register.dart';
import 'package:flutter/material.dart';
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

        if (type == 3) {
          // แสดง pop-up ให้เลือก
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title:
                    const Text('ประเภทผู้ใช้งาน', textAlign: TextAlign.center),
                content: const Text(
                  'กรุณาเลือกประเภทผู้ใช้งานที่ต้องการเข้าสู่ระบบ',
                  textAlign: TextAlign.center,
                ),
                actionsPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                actions: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            minimumSize: Size.fromHeight(48),
                          ),
                          onPressed: () {
                            int currentMonth = DateTime.now().month;
                            int currentYear = DateTime.now().year;
                            Navigator.pop(context);
                            Navigator.push(
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
                          child: const Text('ผู้จ้าง'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            minimumSize: Size.fromHeight(48),
                          ),
                          onPressed: () {
                            int currentMonth = DateTime.now().month;
                            int currentYear = DateTime.now().year;

                            Navigator.pop(context);
                            Navigator.push(
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
                          child: const Text('ผู้รับจ้าง'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('ปิด'),
                    ),
                  ),
                ],
              );
            },
          );
        } else if (type == 1) {
          // ไปหน้า home_emp พร้อมส่ง mid
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeEmpPage(mid: mid)),
          );
        } else if (type == 2) {
          // ไปหน้า home พร้อมส่ง mid
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage(mid: mid)),
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
      backgroundColor: const Color(0xFFFFCC99), // สีพื้นหลังส้มอ่อน
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // โลโก้
              Image.asset('images/logo.png', height: 230),
              const SizedBox(height: 30),
              const Text(
                'เข้าสู่ระบบ',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3B3B3B),
                  fontFamily: 'Roboto',
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  hintText: 'ชื่อผู้ใช้ / อีเมล',
                  hintStyle: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 16,
                    fontFamily: 'Roboto',
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'รหัสผ่าน',
                  hintStyle: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 16,
                    fontFamily: 'Roboto',
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // เพิ่มฟังก์ชันลืมรหัสผ่าน
                    },
                    child: const Text(
                      'ลืมรหัสผ่าน',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Roboto',
                          ),
                        ),
                        onPressed: isFormValid ? login : null,
                        child: const Text('เข้าสู่ระบบ'),
                      ),
                    ),
              const SizedBox(height: 20),
              if (message.isNotEmpty)
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontFamily: 'Roboto',
                  ),
                ),
            ],
          ),
        ),
      ),
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
