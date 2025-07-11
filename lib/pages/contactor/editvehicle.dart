import 'dart:convert';
import 'package:agri_booking2/pages/contactor/home.dart';
import 'package:agri_booking2/pages/contactor/DetailVehicle.dart';
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

      if (response.statusCode == 200) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('อัปเดตข้อมูลรถสำเร็จ'),
            content: const Text('ข้อมูลรถของคุณได้รับการอัปเดตแล้ว'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Detailvehicle(vid: _currentVid),
                    ),
                  );
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
      appBar: AppBar(
        backgroundColor: Color(0xFFFFCC99),
        title: Text('แก้ไขข้อมูลรถ #${_currentVid}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, true);
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
              // รูปภาพ
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
                    Text(
                      'เปลี่ยนรูปรถ',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ชื่อรถ
              Text(
                'ชื่อรถ',
                style: Theme.of(context).textTheme.titleMedium,
              ),
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

              // ราคา + หน่วย
              Text(
                'ราคาต่อพื้นที่ที่จ้างงาน (เช่น 100 บาท/ไร่)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
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
                      value: selectedUnit ?? 'ไร่',
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

              // รายละเอียด
              Text(
                'รายละเอียดรถ',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: detailController,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText:
                      'ตัดหญ้า ขุดดิน จ้างได้ไม่เกิน10ไร่ ราคาขึ้นอยู่กับหน้างาน แต่เริ่มต้นที่1000บาทต่อไร่',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'กรุณากรอกรายละเอียด' : null,
              ),
              const SizedBox(height: 16),

              // ป้ายทะเบียนรถ
              Text(
                'ป้ายทะเบียนรถ',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: plateController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(height: 32),

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
                      onPressed: isLoading ? null : updateVehicle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('ตกลง',
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
