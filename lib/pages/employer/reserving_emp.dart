import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ReservingEmp extends StatefulWidget {
  final int mid;
  final int vid;
  final int fid;
  final dynamic farm;

  const ReservingEmp({
    super.key,
    required this.mid,
    required this.vid,
    required this.fid,
    this.farm,
  });

  @override
  State<ReservingEmp> createState() => _ReservingEmpState();
}

class _ReservingEmpState extends State<ReservingEmp> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController areaAmountController = TextEditingController();
  final TextEditingController detailController = TextEditingController();
  final TextEditingController customUnitController = TextEditingController();

  DateTime? dateStart;
  DateTime? dateEnd;

  bool isLoading = false;
  bool isFarmLoading = false;
  List<dynamic> farmList = [];
  dynamic selectedFarm;

  final List<String> unitOptions = [
    'ตารางวา',
    'ไร่',
    'งาน',
    'ตารางเมตร',
    'อื่นๆ'
  ];
  String? selectedUnit = 'ตารางวา';
  bool isCustomUnit = false;

  @override
  void initState() {
    super.initState();

    print('Initializing ReservingEmp with farm: ${widget.farm}');
  }

  Future<void> _selectDateStart(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: dateStart ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: 9, minute: 0),
      );
      if (pickedTime != null) {
        setState(() {
          dateStart = DateTime(picked.year, picked.month, picked.day,
              pickedTime.hour, pickedTime.minute);
        });
      }
    }
  }

  Future<void> _selectDateEnd(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: dateEnd ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: 13, minute: 0),
      );
      if (pickedTime != null) {
        setState(() {
          dateEnd = DateTime(picked.year, picked.month, picked.day,
              pickedTime.hour, pickedTime.minute);
        });
      }
    }
  }

  Future<void> _submitReservation() async {
    if (!_formKey.currentState!.validate()) return;
    if (dateStart == null || dateEnd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกวันที่เริ่มและวันที่สิ้นสุด')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final String finalUnit =
        isCustomUnit ? customUnitController.text.trim() : selectedUnit ?? '';

    final Map<String, dynamic> body = {
      "name_rs": nameController.text.trim(),
      "area_amount": int.tryParse(areaAmountController.text.trim()) ?? 0,
      "unit_area": finalUnit,
      "detail": detailController.text.trim(),
      "date_start":
          dateStart!.toIso8601String().replaceFirst('T', ' ').substring(0, 19),
      "date_end":
          dateEnd!.toIso8601String().replaceFirst('T', ' ').substring(0, 19),
      "progress_status": null,
      "mid_employee": widget.mid,
      "vid": widget.vid,
      "fid": widget.fid,
    };

    try {
      final response = await http.post(
        Uri.parse('http://projectnodejs.thammadalok.com/AGribooking/reserve'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('จองสำเร็จ')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ผิดพลาด: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildFarmDropdown() {
    return isFarmLoading
        ? const Center(child: CircularProgressIndicator())
        : farmList.isEmpty
            ? const Center(child: Text('ไม่พบฟาร์มของคุณ'))
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("เลือกฟาร์มของคุณ",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<dynamic>(
                      value: selectedFarm,
                      decoration: const InputDecoration(
                        labelText: 'เลือกฟาร์ม',
                        border: OutlineInputBorder(),
                      ),
                      items: farmList.map<DropdownMenuItem<dynamic>>((farm) {
                        return DropdownMenuItem<dynamic>(
                          value: farm,
                          child: Text(farm['name_farm'] ?? "-"),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedFarm = value;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'กรุณาเลือกฟาร์ม' : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: selectedFarm == null
                          ? null
                          : () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ReservingEmp(
                                    mid: widget.mid,
                                    vid: widget.vid,
                                    fid: selectedFarm['fid'] ?? 0,
                                    farm: selectedFarm,
                                  ),
                                ),
                              );
                            },
                      child: const Text('ถัดไป'),
                    ),
                  ],
                ),
              );
  }

  @override
  Widget build(BuildContext context) {
    final bool shouldSelectFarm = widget.farm == null ||
        widget.farm is! Map ||
        (widget.farm is Map && widget.farm.isEmpty);

    return Scaffold(
      appBar: AppBar(
        title: const Text("จองคิวรถ"),
        backgroundColor: Colors.orange,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : shouldSelectFarm
              ? _buildFarmDropdown()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        const Text("ข้อมูลฟาร์มที่เลือก",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text("ชื่อฟาร์ม: ${widget.farm['name_farm'] ?? '-'}"),
                        Text("หมู่บ้าน: ${widget.farm['village'] ?? '-'}"),
                        Text("ตำบล: ${widget.farm['subdistrict'] ?? '-'}"),
                        Text("อำเภอ: ${widget.farm['district'] ?? '-'}"),
                        Text("จังหวัด: ${widget.farm['province'] ?? '-'}"),
                        Text(
                            "ขนาดพื้นที่: ${widget.farm['area_amount'] ?? '-'} ${widget.farm['unit_area'] ?? ''}"),
                        Text("รายละเอียด: ${widget.farm['detail'] ?? '-'}"),
                        const Divider(height: 32, color: Colors.orange),
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'ชื่อการจอง',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'กรุณากรอกชื่อการจอง'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: areaAmountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'จำนวนพื้นที่',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'กรุณากรอกจำนวนพื้นที่';
                            }
                            if (int.tryParse(value) == null) {
                              return 'กรุณากรอกเป็นตัวเลข';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedUnit,
                          items: unitOptions.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedUnit = value;
                              isCustomUnit = value == 'อื่นๆ';
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'หน่วยพื้นที่',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'กรุณาเลือกหน่วยพื้นที่'
                              : null,
                        ),
                        if (isCustomUnit) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: customUnitController,
                            decoration: const InputDecoration(
                              labelText: 'ระบุหน่วยพื้นที่เอง',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                (value == null || value.isEmpty)
                                    ? 'กรุณากรอกหน่วยพื้นที่เอง'
                                    : null,
                          ),
                        ],
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: detailController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'รายละเอียด',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'กรุณากรอกรายละเอียด'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _selectDateStart(context),
                                child: Text(dateStart == null
                                    ? 'เลือกวันที่เริ่ม'
                                    : 'วันที่เริ่ม: ${dateStart!.toLocal()}'
                                        .split('.')[0]),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _selectDateEnd(context),
                                child: Text(dateEnd == null
                                    ? 'เลือกวันที่สิ้นสุด'
                                    : 'วันที่สิ้นสุด: ${dateEnd!.toLocal()}'
                                        .split('.')[0]),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _submitReservation,
                          child: const Text('ยืนยันจอง'),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
