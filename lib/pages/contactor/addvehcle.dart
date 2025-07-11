import 'dart:convert';
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
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomePage(
                        mid: widget.mid,
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
      appBar: AppBar(
        title: const Text('เพิ่มรถ'),
        backgroundColor: const Color(0xFFFFCC99),
        leading: IconButton(
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ✅ รูปรถ + ปุ่มแก้ไข
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[300],
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
                              onPressed: isLoading ? null : pickAndUploadImage,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('เพิ่มรูปรถ',
                        style:
                            TextStyle(fontSize: 14, color: Colors.grey[700])),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ✅ ชื่อรถ
              Text('ชื่อรถ', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'ชื่อรถ',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'กรุณากรอกชื่อรถ' : null,
              ),

              const SizedBox(height: 16),

              // ✅ ราคาต่อหน่วย
              Text('ราคาต่อพื้นที่ที่จ้างงาน (เช่น 100 บาท/ไร่)',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              // เก็บค่า dropdown ที่เลือ

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '500',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'กรุณากรอกราคา' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text('บาท/', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedUnit = 'ไร่',
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      validator: (v) =>
                          v == null || v.isEmpty ? 'กรุณาเลือกหน่วย' : null,
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
                    border: OutlineInputBorder(),
                    hintText: 'กรอกหน่วยเอง เช่น เมตร',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  validator: (v) {
                    if (selectedUnit == 'อื่นๆ' && (v == null || v.isEmpty)) {
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

              // ✅ รายละเอียด
              Text('รายละเอียดรถ',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: detailController,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'อธิบายการใช้งานรถ เช่น ขุดดิน ไถนา',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'กรุณากรอกรายละเอียด' : null,
              ),

              const SizedBox(height: 16),

              // ✅ ทะเบียน (ไม่บังคับ)
              Text('ป้ายทะเบียนรถ',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: plateController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'ไม่บังคับ',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('ยกเลิก',
                          style: TextStyle(color: Colors.grey[800])),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLoading ? null : submitVehicle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('เพิ่มรถ',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),

              if (isLoading)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
