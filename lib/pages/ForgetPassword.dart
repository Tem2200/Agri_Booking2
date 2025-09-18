import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:agri_booking2/pages/GenaralUser/tabbar.dart';
import 'package:agri_booking2/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

class Forgetpassword extends StatefulWidget {
  const Forgetpassword({super.key});

  @override
  State<Forgetpassword> createState() => _ForgetpasswordState();
}

class _ForgetpasswordState extends State<Forgetpassword> {
  int step = 1;
  final emailController = TextEditingController();
  String? emailError; // สำหรับข้อความผิดพลาดใต้ช่องกรอก
  bool isLoading = false;

  final otpControllers = List.generate(6, (_) => TextEditingController());
  final newPassController = TextEditingController();
  final confirmPassController = TextEditingController();

  String? generatedOtp;
  int _remainingSeconds = 60;
  bool otpExpired = false;
  Timer? _timer;

  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // ฟังก์ชันตรวจสอบรหัสผ่าน
  String? validatePassword() {
    String password = newPassController.text;
    String confirmPassword = confirmPassController.text;

    if (password.isEmpty) return 'กรุณากรอกรหัสผ่าน';
    if (password.length < 8) return 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร';
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'รหัสผ่านต้องมีอักษรพิมพ์ใหญ่อย่างน้อย 1 ตัว';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'รหัสผ่านต้องมีอักษรพิมพ์เล็กอย่างน้อย 1 ตัว';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'รหัสผ่านต้องมีตัวเลขอย่างน้อย 1 ตัว';
    }
    if (!RegExp(r'[!@#\$&*~.]').hasMatch(password)) {
      return 'รหัสผ่านต้องมีอักขระพิเศษอย่างน้อย 1 ตัว เช่น !@#\$&*~.';
    }
    if (password != confirmPassword) return 'รหัสผ่านไม่ตรงกัน';

