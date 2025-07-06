import 'dart:convert';
import 'package:agri_booking_app2/pages/contactor/home.dart';
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

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        final int vid = res['vid'];
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('เพิ่มรถสำเร็จ'),
            content: Text('รหัสรถ (VID): $vid'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // ปิด dialog
                  Navigator.pop(context, true); // กลับหน้า Home
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(mid: widget.mid),
              ), // ← ไปหน้า Login
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
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'ชื่อรถ'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'กรุณากรอกชื่อรถ' : null,
              ),
              TextFormField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'ราคา'),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v == null || v.isEmpty ? 'กรุณากรอกราคา' : null,
              ),
              TextFormField(
                controller: unitPriceController,
                decoration: const InputDecoration(
                    labelText: 'หน่วยราคา (เช่น ชั่วโมง, ไร่)'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'กรุณากรอกหน่วยราคา' : null,
              ),
              TextFormField(
                controller: detailController,
                decoration: const InputDecoration(labelText: 'รายละเอียด'),
                maxLines: 3,
                validator: (v) =>
                    v == null || v.isEmpty ? 'กรุณากรอกรายละเอียด' : null,
              ),
              TextFormField(
                controller: plateController,
                decoration:
                    const InputDecoration(labelText: 'ทะเบียนรถ (ไม่บังคับ)'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: isLoading ? null : pickAndUploadImage,
                icon: const Icon(Icons.image),
                label: const Text('เลือกรูปภาพ (อัปโหลดไป imgbb)'),
              ),
              if (imageUrl != null) ...[
                const SizedBox(height: 12),
                Image.network(imageUrl!, height: 150),
              ],
              const SizedBox(height: 20),
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: submitVehicle,
                      child: const Text('เพิ่มรถ'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
