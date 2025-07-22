import 'package:agri_booking2/pages/employer/homeEmp.dart';
import 'package:agri_booking2/pages/employer/map_farms.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:agri_booking2/pages/assets/location_data.dart';

class AddFarmPage2 extends StatefulWidget {
  final int mid;
  const AddFarmPage2({super.key, required this.mid});

  @override
  State<AddFarmPage2> createState() => _AddFarmPage2State();
}

class _AddFarmPage2State extends State<AddFarmPage2> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController nameFarmCtrl = TextEditingController();
  TextEditingController villageCtrl = TextEditingController();
  TextEditingController detailCtrl = TextEditingController();
  TextEditingController areaAmountCtrl = TextEditingController();
  TextEditingController customUnitCtrl = TextEditingController();

  List<String> provinces = [];
  List<String> amphoes = [];
  List<String> districts = [];

  String? selectedProvince;
  String? selectedAmphoe;
  String? selectedDistrict;
  double? latitude;
  double? longitude;
  String markerMessage = '';

  final List<String> unitOptions = ['ไร่', 'งาน', 'ตารางวา', 'อื่นๆ'];
  String? selectedUnit;

  @override
  void initState() {
    super.initState();
    provinces = locationData
        .map((e) => e['province'] as String)
        .toSet()
        .toList()
      ..sort();
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

    final unitToSend =
        selectedUnit == 'อื่นๆ' ? customUnitCtrl.text : selectedUnit;

    final farmData = {
      "name_farm": nameFarmCtrl.text,
      "village": villageCtrl.text,
      "subdistrict": selectedDistrict,
      "district": selectedAmphoe,
      "province": selectedProvince,
      "detail": detailCtrl.text,
      "area_amount": int.tryParse(areaAmountCtrl.text) ?? 0,
      "unit_area": unitToSend,
      "latitude": latitude,
      "longitude": longitude,
      "mid": widget.mid,
    };

    final url =
        Uri.parse('http://projectnodejs.thammadalok.com/AGribooking/add-farm');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(farmData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เพิ่มฟาร์มสำเร็จ')),
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
        backgroundColor: const Color.fromARGB(255, 255, 158, 60),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        //automaticallyImplyLeading: false, // ✅ ลบปุ่มย้อนกลับ
        title: const Text(
          'เพิ่มไร่นา',
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
              const Text('กรุณากรอกข้อมูลฟาร์มของคุณเพื่อใช้ในการจองงาน'),
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
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
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
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
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
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
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
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedUnit = value;
                  });
                },
                validator: (val) =>
                    val == null ? 'กรุณาเลือกหน่วยพื้นที่' : null,
              ),
              if (selectedUnit == 'อื่นๆ')
                TextFormField(
                  controller: customUnitCtrl,
                  decoration:
                      const InputDecoration(labelText: 'ระบุหน่วยพื้นที่เอง'),
                  validator: (val) => val == null || val.isEmpty
                      ? 'กรุณาระบุหน่วยพื้นที่'
                      : null,
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
                child: const Text('บันทึกฟาร์ม'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
