import 'dart:convert';
import 'package:agri_booking2/pages/employer/Tabbar.dart';
import 'package:agri_booking2/pages/employer/addFarm2.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ReservingEmp extends StatefulWidget {
  final int mid;
  final int vid;
  final int fid;
  final dynamic farm;
  final dynamic vihicleData;

  const ReservingEmp({
    super.key,
    required this.mid,
    required this.vid,
    required this.fid,
    this.vihicleData,
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
  Future<List<dynamic>>? farmsFuture;

  @override
  void initState() {
    print('Initializing ReservingEmp with vihicle: ${widget.vihicleData}');
    print('Initializing ReservingEmp with farm: ${widget.farm}');
    super.initState();
    farmsFuture = fetchFarms(widget.mid);
  }

  // Future<void> _selectDateStart(BuildContext context) async {
  //   final DateTime? picked = await showDatePicker(
  //     context: context,
  //     initialDate: dateStart ?? DateTime.now(),
  //     firstDate: DateTime(2023),
  //     lastDate: DateTime(2100),
  //   );
  //   if (picked != null) {
  //     final TimeOfDay? pickedTime = await showTimePicker(
  //       context: context,
  //       initialTime: TimeOfDay(hour: 9, minute: 0),
  //     );
  //     if (pickedTime != null) {
  //       setState(() {
  //         dateStart = DateTime(picked.year, picked.month, picked.day,
  //             pickedTime.hour, pickedTime.minute);
  //       });
  //     }
  //   }
  // }

  Future<List<dynamic>> fetchFarms(int mid) async {
    final url = Uri.parse(
      'http://projectnodejs.thammadalok.com/AGribooking/get_farms/$mid',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("ข้อมูลฟาร์ม: $data");
      return data;
    } else {
      throw Exception('ไม่พบข้อมูลฟาร์ม');
    }
  }

  Future<void> _selectDateStart(BuildContext context) async {
    final DateTime now = DateTime.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: dateStart ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: 9, minute: 0),
      );

      if (pickedTime != null) {
        final DateTime selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        // เช็คว่าเป็นอนาคต
        if (selectedDateTime.isAfter(now)) {
          setState(() {
            dateStart = selectedDateTime;
          });
        } else {
          // แจ้งเตือนถ้าเลือกเวลาย้อนหลัง
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('กรุณาเลือกวันที่และเวลาที่มากกว่าปัจจุบัน')),
          );
        }
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

  // Future<void> _submitReservation() async {
  //   if (!_formKey.currentState!.validate()) return;
  //   if (dateStart == null || dateEnd == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('กรุณาเลือกวันที่เริ่มและวันที่สิ้นสุด')),
  //     );
  //     return;
  //   }

  //   setState(() {
  //     isLoading = true;
  //   });

  //   final String finalUnit =
  //       isCustomUnit ? customUnitController.text.trim() : selectedUnit ?? '';
  //   final String detailText = detailController.text.trim().isEmpty
  //       ? 'ไม่มีรายละเอียด'
  //       : detailController.text.trim();

  //   final Map<String, dynamic> body = {
  //     "name_rs": nameController.text.trim(),
  //     "area_amount": int.tryParse(areaAmountController.text.trim()) ?? 0,
  //     "unit_area": finalUnit,
  //     "detail": detailText,
  //     "date_start":
  //         dateStart!.toIso8601String().replaceFirst('T', ' ').substring(0, 19),
  //     "date_end":
  //         dateEnd!.toIso8601String().replaceFirst('T', ' ').substring(0, 19),
  //     "progress_status": null,
  //     "mid_employee": widget.mid,
  //     "vid": widget.vid,
  //     "fid": widget.fid,
  //   };

  //   try {
  //     final response = await http.post(
  //       Uri.parse('http://projectnodejs.thammadalok.com/AGribooking/reserve'),
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode(body),
  //     );

  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('จองสำเร็จ')),
  //       );
  //       //Navigator.pop(context);
  //       int currentMonth = DateTime.now().month;
  //       int currentYear = DateTime.now().year;
  //       Navigator.pushReplacement(
  //         context,
  //         MaterialPageRoute(
  //           builder: (context) => Tabbar(
  //             mid: widget.mid,
  //             value: 1,
  //             month: currentMonth,
  //             year: currentYear,
  //           ),
  //         ),
  //       );
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('ผิดพลาด: ${response.statusCode}')),
  //       );
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
  //     );
  //   } finally {
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }

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

  Future<void> _submitReservation() async {
    if (!_formKey.currentState!.validate()) return;

    if (dateStart == null || dateEnd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกวันที่เริ่มและวันที่สิ้นสุด')),
      );
      return;
    }

    // ✅ ตรวจสอบว่าเวลาสิ้นสุดมากกว่าหรือเท่ากับเวลาเริ่ม
    if (dateEnd!.isBefore(dateStart!)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('การจองผิดพลาด'),
          content: const Text('เวลาสิ้นสุดต้องมากกว่าหรือเท่ากับเวลาเริ่มต้น'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ตกลง'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final String finalUnit =
        isCustomUnit ? customUnitController.text.trim() : selectedUnit ?? '';
    final String detailText = detailController.text.trim().isEmpty
        ? 'ไม่มีรายละเอียด'
        : detailController.text.trim();

    final Map<String, dynamic> body = {
      "name_rs": nameController.text.trim(),
      "area_amount": int.tryParse(areaAmountController.text.trim()) ?? 0,
      "unit_area": finalUnit,
      "detail": detailText,
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
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('การจองล้มเหลว'),
            content: Text('ผิดพลาด: ${response.statusCode}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('ตกลง'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ข้อผิดพลาด'),
          content: Text('เกิดข้อผิดพลาด: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ตกลง'),
            ),
          ],
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Widget _buildFarmDropdown() {
  //   return isFarmLoading
  //       ? const Center(child: CircularProgressIndicator())
  //       : farmList.isEmpty
  //           ? const Center(child: Text('ไม่พบฟาร์มของคุณ'))
  //           : Padding(
  //               padding: const EdgeInsets.all(16),
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   const Text("เลือกฟาร์มของคุณ",
  //                       style: TextStyle(
  //                           fontWeight: FontWeight.bold, fontSize: 18)),
  //                   const SizedBox(height: 16),
  //                   DropdownButtonFormField<dynamic>(
  //                     value: selectedFarm,
  //                     decoration: const InputDecoration(
  //                       labelText: 'เลือกฟาร์ม',
  //                       border: OutlineInputBorder(),
  //                     ),
  //                     items: farmList.map<DropdownMenuItem<dynamic>>((farm) {
  //                       return DropdownMenuItem<dynamic>(
  //                         value: farm,
  //                         child: Text(farm['name_farm'] ?? "-"),
  //                       );
  //                     }).toList(),
  //                     onChanged: (value) {
  //                       setState(() {
  //                         selectedFarm = value;
  //                       });
  //                     },
  //                     validator: (value) =>
  //                         value == null ? 'กรุณาเลือกฟาร์ม' : null,
  //                   ),
  //                   const SizedBox(height: 24),
  //                   ElevatedButton(
  //                     onPressed: selectedFarm == null
  //                         ? null
  //                         : () {
  //                             Navigator.pushReplacement(
  //                               context,
  //                               MaterialPageRoute(
  //                                 builder: (context) => ReservingEmp(
  //                                   mid: widget.mid,
  //                                   vid: widget.vid,
  //                                   fid: selectedFarm['fid'] ?? 0,
  //                                   farm: selectedFarm,
  //                                 ),
  //                               ),
  //                             );
  //                           },
  //                     child: const Text('ถัดไป'),
  //                   ),
  //                 ],
  //               ),
  //             );
  // }

  Widget _buildFarmDropdown() {
    return isFarmLoading
        ? const Center(child: CircularProgressIndicator())
        : farmList.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        'คุณยังไม่มีข้อมูลที่นา',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AddFarmPage2(mid: widget.mid),
                            ),
                          ).then((_) =>
                              _loadFarms()); // รีโหลดเมื่อกลับมาจากหน้าสร้างฟาร์ม
                        },
                        icon: const Icon(Icons.add_location_alt,
                            color: Colors.white),
                        label: const Text(
                          'เพิ่มที่นา',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 32, thickness: 1),
                  ],
                ),
              )
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

  TextStyle get _sectionTitleStyle =>
      const TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
  @override
  Widget build(BuildContext context) {
    final bool shouldSelectFarm = widget.farm == null ||
        widget.farm is! Map ||
        (widget.farm is Map && widget.farm.isEmpty);

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
                        Center(
                          child: Container(
                              // padding: const EdgeInsets.all(16),
                              // margin: const EdgeInsets.symmetric(
                              //     vertical: 12, horizontal: 16),
                              // decoration: BoxDecoration(
                              //   color: Colors.orange[50],
                              //   borderRadius: BorderRadius.circular(16),
                              //   border: Border.all(color: Colors.orange),
                              //   boxShadow: [
                              //     BoxShadow(
                              //       color: Colors.orange.withOpacity(0.2),
                              //       blurRadius: 6,
                              //       offset: const Offset(0, 4),
                              //     ),
                              //   ],
                              // ),
                              child: Card(
                            elevation: 8, // เงาชัดเจน
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(16), // มุมโค้งมนสวย
                            ),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 2, vertical: 2), // เว้นขอบการ์ด
                            shadowColor:
                                Colors.black54, // เงาสีเข้มขึ้นเล็กน้อย
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 12), // ระยะห่างในการ์ด
                              child: ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    widget.vihicleData['image_vehicle'] ?? '',
                                    width: 120,
                                    height: 180,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const SizedBox(
                                      width: 100,
                                      height: 180,
                                      child: Icon(Icons.broken_image,
                                          size: 48, color: Colors.grey),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  widget.vihicleData['name_vehicle'],
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black12,
                                        offset: Offset(1, 1),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                                subtitle: Text(
                                  'ผู้รับจ้าง: ${widget.vihicleData['username']}\n${widget.vihicleData['price']} บาท/ ${widget.vihicleData['unit_price']}, ${widget.vihicleData['detail']}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color.fromARGB(255, 95, 95, 95),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 0), // จัดระยะห่างภายใน ListTile
                              ),
                            ),
                          )),
                        ),
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
                        ),
                        const SizedBox(height: 16),
                        Text("เลือกวันและเวลาทำงาน", style: _sectionTitleStyle),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _selectDateStart(context),
                                child: Text(dateStart == null
                                    ? 'เลือกวันที่เริ่ม'
                                    : 'วันที่เริ่ม: ${formatDateThai(dateStart!)}'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _selectDateEnd(context),
                                child: Text(dateEnd == null
                                    ? 'เลือกวันที่สิ้นสุด'
                                    : 'วันที่สิ้นสุด: ${formatDateThai(dateEnd!)}'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Center(
                          child: Container(
                              padding: const EdgeInsets.all(0),
                              margin: const EdgeInsets.symmetric(
                                  vertical: 5, horizontal: 2),
                              // decoration: BoxDecoration(
                              //   color: Colors.orange[50],
                              //   borderRadius: BorderRadius.circular(16),
                              //   border: Border.all(color: Colors.orange),
                              //   boxShadow: [
                              //     BoxShadow(
                              //       color: Colors.orange.withOpacity(0.2),
                              //       blurRadius: 6,
                              //       offset: const Offset(0, 4),
                              //     ),
                              //   ],
                              // ),
                              // child: Column(
                              //   crossAxisAlignment: CrossAxisAlignment.start,
                              //   children: [
                              //     const Text(
                              //       "ข้อมูลไร่นา",
                              //       style: TextStyle(
                              //         fontWeight: FontWeight.bold,
                              //         fontSize: 16,
                              //         color: Colors.black,
                              //       ),
                              //     ),
                              //     const SizedBox(height: 12),
                              //     _buildInfoText(
                              //         "ชื่อฟาร์ม", widget.farm['name_farm']),
                              //     _buildInfoText(
                              //         "หมู่บ้าน", widget.farm['village']),
                              //     _buildInfoText(
                              //         "ตำบล", widget.farm['subdistrict']),
                              //     _buildInfoText(
                              //         "อำเภอ", widget.farm['district']),
                              //     _buildInfoText(
                              //         "จังหวัด", widget.farm['province']),
                              //     _buildInfoText("ขนาดพื้นที่",
                              //         "${widget.farm['area_amount'] ?? '-'} ${widget.farm['unit_area'] ?? ''}"),
                              //     _buildInfoText(
                              //         "รายละเอียด", widget.farm['detail']),
                              //   ],
                              // ),

                              child: Card(
                                elevation: 8, // เงาชัดเจน
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(16), // มุมโค้งมนสวย
                                ),
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10), // เว้นขอบการ์ด
                                shadowColor:
                                    Colors.black54, // เงาสีเข้มขึ้นเล็กน้อย
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 12), // ระยะห่างในการ์ด
                                  child: ListTile(
                                    title: Text(
                                      widget.farm['name_farm'],
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black12,
                                            offset: Offset(1, 1),
                                            blurRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${widget.farm['village']}, ${widget.farm['subdistrict']}, ${widget.farm['district']}, ${widget.farm['province']},${widget.farm['area_amount']} ${widget.farm['unit_area']}\n${widget.farm['detail'] ?? 'ไม่มีรายละเอียดอื่นๆ'}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color.fromARGB(255, 95, 95, 95),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),

                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal:
                                            0), // จัดระยะห่างภายใน ListTile
                                  ),
                                ),
                              )),
                        ),
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

  String formatDateThai(DateTime date) {
    final thaiMonths = [
      '',
      'มกราคม',
      'กุมภาพันธ์',
      'มีนาคม',
      'เมษายน',
      'พฤษภาคม',
      'มิถุนายน',
      'กรกฎาคม',
      'สิงหาคม',
      'กันยายน',
      'ตุลาคม',
      'พฤศจิกายน',
      'ธันวาคม',
    ];
    String day = date.day.toString();
    String month = thaiMonths[date.month];
    String year = (date.year + 543).toString(); // พ.ศ.
    String hour = date.hour.toString().padLeft(2, '0');
    String minute = date.minute.toString().padLeft(2, '0');

    return '$day $month $year $hour:$minute';
  }

// ฟังก์ชันช่วยสร้างข้อความแต่ละบรรทัด พร้อมสไตล์สวยงาม
  Widget _buildInfoText(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          text: "$label: ",
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Colors.black,
          ),
          children: [
            TextSpan(
              text: value?.toString() ?? "-",
              style: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
