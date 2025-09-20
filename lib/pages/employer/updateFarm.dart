import 'dart:convert';
import 'package:agri_booking2/pages/employer/map_farms.dart';
import 'package:agri_booking2/pages/map_edit.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:agri_booking2/pages/assets/location_data.dart';

class UpdateFarmPage extends StatefulWidget {
  final int fid;
  final Map<String, dynamic> farmData;

  const UpdateFarmPage({
    super.key,
    required this.fid,
    required this.farmData,
  });

  @override
  State<UpdateFarmPage> createState() => _UpdateFarmPageState();
}

class _UpdateFarmPageState extends State<UpdateFarmPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameFarmCtrl;
  late TextEditingController villageCtrl;
  late TextEditingController detailCtrl;
  late TextEditingController areaAmountCtrl;
  late TextEditingController unitAreaOtherCtrl;

  List<String> provinces = [];
  List<String> amphoes = [];
  List<String> districts = [];
  final List<String> unitOptions = ['ไร่', 'งาน', 'ตารางวา', 'อื่นๆ'];

  String? selectedProvince;
  String? selectedAmphoe;
  String? selectedDistrict;
  String? selectedUnit;

  double? latitude;
  double? longitude;

  String markerMessage = '';
  bool showOtherUnitField = false;

  @override
  void initState() {
    super.initState();

    nameFarmCtrl = TextEditingController(text: widget.farmData['name_farm']);
    villageCtrl = TextEditingController(text: widget.farmData['village']);
    detailCtrl = TextEditingController(text: widget.farmData['detail'] ?? '');
    areaAmountCtrl =
        TextEditingController(text: widget.farmData['area_amount'].toString());

    // ถ้า unit_area เป็นหนึ่งในตัวเลือก ให้ตั้ง selectedUnit ตรงนั้น
    // ถ้าไม่ใช่ ให้เลือก 'อื่นๆ' และแสดงช่องกรอกอื่น ๆ
    if (widget.farmData['unit_area'] != null &&
        unitOptions.contains(widget.farmData['unit_area'])) {
      selectedUnit = widget.farmData['unit_area'];
      showOtherUnitField = false;
      unitAreaOtherCtrl = TextEditingController(text: '');
    } else {
      selectedUnit = 'อื่นๆ';
      showOtherUnitField = true;
      unitAreaOtherCtrl =
          TextEditingController(text: widget.farmData['unit_area'] ?? '');
    }

    latitude = widget.farmData['latitude'];
    longitude = widget.farmData['longitude'];

    if (latitude != null && longitude != null) {
      markerMessage = 'ปักหมุดแผนที่แล้ว';
    }

    selectedProvince = widget.farmData['province'];
    selectedAmphoe = widget.farmData['district'];
    selectedDistrict = widget.farmData['subdistrict'];

    provinces = locationData
        .map((e) => e['province'] as String)
        .toSet()
        .toList()
      ..sort();

    if (selectedProvince != null) {
      amphoes = locationData
          .where((e) => e['province'] == selectedProvince)
          .map((e) => e['amphoe'] as String)
          .toSet()
          .toList()
        ..sort();

      if (selectedAmphoe != null) {
        districts = locationData
            .where((e) =>
                e['province'] == selectedProvince &&
                e['amphoe'] == selectedAmphoe)
            .map((e) => e['district'] as String)
            .toSet()
            .toList()
          ..sort();
      }
    }
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => MapEdit(
                initialLat: latitude,
                initialLng: longitude,
              )),
    );

    if (result != null && result is Map<String, double>) {
      setState(() {
        latitude = result['lat'];
        longitude = result['lng'];
        markerMessage = 'ปักหมุดแผนที่แล้ว';
      });
    }
  }

  Future<void> _submitFarm() async {
    if (!_formKey.currentState!.validate()) return;

    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกตำแหน่งแผนที่')),
      );
      return;
    }

    String unitAreaFinal;
    if (selectedUnit == 'อื่นๆ') {
      unitAreaFinal = unitAreaOtherCtrl.text.trim();
      if (unitAreaFinal.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณากรอกหน่วยพื้นที่')),
        );
        return;
      }
    } else {
      unitAreaFinal = selectedUnit ?? '';
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Center(
          child: Text('ยืนยันการแก้ไข'),
        ),
        content: const Text('คุณต้องการบันทึกการแก้ไขไร่นาใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ยืนยัน'),
          )
        ],
      ),
    );

    if (confirm != true) return;

    final farmData = {
      "fid": widget.fid,
      "name_farm": nameFarmCtrl.text,
      "village": villageCtrl.text,
      "subdistrict": selectedDistrict,
      "district": selectedAmphoe,
      "province": selectedProvince,
      "detail": detailCtrl.text,
      "area_amount": int.tryParse(areaAmountCtrl.text) ?? 0,
      "unit_area": unitAreaFinal,
      "latitude": latitude,
      "longitude": longitude,
    };

    final url = Uri.parse(
        'http://projectnodejs.thammadalok.com/AGribooking/update_farm');

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(farmData),
      );

      if (response.statusCode == 200) {
        Fluttertoast.showToast(
          msg: 'แก้ไขไร่นาสำเร็จ',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        Navigator.pop(context, true);
      } else {
        Fluttertoast.showToast(
          msg: 'เกิดข้อผิดพลาด: ${response.body}',
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
    }
  }

//ช่องกรอกเรียกใช้sty
  InputDecoration customInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      filled: true,
      fillColor: const Color.fromARGB(80, 222, 222, 212),
      enabledBorder: const OutlineInputBorder(
        borderSide:
            BorderSide(color: Color.fromARGB(255, 155, 155, 155), width: 1.5),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFFF9800), width: 2.0),
      ),
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 18, 143, 9),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        //automaticallyImplyLeading: false, // ✅ ลบปุ่มย้อนกลับ
        title: const Text(
          'แก้ไขไร่นา',
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameFarmCtrl,
                decoration: customInputDecoration('ชื่อไร่นา*'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'กรุณากรอกชื่อไร่นา*' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: villageCtrl,
                decoration: customInputDecoration('หมู่บ้าน*'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'กรุณากรอกหมู่บ้าน*' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedProvince,
                decoration: customInputDecoration('จังหวัด*'),
                items: provinces
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e),
                        ))
                    .toList(),
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
                validator: (v) => v == null ? 'กรุณาเลือกจังหวัด*' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedAmphoe,
                decoration: customInputDecoration('อำเภอ*'),
                items: amphoes
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e),
                        ))
                    .toList(),
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
                validator: (v) => v == null ? 'กรุณาเลือกอำเภอ*' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedDistrict,
                decoration: customInputDecoration('ตำบล*'),
                items: districts
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedDistrict = value;
                  });
                },
                validator: (v) => v == null ? 'กรุณาเลือกตำบล*' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: areaAmountCtrl,
                decoration: customInputDecoration('ขนาดพื้นที่*'),
                keyboardType: TextInputType.number,
                validator: (val) =>
                    val == null || val.isEmpty ? 'กรุณากรอกขนาดพื้นที่*' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedUnit,
                decoration: customInputDecoration('หน่วยพื้นที่*'),
                items: unitOptions
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedUnit = value;
                    showOtherUnitField = value == 'อื่นๆ';
                    if (!showOtherUnitField) {
                      unitAreaOtherCtrl.text = '';
                    }
                  });
                },
                validator: (val) => val == null || val.isEmpty
                    ? 'กรุณาเลือกหน่วยพื้นที่*'
                    : null,
              ),
              const SizedBox(height: 16),
              if (showOtherUnitField)
                TextFormField(
                  controller: unitAreaOtherCtrl,
                  decoration: customInputDecoration('กรุณาระบุหน่วยพื้นที่*'),
                  validator: (val) {
                    if (showOtherUnitField && (val == null || val.isEmpty)) {
                      return 'กรุณากรอกหน่วยพื้นที่*';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton(
                    onPressed: _pickLocation, // ฟังก์ชันเลือกตำแหน่ง
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 4,
                      backgroundColor: Colors.transparent,
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
                            const BoxConstraints(minWidth: 180, minHeight: 50),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.map, color: Colors.black),
                            SizedBox(width: 8),
                            Text(
                              'เลือกตำแหน่งบนแผนที่ *',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (markerMessage.isNotEmpty)
                    Center(
                      child: Text(
                        markerMessage,
                        style: const TextStyle(
                          color: Colors.green, // สีเขียวแบบเดิม
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: detailCtrl,
                decoration: customInputDecoration('รายละเอียด (ไม่บังคับ)'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 6, 126, 12),
                  foregroundColor: const Color.fromARGB(255, 255, 255, 255),
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 30),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 8,
                  shadowColor: const Color.fromARGB(164, 174, 174, 174),
                ),
                onPressed: _submitFarm,
                child: const Text('บันทึกการแก้ไข'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
