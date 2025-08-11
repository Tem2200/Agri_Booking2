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
  bool _isSubmitting = false;
  // ประกาศตัวแปรสำหรับ border
  final inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Colors.grey, width: 1.5),
  );

  final enabledBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Colors.grey, width: 1.5),
  );

  final focusedBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Colors.blue, width: 2),
  );

  final errorBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Colors.red, width: 2),
  );

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
    if (_isSubmitting) return; // ป้องกันการกดรัว

    if (!_formKey.currentState!.validate()) return;

    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกตำแหน่งแผนที่')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true; // ตั้งค่าว่ากำลังส่งข้อมูล
    });

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
    } finally {
      setState(() {
        _isSubmitting = false; // ปล่อยให้กดได้อีกหลังจากเสร็จ
      });
    }
  }

  @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       backgroundColor: const Color.fromARGB(255, 255, 158, 60),
  //       centerTitle: true,
  //       iconTheme: const IconThemeData(color: Colors.white),
  //       //automaticallyImplyLeading: false, // ✅ ลบปุ่มย้อนกลับ
  //       title: const Text(
  //         'เพิ่มไร่นา',
  //         style: TextStyle(
  //           fontSize: 22,
  //           fontWeight: FontWeight.bold,
  //           color: Color.fromARGB(255, 255, 255, 255),
  //           //letterSpacing: 1,
  //           shadows: [
  //             Shadow(
  //               color: Color.fromARGB(115, 253, 237, 237),
  //               blurRadius: 3,
  //               offset: Offset(1.5, 1.5),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //     body: SingleChildScrollView(
  //       padding: const EdgeInsets.all(16),
  //       child: Form(
  //         key: _formKey,
  //         child: Column(
  //           children: [
  //             const Text('กรุณากรอกข้อมูลฟาร์มของคุณเพื่อใช้ในการจองงาน'),
  //             TextFormField(
  //               controller: nameFarmCtrl,
  //               decoration: const InputDecoration(labelText: 'ชื่อฟาร์ม'),
  //               validator: (val) =>
  //                   val == null || val.isEmpty ? 'กรุณากรอกชื่อฟาร์ม' : null,
  //             ),
  //             TextFormField(
  //               controller: villageCtrl,
  //               decoration: const InputDecoration(labelText: 'หมู่บ้าน'),
  //               validator: (val) =>
  //                   val == null || val.isEmpty ? 'กรุณากรอกหมู่บ้าน' : null,
  //             ),
  //             DropdownButtonFormField<String>(
  //               value: selectedProvince,
  //               decoration: const InputDecoration(labelText: 'จังหวัด'),
  //               items: provinces
  //                   .map((e) => DropdownMenuItem(value: e, child: Text(e)))
  //                   .toList(),
  //               onChanged: (value) {
  //                 setState(() {
  //                   selectedProvince = value;
  //                   selectedAmphoe = null;
  //                   selectedDistrict = null;

  //                   amphoes = locationData
  //                       .where((e) => e['province'] == value)
  //                       .map((e) => e['amphoe'] as String)
  //                       .toSet()
  //                       .toList()
  //                     ..sort();

  //                   districts = [];
  //                 });
  //               },
  //               validator: (v) => v == null ? 'กรุณาเลือกจังหวัด' : null,
  //             ),
  //             DropdownButtonFormField<String>(
  //               value: selectedAmphoe,
  //               decoration: const InputDecoration(labelText: 'อำเภอ'),
  //               items: amphoes
  //                   .map((e) => DropdownMenuItem(value: e, child: Text(e)))
  //                   .toList(),
  //               onChanged: (value) {
  //                 setState(() {
  //                   selectedAmphoe = value;
  //                   selectedDistrict = null;

  //                   districts = locationData
  //                       .where((e) =>
  //                           e['province'] == selectedProvince &&
  //                           e['amphoe'] == value)
  //                       .map((e) => e['district'] as String)
  //                       .toSet()
  //                       .toList()
  //                     ..sort();
  //                 });
  //               },
  //               validator: (v) => v == null ? 'กรุณาเลือกอำเภอ' : null,
  //             ),
  //             DropdownButtonFormField<String>(
  //               value: selectedDistrict,
  //               decoration: const InputDecoration(labelText: 'ตำบล'),
  //               items: districts
  //                   .map((e) => DropdownMenuItem(value: e, child: Text(e)))
  //                   .toList(),
  //               onChanged: (value) {
  //                 setState(() {
  //                   selectedDistrict = value;
  //                 });
  //               },
  //               validator: (v) => v == null ? 'กรุณาเลือกตำบล' : null,
  //             ),
  //             TextFormField(
  //               controller: detailCtrl,
  //               decoration:
  //                   const InputDecoration(labelText: 'รายละเอียด (ไม่บังคับ)'),
  //             ),
  //             TextFormField(
  //               controller: areaAmountCtrl,
  //               decoration: const InputDecoration(labelText: 'ขนาดพื้นที่'),
  //               keyboardType: TextInputType.number,
  //               validator: (val) =>
  //                   val == null || val.isEmpty ? 'กรุณากรอกขนาดพื้นที่' : null,
  //             ),
  //             DropdownButtonFormField<String>(
  //               value: selectedUnit,
  //               decoration: const InputDecoration(labelText: 'หน่วยพื้นที่'),
  //               items: unitOptions
  //                   .map((e) => DropdownMenuItem(value: e, child: Text(e)))
  //                   .toList(),
  //               onChanged: (value) {
  //                 setState(() {
  //                   selectedUnit = value;
  //                 });
  //               },
  //               validator: (val) =>
  //                   val == null ? 'กรุณาเลือกหน่วยพื้นที่' : null,
  //             ),
  //             if (selectedUnit == 'อื่นๆ')
  //               TextFormField(
  //                 controller: customUnitCtrl,
  //                 decoration:
  //                     const InputDecoration(labelText: 'ระบุหน่วยพื้นที่เอง'),
  //                 validator: (val) => val == null || val.isEmpty
  //                     ? 'กรุณาระบุหน่วยพื้นที่'
  //                     : null,
  //               ),
  //             const SizedBox(height: 16),
  //             ElevatedButton.icon(
  //               icon: const Icon(Icons.map),
  //               label: const Text('เลือกตำแหน่งบนแผนที่'),
  //               onPressed: _pickLocation,
  //             ),
  //             if (markerMessage.isNotEmpty)
  //               Padding(
  //                 padding: const EdgeInsets.only(top: 8),
  //                 child: Text(
  //                   markerMessage,
  //                   style: const TextStyle(
  //                       color: Colors.green, fontWeight: FontWeight.bold),
  //                 ),
  //               ),
  //             const SizedBox(height: 20),
  //             ElevatedButton(
  //               onPressed: _submitFarm,
  //               child: const Text('บันทึกฟาร์ม'),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: Colors.grey[800],
    );

    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.white,
      labelStyle: labelStyle,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 18, 143, 9),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'เพิ่มไร่นา',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
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
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'กรุณากรอกข้อมูลฟาร์มของคุณเพื่อใช้ในการจองงาน',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: nameFarmCtrl,
                decoration: inputDecoration.copyWith(labelText: 'ชื่อฟาร์ม*'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'กรุณากรอกชื่อฟาร์ม*' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: villageCtrl,
                decoration: inputDecoration.copyWith(labelText: 'หมู่บ้าน*'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'กรุณากรอกหมู่บ้าน*' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedProvince,
                decoration: inputDecoration.copyWith(labelText: 'จังหวัด*'),
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
                validator: (v) => v == null ? 'กรุณาเลือกจังหวัด*' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedAmphoe,
                decoration: inputDecoration.copyWith(labelText: 'อำเภอ*'),
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
                validator: (v) => v == null ? 'กรุณาเลือกอำเภอ*' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedDistrict,
                decoration: inputDecoration.copyWith(labelText: 'ตำบล*'),
                items: districts
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedDistrict = value;
                  });
                },
                validator: (v) => v == null ? 'กรุณาเลือกตำบล*' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: areaAmountCtrl,
                decoration: inputDecoration.copyWith(labelText: 'ขนาดพื้นที่*'),
                keyboardType: TextInputType.number,
                validator: (val) =>
                    val == null || val.isEmpty ? 'กรุณากรอกขนาดพื้นที่*' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedUnit,
                decoration:
                    inputDecoration.copyWith(labelText: 'หน่วยพื้นที่*'),
                items: unitOptions
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedUnit = value;
                  });
                },
                validator: (val) =>
                    val == null ? 'กรุณาเลือกหน่วยพื้นที่*' : null,
              ),
              if (selectedUnit == 'อื่นๆ')
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextFormField(
                    controller: customUnitCtrl,
                    decoration: inputDecoration.copyWith(
                        labelText: 'ระบุหน่วยพื้นที่เอง*'),
                    validator: (val) => val == null || val.isEmpty
                        ? 'กรุณาระบุหน่วยพื้นที่*'
                        : null,
                  ),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: detailCtrl,
                maxLength: 500,
                maxLines: null,
                // เพิ่มบรรทัดนี้: อัปเดต UI ทุกครั้งที่มีการเปลี่ยนแปลงข้อความ
                onChanged: (text) {
                  setState(() {});
                },
                decoration: InputDecoration(
                  labelText: 'รายละเอียดที่อยู่ (ไม่บังคับ)',
                  filled: true,
                  fillColor: const Color.fromARGB(248, 255, 249, 221)
                      .withOpacity(0.15),
                  labelStyle: const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.w600),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: inputBorder,
                  enabledBorder: enabledBorder,
                  focusedBorder: focusedBorder,
                  errorBorder: errorBorder,
                  focusedErrorBorder: errorBorder,
                  // counterText ที่ถูกต้อง
                  counterText: '${detailCtrl.text.length}/500',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pickLocation,
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
              // แสดงข้อความตำแหน่งที่เลือก (ถ้ามี)
              if (markerMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    markerMessage,
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Center(
                child: SizedBox(
                  width: 150, // กำหนดความยาวปุ่ม
                  child: ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : _submitFarm, // ปิดปุ่มถ้ากำลังส่ง
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 6, 126, 12),
                      foregroundColor: const Color.fromARGB(255, 255, 255, 255),
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 30,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 8,
                      shadowColor: const Color.fromARGB(164, 174, 174, 174),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'บันทึกฟาร์ม',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
