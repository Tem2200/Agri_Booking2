import 'dart:convert';

import 'package:agri_booking2/pages/contactor/Tabbar.dart';
import 'package:agri_booking2/pages/employer/Tabbar.dart';
import 'package:agri_booking2/pages/login.dart';
import 'package:agri_booking2/pages/map_register.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:agri_booking2/pages/assets/location_data.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  String? imageUrl; // URL รูปภาพจาก imagebb
  double? latitude;
  double? longitude;
  bool isLoading = false;
  int? typeMember;
  int? mid; // รหัสสมาชิก (MID) ที่จะใช้ในการเช็คประเภทสมาชิก
  int phoneLength = 0;

  List<String> provinces = [];
  List<String> amphoes = [];
  List<String> districts = [];

  String? selectedProvince;
  String? selectedAmphoe;
  String? selectedDistrict;

  @override
  void initState() {
    super.initState();

    provinces = locationData
        .map((e) => e['province'] as String)
        .toSet()
        .toList()
      ..sort();
  }

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final email = emailController.text;
    final emailIsValid = await isRealEmail(email);

    if (!emailIsValid) {
      setState(() => isLoading = false);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('อีเมลไม่ถูกต้อง'),
          content: const Text(
              'อีเมลนี้ไม่สามารถรับส่งข้อความได้จริง กรุณากรอกอีเมลอื่น'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ตกลง'),
            ),
          ],
        ),
      );
      return;
    }

    if (typeMember == null) {
      setState(() => isLoading = false);
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text('ข้อผิดพลาด'),
          content: Text('กรุณาเลือกประเภทสมาชิก'),
        ),
      );
      return;
    }

    if (latitude == null || longitude == null) {
      setState(() => isLoading = false);
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text('ข้อผิดพลาด'),
          content: Text('กรุณาเลือกตำแหน่งจากแผนที่'),
        ),
      );
      return;
    }

    final url =
        Uri.parse('http://projectnodejs.thammadalok.com/AGribooking/register');
    final data = {
      "username": usernameController.text,
      "email": email,
      "password": passwordController.text,
      "phone": phoneController.text,
      "image": imageUrl ?? null,
      "detail_address":
          addressController.text.isEmpty ? null : addressController.text,
      "province": selectedProvince,
      "district": selectedAmphoe,
      "subdistrict": selectedDistrict,
      "latitude": latitude,
      "longitude": longitude,
      "type_member": typeMember,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      final res = jsonDecode(response.body);

      if (response.statusCode == 201 && res['mid'] != null) {
        final mid = res['mid'];

        // โหลดข้อมูลสมาชิกจาก mid
        final urlCon = Uri.parse(
            'http://projectnodejs.thammadalok.com/AGribooking/members/$mid');
        final response2 = await http.get(urlCon);

        if (response2.statusCode == 200) {
          final data = jsonDecode(response2.body);

          setState(() => isLoading = false);

          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('สำเร็จ'),
              content: Text('สมัครสมาชิกสำเร็จ MID: $mid'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // ปิด AlertDialog

                    if (data['type_member'] == 1) {
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
                    } else if (data['type_member'] == 2) {
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
                  },
                  child: const Text('ตกลง'),
                ),
              ],
            ),
          );
        } else {
          setState(() => isLoading = false);
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('ข้อผิดพลาด'),
              content: Text(
                  'ไม่สามารถโหลดข้อมูลสมาชิกได้ (status ${response2.statusCode})'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ตกลง'),
                ),
              ],
            ),
          );
        }
      } else {
        setState(() => isLoading = false);
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('ข้อผิดพลาด'),
            content: Text(res['message'] ?? 'สมัครสมาชิกไม่สำเร็จ'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ตกลง'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('ข้อผิดพลาด'),
          content: Text('เชื่อมต่อ API ไม่ได้: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ปิด'),
            ),
          ],
        ),
      );
    }
  }

