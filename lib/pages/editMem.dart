import 'dart:convert';
import 'dart:io';
import 'package:agri_booking2/pages/assets/location_data.dart';
import 'package:agri_booking2/pages/map_edit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart'; // Assuming you have a file with location data
import 'package:google_fonts/google_fonts.dart';

class EditMemberPage extends StatefulWidget {
  final Map<String, dynamic> memberData;

  const EditMemberPage({super.key, required this.memberData});

  @override
  State<EditMemberPage> createState() => _EditMemberPageState();
}

class _EditMemberPageState extends State<EditMemberPage> {
  late TextEditingController usernameController;
  late TextEditingController phoneController;
  late TextEditingController addressController;
  late TextEditingController provinceController;
  late TextEditingController districtController;
  late TextEditingController subdistrictController;
  late TextEditingController otherController;

  double? _selectedLat;
  double? _selectedLng;
  bool _imageUploaded = false;
  String? _imageUrl;

  List<String> provinces = [];
  List<String> amphoes = [];
  List<String> districts = [];

  String? selectedProvince;
  String? selectedAmphoe;
  String? selectedDistrict;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    usernameController =
        TextEditingController(text: widget.memberData['username'] ?? '');
    phoneController =
        TextEditingController(text: widget.memberData['phone'] ?? '');
    addressController =
        TextEditingController(text: widget.memberData['detail_address'] ?? '');

    provinceController =
        TextEditingController(text: widget.memberData['province'] ?? '');
    districtController =
        TextEditingController(text: widget.memberData['district'] ?? '');
    subdistrictController =
        TextEditingController(text: widget.memberData['subdistrict'] ?? '');
    otherController =
        TextEditingController(text: widget.memberData['other'] ?? '');

    _selectedLat = widget.memberData['latitude'];
    _selectedLng = widget.memberData['longitude'];

    _imageUrl = widget.memberData['image'];
    _imageUploaded = _imageUrl != null && _imageUrl!.isNotEmpty;

    // ดึง province ทั้งหมด
    provinces = locationData
        .map((e) => e['province'] as String)
        .toSet()
        .toList()
      ..sort();

    // Set ค่า province/district/subdistrict จาก memberData
    selectedProvince = widget.memberData['province'];
    if (selectedProvince != null) {
      amphoes = locationData
          .where((e) => e['province'] == selectedProvince)
          .map((e) => e['amphoe'] as String)
          .toSet()
          .toList()
        ..sort();
    }

    selectedAmphoe = widget.memberData['district'];
    if (selectedProvince != null && selectedAmphoe != null) {
      districts = locationData
          .where((e) =>
              e['province'] == selectedProvince &&
              e['amphoe'] == selectedAmphoe)
          .map((e) => e['district'] as String)
          .toSet()
          .toList()
        ..sort();
    }

