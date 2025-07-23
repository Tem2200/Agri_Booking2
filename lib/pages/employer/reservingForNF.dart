import 'dart:convert';
import 'package:agri_booking2/pages/employer/Tabbar.dart';
import 'package:agri_booking2/pages/employer/addFarm2.dart';
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

        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => PlanEmp(mid: widget.mid),
        //   ),
        // );

        int currentMonth = DateTime.now().month;
        int currentYear = DateTime.now().year;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Tabbar(
              mid: widget.mid,
              value: 1,
              month: currentMonth,
              year: currentYear,
            ),
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

  final TextStyle _infoStyles = const TextStyle(
    fontSize: 16,
    color: Colors.black87,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

// เพิ่มในส่วนบนของไฟล์:
  TextStyle get _infoStyle =>
      const TextStyle(fontSize: 14, color: Colors.black87);
  TextStyle get _sectionTitleStyle =>
      const TextStyle(fontSize: 16, fontWeight: FontWeight.bold);

// เพิ่มฟังก์ชันช่วยสร้าง TextField:
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? inputType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: validator ??
          (value) => value == null || value.isEmpty ? 'กรุณากรอก $label' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 18, 143, 9),
        centerTitle: true,
        //automaticallyImplyLeading: false,
        title: const Text(
          'จองคิวรถ',
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
        leading: IconButton(
          color: Colors.white,
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // ✅ กลับหน้าก่อนหน้า
          },
        ),
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
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      // Text("หมู่บ้าน: ${selectedFarm['village'] ?? '-'}",
                      //     style: _infoStyle),
                      // Text("ตำบล: ${selectedFarm['subdistrict'] ?? '-'}",
                      //     style: _infoStyle),
                      // Text("อำเภอ: ${selectedFarm['district'] ?? '-'}",
                      //     style: _infoStyle),
                      // Text("จังหวัด: ${selectedFarm['province'] ?? '-'}",
                      //     style: _infoStyle),
                      // Text(
                      //     "ขนาดพื้นที่: ${selectedFarm['area_amount'] ?? '-'} ${selectedFarm['unit_area'] ?? ''}",
                      //     style: _infoStyle),
                      // Text("รายละเอียด: ${selectedFarm['detail'] ?? '-'}",
                      //     style: _infoStyle),
                      // const Divider(height: 32, thickness: 1),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.orange),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  "หมู่บ้าน: ${selectedFarm['village'] ?? '-'}",
                                  style: _infoStyles),
                              Text(
                                  "ตำบล: ${selectedFarm['subdistrict'] ?? '-'}",
                                  style: _infoStyles),
                              Text("อำเภอ: ${selectedFarm['district'] ?? '-'}",
                                  style: _infoStyles),
                              Text(
                                  "จังหวัด: ${selectedFarm['province'] ?? '-'}",
                                  style: _infoStyles),
                              Text(
                                "ขนาดพื้นที่: ${selectedFarm['area_amount'] ?? '-'} ${selectedFarm['unit_area'] ?? ''}",
                                style: _infoStyles,
                              ),
                              Text(
                                  "รายละเอียด: ${selectedFarm['detail'] ?? '-'}",
                                  style: _infoStyles),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (farmList.isEmpty) ...[
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          'คุณยังไม่มีข้อมูลที่นา',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        // จัดปุ่มให้อยู่ตรงกลาง
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AddFarmPage2(mid: widget.mid),
                              ),
                            ).then((_) => _loadFarms());
                          },
                          icon: const Icon(Icons.add_location_alt,
                              color: Colors.white), // ไอคอนสีขาว
                          label: const Text(
                            'เพิ่มที่นา',
                            style: TextStyle(
                                color: Colors.white), // ตัวหนังสือสีขาว
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green, // พื้นปุ่มสีเขียว
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12), // ปรับขนาดปุ่มให้พอดี
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(8), // มุมโค้งเล็กน้อย
                            ),
                          ),
                        ),
                      ),
                      const Divider(height: 32, thickness: 1),
                    ],
                    _buildTextField(
                        label: 'ชื่อการจอง', controller: nameController),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'จำนวนพื้นที่',
                      controller: areaAmountController,
                      inputType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'กรุณากรอกจำนวนพื้นที่';
                        if (int.tryParse(value) == null)
                          return 'กรุณากรอกเป็นตัวเลข';
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
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'กรุณาเลือกหน่วยพื้นที่'
                          : null,
                    ),
                    if (isCustomUnit) ...[
                      const SizedBox(height: 16),
                      _buildTextField(
                          label: 'ระบุหน่วยพื้นที่เอง',
                          controller: customUnitController),
                    ],
                    const SizedBox(height: 16),
                    _buildTextField(
                        label: 'รายละเอียด',
                        controller: detailController,
                        maxLines: 3),
                    const SizedBox(height: 20),
                    Text("เลือกวันและเวลาทำงาน", style: _sectionTitleStyle),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _selectDateStart(context),
                            child: Text(
                              dateStart == null
                                  ? 'เลือกวันที่เริ่ม'
                                  : 'เริ่ม: ${dateStart!.toLocal()}'
                                      .split('.')[0],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _selectDateEnd(context),
                            child: Text(
                              dateEnd == null
                                  ? 'เลือกวันที่สิ้นสุด'
                                  : 'สิ้นสุด: ${dateEnd!.toLocal()}'
                                      .split('.')[0],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitReservation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        child: const Text('ยืนยันจอง'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
