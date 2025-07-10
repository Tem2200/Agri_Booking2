import 'dart:convert';
import 'package:agri_booking2/pages/contactor/home.dart'; // Used for navigating to the Home page
import 'package:agri_booking2/pages/contactor/DetailVehicle.dart'; // Used for navigating to DetailVehicle after update
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class EditVehicle extends StatefulWidget {
  // Receives all initial data through initialVehicleData
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

  // Variables to store vid and mid extracted from initialVehicleData
  late int _currentVid;
  late int
      _currentMid; // Still keeps mid in case it's needed to go back to Home (though currently navigates to DetailVehicle)

  @override
  void initState() {
    super.initState();
    // Check and extract data from initialVehicleData to set initial values
    if (widget.initialVehicleData != null) {
      _populateFields(widget.initialVehicleData!);
      // Extract vid and mid from the passed data
      _currentVid = widget.initialVehicleData!['vid'] ?? 0;
      _currentMid = widget.initialVehicleData!['mid'] ?? 0;
    } else {
      // Case where initialVehicleData is null (should not happen if called from DetailVehicle)
      print("Error: initialVehicleData is null in EditVehicle.");
      // Set default values to prevent errors
      _currentVid = 0;
      _currentMid = 0;
    }
  }

  // Function to populate controllers from vehicle data
  void _populateFields(Map<String, dynamic> data) {
    nameController.text = data['name_vehicle'] ?? '';
    priceController.text = data['price']?.toString() ?? '';
    unitPriceController.text = data['unit_price'] ?? '';
    detailController.text = data['detail'] ?? '';
    plateController.text = data['plate_number'] ?? '';
    imageUrl = data['image'];
  }

  // Function to pick and upload image
  Future<void> pickAndUploadImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() => isLoading = true);

    try {
      final bytes = await pickedFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      const apiKey =
          'a051ad7a04e7037b74d4d656e7d667e9'; // API Key should be stored more securely in Production
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

  // Function to send updated vehicle data to the API
  Future<void> updateVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final data = {
      "vid": _currentVid, // Use _currentVid extracted from initialVehicleData
      "name_vehicle": nameController.text,
      "price": int.tryParse(priceController.text) ?? 0,
      "unit_price": unitPriceController.text,
      "image": imageUrl,
      "detail": detailController.text,
      "plate_number":
          plateController.text.isEmpty ? null : plateController.text,
    };

    try {
      final url = Uri.parse(
          'http://projectnodejs.thammadalok.com/AGribooking/update_vehicle');
      final response = await http.put(
        // Using http.put as the API might expect for updates
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
                  Navigator.pop(context); // Close the dialog
                  // Navigate to DetailVehicle and replace the current route
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Display vid from _currentVid
        backgroundColor: Color(0xFFFFCC99),
        title: Text('แก้ไขข้อมูลรถ #${_currentVid}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // When pressing the back button, send 'true' back to DetailVehicle
            // to signal that DetailVehicle should refresh its data
            Navigator.pop(context, true);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch, // Ensure elements stretch
            children: [
              // Profile Picture Section
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50, // กำหนดขนาดรัศมีของวงกลม
                          backgroundColor:
                              Colors.grey[300], // สีพื้นหลังเมื่อไม่มีรูปภาพ
                          // ตรงนี้คือส่วนที่รวมการแสดงรูปภาพจาก URL เข้ามาแล้ว:
                          backgroundImage: imageUrl != null &&
                                  imageUrl!.isNotEmpty
                              ? NetworkImage(
                                  imageUrl!) // ถ้า imageUrl มีค่าและไม่ว่างเปล่า ให้แสดงรูปจาก Network
                              : null, // ถ้าไม่มีค่า ก็ไม่ต้องมี backgroundImage
                          child: imageUrl == null || imageUrl!.isEmpty
                              ? Icon(
                                  Icons
                                      .directions_car, // ถ้าไม่มี imageUrl (ยังไม่เคยเลือกรูป) ให้แสดงไอคอนคนแทน
                                  size: 60,
                                  color: Colors.grey[600])
                              : null, // ถ้ามี imageUrl แล้ว ก็ไม่ต้องแสดงไอคอน
                        ),
                        Positioned(
                          bottom: 0, // ตำแหน่งปุ่มแก้ไขรูป (ด้านล่าง)
                          right: 0, // ตำแหน่งปุ่มแก้ไขรูป (ด้านขวา)
                          child: CircleAvatar(
                            backgroundColor:
                                Colors.green[700], // สีพื้นหลังของปุ่มแก้ไข
                            radius: 18, // ขนาดปุ่มแก้ไข
                            child: IconButton(
                              icon: const Icon(
                                  Icons.edit, // ไอคอนรูปดินสอ (แก้ไข)
                                  color: Colors.white,
                                  size: 20), // สีขาว ขนาด 20
                              onPressed: isLoading
                                  ? null // ถ้ากำลังโหลดอยู่ ปุ่มจะถูกปิดใช้งาน
                                  : pickAndUploadImage, // ถ้าไม่กำลังโหลด กดแล้วจะเรียกฟังก์ชันเลือกและอัปโหลดรูป
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8), // เว้นช่องว่าง 8 หน่วย
                    Text(
                      'เปลี่ยนรูปรถ', // ข้อความ "เปลี่ยนรูปรถ" ใต้รูป
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700]), // สไตล์ข้อความ
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24), // Increased spacing

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
                  hintText: 'ชื่อรถ', // Placeholder text
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'กรุณากรอกชื่อรถ' : null,
              ),
              const SizedBox(height: 16),

              // ราคาต่อพื้นที่ที่จ้างงาน & หน่วยราคาจ้างงาน
              Text(
                'ราคาต่อพื้นที่ที่จ้างงาน (เช่น 100 ต่อ ไร่) ',
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
                        hintText: '500', // Placeholder text
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'กรุณากรอกราคา' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'บาท',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: unitPriceController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'ชั่วโมง', // Placeholder text
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'กรุณากรอกหน่วยราคา' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // รายละเอียดรถ
              Text(
                'รายละเอียดรถ',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: detailController,
                maxLines: 3, // As per your original code
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText:
                      'ตัดหญ้า ขุดดิน จ้างได้ไม่เกิน10ไร่ ราคาขึ้นอยู่กับหน้างาน แต่เริ่มต้นที่1000บาทต่อไร่', // Placeholder text
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
                  hintText:
                      '', // No specific placeholder shown in image for this
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(height: 32), // Spacing before buttons

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              Navigator.pop(context,
                                  false); // No refresh needed if cancelled
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.grey[300], // Grey background for "Cancel"
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'ยกเลิก',
                        style: TextStyle(color: Colors.grey[800]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLoading ? null : updateVehicle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.green, // Green background for "Confirm"
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'ตกลง',
                        style: TextStyle(color: Colors.white),
                      ),
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