// ฟังก์ชันตรวจสอบอีเมลจริงด้วย Abstract API
  Future<bool> isRealEmail(String email) async {
    final apiKey = 'f1be6dd55f1043dd9fb0794725d344a1';
    final url = Uri.parse(
        'https://emailvalidation.abstractapi.com/v1/?api_key=$apiKey&email=$email');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // เช็คค่า deliverability ว่าส่งได้จริงไหม
        return data['deliverability'] == 'DELIVERABLE';
      }
    } catch (e) {
      print("Error validating email: $e");
    }
    return false;
  }

  void goToMapPage() async {
    // ไปหน้าแผนที่เพื่อเลือกพิกัด (สร้างหน้า MapPage ไว้แยก)
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => const MapRegister()), // สร้างหน้า MapPage แยก
    );

    if (result != null && result is Map<String, double>) {
      setState(() {
        latitude = result['lat'];
        longitude = result['lng'];
      });
    }
  }

  final ImagePicker picker = ImagePicker();

  void uploadImageFromImageBB() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    final bytes = await pickedFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    const apiKey =
        'a051ad7a04e7037b74d4d656e7d667e9'; // ← 🔴 แก้ตรงนี้ให้เป็น API KEY จริงของคุณ
    final url = Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey');

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        url,
        body: {'image': base64Image},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final uploadedUrl = data['data']['url'];

        setState(() {
          imageUrl = uploadedUrl;
        });
      } else {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('อัปโหลดไม่สำเร็จ'),
            content: Text('เกิดข้อผิดพลาด: ${response.body}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ปิด'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('เกิดข้อผิดพลาด'),
          content: Text('ไม่สามารถอัปโหลดรูปได้: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ปิด'),
            ),
          ],
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สมัครสมาชิก'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Login()),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    // Icon/Image for profile
                    Stack(
                      children: [
                        ClipOval(
                          child: imageUrl != null
                              ? Image.network(
                                  imageUrl!,
                                  height: 120,
                                  width: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                    Icons.person_outline,
                                    size: 120,
                                    color: Color.fromARGB(255, 16, 191, 6),
                                  ),
                                )
                              : const Icon(
                                  Icons.person_outline,
                                  size: 120,
                                  color: Color.fromARGB(255, 3, 140, 53),
                                ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.edit,
                                  color: Color.fromARGB(255, 5, 122, 40)),
                              onPressed:
                                  uploadImageFromImageBB, // เรียกใช้ฟังก์ชันเลือกรูป
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'โปรดกดปุ่มเลือกประเภทผู้ใช้ *', // เพิ่ม *
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    // ปุ่มเลือกประเภทผู้ใช้ (ผู้จ้าง / ผู้รับจ้าง)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              typeMember = 1; // ผู้รับจ้าง
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: typeMember == 1
                                ? const Color(0xFF5D7B48)
                                : Colors.grey[300],
                            foregroundColor:
                                typeMember == 1 ? Colors.white : Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 12),
                          ),
                          child: const Text('ผู้รับจ้าง'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              typeMember = 2; // ผู้รจ้าง
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: typeMember == 2
                                ? const Color(0xFF90B083)
                                : Colors.grey[300],
                            foregroundColor:
                                typeMember == 2 ? Colors.white : Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 12),
                          ),
                          child: const Text('ผู้จ้าง'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // กรอบสีส้มสำหรับข้อมูล
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD180), // สีส้มอ่อน
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: usernameController,
                      decoration: const InputDecoration(
                        labelText: 'ชื่อผู้ใช้ *', // เพิ่ม *
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (v) =>
                          v!.isEmpty ? 'กรุณากรอก username' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'อีเมล *', // เพิ่ม *
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (v) => v!.isEmpty ? 'กรุณากรอก email' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: passwordController,
                      decoration: const InputDecoration(
                        labelText: 'รหัสผ่าน *', // เพิ่ม *
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      obscureText: true,
                      validator: (v) =>
                          v!.isEmpty ? 'กรุณากรอก password' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.number,
                      maxLength: 10,
                      decoration: const InputDecoration(
                        labelText: 'เบอร์โทร',
                        filled: true,
                        fillColor: Color(0xFFE0E0E0),
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'กรุณากรอกเบอร์โทร';
                        }
                        if (!RegExp(r'^0\d{9}$').hasMatch(value)) {
                          return 'เบอร์โทรต้องเป็นตัวเลข 10 หลัก และขึ้นต้นด้วย 0';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),
                    // Dropdown สำหรับ จังหวัด อำเภอ ตำบล (อยู่คนละบรรทัด)
                    DropdownButtonFormField<String>(
                      value: selectedProvince,
                      decoration: const InputDecoration(
                        labelText: 'จังหวัด *', // เพิ่ม *
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: provinces
                          .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedProvince = value;
                          selectedAmphoe = null;
                          selectedDistrict = null;

                          amphoes = locationData
                              .where((e) => e['province'] == value)
                              .map((e) => e['amphoe'] as String)
                              .toSet()
                              .toList()
                            ..sort();

                          districts = [];
                        });
                      },
                      validator: (v) => v == null ? 'กรุณาเลือกจังหวัด' : null,
                    ),
                    const SizedBox(height: 10), // เพิ่มระยะห่างระหว่าง Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedAmphoe,
                      decoration: const InputDecoration(
                        labelText: 'อำเภอ *', // เพิ่ม *
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: amphoes
                          .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedAmphoe = value;
                          selectedDistrict = null;

                          districts = locationData
                              .where((e) =>
                                  e['province'] == selectedProvince &&
                                  e['amphoe'] == value)
                              .map((e) => e['district'] as String)
                              .toSet()
                              .toList()
                            ..sort();
                        });
                      },
                      validator: (v) => v == null ? 'กรุณาเลือกอำเภอ' : null,
                    ),
                    const SizedBox(height: 10), // เพิ่มระยะห่างระหว่าง Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedDistrict,
                      decoration: const InputDecoration(
                        labelText: 'ตำบล *', // เพิ่ม *
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: districts
                          .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedDistrict = value;
                        });
                      },
                      validator: (v) => v == null ? 'กรุณาเลือกตำบล' : null,
                    ),
                    const SizedBox(height: 20), // ระยะห่างก่อนปุ่มแผนที่
                    // ปุ่มเลือกตำแหน่งจากแผนที่
                    ElevatedButton(
                      onPressed: goToMapPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 252, 185, 17),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'เลือกตำแหน่งจากแผนที่',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                    if (latitude != null && longitude != null)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          'ปักหมุดแผนที่เรียบร้อยแล้ว',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        labelText: 'ที่อยู่ *', // เพิ่ม *
                        hintText:
                            'เช่น บ้านเลขที่ หมู่บ้าน ซอย ถนน ตำบล อำเภอ จังหวัด',
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                          borderSide: BorderSide.none,
                        ),
                        counterText: '0/300', // Counter ตามรูป
                      ),
                      maxLength: 300,
                      maxLines: 3, // เพิ่ม maxLines เพื่อให้ดูเป็นกล่องใหญ่ขึ้น
                      keyboardType: TextInputType.multiline,
                      validator: (v) => v!.isEmpty ? 'กรุณากรอกที่อยู่' : null,
                    ),
                    const SizedBox(height: 20),
                    // ปุ่ม ยกเลิก และ สมัครสมาชิก
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('ยกเลิก'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton(
                                  onPressed: register,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('สมัครสมาชิก'),
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
      ),
    );
  }
}
