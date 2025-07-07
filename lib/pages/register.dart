import 'dart:convert';
import 'package:agri_booking_app2/pages/contactor/home.dart';
import 'package:agri_booking_app2/pages/employer/homeEmp.dart';
import 'package:agri_booking_app2/pages/login.dart';
import 'package:agri_booking_app2/pages/map_register.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:agri_booking_app2/pages/assets/location_data.dart';

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
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomeEmpPage(mid: data['mid']),
                        ),
                      );
                    } else if (data['type_member'] == 2) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomePage(mid: data['mid']),
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
              MaterialPageRoute(
                  builder: (context) => const Login()), // ← ไปหน้า Login
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<int>(
                value: typeMember,
                decoration: const InputDecoration(labelText: 'ประเภทสมาชิก'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('ผู้จ้าง')),
                  DropdownMenuItem(value: 2, child: Text('ผู้รับจ้าง')),
                ],
                onChanged: (value) {
                  setState(() {
                    typeMember = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'กรุณาเลือกประเภทสมาชิก' : null,
              ),
              TextFormField(
                  controller: usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                  validator: (v) => v!.isEmpty ? 'กรุณากรอก username' : null),
              TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) => v!.isEmpty ? 'กรุณากรอก email' : null),
              TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (v) => v!.isEmpty ? 'กรุณากรอก password' : null),
              TextFormField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'เบอร์โทรศัพท์',
                  counterText: '$phoneLength/10',
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                onChanged: (value) {
                  setState(() {
                    phoneLength = value.length;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกเบอร์โทรศัพท์';
                  }
                  if (!RegExp(r'^0[0-9]{8,9}$').hasMatch(value)) {
                    return 'เบอร์โทรต้องขึ้นต้นด้วย 0 และมี 9-10 หลัก';
                  }
                  return null;
                },
              ),
              TextFormField(
                  controller: addressController,
                  decoration:
                      const InputDecoration(labelText: 'ที่อยู่ (ไม่บังคับ)')),
              DropdownButtonFormField<String>(
                value: selectedProvince,
                decoration: const InputDecoration(labelText: 'จังหวัด'),
                items: provinces
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e),
                        ))
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
              DropdownButtonFormField<String>(
                value: selectedAmphoe,
                decoration: const InputDecoration(labelText: 'อำเภอ'),
                items: amphoes
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e),
                        ))
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
              DropdownButtonFormField<String>(
                value: selectedDistrict,
                decoration: const InputDecoration(labelText: 'ตำบล'),
                items: districts
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedDistrict = value;
                  });
                },
                validator: (v) => v == null ? 'กรุณาเลือกตำบล' : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: uploadImageFromImageBB,
                icon: const Icon(Icons.image),
                label: const Text('เลือกรูปจาก imagebb'),
              ),
              if (imageUrl != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.network(imageUrl!, height: 100),
                ),
              ElevatedButton.icon(
                onPressed: goToMapPage,
                icon: const Icon(Icons.map),
                label: const Text('เลือกตำแหน่งจากแผนที่'),
              ),
              if (latitude != null && longitude != null)
                Text('ปักหมุดแผนที่เรียบร้อยแล้ว'),
              const SizedBox(height: 20),
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: register,
                      child: const Text('สมัครสมาชิก'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
