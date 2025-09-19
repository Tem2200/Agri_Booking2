import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class EditVehicle extends StatefulWidget {
  final Map<String, dynamic>? initialVehicleData;

  const EditVehicle({
    super.key,
    this.initialVehicleData,
  });

  @override
  State<EditVehicle> createState() => _EditVehicleState();
}

class _EditVehicleState extends State<EditVehicle> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController unitPriceController = TextEditingController();
  final TextEditingController detailController = TextEditingController();
  final TextEditingController plateController = TextEditingController();

  // กำหนด style สำหรับหัวข้อข้อความ
  final TextStyle labelStyle = const TextStyle(
    fontSize: 16,
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

  String? imageUrl;
  bool isLoading = false;

  final ImagePicker picker = ImagePicker();

  late int _currentVid;
  late int _currentMid;

  String? selectedUnit;
  final TextEditingController customUnitController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialVehicleData != null) {
      _populateFields(widget.initialVehicleData!);

      _currentVid = widget.initialVehicleData!['vid'] ?? 0;
      _currentMid = widget.initialVehicleData!['mid'] ?? 0;

      // โหลด unit_price เข้ามา set ค่าใน dropdown
      String unit = widget.initialVehicleData!['unit_price'] ?? '';
      if (['ไร่', 'วัน', 'ชั่วโมง', 'ตารางวา'].contains(unit)) {
        selectedUnit = unit;
      } else if (unit.isNotEmpty) {
        selectedUnit = 'อื่นๆ';
        customUnitController.text = unit;
        unitPriceController.text = unit;
      }
    } else {
      print("Error: initialVehicleData is null in EditVehicle.");
      _currentVid = 0;
      _currentMid = 0;
    }
  }

  void _populateFields(Map<String, dynamic> data) {
    nameController.text = data['name_vehicle'] ?? '';
    priceController.text = data['price']?.toString() ?? '';
    unitPriceController.text = data['unit_price'] ?? '';
    detailController.text = data['detail'] ?? '';
    plateController.text = data['plate_number'] ?? '';
    imageUrl = data['image_vehicle'];
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
        throw Exception('อัปโหลดรูปภาพล้มเหลว: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการอัปโหลดรูปภาพ: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> updateVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final data = {
      "vid": _currentVid,
      "name_vehicle": nameController.text,
      "price": int.tryParse(priceController.text) ?? 0,
      "unit_price": selectedUnit == 'อื่นๆ'
          ? customUnitController.text
          : (selectedUnit ?? ''),
      "image": imageUrl,
      "detail": detailController.text,
      "plate_number":
          plateController.text.isEmpty ? null : plateController.text,
    };

    try {
      final url = Uri.parse(
          'http://projectnodejs.thammadalok.com/AGribooking/update_vehicle');
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      // if (response.statusCode == 200) {
      //   showDialog(
      //     context: context,
      //     builder: (_) => AlertDialog(
      //       title: const Text('อัปเดตข้อมูลรถสำเร็จ'),
      //       content: const Text('ข้อมูลรถของคุณได้รับการอัปเดตแล้ว'),
      //       actions: [
      //         TextButton(
      //           onPressed: () {
      //             Navigator.pop(context);
      //             Navigator.pushReplacement(
      //               context,
      //               MaterialPageRoute(
      //                 builder: (context) => Detailvehicle(vid: _currentVid),
      //               ),
      //             );
      //           },
      //           child: const Text('ตกลง'),
      //         ),
      //       ],
      //     ),
      //   );
      // }
      if (response.statusCode == 200) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('อัปเดตข้อมูลรถสำเร็จ'),
            content: const Text('ข้อมูลรถของคุณได้รับการอัปเดตแล้ว'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // ปิด Dialog ก่อน
                  Navigator.pop(
                      context, true); // กลับไปหน้าก่อนหน้า พร้อมส่งค่า true
                },
                child: const Text('ตกลง'),
              ),
            ],
          ),
        );
      } else {
        throw Exception('ผิดพลาดในการอัปเดต: ${response.body}');
      }
    } catch (e) {
      print('Error updating vehicle: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถอัปเดตข้อมูลรถได้: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    customUnitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 217, 180),
      appBar: AppBar(
        //backgroundColor: const Color.fromARGB(255, 255, 158, 60),
        backgroundColor: const Color.fromARGB(255, 18, 143, 9),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: const Text(
          'เพิ่มรถรับจ้าง',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 255, 255, 255),
            shadows: [
              Shadow(
                color: Color.fromARGB(115, 253, 237, 237),
                blurRadius: 3,
                offset: Offset(1.5, 1.5),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          // ✅ ภาพพื้นหลังแบบเต็มจอ
          // Positioned.fill(
          //   child: Image.network(
          //     'https://i.ibb.co/FbG6mQrF/Rectangle-33-1.png', // 🔗 เปลี่ยนลิงก์ภาพได้
          //     fit: BoxFit.cover,
          //   ),
          // ),

          // ✅ ชั้นที่มีเนื้อหาหลัก
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ✅ AppBar แบบกำหนดเอง
                  // Row(
                  //   children: [
                  //     IconButton(
                  //       icon: const Icon(Icons.arrow_back, color: Colors.white),
                  //       onPressed: () => Navigator.pop(context, true),
                  //     ),
                  //     const Spacer(),
                  //     const Text(
                  //       'แก้ไขข้อมูลรถ',
                  //       style: TextStyle(
                  //         fontSize: 22,
                  //         fontWeight: FontWeight.bold,
                  //         color: Colors.white,
                  //         shadows: [
                  //           Shadow(
                  //             color: Color.fromARGB(115, 0, 0, 0),
                  //             blurRadius: 4,
                  //             offset: Offset(1, 1),
                  //           ),
                  //         ],
                  //       ),
                  //     ),
                  //     const Spacer(),
                  //   ],
                  // ),
                  // const SizedBox(height: 16),

                  // ✅ Card โปร่งใส
                  Card(
                    color: Colors.white.withOpacity(0.85), // โปร่งใส
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
                            // ⬇️ (ใส่ฟอร์มทั้งหมดของคุณตามที่คุณมีอยู่ เช่น รูปรถ, TextFormField, Dropdown, ปุ่ม ฯลฯ)
                            // ✅ รูปภาพ + ปุ่มเปลี่ยน
                            Center(
                              child: Column(
                                children: [
                                  Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 50,
                                        backgroundColor: Colors.grey[300],
                                        backgroundImage: imageUrl != null &&
                                                imageUrl!.isNotEmpty
                                            ? NetworkImage(imageUrl!)
                                            : null,
                                        child: imageUrl == null ||
                                                imageUrl!.isEmpty
                                            ? Icon(Icons.directions_car,
                                                size: 60,
                                                color: Colors.grey[600])
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
                                  Text('เปลี่ยนรูปรถ', style: labelStyle),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // ชื่อรถ
                            Text('ชื่อรถ', style: labelStyle),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                filled: true, // ✅ เปิดการเติมสีพื้นหลัง
                                fillColor:
                                    Colors.white, // ✅ กำหนดสีพื้นหลังเป็นสีขาว
                                border: OutlineInputBorder(),
                                hintText: 'ชื่อรถ',
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                              validator: (v) => v == null || v.isEmpty
                                  ? 'กรุณากรอกชื่อรถ'
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            // ราคา + หน่วย
                            Text('ราคาต่อพื้นที่ที่จ้างงาน (เช่น 100 บาท/ไร่)',
                                style: labelStyle),
                            const SizedBox(height: 8),
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
                                      //hintText: '500',
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                    ),
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'กรุณากรอกราคา'
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text('บาท/',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: selectedUnit ?? 'ไร่',
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
                                        ? 'กรุณาเลือกหน่วย'
                                        : null,
                                  ),
                                ),
                              ],
                            ),

                            if (selectedUnit == 'อื่นๆ') ...[
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: customUnitController,
                                decoration: const InputDecoration(
                                  filled: true, // ✅ เปิดการเติมสีพื้นหลัง
                                  fillColor: Colors
                                      .white, // ✅ กำหนดสีพื้นหลังเป็นสีขาว
                                  border: OutlineInputBorder(),
                                  hintText: 'กรอกหน่วยเอง เช่น เมตร',
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                                validator: (v) {
                                  if (selectedUnit == 'อื่นๆ' &&
                                      (v == null || v.isEmpty)) {
                                    return 'กรุณากรอกหน่วย';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  unitPriceController.text = value;
                                },
                              ),
                            ],

                            const SizedBox(height: 16),

                            // รายละเอียด
                            Text('รายละเอียดรถ', style: labelStyle),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: detailController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                filled: true, // ✅ เปิดการเติมสีพื้นหลัง
                                fillColor:
                                    Colors.white, // ✅ กำหนดสีพื้นหลังเป็นสีขาว
                                border: OutlineInputBorder(),
                                hintText:
                                    'ตัดหญ้า ขุดดิน จ้างได้ไม่เกิน10ไร่ ราคาขึ้นอยู่กับหน้างาน แต่เริ่มต้นที่1000บาทต่อไร่',
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                              // validator: (v) => v == null || v.isEmpty
                              //     ? 'กรุณากรอกรายละเอียด'
                              //     : null,
                            ),
                            const SizedBox(height: 16),

                            // ป้ายทะเบียนรถ
                            Text('ป้ายทะเบียนรถ', style: labelStyle),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: plateController,
                              decoration: const InputDecoration(
                                filled: true, // ✅ เปิดการเติมสีพื้นหลัง
                                fillColor:
                                    Colors.white, // ✅ กำหนดสีพื้นหลังเป็นสีขาว
                                border: OutlineInputBorder(),
                                hintText: '',
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // 📌 ตัวอย่างท้ายสุด: ปุ่ม
                            Row(
                              children: [
                                // ยกเลิก
                                Expanded(
                                  child: ElevatedButton.icon(
                                    label: Text('ยกเลิก',
                                        style: cancelButtonTextStyle),
                                    onPressed: isLoading
                                        ? null
                                        : () => Navigator.pop(context, false),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey[200],
                                      elevation: 2,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // ตกลง
                                Expanded(
                                  child: ElevatedButton.icon(
                                    label: const Text('ตกลง',
                                        style: submitButtonTextStyle),
                                    onPressed: isLoading ? null : updateVehicle,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green[700],
                                      elevation: 3,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (isLoading)
                              const Padding(
                                padding: EdgeInsets.all(8),
                                child:
                                    Center(child: CircularProgressIndicator()),
                              ),
                          ],
                        ),
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

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     backgroundColor: Color.fromARGB(255, 255, 240, 195),
  //     appBar: AppBar(
  //       backgroundColor: const Color.fromARGB(255, 255, 158, 60),
  //       centerTitle: true, // ✅ บังคับให้อยู่ตรงกลาง
  //       title: Text(
  //         'แก้ไขข้อมูลรถ #${_currentVid}',
  //         style: const TextStyle(
  //           fontSize: 22,
  //           fontWeight: FontWeight.bold,
  //           color: Color.fromARGB(255, 255, 255, 255),
  //           //letterSpacing: 1,
  //           shadows: [
  //             Shadow(
  //               color: Color.fromARGB(115, 253, 237, 237),
  //               blurRadius: 3,
  //               offset: Offset(1.5, 1.5),
  //             ),
  //           ],
  //         ),
  //       ),
  //       iconTheme: const IconThemeData(
  //         color: Colors.white, // ✅ ลูกศรย้อนกลับสีขาว
  //       ),
  //       leading: IconButton(
  //         icon: const Icon(Icons.arrow_back),
  //         onPressed: () {
  //           Navigator.pop(context, true);
  //         },
  //       ),
  //     ),
  //     body: SingleChildScrollView(
  //       padding: const EdgeInsets.all(16),
  //       child: Form(
  //         key: _formKey,
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.stretch,
  //           children: [
  //             // รูปภาพ
  //             Center(
  //               child: Column(
  //                 children: [
  //                   Stack(
  //                     children: [
  //                       CircleAvatar(
  //                         radius: 50,
  //                         backgroundColor: Colors.grey[300],
  //                         backgroundImage:
  //                             imageUrl != null && imageUrl!.isNotEmpty
  //                                 ? NetworkImage(imageUrl!)
  //                                 : null,
  //                         child: imageUrl == null || imageUrl!.isEmpty
  //                             ? Icon(Icons.directions_car,
  //                                 size: 60, color: Colors.grey[600])
  //                             : null,
  //                       ),
  //                       Positioned(
  //                         bottom: 0,
  //                         right: 0,
  //                         child: CircleAvatar(
  //                           backgroundColor: Colors.green[700],
  //                           radius: 18,
  //                           child: IconButton(
  //                             icon: const Icon(Icons.edit,
  //                                 color: Colors.white, size: 20),
  //                             onPressed: isLoading ? null : pickAndUploadImage,
  //                           ),
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                   const SizedBox(height: 8),
  //                   Text('เปลี่ยนรูปรถ', style: labelStyle),
  //                 ],
  //               ),
  //             ),
  //             const SizedBox(height: 24),

  //             // ชื่อรถ
  //             Text('ชื่อรถ', style: labelStyle),
  //             const SizedBox(height: 8),
  //             TextFormField(
  //               controller: nameController,
  //               decoration: const InputDecoration(
  //                 filled: true, // ✅ เปิดการเติมสีพื้นหลัง
  //                 fillColor: Colors.white, // ✅ กำหนดสีพื้นหลังเป็นสีขาว
  //                 border: OutlineInputBorder(),
  //                 hintText: 'ชื่อรถ',
  //                 contentPadding:
  //                     EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  //               ),
  //               validator: (v) =>
  //                   v == null || v.isEmpty ? 'กรุณากรอกชื่อรถ' : null,
  //             ),
  //             const SizedBox(height: 16),

  //             // ราคา + หน่วย
  //             Text('ราคาต่อพื้นที่ที่จ้างงาน (เช่น 100 บาท/ไร่)',
  //                 style: labelStyle),
  //             const SizedBox(height: 8),
  //             Row(
  //               children: [
  //                 Expanded(
  //                   child: TextFormField(
  //                     controller: priceController,
  //                     keyboardType: TextInputType.number,
  //                     decoration: const InputDecoration(
  //                       filled: true, // ✅ เปิดการเติมสีพื้นหลัง
  //                       fillColor: Colors.white, // ✅ กำหนดสีพื้นหลังเป็นสีขาว
  //                       border: OutlineInputBorder(),
  //                       hintText: '500',
  //                       contentPadding:
  //                           EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  //                     ),
  //                     validator: (v) =>
  //                         v == null || v.isEmpty ? 'กรุณากรอกราคา' : null,
  //                   ),
  //                 ),
  //                 const SizedBox(width: 16),
  //                 Text('บาท/', style: Theme.of(context).textTheme.titleMedium),
  //                 const SizedBox(width: 16),
  //                 Expanded(
  //                   child: DropdownButtonFormField<String>(
  //                     value: selectedUnit ?? 'ไร่',
  //                     decoration: const InputDecoration(
  //                       filled: true, // ✅ เปิดการเติมสีพื้นหลัง
  //                       fillColor: Colors.white, // ✅ กำหนดสีพื้นหลังเป็นสีขาว
  //                       border: OutlineInputBorder(),
  //                       contentPadding:
  //                           EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  //                     ),
  //                     items: [
  //                       'ไร่',
  //                       'วัน',
  //                       'ชั่วโมง',
  //                       'ตารางวา',
  //                       'อื่นๆ',
  //                     ].map((unit) {
  //                       return DropdownMenuItem<String>(
  //                         value: unit,
  //                         child: Text(unit),
  //                       );
  //                     }).toList(),
  //                     onChanged: (value) {
  //                       setState(() {
  //                         selectedUnit = value;
  //                         if (value != 'อื่นๆ') {
  //                           unitPriceController.text = value!;
  //                         } else {
  //                           unitPriceController.clear();
  //                         }
  //                       });
  //                     },
  //                     validator: (v) =>
  //                         v == null || v.isEmpty ? 'กรุณาเลือกหน่วย' : null,
  //                   ),
  //                 ),
  //               ],
  //             ),

  //             if (selectedUnit == 'อื่นๆ') ...[
  //               const SizedBox(height: 16),
  //               TextFormField(
  //                 controller: customUnitController,
  //                 decoration: const InputDecoration(
  //                   filled: true, // ✅ เปิดการเติมสีพื้นหลัง
  //                   fillColor: Colors.white, // ✅ กำหนดสีพื้นหลังเป็นสีขาว
  //                   border: OutlineInputBorder(),
  //                   hintText: 'กรอกหน่วยเอง เช่น เมตร',
  //                   contentPadding:
  //                       EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  //                 ),
  //                 validator: (v) {
  //                   if (selectedUnit == 'อื่นๆ' && (v == null || v.isEmpty)) {
  //                     return 'กรุณากรอกหน่วย';
  //                   }
  //                   return null;
  //                 },
  //                 onChanged: (value) {
  //                   unitPriceController.text = value;
  //                 },
  //               ),
  //             ],

  //             const SizedBox(height: 16),

  //             // รายละเอียด
  //             Text('รายละเอียดรถ', style: labelStyle),
  //             const SizedBox(height: 8),
  //             TextFormField(
  //               controller: detailController,
  //               maxLines: 3,
  //               decoration: const InputDecoration(
  //                 filled: true, // ✅ เปิดการเติมสีพื้นหลัง
  //                 fillColor: Colors.white, // ✅ กำหนดสีพื้นหลังเป็นสีขาว
  //                 border: OutlineInputBorder(),
  //                 hintText:
  //                     'ตัดหญ้า ขุดดิน จ้างได้ไม่เกิน10ไร่ ราคาขึ้นอยู่กับหน้างาน แต่เริ่มต้นที่1000บาทต่อไร่',
  //                 contentPadding:
  //                     EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  //               ),
  //               validator: (v) =>
  //                   v == null || v.isEmpty ? 'กรุณากรอกรายละเอียด' : null,
  //             ),
  //             const SizedBox(height: 16),

  //             // ป้ายทะเบียนรถ
  //             Text('ป้ายทะเบียนรถ', style: labelStyle),
  //             const SizedBox(height: 8),
  //             TextFormField(
  //               controller: plateController,
  //               decoration: const InputDecoration(
  //                 filled: true, // ✅ เปิดการเติมสีพื้นหลัง
  //                 fillColor: Colors.white, // ✅ กำหนดสีพื้นหลังเป็นสีขาว
  //                 border: OutlineInputBorder(),
  //                 hintText: '',
  //                 contentPadding:
  //                     EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  //               ),
  //             ),
  //             const SizedBox(height: 32),

  //             Row(
  //               children: [
  //                 // 🔴 ปุ่มยกเลิก
  //                 Expanded(
  //                   child: ElevatedButton.icon(
  //                     icon: const Icon(Icons.close, color: Colors.black87),
  //                     label: Text('ยกเลิก', style: cancelButtonTextStyle),
  //                     onPressed: isLoading
  //                         ? null
  //                         : () => Navigator.pop(context, false),
  //                     style: ElevatedButton.styleFrom(
  //                       backgroundColor: Colors.grey[200], // สีพื้นแบบนุ่ม
  //                       elevation: 2, // เงาเล็กน้อย
  //                       padding: const EdgeInsets.symmetric(vertical: 14),
  //                       shape: RoundedRectangleBorder(
  //                         borderRadius: BorderRadius.circular(12),
  //                       ),
  //                     ),
  //                   ),
  //                 ),

  //                 const SizedBox(width: 16),

  //                 // ✅ ปุ่มตกลง
  //                 Expanded(
  //                   child: ElevatedButton.icon(
  //                     icon: const Icon(Icons.check, color: Colors.white),
  //                     label: const Text('ตกลง', style: submitButtonTextStyle),
  //                     onPressed: isLoading ? null : updateVehicle,
  //                     style: ElevatedButton.styleFrom(
  //                       backgroundColor: Colors.green[700],
  //                       elevation: 3,
  //                       padding: const EdgeInsets.symmetric(vertical: 14),
  //                       shape: RoundedRectangleBorder(
  //                         borderRadius: BorderRadius.circular(12),
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),

  //             if (isLoading)
  //               const Padding(
  //                 padding: EdgeInsets.all(8.0),
  //                 child: Center(child: CircularProgressIndicator()),
  //               ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
}
