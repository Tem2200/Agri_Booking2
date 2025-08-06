import 'dart:convert';
import 'package:agri_booking2/pages/employer/Tabbar.dart';
import 'package:agri_booking2/pages/employer/addFarm2.dart';
import 'package:agri_booking2/pages/employer/plan_emp.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ReservingForNF extends StatefulWidget {
  final int mid;
  final int vid;
  final int? fid; // ✅ เพิ่มตรงนี้
  final dynamic farm; // ✅ เพิ่มตรงนี้
  final dynamic vihicleData;
  const ReservingForNF({
    super.key,
    required this.mid,
    required this.vid,
    this.fid, // ✅ รับข้อมูลฟาร์ม
    this.farm, // ✅ รับข้อมูลฟาร์ม
    required this.vihicleData,
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

  // @override
  // void initState() {
  //   super.initState();
  //   print("ฟาร์มที่เลือก: ${widget.farm}");
  //   //selectedFarm = widget.farm; // ✅ ถ้ามีส่งมาก็ set เลย
  //   selectedFarm['fid'] = widget.farm['fid']; // ✅ ถ้ามี fid ก็ set ให้
  //   selectedFarm['name_farm'] = widget.farm?['name_farm'];
  //   selectedFarm['village'] = widget.farm?['village'];
  //   selectedFarm['subdistrict'] = widget.farm?['subdistrict'];
  //   selectedFarm['district'] = widget.farm?['district'];
  //   selectedFarm['province'] = widget.farm?['province'];
  //   selectedFarm['area_amount'] = widget.farm?['area_amount'];
  //   selectedFarm['unit_area'] = widget.farm?['unit_area'];
  //   selectedFarm['detail'] = widget.farm?['detail'];
  //   _loadFarms();
  // }
  @override
  void initState() {
    super.initState();

    print("ฟาร์มที่เลือก: ${widget.farm}");

    if (widget.farm != null) {
      selectedFarm = {
        'fid': widget.farm['fid'],
        'name_farm': widget.farm['name_farm'],
        'village': widget.farm['village'],
        'subdistrict': widget.farm['subdistrict'],
        'district': widget.farm['district'],
        'province': widget.farm['province'],
        'area_amount': widget.farm['area_amount'],
        'unit_area': widget.farm['unit_area'],
        'detail': widget.farm['detail'],
      };
    } else {
      selectedFarm = null;
    }

    _loadFarms();
  }

  // Future<void> _loadFarms() async {
  //   setState(() => isFarmLoading = true);
  //   try {
  //     final url = Uri.parse(
  //         'http://projectnodejs.thammadalok.com/AGribooking/get_farms/${widget.mid}');
  //     final res = await http.get(url);
  //     if (res.statusCode == 200) {
  //       final data = jsonDecode(res.body);
  //       setState(() {
  //         farmList = data;
  //       });
  //     }
  //   } catch (e) {
  //     print('Error loading farms: $e');
  //   } finally {
  //     setState(() => isFarmLoading = false);
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

          // 👇 หา farm object ใน farmList ที่มี fid ตรงกับ widget.farm['fid']
          if (widget.farm != null) {
            selectedFarm = farmList.firstWhere(
              (f) => f['fid'] == widget.farm['fid'],
              orElse: () => null,
            );
          }
        });
      }
    } catch (e) {
      print('Error loading farms: $e');
    } finally {
      setState(() => isFarmLoading = false);
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
    if (dateStart == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกวันเริ่มต้นก่อน')),
      );
      return;
    }

    final DateTime now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: dateEnd ?? dateStart!,
      firstDate: dateStart!,
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 13, minute: 0),
      );

      if (pickedTime != null) {
        final DateTime selectedEndDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        // ตรวจสอบว่า วันสิ้นสุด >= วันเริ่มต้น และถ้าเท่ากัน เวลา end > start
        if (selectedEndDateTime.isAfter(dateStart!)) {
          setState(() {
            dateEnd = selectedEndDateTime;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('วันและเวลาสิ้นสุดต้องมากกว่าวันเริ่มต้น'),
            ),
          );
        }
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
      "detail": detailController.text.trim() ?? 'ไม่มีรายละเอียดการจอง',
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

// // เพิ่มฟังก์ชันช่วยสร้าง TextField:
//   Widget _buildTextField({
//     required String label,
//     required TextEditingController controller,
//     TextInputType? inputType,
//     String? Function(String?)? validator,
//     int maxLines = 1,
//   }) {
//     return TextFormField(
//       controller: controller,
//       keyboardType: inputType,
//       maxLines: maxLines,
//       decoration: InputDecoration(
//         labelText: label,
//         border: const OutlineInputBorder(),
//         contentPadding:
//             const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       ),
//       validator: validator ??
//           (value) => value == null || value.isEmpty ? 'กรุณากรอก $label' : null,
//     );
//   }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? inputType,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool isOptional = false, // ✅ เพิ่มตรงนี้
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: isOptional ? 'ไม่จำเป็นต้องกรอก' : null, // แนะนำผู้ใช้
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: validator ??
          (value) {
            if (isOptional) return null; // ✅ ไม่ตรวจสอบหากไม่บังคับ
            return value == null || value.isEmpty ? 'กรุณากรอก $label' : null;
          },
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
                    Container(
                        child: Card(
                      elevation: 8, // เงาชัดเจน
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16), // มุมโค้งมนสวย
                      ),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 2, vertical: 2), // เว้นขอบการ์ด
                      shadowColor: Colors.black54, // เงาสีเข้มขึ้นเล็กน้อย
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12), // ระยะห่างในการ์ด
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              widget.vihicleData['image_vehicle'] ?? '',
                              width: 120,
                              height: 180,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
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
                    const SizedBox(height: 16),
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
                      maxLines: 3,
                      isOptional: true,
                    ),
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
                    const SizedBox(height: 16),
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
                    // if (selectedFarm != null) ...[
                    //   Center(
                    //     child: Container(
                    //         padding: const EdgeInsets.all(0),
                    //         margin: const EdgeInsets.symmetric(
                    //             vertical: 5, horizontal: 2),
                    //         child: Card(
                    //           elevation: 8, // เงาชัดเจน
                    //           shape: RoundedRectangleBorder(
                    //             borderRadius:
                    //                 BorderRadius.circular(16), // มุมโค้งมนสวย
                    //           ),
                    //           margin: const EdgeInsets.symmetric(
                    //               horizontal: 16, vertical: 10), // เว้นขอบการ์ด
                    //           shadowColor:
                    //               Colors.black54, // เงาสีเข้มขึ้นเล็กน้อย
                    //           child: Padding(
                    //             padding: const EdgeInsets.symmetric(
                    //                 vertical: 8,
                    //                 horizontal: 12), // ระยะห่างในการ์ด
                    //             child: ListTile(
                    //               title: Text(
                    //                 selectedFarm['name_farm'],
                    //                 style: const TextStyle(
                    //                   fontSize: 15,
                    //                   fontWeight: FontWeight.bold,
                    //                   color: Colors.black87,
                    //                   shadows: [
                    //                     Shadow(
                    //                       color: Colors.black12,
                    //                       offset: Offset(1, 1),
                    //                       blurRadius: 2,
                    //                     ),
                    //                   ],
                    //                 ),
                    //               ),
                    //               subtitle: Text(
                    //                 '${selectedFarm['village']}, ${selectedFarm['subdistrict']}, ${selectedFarm['district']}, ${selectedFarm['province']},${selectedFarm['area_amount']} ${selectedFarm['unit_area']}\n${selectedFarm['detail'] ?? 'ไม่มีรายละเอียดอื่นๆ'}',
                    //                 style: const TextStyle(
                    //                   fontSize: 14,
                    //                   color: Color.fromARGB(255, 95, 95, 95),
                    //                   fontWeight: FontWeight.w500,
                    //                 ),
                    //               ),

                    //               contentPadding: const EdgeInsets.symmetric(
                    //                   horizontal:
                    //                       0), // จัดระยะห่างภายใน ListTile
                    //             ),
                    //           ),
                    //         )),
                    //   ),
                    // ],
                    if (selectedFarm != null) ...[
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(0),
                          margin: const EdgeInsets.symmetric(
                              vertical: 5, horizontal: 2),
                          child: Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            shadowColor: Colors.black54,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 12),
                              child: ListTile(
                                title: Text(
                                  selectedFarm['name_farm'],
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
                                  '${selectedFarm['village']}, ${selectedFarm['subdistrict']}, ${selectedFarm['district']}, ${selectedFarm['province']}, ${selectedFarm['area_amount']} ${selectedFarm['unit_area']}\n'
                                  '${selectedFarm['detail'] ?? 'ไม่มีรายละเอียดอื่นๆ'}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color.fromARGB(255, 95, 95, 95),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 0),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    // const SizedBox(height: 12),
                    // const Center(
                    //   child: Text(
                    //     'ต้องการเปลี่ยนที่นา?',
                    //     style: TextStyle(fontWeight: FontWeight.bold),
                    //   ),
                    // ),
                    // const SizedBox(height: 8),
                    // Padding(
                    //   padding: const EdgeInsets.symmetric(horizontal: 16),
                    //   child: DropdownButtonFormField<dynamic>(
                    //     value: selectedFarm,
                    //     decoration: const InputDecoration(
                    //       labelText: 'เลือกที่นาอื่น',
                    //       border: OutlineInputBorder(),
                    //     ),
                    //     items: farmList.map<DropdownMenuItem<dynamic>>((farm) {
                    //       return DropdownMenuItem<dynamic>(
                    //         value: farm,
                    //         child: Text(farm['name_farm'] ?? "-"),
                    //       );
                    //     }).toList(),
                    //     onChanged: (value) {
                    //       setState(() {
                    //         selectedFarm = value;
                    //       });
                    //     },
                    //   ),
                    // ),

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
