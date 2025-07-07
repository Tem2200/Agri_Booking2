import 'dart:convert';
import 'package:agri_booking2/pages/employer/map_farms.dart';
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
  late TextEditingController unitAreaCtrl;

  List<String> provinces = [];
  List<String> amphoes = [];
  List<String> districts = [];

  String? selectedProvince;
  String? selectedAmphoe;
  String? selectedDistrict;

  double? latitude;
  double? longitude;

  String markerMessage = '';

  @override
  void initState() {
    super.initState();

    nameFarmCtrl = TextEditingController(text: widget.farmData['name_farm']);
    villageCtrl = TextEditingController(text: widget.farmData['village']);
    detailCtrl = TextEditingController(text: widget.farmData['detail'] ?? '');
    areaAmountCtrl =
        TextEditingController(text: widget.farmData['area_amount'].toString());
    unitAreaCtrl =
        TextEditingController(text: widget.farmData['unit_area'] ?? '');

    // ค่า location เดิม
    latitude = widget.farmData['latitude'];
    longitude = widget.farmData['longitude'];

    if (latitude != null && longitude != null) {
      markerMessage = 'ปักหมุดแผนที่แล้ว';
    }

    // Province, amphoe, district เดิม
    selectedProvince = widget.farmData['province'];
    selectedAmphoe = widget.farmData['district'];
    selectedDistrict = widget.farmData['subdistrict'];

    provinces = locationData
        .map((e) => e['province'] as String)
        .toSet()
        .toList()
      ..sort();

    // load amphoes และ districts ตาม province/district เดิม
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
      MaterialPageRoute(builder: (_) => const MapFarm()),
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
      "unit_area": unitAreaCtrl.text,
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
              TextFormField(
                controller: unitAreaCtrl,
                decoration: const InputDecoration(labelText: 'หน่วยพื้นที่'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'กรุณากรอกหน่วยพื้นที่' : null,
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
