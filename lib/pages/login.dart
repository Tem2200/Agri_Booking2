import 'dart:convert';
import 'package:agri_booking_app2/pages/contactor/home.dart';
import 'package:agri_booking_app2/pages/employer/homeEmp.dart';
import 'package:agri_booking_app2/pages/register.dart';
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
                title: const Text('เลือกหน้าที่ต้องการ'),
                content: const Text('กรุณาเลือกหน้าที่ต้องการไป'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // ปิด dialog
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => HomeEmpPage(mid: mid)),
                      );
                    },
                    child: const Text('ผู้จ้าง'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => HomePage(mid: mid)),
                      );
                    },
                    child: const Text('ผู้รับจ้าง'),
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
      appBar: AppBar(title: const Text('เข้าสู่ระบบ')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text('สวัสดี', style: TextStyle(fontSize: 24)),
                const SizedBox(height: 20),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'อีเมลหรือชื่อผู้ใช้',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'รหัสผ่าน',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 30),
                isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: isFormValid && !isLoading ? login : null,
                        child: const Text('เข้าสู่ระบบ'),
                      ),
                const SizedBox(height: 20),
                Text(message, style: const TextStyle(color: Colors.green)),
                const SizedBox(height: 30),
                isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Register(),
                            ),
                          );
                        },
                        child: const Text('สมัครสมาชิก'),
                      ),
                const SizedBox(height: 20),
                Text(message,
                    style: const TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255))),
              ],
            ),
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
