import 'dart:convert';
import 'package:agri_booking2/pages/GenaralUser/tabbar.dart';
import 'package:agri_booking2/pages/contactor/Tabbar.dart';
import 'package:agri_booking2/pages/employer/addFarm.dart';
import 'package:agri_booking2/pages/map_register.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
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
  final TextEditingController otherController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final FocusNode usernameFocus = FocusNode();
  final FocusNode emailFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();
  final FocusNode confirmPasswordFocus = FocusNode();
  final FocusNode phoneFocus = FocusNode();
  final FocusNode addressFocus = FocusNode();
  final FocusNode typeFocus = FocusNode();
  final FocusNode mapFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final FocusNode provinceFocus = FocusNode();
  final FocusNode amphoeFocus = FocusNode();
  final FocusNode districtFocus = FocusNode();

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
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // เพิ่มตัวแปร error สำหรับปุ่ม/ช่องที่ไม่ใช่ TextFormField
  String? typeMemberError;
  String? mapError;

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
    setState(() {
      typeMemberError = null;
      mapError = null;
    });

    // ตรวจสอบฟอร์ม
    if (!_formKey.currentState!.validate()) {
      // Focus ไปช่องแรกที่ผิด
      if (usernameController.text.isEmpty) {
        scrollToFocus(usernameFocus);
        return;
      }
      if (emailController.text.isEmpty) {
        scrollToFocus(emailFocus);
        return;
      }
      if (passwordController.text.isEmpty) {
        scrollToFocus(passwordFocus);
        return;
      }
      if (confirmPasswordController.text.isEmpty) {
        scrollToFocus(confirmPasswordFocus);
        return;
      }
      if (phoneController.text.isEmpty) {
        scrollToFocus(phoneFocus);
        return;
      }
      if (selectedProvince == null) {
        scrollToFocus(provinceFocus);
        return;
      }
      if (selectedAmphoe == null) {
        scrollToFocus(amphoeFocus);
        return;
      }
      if (selectedDistrict == null) {
        scrollToFocus(districtFocus);
        return;
      }
      if (typeMember == null) {
        setState(() {
          typeMemberError = 'กรุณาเลือกประเภทสมาชิก';
        });
        scrollToFocus(typeFocus);
        return;
      }
      if (latitude == null || longitude == null) {
        setState(() {
          mapError = 'กรุณาเลือกตำแหน่งจากแผนที่';
        });
        scrollToFocus(mapFocus);
        return;
      }
      if (addressController.text.isEmpty) {
        scrollToFocus(addressFocus);
        return;
      }
      return;
    }

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
      "image": imageUrl,
      "detail_address": addressController.text,
      "province": selectedProvince,
      "district": selectedAmphoe,
      "subdistrict": selectedDistrict,
      "latitude": latitude,
      "longitude": longitude,
      "other": otherController.text,
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
              title: const Text('สมัครสมาชิกสำเร็จ'),
              content: Text('ยินดีต้อนรับคุณ ${data['username']}'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // ปิด AlertDialog

                    if (data['type_member'] == 1) {
                      int currentMonth = DateTime.now().month;
                      int currentYear = DateTime.now().year;

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TabbarCar(
                            mid: mid,
                            value: 0,
                            month: currentMonth,
                            year: currentYear,
                          ),
                        ),
                        (route) =>
                            false, // ✅ เคลียร์ทุกหน้าออก เหลือแค่ TabbarCar
                      );
                    } else if (data['type_member'] == 2) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddFarmPage(mid: mid),
                        ),
                        (route) =>
                            false, // ✅ เคลียร์ทุกหน้าออก เหลือแค่ AddFarmPage
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

  void scrollToFocus(FocusNode focusNode) {
    if (!focusNode.hasFocus) {
      FocusScope.of(context).requestFocus(focusNode);
    }
    final RenderObject? renderObject = focusNode.context?.findRenderObject();
    if (renderObject != null) {
      final yPosition =
          (renderObject as RenderBox).localToGlobal(Offset.zero).dy;
      _scrollController.animateTo(
        yPosition - 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

// ฟังก์ชันตรวจสอบอีเมลจริงด้วย Abstract API
  Future<bool> isRealEmail(String email) async {
    const apiKey = 'f1be6dd55f1043dd9fb0794725d344a1';
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
          content: const Text('ไม่สามารถอัปโหลดรูปได้'),
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 18, 143, 9),
        elevation: 0,
        title: Text(
          'สมัครสมาชิก',
          style: GoogleFonts.prompt(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const TabbarGenaralUser(value: 1)),
            );
          },
        ),
      ),
      body: Stack(
        children: [
          // รูปพื้นหลัง (ใส่ลิงก์ของคุณเอง)
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                    "https://i.ibb.co/Q3q8kTG8/pexels-lucas-d-amico-2150246673-31717239.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Content หลัก
          SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 32, 16, 16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Center(
                    child: Stack(
                      children: [
                        ClipOval(
                          child: imageUrl != null
                              ? Image.network(
                                  imageUrl!,
                                  height: 100,
                                  width: 100,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(
                                  Icons.person_outline,
                                  size: 100,
                                  color: Colors.white,
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
                              onPressed: uploadImageFromImageBB,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'โปรดกดปุ่มเลือกประเภทผู้ใช้ *',
                    style: GoogleFonts.prompt(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Focus(
                        focusNode: typeFocus,
                        child: _buildUserTypeButton("ผู้รับจ้าง", 1),
                      ),
                      const SizedBox(width: 10),
                      _buildUserTypeButton("ผู้จ้าง", 2),
                    ],
                  ),
                  // เพิ่มข้อความ error สีแดงใต้ปุ่มเลือกประเภทสมาชิก
                  if (typeMemberError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        typeMemberError!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Card โปร่งใส
                  Card(
                    color:
                        const Color.fromRGBO(255, 249, 249, 1).withOpacity(0.8),
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildTextField(
                            "ชื่อผู้ใช้ *",
                            usernameController,
                            'กรุณากรอก username *',
                            keyboardType: TextInputType.text,
                            maxLength: 30,
                            focusNode: usernameFocus,
                          ),
                          _buildTextField(
                              "อีเมล *", emailController, 'กรุณากรอก email *',
                              focusNode: emailFocus),
                          _buildTextField(
                            "รหัสผ่าน *",
                            passwordController,
                            'กรุณากรอกรหัสผ่าน *',
                            obscure: !_isPasswordVisible,
                            onToggleVisibility: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                            hintText:
                                'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร มีทั้งอักษรพิมพ์ใหญ่ พิมพ์เล็ก ตัวเลข และอักขระพิเศษ !@#\$&*~.',
                            validator: (value) => validatePassword(),
                            focusNode: passwordFocus,
                          ),
                          _buildTextField(
                            "ยืนยันรหัสผ่าน *",
                            confirmPasswordController,
                            'กรุณายืนยันรหัสผ่าน *',
                            obscure: !_isConfirmPasswordVisible,
                            onToggleVisibility: () {
                              setState(() {
                                _isConfirmPasswordVisible =
                                    !_isConfirmPasswordVisible;
                              });
                            },
                            focusNode: confirmPasswordFocus,
                          ),
                          _buildTextField(
                            "เบอร์โทร *",
                            phoneController,
                            'กรุณากรอกเบอร์โทร *',
                            keyboardType: TextInputType.number,
                            maxLength: 10,
                            focusNode: phoneFocus,
                          ),
                          _buildDropdown(
                              "จังหวัด *", selectedProvince, provinces,
                              (value) {
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
                          }, focusNode: provinceFocus),
                          _buildDropdown("อำเภอ *", selectedAmphoe, amphoes,
                              (value) {
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
                          }, focusNode: amphoeFocus),
                          _buildDropdown("ตำบล *", selectedDistrict, districts,
                              (value) {
                            setState(() {
                              selectedDistrict = value;
                            });
                          }, focusNode: districtFocus),
                          // ช่องกรอก
                          _buildTextField(
                            'ช่องทางติดต่อเพิ่มเติม',
                            otherController,
                            '',
                            maxLength: 500,
                            keyboardType: TextInputType.multiline,
                            hintText: 'เช่น Line, Facebook, Instagram',
                            validator: (value) {
                              if (value != null && value.length > 500) {
                                return 'ต้องไม่เกิน 500 ตัวอักษร';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: goToMapPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orangeAccent,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Focus(
                              focusNode: mapFocus,
                              child: const Center(
                                child: Text(
                                  'เลือกตำแหน่งจากแผนที่ *',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                          ),
                          // เพิ่มข้อความ error สีแดงใต้ปุ่มเลือกตำแหน่งแผนที่
                          if (mapError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                mapError!,
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 14),
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
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Stack(
                              children: [
                                // เงาจำลองให้ช่องดูลึก

                                // ช่องกรอก
                                _buildTextField(
                                  'รายละเอียดที่อยู่ที่อยู่',
                                  addressController,
                                  'กรุณากรอกที่อยู่',
                                  maxLength: 500,
                                  keyboardType: TextInputType.multiline,
                                  hintText:
                                      'เช่น บ้านเลขที่ หมู่บ้าน ซอย ถนน ตำบล อำเภอ จังหวัด',
                                  validator: (value) {
                                    if (value != null && value.length > 500) {
                                      return 'ต้องไม่เกิน 500 ตัวอักษร';
                                    }
                                    return null;
                                  },
                                  focusNode: addressFocus,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
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
                                    ? const Center(
                                        child: CircularProgressIndicator())
                                    : ElevatedButton(
                                        onPressed: register,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
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
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? validatePassword() {
    String password = passwordController.text;
    String confirmPassword = confirmPasswordController.text;

    // 1. ตรวจสอบว่ามีข้อมูลหรือไม่
    if (password.isEmpty) {
      return 'กรุณากรอกรหัสผ่าน';
    }

    // 2. ตรวจสอบความยาว
    if (password.length < 8) {
      return 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร';
    }

    // 3. ตรวจสอบอักษรพิมพ์ใหญ่
    RegExp hasUppercase = RegExp(r'[A-Z]');
    if (!hasUppercase.hasMatch(password)) {
      return 'รหัสผ่านต้องมีอักษรพิมพ์ใหญ่อย่างน้อย 1 ตัว';
    }

    // 4. ตรวจสอบอักษรพิมพ์เล็ก
    RegExp hasLowercase = RegExp(r'[a-z]');
    if (!hasLowercase.hasMatch(password)) {
      return 'รหัสผ่านต้องมีอักษรพิมพ์เล็กอย่างน้อย 1 ตัว';
    }

    // 5. ตรวจสอบตัวเลข
    RegExp hasDigit = RegExp(r'[0-9]');
    if (!hasDigit.hasMatch(password)) {
      return 'รหัสผ่านต้องมีตัวเลขอย่างน้อย 1 ตัว';
    }

    // 6. ตรวจสอบอักขระพิเศษ
    RegExp hasSpecialChar = RegExp(r'[!@#\$&*~.]');
    if (!hasSpecialChar.hasMatch(password)) {
      return 'รหัสผ่านต้องมีอักขระพิเศษอย่างน้อย 1 ตัว เช่น !@#\$&*~.';
    }

    // 7. ตรวจสอบรหัสผ่านที่ยืนยันว่าตรงกันหรือไม่
    if (password != confirmPassword) {
      return 'รหัสผ่านไม่ตรงกัน';
    }

    // ถ้าผ่านทุกเงื่อนไข ให้ส่งค่า null กลับไป
    return null;
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String validatorText, {
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    Function()? onToggleVisibility,
    String? hintText,
    String? Function(String?)? validator,
    FocusNode? focusNode,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ชื่อช่อง (Label) แยกออกมาอยู่นอก Stack
          Text(
            label,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6), // ช่องว่างระหว่างชื่อกับช่องกรอก
          Stack(
            children: [
              Container(
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.white,
                      offset: Offset(-2, -2),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: Color.fromARGB(246, 69, 62, 62),
                      offset: Offset(2, 2),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              TextFormField(
                controller: controller,
                obscureText: obscure,
                keyboardType: keyboardType,
                maxLength: maxLength,
                focusNode: focusNode,
                decoration: InputDecoration(
                  labelText: null, // ลบ labelText ออก
                  filled: true,
                  fillColor: const Color.fromARGB(255, 255, 255, 255),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  counterText: '',
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  suffixIcon: onToggleVisibility != null
                      ? IconButton(
                          icon: Icon(
                            obscure ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: onToggleVisibility,
                        )
                      : null,
                  errorStyle: const TextStyle(
                      color: Colors.red,
                      fontSize: 13), // เพิ่ม errorStyle สีแดง
                ),
                validator: validator ??
                    (value) {
                      if (value == null || value.isEmpty) {
                        return validatorText;
                      }
                      return null;
                    },
              ),
            ],
          ),
          // แสดงข้อความอธิบายใต้ช่องกรอก ถ้า hintText ไม่เป็น null
          if (hintText != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Text(
                hintText,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged, {
    FocusNode? focusNode,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ชื่อช่อง (Label) แยกออกมา
          Text(
            label,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6), // เว้นระยะห่างระหว่างชื่อช่องกับ Dropdown
          Stack(
            children: [
              Container(
                height: 60,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 92, 85, 85),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.white,
                      offset: Offset(-2, -2),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: Color.fromARGB(246, 69, 62, 62),
                      offset: Offset(2, 2),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              DropdownButtonFormField<String>(
                initialValue: value,
                focusNode: focusNode,
                decoration: InputDecoration(
                  // ลบ labelText ออก เพราะเรากำหนดชื่อช่องไว้แยกแล้ว
                  labelText: null,
                  filled: true,
                  fillColor: const Color.fromARGB(255, 255, 252, 252),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  errorStyle: const TextStyle(
                      color: Colors.red,
                      fontSize: 13), // เพิ่ม errorStyle สีแดง
                ),
                items: items
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: onChanged,
                validator: (v) => v == null ? 'กรุณาเลือก $label' : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeButton(String text, int type) {
    final isSelected = typeMember == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          typeMember = type;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromARGB(255, 13, 161, 40)
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  const BoxShadow(
                    color: Colors.black26,
                    offset: Offset(0, 4),
                    blurRadius: 8,
                  ),
                ]
              : [
                  const BoxShadow(
                    color: Colors.white,
                    offset: Offset(-2, -2),
                    blurRadius: 4,
                  ),
                  const BoxShadow(
                    color: Color.fromARGB(246, 69, 62, 62),
                    offset: Offset(2, 2),
                    blurRadius: 4,
                  ),
                ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
