import 'dart:convert';
import 'package:agri_booking_app2/pages/contactor/home.dart'; // Used for navigating to the Home page
import 'package:agri_booking_app2/pages/contactor/DetailVehicle.dart'; // Used for navigating to DetailVehicle after update
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
              if (imageUrl != null && imageUrl!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Image.network(
                  imageUrl!,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 150,
                    color: Colors.grey[300],
                    child: const Center(child: Text('ไม่สามารถโหลดรูปภาพได้')),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: updateVehicle,
                      child: const Text('บันทึกการแก้ไข'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
