import 'dart:convert';
import 'dart:ui';
import 'package:agri_booking2/pages/contactor/Tabbar.dart';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class AddVehicle extends StatefulWidget {
  final int mid;
  const AddVehicle({super.key, required this.mid});
//tast git
//dskfp
// rgkthhkt
  @override
  State<AddVehicle> createState() => _AddVehicleState();
}

class _AddVehicleState extends State<AddVehicle> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController unitPriceController = TextEditingController();
  final TextEditingController detailController = TextEditingController();
  final TextEditingController plateController = TextEditingController();

  // กำหนด style สำหรับหัวข้อข้อความ
  final TextStyle labelStyle = const TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );

// กำหนด style สำหรับข้อความในปุ่มยกเลิก
  final TextStyle cancelButtonTextStyle = TextStyle(
    color: Colors.grey[800],
    fontWeight: FontWeight.w600,
  );

// กำหนด style สำหรับข้อความในปุ่มเพิ่มรถ
  static const TextStyle submitButtonTextStyle = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w600,
  );

  String? imageUrl; // URL ของรูปภาพหลังอัปโหลด
  bool isLoading = false;

  final ImagePicker picker = ImagePicker();
  String? selectedUnit;
  final TextEditingController customUnitController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    customUnitController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    //selectedUnit = 'ไร่'; // กำหนดค่าเริ่มต้นที่นี่แทน
  }

  Future<void> pickAndUploadImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() => isLoading = true);

    try {
      final bytes = await pickedFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      const apiKey = 'a051ad7a04e7037b74d4d656e7d667e9';
      final url = Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey');

      final response = await http.post(url, body: {'image': base64Image});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          imageUrl = data['data']['url'];
        });
        Fluttertoast.showToast(
          msg: 'อัปโหลดรูปภาพสำเร็จ',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } else {
        throw Exception('อัปโหลดรูปภาพล้มเหลว');
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'เกิดข้อผิดพลาด: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> submitVehicle() async {
    if (_isSubmitting) return; // ป้องกันกดซ้ำ

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      _isSubmitting = true;
    });

    final data = {
      "name_vehicle": nameController.text,
      "price": int.tryParse(priceController.text) ?? 0,
      "unit_price": unitPriceController.text,
      "image": imageUrl, // ถ้าไม่มีรูป ส่ง null หรือเว้นไว้
      "detail": detailController.text,
      "plate_number": plateController.text,
      "mid": widget.mid,
    };

    try {
      final url = Uri.parse(
          'http://projectnodejs.thammadalok.com/AGribooking/add-vehicle');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        final res = jsonDecode(response.body);
        final int vid = res['vehicleId'] ?? 0;
        showDialog(
          context: context,
          barrierDismissible: false, // ป้องกันแตะนอก dialog ปิด
          builder: (_) => WillPopScope(
            onWillPop: () async => false, // ป้องกันกด back ปิด dialog
            child: AlertDialog(
              title: const Center(
                child: Text('เพิ่มรถสำเร็จ'),
              ),
              content: const Text('ข้อมูลรถของคุณถูกบันทึกเรียบร้อย'),
              // content: Text('รหัสรถ (VID): $vid'),
              actions: [
                TextButton(
                  onPressed: () {
                    int currentMonth = DateTime.now().month;
                    int currentYear = DateTime.now().year;
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
                  },
                  child: const Text('ตกลง'),
                ),
              ],
            ),
          ),
        );
      } else {
        throw Exception('ผิดพลาด: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถเพิ่มรถได้: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 217, 180),
      appBar: AppBar(
        //backgroundColor: const Color(0xFF006000),
        // backgroundColor: const Color.fromARGB(255, 255, 158, 60),
        backgroundColor: const Color.fromARGB(255, 18, 143, 9),
        centerTitle: true,
        title: const Text(
          'เพิ่มรถรับจ้าง',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 255, 255, 255),
            //letterSpacing: 1,
            shadows: [
              Shadow(
                color: Color.fromARGB(115, 253, 237, 237),
                blurRadius: 3,
                offset: Offset(1.5, 1.5),
              ),
            ],
          ),
        ),
        leading: IconButton(
          color: Colors.white,
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            int currentMonth = DateTime.now().month;
            int currentYear = DateTime.now().year;
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
          },
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Card(
                color: Colors.white
                    .withOpacity(1), // หรือปรับ 0.8, 0.85 ตามความโปร่งใส

                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
  child: Column(
    children: [
      Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 245, 255, 243),
                  Color.fromARGB(255, 80, 211, 54),
                  Color.fromARGB(255, 38, 103, 8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.transparent,
              backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
                  ? NetworkImage(imageUrl!)
                  : null,
              child: (imageUrl == null || imageUrl!.isEmpty)
                  ? const Icon(
                      Icons.directions_car,
                      size: 60,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: CircleAvatar(
              backgroundColor: Colors.green[700],
              radius: 18,
              child: IconButton(
                icon: Icon(
                  imageUrl != null && imageUrl!.isNotEmpty
                      ? Icons.close // 👉 มีรูป → แสดงกากบาท
                      : Icons.edit, // 👉 ไม่มีรูป → แสดงดินสอ
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: isLoading
                    ? null
                    : () {
                        if (imageUrl != null && imageUrl!.isNotEmpty) {
                          // 👉 ลบรูป
                          setState(() {
                            imageUrl = null;
                          });
                        } else {
                          // 👉 อัปโหลดรูป
                          pickAndUploadImage();
                        }
                      },
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text('เพิ่มรูปรถ', style: labelStyle),
    ],
  ),
),


                        const SizedBox(height: 24),

                        // ชื่อรถ
Text('ชื่อรถ *', style: labelStyle),
const SizedBox(height: 8),
TextFormField(
  controller: nameController,
  maxLength: 255,
  decoration: const InputDecoration(
    filled: true, // เปิดการเติมสีพื้นหลัง
    fillColor: Colors.white, // กำหนดสีพื้นหลังเป็นสีขาว
    border: OutlineInputBorder(),
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    counterText: '', // ซ่อนตัวนับจำนวนตัวอักษร
  ),
  validator: (v) => v == null || v.isEmpty
      ? 'กรุณากรอกชื่อรถ*'
      : null,
),


                        const SizedBox(height: 16),

                        //ราคาต่อการจ้าง
                        Text('ราคาต่อการจ้าง(เช่น100บาท/ไร่)*',
                            style: labelStyle),
                        const SizedBox(height: 8),
                        // เก็บค่า dropdown ที่เลือ

                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: priceController,
                                maxLength: 10,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  filled: true, //เปิดการเติมสีพื้นหลัง
                                  fillColor:
                                      Colors.white, // กำหนดสีพื้นหลังเป็นสีขาว
                                  border: OutlineInputBorder(),
                                  counterText: '',
                                  //hintText: 'จำนวนเงิน',
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                                validator: (v) => v == null || v.isEmpty
                                    ? 'กรุณากรอกราคา*'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text('บาท/', style: labelStyle),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedUnit,
                                decoration: const InputDecoration(
                                  filled: true, // ✅ เปิดการเติมสีพื้นหลัง
                                  fillColor: Colors
                                      .white, // ✅ กำหนดสีพื้นหลังเป็นสีขาว
                                  border: OutlineInputBorder(),
                                  
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                                items: [
                                  'ไร่',
                                  'วัน',
                                  'ชั่วโมง',
                                  'ตารางวา',
                                  'อื่นๆ',
                                ].map((unit) {
                                  return DropdownMenuItem<String>(
                                    value: unit,
                                    child: Text(unit),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedUnit = value;
                                    if (value != 'อื่นๆ') {
                                      unitPriceController.text = value!;
                                    } else {
                                      unitPriceController.clear();
                                    }
                                  });
                                },
                                validator: (v) => v == null || v.isEmpty
                                    ? 'กรุณาเลือกหน่วย*'
                                    : null,
                              ),
                            ),
                          ],
                        ),

                        // แสดงช่องกรอกหน่วยเอง ถ้าเลือก "อื่นๆ"
                        if (selectedUnit == 'อื่นๆ') ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: customUnitController,
                            maxLength: 20,
                            decoration: const InputDecoration(
                              filled: true, // เปิดการเติมสีพื้นหลัง
                              fillColor:
                                  Colors.white, //กำหนดสีพื้นหลังเป็นสีขาว
                              border: OutlineInputBorder(),
                              counterText: '',
                              hintText: 'กรอกหน่วยเอง เช่น เมตร',
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            validator: (v) {
                              if (selectedUnit == 'อื่นๆ' &&
                                  (v == null || v.isEmpty)) {
                                return 'กรุณากรอกหน่วย*';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              unitPriceController.text = value;
                            },
                          ),
                        ],

                        const SizedBox(height: 16),

                        Text('รายละเอียดรถ', style: labelStyle),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: detailController,
                          maxLength: 500,
                          maxLines: 1,
                          decoration: const InputDecoration(
                            filled: true, // เปิดการเติมสีพื้นหลัง
                            fillColor: Colors.white, // กำหนดสีพื้นหลังเป็นสีขาว
                            border: OutlineInputBorder(),
                            counterText: '',
                            hintText: 'อธิบายการใช้งานรถ เช่น ขุดดิน ไถนา',
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          // validator: (v) => v == null || v.isEmpty
                          //     ? 'กรุณากรอกรายละเอียด*'
                          //     : null,
                        ),

                        const SizedBox(height: 16),

                        //ทะเบียน (ไม่บังคับ)
                        Text('ป้ายทะเบียนรถ', style: labelStyle),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: plateController,
                          maxLength: 20,
                          decoration: const InputDecoration(
                            filled: true, //เปิดการเติมสีพื้นหลัง
                            fillColor: Colors.white, //กำหนดสีพื้นหลังเป็นสีขาว
                            border: OutlineInputBorder(),
                            counterText: '',
                            //hintText: 'ไม่บังคับ',
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        ),

                        const SizedBox(height: 32),

                        //ปุ่มยกเลิก/เพิ่มรถ
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        Navigator.pop(context, false);
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[300],
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text('ยกเลิก',
                                    style: cancelButtonTextStyle),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: (_isSubmitting || isLoading)
                                    ? isLoading
                                        ? () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('กรุณารอให้การอัปโหลดรูปเสร็จก่อน'),
                                                backgroundColor: Colors.orange,
                                              ),
                                            );
                                          }
                                        : null
                                    : () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title:
                                                const Text('ยืนยันการเพิ่มรถ'),
                                            content: const Text(
                                                'คุณแน่ใจหรือไม่ว่าต้องการเพิ่มรถคันนี้?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, false),
                                                child: const Text('ยกเลิก'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(
                                                    context, true),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                  foregroundColor: Colors.white,
                                                ),
                                                child: const Text('ตกลง'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          submitVehicle();
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: (_isSubmitting || isLoading)
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'เพิ่มรถ',
                                        style: submitButtonTextStyle,
                                      ),
                              ),
                            ),
                          ],
                        ),

                        // if (isLoading)
                        //   const Padding(
                        //     padding: EdgeInsets.all(8.0),
                        //     child: Center(child: CircularProgressIndicator()),
                        //   ),
                        const SizedBox(width: 50),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
