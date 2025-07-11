import 'dart:convert';
import 'package:agri_booking2/pages/employer/plan_emp.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ReservingForNF extends StatefulWidget {
  final int mid;
  final int vid;

  const ReservingForNF({
    super.key,
    required this.mid,
    required this.vid,
  });

  @override
  State<ReservingForNF> createState() => _ReservingForNFState();
}

class _ReservingForNFState extends State<ReservingForNF> {
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
    _loadFarms();
  }

  Future<void> _loadFarms() async {
    setState(() => isFarmLoading = true);
    try {
      final url = Uri.parse(
          'http://projectnodejs.thammadalok.com/AGribooking/get_farms/${widget.mid}');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          farmList = data;
        });
      }
    } catch (e) {
      print('Error loading farms: $e');
    } finally {
      setState(() => isFarmLoading = false);
    }
  }

  Future<void> _selectDateStart(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dateStart ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 9, minute: 0),
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
    final picked = await showDatePicker(
      context: context,
      initialDate: dateEnd ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 13, minute: 0),
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
    if (selectedFarm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกที่นา')),
      );
      return;
    }
    if (dateStart == null || dateEnd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกวันที่เริ่มและสิ้นสุด')),
      );
      return;
    }

    setState(() => isLoading = true);

    final String finalUnit =
        isCustomUnit ? customUnitController.text.trim() : selectedUnit ?? '';

    final Map<String, dynamic> body = {
      "name_rs": nameController.text.trim(),
      "area_amount": int.tryParse(areaAmountController.text.trim()) ?? 0,
      "unit_area": finalUnit,
      "detail": detailController.text.trim(),
      "date_start":
          "${dateStart!.toIso8601String().split('T')[0]} ${dateStart!.hour.toString().padLeft(2, '0')}:${dateStart!.minute.toString().padLeft(2, '0')}:00",
      "date_end":
          "${dateEnd!.toIso8601String().split('T')[0]} ${dateEnd!.hour.toString().padLeft(2, '0')}:${dateEnd!.minute.toString().padLeft(2, '0')}:00",
      "progress_status": null,
      "mid_employee": widget.mid,
      "vid": widget.vid,
      "fid": selectedFarm['fid'],
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

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PlanEmp(mid: widget.mid),
          ),
        );
      } else {
        String errorMsg;
        try {
          final decoded = jsonDecode(response.body);
          errorMsg = decoded["message"]?.toString() ?? response.body;
        } catch (e) {
          errorMsg = response.body;
        }

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("เกิดข้อผิดพลาด"),
            content: Text(errorMsg),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("ปิด"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("จองคิวรถจากที่นา"),
        backgroundColor: Colors.orange,
      ),
      body: isLoading || isFarmLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<dynamic>(
                      value: selectedFarm,
                      decoration: const InputDecoration(
                        labelText: 'เลือกที่นา',
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
                          value == null ? 'กรุณาเลือกที่นา' : null,
                    ),
                    const SizedBox(height: 16),
                    if (selectedFarm != null) ...[
                      Text("หมู่บ้าน: ${selectedFarm['village'] ?? '-'}"),
                      Text("ตำบล: ${selectedFarm['subdistrict'] ?? '-'}"),
                      Text("อำเภอ: ${selectedFarm['district'] ?? '-'}"),
                      Text("จังหวัด: ${selectedFarm['province'] ?? '-'}"),
                      Text(
                          "ขนาดพื้นที่: ${selectedFarm['area_amount'] ?? '-'} ${selectedFarm['unit_area'] ?? ''}"),
                      Text("รายละเอียด: ${selectedFarm['detail'] ?? '-'}"),
                      const Divider(),
                    ],
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
                        validator: (value) => value == null || value.isEmpty
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
                                : 'เริ่ม: ${dateStart!.toLocal()}'
                                    .split('.')[0]),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _selectDateEnd(context),
                            child: Text(dateEnd == null
                                ? 'เลือกวันที่สิ้นสุด'
                                : 'สิ้นสุด: ${dateEnd!.toLocal()}'
                                    .split('.')[0]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submitReservation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      child: const Center(child: Text('ยืนยันจอง')),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
