import 'dart:convert';
import 'package:agri_booking2/pages/employer/map_farms.dart';
import 'package:agri_booking2/pages/map_edit.dart';
import 'package:flutter/material.dart';
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
        title: const Text('ยืนยันการแก้ไข'),
        content: const Text('คุณต้องการบันทึกการแก้ไขฟาร์มใช่หรือไม่?'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('แก้ไขฟาร์มสำเร็จ')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แก้ไขฟาร์ม'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameFarmCtrl,
                decoration: const InputDecoration(labelText: 'ชื่อฟาร์ม'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'กรุณากรอกชื่อฟาร์ม' : null,
              ),
              TextFormField(
                controller: villageCtrl,
                decoration: const InputDecoration(labelText: 'หมู่บ้าน'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'กรุณากรอกหมู่บ้าน' : null,
              ),
              DropdownButtonFormField<String>(
                value: selectedProvince,
                decoration: const InputDecoration(labelText: 'จังหวัด'),
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
                validator: (v) => v == null ? 'กรุณาเลือกจังหวัด' : null,
              ),
              DropdownButtonFormField<String>(
                value: selectedAmphoe,
                decoration: const InputDecoration(labelText: 'อำเภอ'),
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
                validator: (v) => v == null ? 'กรุณาเลือกอำเภอ' : null,
              ),
              DropdownButtonFormField<String>(
                value: selectedDistrict,
                decoration: const InputDecoration(labelText: 'ตำบล'),
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
                validator: (v) => v == null ? 'กรุณาเลือกตำบล' : null,
              ),
              TextFormField(
                controller: detailCtrl,
                decoration:
                    const InputDecoration(labelText: 'รายละเอียด (ไม่บังคับ)'),
              ),
              TextFormField(
                controller: areaAmountCtrl,
                decoration: const InputDecoration(labelText: 'ขนาดพื้นที่'),
                keyboardType: TextInputType.number,
                validator: (val) =>
                    val == null || val.isEmpty ? 'กรุณากรอกขนาดพื้นที่' : null,
              ),
              DropdownButtonFormField<String>(
                value: selectedUnit,
                decoration: const InputDecoration(labelText: 'หน่วยพื้นที่'),
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
                    ? 'กรุณาเลือกหน่วยพื้นที่'
                    : null,
              ),
              if (showOtherUnitField)
                TextFormField(
                  controller: unitAreaOtherCtrl,
                  decoration:
                      const InputDecoration(labelText: 'กรุณาระบุหน่วยพื้นที่'),
                  validator: (val) {
                    if (showOtherUnitField && (val == null || val.isEmpty)) {
                      return 'กรุณากรอกหน่วยพื้นที่';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.map),
                label: const Text('เลือกตำแหน่งบนแผนที่'),
                onPressed: _pickLocation,
              ),
              if (markerMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    markerMessage,
                    style: const TextStyle(
                        color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
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
