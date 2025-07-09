import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ReservingEmp extends StatefulWidget {
  final int mid;
  final int vid;
  final int fid;

  const ReservingEmp({
    super.key,
    required this.mid,
    required this.vid,
    required this.fid,
  });

  @override
  State<ReservingEmp> createState() => _ReservingEmpState();
}

class _ReservingEmpState extends State<ReservingEmp> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController areaAmountController = TextEditingController();
  final TextEditingController unitAreaController =
      TextEditingController(text: "ตารางวา");
  final TextEditingController detailController = TextEditingController();

  DateTime? dateStart;
  DateTime? dateEnd;

  bool isLoading = false;

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

    final Map<String, dynamic> body = {
      "name_rs": nameController.text.trim(),
      "area_amount": int.tryParse(areaAmountController.text.trim()) ?? 0,
      "unit_area": unitAreaController.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("จองคิวรถ"),
        backgroundColor: Colors.orange,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
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
                        if (value == null || value.isEmpty)
                          return 'กรุณากรอกจำนวนพื้นที่';
                        if (int.tryParse(value) == null)
                          return 'กรุณากรอกเป็นตัวเลข';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: unitAreaController,
                      decoration: const InputDecoration(
                        labelText: 'หน่วยพื้นที่',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'กรุณากรอกหน่วยพื้นที่'
                          : null,
                    ),
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
                    )
                  ],
                ),
              ),
            ),
    );
  }
}