    selectedDistrict = widget.memberData['subdistrict'];
  }

  @override
  void dispose() {
    usernameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    provinceController.dispose();
    districtController.dispose();
    subdistrictController.dispose();
    super.dispose();
  }

  Future<void> _selectLocationOnMap() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapEdit(
          initialLat: _selectedLat,
          initialLng: _selectedLng,
        ),
      ),
    );

    if (result != null && result is Map<String, double>) {
      setState(() {
        _selectedLat = result['lat'];
        _selectedLng = result['lng'];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'เลือกตำแหน่งแผนที่แล้ว: Lat ${_selectedLat?.toStringAsFixed(4)}, Lng ${_selectedLng?.toStringAsFixed(4)}')),
      );
    }
  }

  Future<String?> uploadImageToImgbb(File imageFile) async {
    const apiKey = 'a051ad7a04e7037b74d4d656e7d667e9';
    final url = Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey');

    final base64Image = base64Encode(await imageFile.readAsBytes());
    final response = await http.post(
      url,
      body: {'image': base64Image},
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return responseData['data']['url'];
    } else {
      print('อัปโหลดรูปไม่สำเร็จ: ${response.body}');
      return null;
    }
  }

  bool _isUploadingImage = false;

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() => _isUploadingImage = true);

      final imageFile = File(pickedFile.path);
      final imageUrl = await uploadImageToImgbb(imageFile);

      if (imageUrl != null) {
        setState(() {
          _imageUrl = imageUrl;
          widget.memberData['image'] = imageUrl;
          _imageUploaded = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('อัปโหลดรูปสำเร็จ')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('อัปโหลดรูปไม่สำเร็จ')),
        );
      }

      setState(() => _isUploadingImage = false);
    }
  }

  void _submit() async {
    final updatedData = {
      "mid": widget.memberData['mid'],
      "username": usernameController.text,
      "phone": phoneController.text,
      "image": (_imageUrl != null && _imageUrl!.isNotEmpty)
          ? _imageUrl
          : null, // ใช้ null ถ้าไม่มีรูป
      "province": selectedProvince,
      "district": selectedAmphoe,
      "subdistrict": selectedDistrict,
      "detail_address":
          addressController.text.isNotEmpty ? addressController.text : "",
      "latitude": _selectedLat,
      "longitude": _selectedLng,
      "other": otherController.text.isNotEmpty ? otherController.text : "",
      "type_member": widget.memberData['type_member'],
    };

    try {
      final url = Uri.parse(
          'http://projectnodejs.thammadalok.com/AGribooking/update_member');
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updatedData),
      );

      if (response.statusCode == 200) {
        Fluttertoast.showToast(
          msg: 'อัปเดตข้อมูลสำเร็จ',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        Navigator.pop(context, true);
      } else {
        print(jsonEncode(updatedData));
        print(response.statusCode);
        print(response.body);
        Fluttertoast.showToast(
          msg: 'อัปเดตข้อมูลล้มเหลว: ${response.body}',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
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
      print('เกิดข้อผิดพลาด: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //backgroundColor: const Color.fromARGB(255, 255, 158, 60),
        backgroundColor: const Color.fromARGB(255, 18, 143, 9),
        centerTitle: true, // ✅ บังคับให้อยู่ตรงกลาง
        title: const Text(
          'แก้ไขข้อมูลส่วนตัว',
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
        iconTheme: const IconThemeData(
          color: Colors.white, // ✅ ลูกศรย้อนกลับสีขาว
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
Center(
  child: Stack(
    alignment: Alignment.bottomRight,
    children: [
      CircleAvatar(
        radius: 50,
        backgroundImage: _imageUrl != null && _imageUrl!.isNotEmpty
            ? NetworkImage(_imageUrl!)
            : const AssetImage('assets/profile.png') as ImageProvider,
      ),
      CircleAvatar(
        radius: 16,
        backgroundColor: Colors.white,
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(
            _imageUrl != null && _imageUrl!.isNotEmpty
                ? Icons.close // ถ้ามีรูป → แสดงกากบาท
                : Icons.edit, // ถ้าไม่มีรูป → แสดงดินสอ
            size: 16,
            color: _imageUrl != null && _imageUrl!.isNotEmpty
                ? Colors.red
                : Colors.green,
          ),
          onPressed: () {
            setState(() {
              if (_imageUrl != null && _imageUrl!.isNotEmpty) {
                // 👉 ถ้ามีรูปแล้วกด = ลบรูป
                _imageUrl = null;
              } else {
                // 👉 ถ้ายังไม่มีรูป = อัปโหลดรูปใหม่
                _pickAndUploadImage();
              }
            });
          },
        ),
      ),
    ],
  ),
),

              const SizedBox(height: 10),

              // Input fields
              buildInput(
                usernameController,
                'ชื่อผู้ใช้',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกชื่อผู้ใช้';
                  }
                  return null;
                },
              ),
              buildInputPhone(
                phoneController,
                'เบอร์โทร',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกเบอร์โทร';
                  }
                  if (!RegExp(r'^0\d{9}$').hasMatch(value)) {
                    return 'เบอร์โทรต้องเป็นตัวเลข 10 หลัก และขึ้นต้นด้วย 0';
                  }
                  return null;
                },
              ),
              buildDropdownInput(
                label: 'จังหวัด',
                value: selectedProvince,
                items: provinces,
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
                validator: (value) =>
                    value == null ? 'กรุณาเลือกจังหวัด' : null,
              ),

              buildDropdownInput(
                label: 'อำเภอ',
                value: selectedAmphoe,
                items: amphoes,
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
                validator: (value) => value == null ? 'กรุณาเลือกอำเภอ' : null,
              ),

              buildDropdownInput(
                label: 'ตำบล',
                value: selectedDistrict,
                items: districts,
                onChanged: (value) {
                  setState(() {
                    selectedDistrict = value;
                  });
                },
                validator: (value) => value == null ? 'กรุณาเลือกตำบล' : null,
              ),

              const SizedBox(height: 16),

              // ElevatedButton(
              //   onPressed: _selectLocationOnMap,
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor: const Color.fromARGB(255, 255, 238, 50),
              //     foregroundColor: Colors.black,
              //   ),
              //   child: const Text('เลือกตำแหน่งแผนที่'),
              // ),
              ElevatedButton(
                onPressed: _selectLocationOnMap,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets
                      .zero, // ลบ padding ปุ่มออกเพื่อให้ gradient เต็ม
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 4,
                  backgroundColor:
                      Colors.transparent, // ตั้งค่าโปร่งใส เพื่อโชว์ gradient
                  shadowColor: Colors.black,
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFFF176), // เหลืองอ่อน
                        Color(0xFFFFC107), // เหลืองเข้ม
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    constraints:
                        const BoxConstraints(minWidth: 150, minHeight: 45),
                    child: const Text(
                      'เลือกตำแหน่งแผนที่',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              buildInput(
                addressController,
                'รายละเอียดที่อยู่',
                
                validator: (value) {
                  // if (value == null || value.isEmpty) {
                  //   return 'กรุณากรอกรายละเอียดที่อยู่';
                  // }
                  return null;
                },
              ),
              //const SizedBox(height: 10),
              buildInput(
                otherController,
                'ข้อมูลติดต่อเพิ่มเติม (ถ้ามี)',
                readOnly: false,
                validator: (value) {
                  return null;
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('ยกเลิก'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_isUploadingImage) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('กรุณารอให้การอัปโหลดรูปเสร็จก่อน')),
                          );
                          return; // รอจนเสร็จ
                        }

                        if (_formKey.currentState?.validate() ?? false) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('ยืนยันการแก้ไข'),
                              content: const Text(
                                  'คุณต้องการแก้ไขข้อมูลใช่หรือไม่?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('ยกเลิก'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    _submit();
                                  },
                                  child: const Text('ยืนยัน'),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: _isUploadingImage
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('ตกลง'),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget buildInput(
  TextEditingController controller,
  String label, {
  bool readOnly = false,
  String? Function(String?)? validator,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ชื่อช่องอยู่บนสุด
        Text(
          label,
          style: GoogleFonts.mitr(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color.fromARGB(255, 0, 0, 0),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          style: GoogleFonts.mitr(
            fontSize: 16,
            color: Colors.black,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFE0E0E0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color.fromARGB(255, 255, 170, 0),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
          ),
          validator: validator,
          maxLines: 1,
          maxLength: label == 'รายละเอียดที่อยู่' ? 500 : (label == 'ข้อมูลติดต่อเพิ่มเติม (ถ้ามี)' ? 500 : null),
          buildCounter: label == 'รายละเอียดที่อยู่' || label == 'ข้อมูลติดต่อเพิ่มเติม (ถ้ามี)'
              ? (BuildContext context,
                      {required int currentLength,
                      required bool isFocused,
                      required int? maxLength}) =>
                  null // ปิดตัวนับ
              : null,
        ),
      ],
    ),
  );
}


  Widget buildDropdownInput({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ชื่อช่องอยู่บนสุด
          Text(
            label,
            style: GoogleFonts.mitr(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color.fromARGB(255, 0, 0, 0),
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: value,
            items: items
                .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(
                        e,
                        style:
                            GoogleFonts.mitr(fontSize: 16, color: Colors.black),
                      ),
                    ))
                .toList(),
            onChanged: enabled ? onChanged : null,
            validator: validator,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFE0E0E0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.black),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.black),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color.fromARGB(255, 255, 170, 0),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
            ),
            dropdownColor: const Color(0xFFE0E0E0),
          ),
        ],
      ),
    );
  }

  Widget buildInputPhone(
    TextEditingController controller,
    String label, {
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.mitr(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color.fromARGB(255, 0, 0, 0),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            readOnly: readOnly,
            style: GoogleFonts.mitr(
              fontSize: 16,
              color: Colors.black,
            ),
            keyboardType: label == 'เบอร์โทร' ? TextInputType.number : null,
            inputFormatters: label == 'เบอร์โทร'
                ? [FilteringTextInputFormatter.digitsOnly]
                : null,
            maxLength: label == 'เบอร์โทร' ? 10 : null,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFE0E0E0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                
                borderSide: const BorderSide(color: Colors.black),
              ),
              counterText: '',
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.black),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color.fromARGB(255, 255, 170, 0),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
            ),
            validator: validator,
          ),
        ],
      ),
    );
  }
}