    return null;
  }

  // ฟังก์ชันอัปเดตรหัสผ่าน
  Future<void> updatePassword(String email, String newPassword) async {
    final url = Uri.parse(
        "http://projectnodejs.thammadalok.com/AGribooking/forgot_password");

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "newPassword": newPassword}),
      );

      String msg = response.body;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            "เปลี่ยนรหัสผ่านสำเร็จ",
            textAlign: TextAlign.center,
          ),
          // content: Text(msg),
          content: const Text(
            "รหัสผ่านใหม่ถูกบันทึกเรียบร้อยแล้ว กรุณาเข้าสู่ระบบด้วยรหัสใหม่",
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TabbarGenaralUser(
                      value: 1,
                    ),
                  ),
                );
              },
              child: const Text("ตกลง"),
            ),
          ],
        ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text("เกิดข้อผิดพลาด"),
          content: Text("ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้"),
        ),
      );
    }
  }

  // ฟังก์ชันตรวจสอบรูปแบบอีเมล
  bool isValidEmailFormat(String email) {
    final emailRegex = RegExp(
        r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$");
    return emailRegex.hasMatch(email);
  }

  // ฟังก์ชันตรวจสอบอีเมลมีในระบบหรือไม่
  Future<bool> checkEmailInSystem(String email) async {
    try {
      final url = Uri.parse(
          'http://projectnodejs.thammadalok.com/AGribooking/email_members?email=$email');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['found'] == true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  void startOtpTimer() {
    _remainingSeconds = 60;
    otpExpired = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          timer.cancel();
          otpExpired = true;
        }
      });
    });
  }

  // ฟังก์ชันสุ่ม OTP
  String generateOtp() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // ฟังก์ชันส่ง OTP
  Future<void> sendOtpEmail(String email, String otp) async {
    const serviceId = 'service_x7vmrvq';
    const templateId = 'template_1mrmj3e';
    const userId = '9pdBbRJwCa8veHOzy';

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    final response = await http.post(
      url,
      headers: {
        'origin': 'http://localhost',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': userId,
        'template_params': {
          'from_name': 'ระบบรีเซ็ตรหัสผ่าน AgriBooking',
          'to_name': 'ผู้ใช้งาน',
          'message': 'รหัส OTP สำหรับรีเซ็ตรหัสผ่านของคุณคือ: $otp',
          'to_email': email,
        }
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ส่ง OTP ไปที่อีเมลแล้ว")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ไม่สามารถส่งอีเมลได้")),
      );
    }
  }

  Widget buildStepEmail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // const Text("กรอกอีเมลที่ใช้สมัคร"),
        const Text(
          "กรอกอีเมลที่ใช้สมัคร เพื่อเปลี่ยนรหัสผ่าน",
          style: TextStyle(
            fontSize: 16,
          ),
        ),

        const SizedBox(height: 8),
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            errorText: emailError,
          ),
          onChanged: (_) {
            if (emailError != null) {
              setState(() => emailError = null);
            }
          },
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();

              if (!isValidEmailFormat(email)) {
                setState(() {
                  emailError = 'รูปแบบอีเมลไม่ถูกต้อง';
                });
                return;
              }

              setState(() {
                isLoading = true;
              });

              final exists = await checkEmailInSystem(email);

              setState(() {
                isLoading = false;
              });

              if (!exists) {
                setState(() {
                  emailError = 'อีเมลนี้ไม่พบในระบบ กรุณากรอกอีเมลอื่น';
                });
                return;
              }

              final otp = generateOtp();
              generatedOtp = otp;
              sendOtpEmail(email, otp);
              startOtpTimer();
              setState(() => step = 2);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green, // สีพื้นหลังปุ่ม
              foregroundColor: Colors.white, // สีตัวอักษร

              padding: const EdgeInsets.symmetric(vertical: 16), // เพิ่มระยะสูง
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20, // กว้าง
                    height: 20, // สูง
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3, // ความหนาเส้น
                    ),
                  )
                : const Text(
                    "ส่ง OTP",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget buildStepOtp() {
    return Column(
      children: [
        const Text(
          "กรอกรหัส OTP ที่ส่งไปทางอีเมล",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 45,
              child: TextField(
                controller: otpControllers[index],
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(1),
                ],
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty && index < 5) {
                    FocusScope.of(context).nextFocus();
                  }
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        Text(
          otpExpired
              ? "OTP หมดอายุ คุณสามารถส่งใหม่ได้"
              : 'OTP หมดอายุใน $_remainingSeconds วินาที',
          style: TextStyle(
            color: otpExpired ? Colors.red : Colors.black,
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity, // กว้างเต็มหน้าจอ
          child: ElevatedButton(
            onPressed: () {
              final enteredOtp = otpControllers.map((c) => c.text).join();
              if (enteredOtp == generatedOtp) {
                _timer?.cancel();
                setState(() => step = 3);
              } else if (otpExpired) {
                resendOtp();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("OTP ไม่ถูกต้อง")),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green, // สีพื้นหลังปุ่ม
              foregroundColor: Colors.white, // สีตัวอักษร
              minimumSize: const Size(double.infinity, 55), // กว้างเต็ม, สูง 55
            ),
            child: Text(
              otpExpired ? "ส่ง OTP ใหม่" : "ยืนยัน OTP",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void resendOtp() {
    final email = emailController.text.trim();
    if (email.isNotEmpty) {
      final otp = generateOtp();
      generatedOtp = otp;
      sendOtpEmail(email, otp);
      startOtpTimer();
      for (var c in otpControllers) {
        c.clear();
      }
    }
  }

  Widget buildStepNewPassword() {
    return Column(
      children: [
        const Text(
          "ตั้งรหัสผ่านใหม่",
          style: TextStyle(
            fontSize: 16, // ขนาดตัวอักษร
          ),
        ),
        const SizedBox(height: 30),
        TextField(
          controller: newPassController,
          obscureText: _obscureNew,
          decoration: InputDecoration(
            labelText: "รหัสผ่านใหม่",
            suffixIcon: IconButton(
              icon: Icon(
                _obscureNew ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _obscureNew = !_obscureNew;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: confirmPassController,
          obscureText: _obscureConfirm,
          decoration: InputDecoration(
            labelText: "ยืนยันรหัสผ่าน",
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirm = !_obscureConfirm;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity, // กว้างเต็มหน้าจอ
          child: ElevatedButton(
            onPressed: () {
              String? validationError = validatePassword();
              if (validationError != null) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(validationError)));
                return;
              }
              updatePassword(emailController.text, newPassController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green, // สีพื้นหลังปุ่ม
              foregroundColor: Colors.white, // สีตัวอักษร
              minimumSize: const Size(double.infinity, 55), // กว้างเต็ม, สูง 55
            ),
            child: const Text(
              "บันทึกรหัสผ่านใหม่",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ลืมรหัสผ่าน')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: step == 1
            ? buildStepEmail()
            : step == 2
                ? buildStepOtp()
                : buildStepNewPassword(),
      ),
    );
  }
}







































// import 'dart:async';
// import 'dart:convert';
// import 'dart:math';
// import 'package:agri_booking2/pages/login.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutter/services.dart'; // ต้อง import ด้วย

// class Forgetpassword extends StatefulWidget {
//   const Forgetpassword({super.key});

//   @override
//   State<Forgetpassword> createState() => _ForgetpasswordState();
// }

// class _ForgetpasswordState extends State<Forgetpassword> {
//   int step = 1;
//   final emailController = TextEditingController();
//   final otpControllers = List.generate(6, (_) => TextEditingController());
//   final newPassController = TextEditingController();
//   final confirmPassController = TextEditingController();

//   String? generatedOtp;
//   int _remainingSeconds = 60;
//   bool otpExpired = false;
//   Timer? _timer;

//   // ฟังก์ชันตรวจสอบรหัสผ่าน
//   String? validatePassword() {
//     String password = newPassController.text;
//     String confirmPassword = confirmPassController.text;

//     if (password.isEmpty) return 'กรุณากรอกรหัสผ่าน';
//     if (password.length < 8) return 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร';
//     if (!RegExp(r'[A-Z]').hasMatch(password))
//       return 'รหัสผ่านต้องมีอักษรพิมพ์ใหญ่อย่างน้อย 1 ตัว';
//     if (!RegExp(r'[a-z]').hasMatch(password))
//       return 'รหัสผ่านต้องมีอักษรพิมพ์เล็กอย่างน้อย 1 ตัว';
//     if (!RegExp(r'[0-9]').hasMatch(password))
//       return 'รหัสผ่านต้องมีตัวเลขอย่างน้อย 1 ตัว';
//     if (!RegExp(r'[!@#\$&*~.]').hasMatch(password))
//       return 'รหัสผ่านต้องมีอักขระพิเศษอย่างน้อย 1 ตัว เช่น !@#\$&*~.';
//     if (password != confirmPassword) return 'รหัสผ่านไม่ตรงกัน';

//     return null; // ผ่านทุกเงื่อนไข
//   }

//   // ฟังก์ชันอัปเดตรหัสผ่าน
//   Future<void> updatePassword(String email, String newPassword) async {
//     final url = Uri.parse(
//         "http://projectnodejs.thammadalok.com/AGribooking/forgot_password");

//     try {
//       final response = await http.put(
//         url,
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode({"email": email, "newPassword": newPassword}),
//       );

//       String msg = response.body;

//       showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: const Text("ผลลัพธ์"),
//           content: Text(msg),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(builder: (context) => const Login()),
//                 );
//               },
//               child: const Text("ตกลง"),
//             ),
//           ],
//         ),
//       );
//     } catch (e) {
//       showDialog(
//         context: context,
//         builder: (context) => const AlertDialog(
//           title: Text("เกิดข้อผิดพลาด"),
//           content: Text("ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้"),
//         ),
//       );
//     }
//   }

//   void startOtpTimer() {
//     _remainingSeconds = 60;
//     otpExpired = false;
//     _timer?.cancel();
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       setState(() {
//         if (_remainingSeconds > 0) {
//           _remainingSeconds--;
//         } else {
//           timer.cancel();
//           otpExpired = true;
//           generatedOtp = null;
//         }
//       });
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('ลืมรหัสผ่าน')),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: step == 1
//             ? buildStepEmail()
//             : step == 2
//                 ? buildStepOtp()
//                 : buildStepNewPassword(),
//       ),
//     );
//   }

//   // ฟอร์มกรอกอีเมล
//   Widget buildStepEmail() {
//     return Column(
//       children: [
//         const Text("กรอกอีเมลที่ใช้สมัคร"),
//         TextField(controller: emailController),
//         const SizedBox(height: 16),
//         ElevatedButton(
//           onPressed: () {
//             final email = emailController.text.trim();
//             if (email.isNotEmpty) {
//               final otp = generateOtp();
//               generatedOtp = otp;
//               sendOtpEmail(email, otp);
//               startOtpTimer();
//               setState(() => step = 2);
//             }
//           },
//           child: const Text("ส่ง OTP"),
//         )
//       ],
//     );
//   }

//   // ฟอร์มกรอก OTP
//   Widget buildStepOtp() {
//     return Column(
//       children: [
//         const Text(
//           "กรอกรหัส OTP ที่ส่งไปทางอีเมล",
//           style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 20),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//           children: List.generate(6, (index) {
//             return SizedBox(
//               width: 45,
//               child: TextField(
//                 controller: otpControllers[index],
//                 keyboardType: TextInputType.number,
//                 inputFormatters: [
//                   FilteringTextInputFormatter.digitsOnly,
//                   LengthLimitingTextInputFormatter(1),
//                 ],
//                 textAlign: TextAlign.center,
//                 style:
//                     const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                 decoration: InputDecoration(
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//                 onChanged: (value) {
//                   if (value.isNotEmpty && index < 5) {
//                     FocusScope.of(context).nextFocus();
//                   }
//                 },
//               ),
//             );
//           }),
//         ),
//         const SizedBox(height: 10),
//         Text(
//           otpExpired
//               ? "OTP หมดอายุ"
//               : 'OTP หมดอายุใน $_remainingSeconds วินาที',
//           style: TextStyle(
//             color: otpExpired ? Colors.red : Colors.black,
//           ),
//         ),
//         const SizedBox(height: 20),
//         otpExpired
//             ? ElevatedButton(
//                 onPressed: resendOtp,
//                 child: const Text("ส่ง OTP ใหม่"),
//               )
//             : ElevatedButton(
//                 onPressed: () {
//                   final enteredOtp = otpControllers.map((c) => c.text).join();
//                   if (enteredOtp == generatedOtp) {
//                     _timer?.cancel();
//                     setState(() => step = 3);
//                   } else {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(content: Text("OTP ไม่ถูกต้อง")),
//                     );
//                   }
//                 },
//                 child: const Text("ยืนยัน OTP"),
//               ),
//       ],
//     );
//   }

// // ฟังก์ชันส่ง OTP ใหม่
//   void resendOtp() {
//     final email = emailController.text.trim();
//     if (email.isNotEmpty) {
//       final otp = generateOtp();
//       generatedOtp = otp;
//       sendOtpEmail(email, otp);
//       startOtpTimer();
//     }
//   }

//   bool _obscureNew = true;
//   bool _obscureConfirm = true;

//   // ฟอร์มตั้งรหัสผ่านใหม่
//   Widget buildStepNewPassword() {
//     return Column(
//       children: [
//         const Text("ตั้งรหัสผ่านใหม่"),
//         TextField(
//           controller: newPassController,
//           obscureText: _obscureNew,
//           decoration: InputDecoration(
//             labelText: "รหัสผ่านใหม่",
//             suffixIcon: IconButton(
//               icon: Icon(
//                 _obscureNew ? Icons.visibility_off : Icons.visibility,
//               ),
//               onPressed: () {
//                 setState(() {
//                   _obscureNew = !_obscureNew;
//                 });
//               },
//             ),
//           ),
//         ),
//         TextField(
//           controller: confirmPassController,
//           obscureText: _obscureConfirm,
//           decoration: InputDecoration(
//             labelText: "ยืนยันรหัสผ่าน",
//             suffixIcon: IconButton(
//               icon: Icon(
//                 _obscureConfirm ? Icons.visibility_off : Icons.visibility,
//               ),
//               onPressed: () {
//                 setState(() {
//                   _obscureConfirm = !_obscureConfirm;
//                 });
//               },
//             ),
//           ),
//         ),
//         const SizedBox(height: 16),
//         ElevatedButton(
//           onPressed: () {
//             String? validationError = validatePassword();
//             if (validationError != null) {
//               ScaffoldMessenger.of(context)
//                   .showSnackBar(SnackBar(content: Text(validationError)));
//               return;
//             }
//             updatePassword(emailController.text, newPassController.text);
//           },
//           child: const Text("บันทึกรหัสผ่านใหม่"),
//         )
//       ],
//     );
//   }

//   // ฟังก์ชันส่ง OTP
//   Future<void> sendOtpEmail(String email, String otp) async {
//     const serviceId = 'service_x7vmrvq';
//     const templateId = 'template_1mrmj3e';
//     const userId = '9pdBbRJwCa8veHOzy';

//     final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

//     final response = await http.post(
//       url,
//       headers: {
//         'origin': 'http://localhost',
//         'Content-Type': 'application/json',
//       },
//       body: json.encode({
//         'service_id': serviceId,
//         'template_id': templateId,
//         'user_id': userId,
//         'template_params': {
//           'from_name': 'ระบบรีเซ็ตรหัสผ่าน AgriBooking',
//           'to_name': 'ผู้ใช้งาน',
//           'message': 'รหัส OTP สำหรับรีเซ็ตรหัสผ่านของคุณคือ: $otp',
//           'to_email': email,
//         }
//       }),
//     );

//     if (response.statusCode == 200) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("ส่ง OTP ไปที่อีเมลแล้ว")),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("ไม่สามารถส่งอีเมลได้")),
//       );
//     }
//   }

//   // ฟังก์ชันสุ่ม OTP
//   String generateOtp() {
//     final random = Random();
//     return (100000 + random.nextInt(900000)).toString();
//   }
// }

