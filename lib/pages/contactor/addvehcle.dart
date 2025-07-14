import 'dart:convert';
import 'dart:ui';
import 'package:agri_booking2/pages/contactor/Tabbar.dart';
import 'package:agri_booking2/pages/contactor/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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
  static const TextStyle submitButtonTextStyle = const TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w600,
  );

  String? imageUrl; // URL ของรูปภาพหลังอัปโหลด
  bool isLoading = false;

  final ImagePicker picker = ImagePicker();
  String? selectedUnit;
  final TextEditingController customUnitController = TextEditingController();

  @override
  void dispose() {
    customUnitController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    selectedUnit = 'ไร่'; // กำหนดค่าเริ่มต้นที่นี่แทน
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('อัปโหลดรูปภาพสำเร็จ')),
        );
      } else {
        throw Exception('อัปโหลดรูปภาพล้มเหลว');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> submitVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final data = {
      "name_vehicle": nameController.text,
      "price": int.tryParse(priceController.text) ?? 0,
      "unit_price": unitPriceController.text,
      "image": imageUrl, // ถ้าไม่มีรูป ส่ง null
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
          builder: (_) => AlertDialog(
            title: const Text('เพิ่มรถสำเร็จ'),
            content: Text('รหัสรถ (VID): $vid'),
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
        );
      } else {
        throw Exception('ผิดพลาด: ${response.body}');
      }
    } catch (e) {
      print('Error: $e'); // แสดงในคอนโซล
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถเพิ่มรถได้: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF006000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF006000),
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
          // ✅ พื้นหลังเต็มหน้าจอ
          Positioned.fill(
            child: Image.network(
              'https://i.ibb.co/FbG6mQrF/Rectangle-33-1.png',
              fit: BoxFit.cover,
            ),
          ),

          // ✅ เนื้อหาแบบ Scroll ได้
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Card(
                color: Colors.white
                    .withOpacity(0.9), // หรือปรับ 0.8, 0.85 ตามความโปร่งใส

                elevation: 6,
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
                                  CircleAvatar(
                                    radius: 50,
                                    backgroundColor: const Color.fromARGB(
                                        255, 255, 253, 253),
                                    backgroundImage:
                                        imageUrl != null && imageUrl!.isNotEmpty
                                            ? NetworkImage(imageUrl!)
                                            : null,
                                    child: imageUrl == null || imageUrl!.isEmpty
                                        ? Icon(Icons.directions_car,
                                            size: 60, color: Colors.grey[600])
                                        : null,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.green[700],
                                      radius: 18,
                                      child: IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.white, size: 20),
                                        onPressed: isLoading
                                            ? null
                                            : pickAndUploadImage,
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

                        // ✅ ชื่อรถ
                        Text('ชื่อรถ *', style: labelStyle),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            filled: true, // ✅ เปิดการเติมสีพื้นหลัง
                            fillColor:
                                Colors.white, // ✅ กำหนดสีพื้นหลังเป็นสีขาว
                            border: OutlineInputBorder(),
                            //hintText: 'ชื่อรถ',
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'กรุณากรอกชื่อรถ*'
                              : null,
                        ),

                        const SizedBox(height: 16),

                        // ✅ ราคาต่อหน่วย
                        Text('ราคาต่อพื้นที่จ้างงาน(เช่น100บาท/ไร่)*',
                            style: labelStyle),
                        const SizedBox(height: 8),
                        // เก็บค่า dropdown ที่เลือ

                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: priceController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  filled: true, // ✅ เปิดการเติมสีพื้นหลัง
                                  fillColor: Colors
                                      .white, // ✅ กำหนดสีพื้นหลังเป็นสีขาว
                                  border: OutlineInputBorder(),
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
                            decoration: const InputDecoration(
                              filled: true, // ✅ เปิดการเติมสีพื้นหลัง
                              fillColor:
                                  Colors.white, // ✅ กำหนดสีพื้นหลังเป็นสีขาว
                              border: OutlineInputBorder(),
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

                        // ✅ รายละเอียด
                        Text('รายละเอียดรถ *', style: labelStyle),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: detailController,
                          maxLines: 1,
                          decoration: const InputDecoration(
                            filled: true, // ✅ เปิดการเติมสีพื้นหลัง
                            fillColor:
                                Colors.white, // ✅ กำหนดสีพื้นหลังเป็นสีขาว
                            border: OutlineInputBorder(),
                            //hintText: 'อธิบายการใช้งานรถ เช่น ขุดดิน ไถนา',
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'กรุณากรอกรายละเอียด*'
                              : null,
                        ),

                        const SizedBox(height: 16),

                        // ✅ ทะเบียน (ไม่บังคับ)
                        Text('ป้ายทะเบียนรถ', style: labelStyle),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: plateController,
                          decoration: const InputDecoration(
                            filled: true, // ✅ เปิดการเติมสีพื้นหลัง
                            fillColor:
                                Colors.white, // ✅ กำหนดสีพื้นหลังเป็นสีขาว
                            border: OutlineInputBorder(),
                            //hintText: 'ไม่บังคับ',
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ✅ ปุ่มยกเลิก/เพิ่มรถ
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
                                onPressed: isLoading ? null : submitVehicle,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('เพิ่มรถ',
                                    style: submitButtonTextStyle),
                              ),
                            ),
                          ],
                        ),

                        if (isLoading)
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Center(child: CircularProgressIndicator()),
                          ),
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
