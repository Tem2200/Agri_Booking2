// import 'dart:convert';
// import 'package:agri_booking2/pages/employer/Tabbar.dart';
// import 'package:agri_booking2/pages/employer/addFarm2.dart';
// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:http/http.dart' as http;
// import 'dart:io';

// class ReservingForNF extends StatefulWidget {
//   final int mid;
//   final int vid;
//   final int? fid;
//   final dynamic farm;
//   final dynamic vihicleData;
//   const ReservingForNF({
//     super.key,
//     required this.mid,
//     required this.vid,
//     this.fid,
//     this.farm,
//     required this.vihicleData,
//   });

//   @override
//   State<ReservingForNF> createState() => _ReservingForNFState();
// }

// class _ReservingForNFState extends State<ReservingForNF> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController nameController = TextEditingController();
//   final TextEditingController areaAmountController = TextEditingController();
//   final TextEditingController detailController = TextEditingController();
//   final TextEditingController customUnitController = TextEditingController();

//   DateTime? dateStart;
//   DateTime? dateEnd;

//   bool isLoading = false;
//   bool isFarmLoading = false;
//   List<dynamic> farmList = [];
//   dynamic selectedFarm;
//   late WebSocket _ws;
//   bool _wsConnected = false;
//   String? dateStartError;
//   String? dateEndError;
//   String? farmError;

//   final List<String> unitOptions = [
//     'ตารางวา',
//     'ไร่',
//     'งาน',
//     'ตารางเมตร',
//     'อื่นๆ'
//   ];
//   String? selectedUnit;
//   bool isCustomUnit = false;
//   @override
//   void initState() {
//     super.initState();
//     _connectWebSocket();

//     print("ฟาร์มที่เลือก: ${widget.farm}");

//     if (widget.farm != null) {
//       selectedFarm = {
//         'fid': widget.farm['fid'],
//         'name_farm': widget.farm['name_farm'],
//         'village': widget.farm['village'],
//         'subdistrict': widget.farm['subdistrict'],
//         'district': widget.farm['district'],
//         'province': widget.farm['province'],
//         'area_amount': widget.farm['area_amount'],
//         'unit_area': widget.farm['unit_area'],
//         'detail': widget.farm['detail'],
//       };
//     } else {
//       selectedFarm = null;
//     }

//     _loadFarms();
//   }

//   Future<void> _connectWebSocket() async {
//     try {
//       _ws = await WebSocket.connect(
//           'ws://projectnodejs.thammadalok.com:80/AGribooking');

//       setState(() => _wsConnected = true);
//       print("✅ WebSocket connected");

//       _ws.listen((message) {
//         print("📩 ได้รับจาก WS: $message");
//       }, onDone: () {
//         print("🔌 WebSocket ปิดแล้ว");
//         setState(() => _wsConnected = false);
//       }, onError: (err) {
//         print("⚠️ WS error: $err");
//         setState(() => _wsConnected = false);
//       });
//     } catch (e) {
//       print("❌ ไม่สามารถเชื่อมต่อ WS ได้: $e");
//       setState(() => _wsConnected = false);
//     }
//   }

//   Future<void> _submitReservation() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() {
//       dateStartError = dateStart == null ? 'กรุณาเลือกวันที่เริ่ม' : null;
//       dateEndError = dateEnd == null ? 'กรุณาเลือกวันที่สิ้นสุด' : null;
//       farmError = selectedFarm == null ? 'กรุณาเลือกที่นา' : null;
//     });

//     if (dateStartError != null || dateEndError != null || farmError != null)
//       return;

//     setState(() => isLoading = true);

//     final String finalUnit =
//         isCustomUnit ? customUnitController.text.trim() : selectedUnit ?? '';

//     final Map<String, dynamic> body = {
//       "name_rs": nameController.text.trim(),
//       "area_amount": int.tryParse(areaAmountController.text.trim()) ?? 0,
//       "unit_area": finalUnit,
//       "detail": detailController.text.trim().isEmpty
//           ? 'ไม่มีรายละเอียดการจอง'
//           : detailController.text.trim(),
//       "date_start":
//           "${dateStart!.toIso8601String().split('T')[0]} ${dateStart!.hour.toString().padLeft(2, '0')}:${dateStart!.minute.toString().padLeft(2, '0')}:00",
//       "date_end":
//           "${dateEnd!.toIso8601String().split('T')[0]} ${dateEnd!.hour.toString().padLeft(2, '0')}:${dateEnd!.minute.toString().padLeft(2, '0')}:00",
//       "progress_status": null,
//       "mid_employee": widget.mid,
//       "vid": widget.vid,
//       "fid": selectedFarm!['fid'],
//     };

//     try {
//       // ส่ง HTTP POST
//       final response = await http.post(
//         Uri.parse('http://projectnodejs.thammadalok.com/AGribooking/reserve'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode(body),
//       );

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         Fluttertoast.showToast(
//           msg: 'จองสำเร็จ',
//           toastLength: Toast.LENGTH_SHORT,
//           gravity: ToastGravity.TOP,
//           backgroundColor: Colors.green,
//           textColor: Colors.white,
//           fontSize: 16.0,
//         );
//         int currentMonth = DateTime.now().month;
//         int currentYear = DateTime.now().year;
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (context) => Tabbar(
//               mid: widget.mid,
//               value: 1,
//               month: currentMonth,
//               year: currentYear,
//             ),
//           ),
//         );
//       } else {
//         print("❌ Error ${response.statusCode} : ${response.body}");
//         await showDialog(
//           context: context,
//           builder: (context) {
//             return AlertDialog(
//               content: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const Text(
//                     'ไม่สามารถจองคิวรถได้',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   Image.network(
//                     'https://symbl-cdn.com/i/webp/c1/d9d88630432cf61ad335df98ce37d6.webp',
//                     height: 50,
//                   ),
//                   const SizedBox(height: 12),
//                   const Text(
//                     'รถคันนี้ไม่สามารถจองในเวลาที่เลือกได้ เนื่องจากยังมีงานที่อยู่ในระหว่างดำเนินการ',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(fontSize: 15),
//                   ),
//                   const SizedBox(height: 12),
//                   const Text(
//                     'กรุณาเลือกวันและเวลาอื่น',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(fontSize: 12),
//                   ),
//                 ],
//               ),
//               actionsAlignment: MainAxisAlignment.center,
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.of(context).pop(),
//                   child: const Text(
//                     'ตกลง',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       color: Colors.green,
//                     ),
//                   ),
//                 ),
//               ],
//             );
//           },
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
//       );
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }

//   Future<void> _loadFarms() async {
//     setState(() => isFarmLoading = true);

//     try {
//       final url = Uri.parse(
//           'http://projectnodejs.thammadalok.com/AGribooking/get_farms/${widget.mid}');
//       final res = await http.get(url);

//       if (res.statusCode == 200) {
//         final data = jsonDecode(res.body);

//         setState(() {
//           farmList = data;

//           // 👇 หา farm object ใน farmList ที่มี fid ตรงกับ widget.farm['fid']
//           if (widget.farm != null) {
//             selectedFarm = farmList.firstWhere(
//               (f) => f['fid'] == widget.farm['fid'],
//               orElse: () => null,
//             );
//           }
//         });
//       }
//     } catch (e) {
//       print('Error loading farms: $e');
//     } finally {
//       setState(() => isFarmLoading = false);
//     }
//   }

//   Future<void> _selectDateStart(BuildContext context) async {
//     final DateTime now = DateTime.now();

//     final DateTime? pickedDate = await showDatePicker(
//       context: context,
//       initialDate: dateStart ?? now,
//       firstDate: DateTime(now.year, now.month, now.day),
//       lastDate: DateTime(2100),
//     );

//     if (pickedDate != null) {
//       final TimeOfDay? pickedTime = await showTimePicker(
//         context: context,
//         initialTime: const TimeOfDay(hour: 9, minute: 0),
//       );

//       if (pickedTime != null) {
//         final DateTime selectedDateTime = DateTime(
//           pickedDate.year,
//           pickedDate.month,
//           pickedDate.day,
//           pickedTime.hour,
//           pickedTime.minute,
//         );

//         if (selectedDateTime.isAfter(now)) {
//           setState(() {
//             dateStart = selectedDateTime;

//             // ✅ ถ้า dateEnd มีอยู่แล้ว แต่ดันน้อยกว่าหรือเท่ากับ dateStart ใหม่
//             if (dateEnd != null && !dateEnd!.isAfter(dateStart!)) {
//               dateEnd = null; // reset เพื่อให้ผู้ใช้เลือกใหม่

//               // แจ้งเตือนว่าถูก reset แล้ว
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(
//                   content: Text('วันสิ้นสุดถูกรีเซ็ต กรุณาเลือกใหม่'),
//                 ),
//               );
//             }
//           });
//         } else {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('กรุณาเลือกวันที่และเวลาที่มากกว่าปัจจุบัน'),
//             ),
//           );
//         }
//       }
//     }
//   }

//   Future<void> _selectDateEnd(BuildContext context) async {
//     if (dateStart == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('กรุณาเลือกวันเริ่มต้นก่อน')),
//       );
//       return;
//     }

//     final DateTime now = DateTime.now();
//     final DateTime? pickedDate = await showDatePicker(
//       context: context,
//       initialDate: dateEnd ?? dateStart!,
//       firstDate: dateStart!,
//       lastDate: DateTime(2100),
//     );

//     if (pickedDate != null) {
//       final TimeOfDay? pickedTime = await showTimePicker(
//         context: context,
//         initialTime: const TimeOfDay(hour: 13, minute: 0),
//       );

//       if (pickedTime != null) {
//         final DateTime selectedEndDateTime = DateTime(
//           pickedDate.year,
//           pickedDate.month,
//           pickedDate.day,
//           pickedTime.hour,
//           pickedTime.minute,
//         );

//         // ตรวจสอบว่า วันสิ้นสุด >= วันเริ่มต้น และถ้าเท่ากัน เวลา end > start
//         if (selectedEndDateTime.isAfter(dateStart!)) {
//           setState(() {
//             dateEnd = selectedEndDateTime;
//           });
//         } else {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('วันและเวลาสิ้นสุดต้องมากกว่าวันเริ่มต้น'),
//             ),
//           );
//         }
//       }
//     }
//   }

//   final TextStyle _infoStyles = const TextStyle(
//     fontSize: 16,
//     color: Colors.black87,
//     fontWeight: FontWeight.w500,
//     height: 1.4,
//   );

// // เพิ่มในส่วนบนของไฟล์:
//   TextStyle get _infoStyle =>
//       const TextStyle(fontSize: 14, color: Colors.black87);
//   TextStyle get _sectionTitleStyle =>
//       const TextStyle(fontSize: 16, fontWeight: FontWeight.bold);

//   Widget _buildTextField({
//     required String label,
//     required TextEditingController controller,
//     TextInputType? inputType,
//     String? Function(String?)? validator,
//     int maxLines = 1,
//     bool isOptional = false, // ✅ เพิ่มตรงนี้
//   }) {
//     return TextFormField(
//       controller: controller,
//       keyboardType: inputType,
//       maxLines: maxLines,
//       decoration: InputDecoration(
//         labelText: label,
//         hintText: isOptional ? 'ไม่จำเป็นต้องกรอก' : null, // แนะนำผู้ใช้
//         border: const OutlineInputBorder(),
//         contentPadding:
//             const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       ),
//       validator: validator ??
//           (value) {
//             if (isOptional) return null; // ✅ ไม่ตรวจสอบหากไม่บังคับ
//             return value == null || value.isEmpty ? 'กรุณากรอก $label' : null;
//           },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: const Color.fromARGB(255, 18, 143, 9),
//         centerTitle: true,
//         //automaticallyImplyLeading: false,
//         title: const Text(
//           'จองคิวรถ',
//           style: TextStyle(
//             fontSize: 22,
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//             shadows: [
//               Shadow(
//                 color: Color.fromARGB(115, 253, 237, 237),
//                 blurRadius: 3,
//                 offset: Offset(1.5, 1.5),
//               ),
//             ],
//           ),
//         ),
//         leading: IconButton(
//           color: Colors.white,
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () {
//             Navigator.pop(context); // ✅ กลับหน้าก่อนหน้า
//           },
//         ),
//       ),
//       body: isLoading || isFarmLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(16),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Container(
//                         child: Card(
//                       elevation: 8,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       margin: const EdgeInsets.symmetric(
//                           horizontal: 12, vertical: 8), // เว้นขอบกว้างขึ้น
//                       shadowColor: Colors.black54,
//                       child: Padding(
//                         padding: const EdgeInsets.all(12), // ระยะห่างรอบๆ การ์ด
//                         child: Row(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             // รูปด้านซ้าย
//                             ClipRRect(
//                               borderRadius: BorderRadius.circular(12),
//                               child: Image.network(
//                                 widget.vihicleData['image_vehicle'] ?? '',
//                                 width: 120,
//                                 height: 120,
//                                 fit: BoxFit.cover,
//                                 errorBuilder: (context, error, stackTrace) =>
//                                     Container(
//                                   width: 120,
//                                   height: 120,
//                                   color: Colors.grey[300],
//                                   child: const Icon(Icons.broken_image,
//                                       size: 48, color: Colors.grey),
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(
//                                 width: 12), // เว้นช่องว่างระหว่างรูปกับข้อความ
//                             // ข้อความด้านขวา
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     widget.vihicleData['name_vehicle'] ??
//                                         'ไม่มีชื่อรถ',
//                                     style: const TextStyle(
//                                       fontSize: 18,
//                                       fontWeight: FontWeight.bold,
//                                       color: Colors.black87,
//                                       shadows: [
//                                         Shadow(
//                                           color: Colors.black12,
//                                           offset: Offset(1, 1),
//                                           blurRadius: 2,
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                   const SizedBox(height: 6),
//                                   Text(
//                                     'ผู้รับจ้าง: ${widget.vihicleData['username'] ?? '-'}',
//                                     style: const TextStyle(
//                                       fontSize: 13,
//                                       //fontWeight: FontWeight.w600,
//                                       color: Color.fromARGB(200, 100, 100, 100),
//                                     ),
//                                   ),
//                                   const SizedBox(height: 4),
//                                   Text(
//                                     '${widget.vihicleData['price'] ?? '-'} บาท / ${widget.vihicleData['unit_price'] ?? '-'}',
//                                     style: const TextStyle(
//                                       fontSize: 13,
//                                       color: Color.fromARGB(200, 100, 100, 100),
//                                       //fontWeight: FontWeight.w500,
//                                     ),
//                                   ),
//                                   const SizedBox(height: 4),
//                                   Text(
//                                     widget.vihicleData['detail'] ?? '-',
//                                     style: const TextStyle(
//                                       fontSize: 13,
//                                       color: Color.fromARGB(200, 100, 100, 100),
//                                     ),
//                                     maxLines: 1,
//                                     overflow: TextOverflow.ellipsis,
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     )),
//                     const SizedBox(height: 16),
//                     _buildTextField(
//                         label: 'ชื่อการจอง*', controller: nameController),
//                     const SizedBox(height: 16),
//                     _buildTextField(
//                        label: 'จำนวน (${widget.vihicleData['unit_price']}) *',
//                       controller: areaAmountController,
//                       inputType: TextInputType.number,
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'กรุณากรอกจำนวนพื้นที่*';
//                         }
//                         if (int.tryParse(value) == null) {
//                           return 'กรุณากรอกเป็นตัวเลข*';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 16),
//                     DropdownButtonFormField<String>(
//                       value: selectedUnit,
//                       items: unitOptions.map((String value) {
//                         return DropdownMenuItem<String>(
//                           value: value,
//                           child: Text(value),
//                         );
//                       }).toList(),
//                       onChanged: (value) {
//                         setState(() {
//                           selectedUnit = value;
//                           isCustomUnit = value == 'อื่นๆ';
//                         });
//                       },
//                       decoration: const InputDecoration(
//                         labelText: 'เลือกหน่วย*',
//                         border: OutlineInputBorder(),
//                         contentPadding:
//                             EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                       ),
//                       validator: (value) => value == null || value.isEmpty
//                           ? 'กรุณาเลือกหน่วย'
//                           : null,
//                     ),
//                     if (isCustomUnit) ...[
//                       const SizedBox(height: 16),
//                       _buildTextField(
//                           label: 'ระบุหน่วยเอง*',
//                           controller: customUnitController),
//                     ],
//                     const SizedBox(height: 20),
//                     Text("เลือกวันและเวลาทำงาน*", style: _sectionTitleStyle),
//                     const SizedBox(height: 8),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               OutlinedButton(
//                                 onPressed: () => _selectDateStart(context),
//                                 child: Text(
//                                   dateStart == null
//                                       ? 'เลือกวันที่เริ่ม'
//                                       : 'เริ่ม: ${dateStart!.toLocal()}'
//                                           .split('.')[0],
//                                 ),
//                               ),
//                               if (dateStartError != null)
//                                 Padding(
//                                   padding: const EdgeInsets.only(left: 4),
//                                   child: Text(
//                                     dateStartError!,
//                                     style: const TextStyle(
//                                         color: Colors.red, fontSize: 12),
//                                   ),
//                                 ),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               OutlinedButton(
//                                 onPressed: () => _selectDateEnd(context),
//                                 child: Text(
//                                   dateEnd == null
//                                       ? 'เลือกวันที่สิ้นสุด'
//                                       : 'สิ้นสุด: ${dateEnd!.toLocal()}'
//                                           .split('.')[0],
//                                 ),
//                               ),
//                               if (dateEndError != null)
//                                 Padding(
//                                   padding: const EdgeInsets.only(left: 4),
//                                   child: Text(
//                                     dateEndError!,
//                                     style: const TextStyle(
//                                         color: Colors.red, fontSize: 12),
//                                   ),
//                                 ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 24),
//                     DropdownButtonFormField<dynamic>(
//                       value: selectedFarm,
//                       decoration: InputDecoration(
//                         labelText: 'เลือกที่นา*',
//                         border: const OutlineInputBorder(),
//                         contentPadding: const EdgeInsets.symmetric(
//                             horizontal: 16, vertical: 12),
//                         errorText: farmError, // แสดง error ใต้ dropdown
//                       ),
//                       items: farmList.map<DropdownMenuItem<dynamic>>((farm) {
//                         return DropdownMenuItem<dynamic>(
//                           value: farm,
//                           child: Text(farm['name_farm'] ?? "-"),
//                         );
//                       }).toList(),
//                       onChanged: (value) {
//                         setState(() {
//                           selectedFarm = value;
//                           farmError = null; // เคลียร์ error เมื่อเลือกแล้ว
//                         });
//                       },
//                     ),

//                     if (selectedFarm != null) ...[
//                       Center(
//                         child: Container(
//                           padding: const EdgeInsets.all(0),
//                           margin: const EdgeInsets.symmetric(
//                               vertical: 5, horizontal: 2),
//                           child: Card(
//                             elevation: 8,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(16),
//                             ),
//                             margin: const EdgeInsets.symmetric(
//                                 horizontal: 16, vertical: 10),
//                             shadowColor: Colors.black54,
//                             child: Padding(
//                               padding: const EdgeInsets.symmetric(
//                                   vertical: 8, horizontal: 12),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     'ชื่อ: ${selectedFarm['name_farm'] ?? '-'}',
//                                     style: const TextStyle(
//                                       fontSize: 15,
//                                       fontWeight: FontWeight.bold,
//                                       color: Colors.black87,
//                                       shadows: [
//                                         Shadow(
//                                           color: Colors.black12,
//                                           offset: Offset(1, 1),
//                                           blurRadius: 2,
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                   const SizedBox(height: 8),
//                                   Text(
//                                     'ที่อยู่: ${selectedFarm['village']}, ${selectedFarm['subdistrict']}, ${selectedFarm['district']}, ${selectedFarm['province']}, ${selectedFarm['area_amount']} ${selectedFarm['unit_area']}',
//                                     style: const TextStyle(
//                                       fontSize: 14,
//                                       color: Color.fromARGB(255, 95, 95, 95),
//                                       fontWeight: FontWeight.w500,
//                                     ),
//                                   ),
//                                   const SizedBox(height: 8),
//                                   Text(
//                                     'รายละเอียดไร่นา: ${selectedFarm['detail'] ?? 'ไม่มีรายละเอียดอื่นๆ'}',
//                                     style: const TextStyle(
//                                       fontSize: 14,
//                                       color: Color.fromARGB(255, 95, 95, 95),
//                                       fontWeight: FontWeight.w500,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                     if (farmList.isEmpty) ...[
//                       //const SizedBox(height: 16),
//                       const Center(
//                         child: Text(
//                           'คุณยังไม่มีข้อมูลที่นา',
//                           style: TextStyle(
//                             color: Colors.red,
//                             fontWeight: FontWeight.bold,
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Center(
//                         // จัดปุ่มให้อยู่ตรงกลาง
//                         child: ElevatedButton.icon(
//                           onPressed: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) =>
//                                     AddFarmPage2(mid: widget.mid),
//                               ),
//                             ).then((_) => _loadFarms());
//                           },
//                           icon: const Icon(Icons.add_location_alt,
//                               color: Colors.white), // ไอคอนสีขาว
//                           label: const Text(
//                             'เพิ่มที่นา',
//                             style: TextStyle(
//                                 color: Colors.white), // ตัวหนังสือสีขาว
//                           ),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.green, // พื้นปุ่มสีเขียว
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 24,
//                                 vertical: 12), // ปรับขนาดปุ่มให้พอดี
//                             shape: RoundedRectangleBorder(
//                               borderRadius:
//                                   BorderRadius.circular(8), // มุมโค้งเล็กน้อย
//                             ),
//                           ),
//                         ),
//                       ),
//                       const Divider(height: 32, thickness: 1),
//                     ],
//                     //const SizedBox(height: 16),
//                     _buildTextField(
//                       label: 'รายละเอียดงาน',
//                       controller: detailController,
//                       maxLines: 2,
//                       isOptional: true,
//                     ),
//                     const SizedBox(height: 28),
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         onPressed: _submitReservation,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.orange,
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           textStyle: const TextStyle(
//                               fontSize: 18, fontWeight: FontWeight.bold),
//                         ),
//                         child: const Text('ยืนยันจอง'),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//     );
//   }
// }


import 'dart:convert';
import 'package:agri_booking2/pages/employer/Tabbar.dart';
import 'package:agri_booking2/pages/employer/addFarm2.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class ReservingForNF extends StatefulWidget {
  final int mid;
  final int vid;
  final int? fid;
  final dynamic farm;
  final dynamic vihicleData;
  const ReservingForNF({
    super.key,
    required this.mid,
    required this.vid,
    this.fid,
    this.farm,
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
  late WebSocket _ws;
  bool _wsConnected = false;
  String? dateStartError;
  String? dateEndError;
  String? farmError;

  final List<String> unitOptions = [
    'ตารางวา',
    'ไร่',
    'งาน',
    'ตารางเมตร',
    'อื่นๆ'
  ];
  String? selectedUnit;
  bool isCustomUnit = false;
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

    // ตั้งค่าหน่วยเริ่มต้นตามข้อมูลรถ
    final dynamic unitFromVehicle = widget.vihicleData['unit_price'];
    if (unitFromVehicle != null && unitFromVehicle.toString().trim().isNotEmpty) {
      final String unitText = unitFromVehicle.toString().trim();
      if (unitOptions.contains(unitText)) {
        selectedUnit = unitText;
        isCustomUnit = unitText == 'อื่นๆ';
        if (isCustomUnit) {
          customUnitController.text = '';
        }
      } else {
        selectedUnit = 'อื่นๆ';
        isCustomUnit = true;
        customUnitController.text = unitText;
      }
    } else {
      selectedUnit = null;
      isCustomUnit = false;
      customUnitController.text = '';
    }

    _loadFarms();
  }

  Future<void> _submitReservation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      dateStartError = dateStart == null ? 'กรุณาเลือกวันที่เริ่ม' : null;
      dateEndError = dateEnd == null ? 'กรุณาเลือกวันที่สิ้นสุด' : null;
      farmError = selectedFarm == null ? 'กรุณาเลือกที่นา' : null;
    });

    if (dateStartError != null || dateEndError != null || farmError != null)
      return;

    setState(() => isLoading = true);

    final String finalUnit =
        isCustomUnit ? customUnitController.text.trim() : selectedUnit ?? '';

    final Map<String, dynamic> body = {
      "name_rs": nameController.text.trim(),
      "area_amount": int.tryParse(areaAmountController.text.trim()) ?? 0,
      "unit_area": finalUnit,
      "detail": detailController.text.trim().isEmpty
          ? 'ไม่มีรายละเอียดการจอง'
          : detailController.text.trim(),
      "date_start":
          "${dateStart!.toIso8601String().split('T')[0]} ${dateStart!.hour.toString().padLeft(2, '0')}:${dateStart!.minute.toString().padLeft(2, '0')}:00",
      "date_end":
          "${dateEnd!.toIso8601String().split('T')[0]} ${dateEnd!.hour.toString().padLeft(2, '0')}:${dateEnd!.minute.toString().padLeft(2, '0')}:00",
      "progress_status": null,
      "mid_employee": widget.mid,
      "vid": widget.vid,
      "fid": selectedFarm!['fid'],
    };

    try {
      // ส่ง HTTP POST
      final response = await http.post(
        Uri.parse('http://projectnodejs.thammadalok.com/AGribooking/reserve'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Fluttertoast.showToast(
          msg: 'จองสำเร็จ',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
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
        print("❌ Error ${response.statusCode} : ${response.body}");
        await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'ไม่สามารถจองคิวรถได้',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Image.network(
                    'https://symbl-cdn.com/i/webp/c1/d9d88630432cf61ad335df98ce37d6.webp',
                    height: 50,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'รถคันนี้ไม่สามารถจองในเวลาที่เลือกได้ เนื่องจากยังมีงานที่อยู่ในระหว่างดำเนินการ',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'กรุณาเลือกวันและเวลาอื่น',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'ตกลง',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            );
          },
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
        initialTime: const TimeOfDay(hour: 9, minute: 0),
      );

      if (pickedTime != null) {
        final DateTime selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        if (selectedDateTime.isAfter(now)) {
          setState(() {
            dateStart = selectedDateTime;

            // ✅ ถ้า dateEnd มีอยู่แล้ว แต่ดันน้อยกว่าหรือเท่ากับ dateStart ใหม่
            if (dateEnd != null && !dateEnd!.isAfter(dateStart!)) {
              dateEnd = null; // reset เพื่อให้ผู้ใช้เลือกใหม่

              // แจ้งเตือนว่าถูก reset แล้ว
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('วันสิ้นสุดถูกรีเซ็ต กรุณาเลือกใหม่'),
                ),
              );
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('กรุณาเลือกวันที่และเวลาที่มากกว่าปัจจุบัน'),
            ),
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

  // Widget _buildTextField({
  //   required String label,
  //   required TextEditingController controller,
  //   TextInputType? inputType,
  //   String? Function(String?)? validator,
  //   int maxLines = 1,
  //   bool isOptional = false, // ✅ เพิ่มตรงนี้
  // }) {
  //   return TextFormField(
  //     controller: controller,
  //     keyboardType: inputType,
  //     maxLines: maxLines,
  //     decoration: InputDecoration(
  //       labelText: label,
  //       hintText: isOptional ? 'ไม่จำเป็นต้องกรอก' : null, // แนะนำผู้ใช้
  //       border: const OutlineInputBorder(),
  //       contentPadding:
  //           const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //     ),
  //     validator: validator ??
  //         (value) {
  //           if (isOptional) return null; // ✅ ไม่ตรวจสอบหากไม่บังคับ
  //           return value == null || value.isEmpty ? 'กรุณากรอก $label' : null;
  //         },
  //   );
  // }
  Widget _buildTextField({
  required String label,
  required TextEditingController controller,
  TextInputType? inputType,
  String? Function(String?)? validator,
  int maxLines = 1,
  bool isOptional = false,
  int? maxLength, // ✅ เพิ่มตรงนี้
}) {
  return TextFormField(
    controller: controller,
    keyboardType: inputType,
    maxLines: maxLines,
    maxLength: maxLength,
    buildCounter: (BuildContext context,
            {int? currentLength, bool? isFocused, int? maxLength}) =>
        null, // ✅ ปิดตัวนับตัวอักษร
    decoration: InputDecoration(
      labelText: label,
      hintText: isOptional ? 'ไม่จำเป็นต้องกรอก' : null,
      border: const OutlineInputBorder(),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    validator: validator ??
        (value) {
          if (isOptional) return null;
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
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8), // เว้นขอบกว้างขึ้น
                      shadowColor: Colors.black54,
                      child: Padding(
                        padding: const EdgeInsets.all(12), // ระยะห่างรอบๆ การ์ด
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // รูปด้านซ้าย
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                widget.vihicleData['image_vehicle'] ?? '',
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  width: 120,
                                  height: 120,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.broken_image,
                                      size: 48, color: Colors.grey),
                                ),
                              ),
                            ),
                            const SizedBox(
                                width: 12), // เว้นช่องว่างระหว่างรูปกับข้อความ
                            // ข้อความด้านขวา
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.vihicleData['name_vehicle'] ??
                                        'ไม่มีชื่อรถ',
                                    style: const TextStyle(
                                      fontSize: 18,
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
                                  const SizedBox(height: 6),
                                  Text(
                                    'ผู้รับจ้าง: ${widget.vihicleData['username'] ?? '-'}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      //fontWeight: FontWeight.w600,
                                      color: Color.fromARGB(200, 100, 100, 100),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${widget.vihicleData['price'] ?? '-'} บาท / ${widget.vihicleData['unit_price'] ?? '-'}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color.fromARGB(200, 100, 100, 100),
                                      //fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.vihicleData['detail'] ?? '-',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color.fromARGB(200, 100, 100, 100),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                    const SizedBox(height: 16),
                    _buildTextField(
  label: 'ชื่อการจอง*',
  controller: nameController,
  maxLength: 100,
),

                    const SizedBox(height: 16),
                    _buildTextField(
                       label: 'จำนวน (${widget.vihicleData['unit_price']}) *',
                      controller: areaAmountController,
                      maxLength: 11,
                      inputType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'กรุณากรอกจำนวนพื้นที่*';
                        }
                        if (int.tryParse(value) == null) {
                          return 'กรุณากรอกเป็นตัวเลข*';
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
                        labelText: 'เลือกหน่วย*',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'กรุณาเลือกหน่วย'
                          : null,
                    ),
                    if (isCustomUnit) ...[
                      const SizedBox(height: 16),
                      _buildTextField(
                          label: 'ระบุหน่วยเอง*',
                          controller: customUnitController, maxLength: 20),
                    ],
                    const SizedBox(height: 20),
                    Text("เลือกวันและเวลาทำงาน*", style: _sectionTitleStyle),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              OutlinedButton(
                                onPressed: () => _selectDateStart(context),
                                child: Text(
                                  dateStart == null
                                      ? 'เลือกวันที่เริ่ม'
                                      : 'เริ่ม: ${dateStart!.toLocal()}'
                                          .split('.')[0],
                                ),
                              ),
                              if (dateStartError != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Text(
                                    dateStartError!,
                                    style: const TextStyle(
                                        color: Colors.red, fontSize: 12),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              OutlinedButton(
                                onPressed: () => _selectDateEnd(context),
                                child: Text(
                                  dateEnd == null
                                      ? 'เลือกวันที่สิ้นสุด'
                                      : 'สิ้นสุด: ${dateEnd!.toLocal()}'
                                          .split('.')[0],
                                ),
                              ),
                              if (dateEndError != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Text(
                                    dateEndError!,
                                    style: const TextStyle(
                                        color: Colors.red, fontSize: 12),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<dynamic>(
  value: selectedFarm,
  decoration: InputDecoration(
    labelText: 'เลือกที่นา*',
    border: const OutlineInputBorder(),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    errorText: farmError, // แสดง error ใต้ dropdown
  ),
  isExpanded: true, // ทำให้ dropdown กว้างเต็มพื้นที่
  items: farmList.map<DropdownMenuItem<dynamic>>((farm) {
    return DropdownMenuItem<dynamic>(
      value: farm,
      child: Text(farm['name_farm'] ?? "-"),
    );
  }).toList(),
  onChanged: (value) {
    setState(() {
      selectedFarm = value;
      farmError = null; // เคลียร์ error เมื่อเลือกแล้ว
    });
  },
  validator: (value) {
    if (value == null) {
      return 'กรุณาเลือกที่นา'; // แสดงข้อความ error
    }
    return null;
  },
),


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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ชื่อ: ${selectedFarm['name_farm'] ?? '-'}',
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
                                  const SizedBox(height: 8),
                                  Text(
                                    'ที่อยู่: ${selectedFarm['village']}, ${selectedFarm['subdistrict']}, ${selectedFarm['district']}, ${selectedFarm['province']}, ${selectedFarm['area_amount']} ${selectedFarm['unit_area']}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color.fromARGB(255, 95, 95, 95),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'รายละเอียดไร่นา: ${selectedFarm['detail'] ?? 'ไม่มีรายละเอียดอื่นๆ'}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color.fromARGB(255, 95, 95, 95),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (farmList.isEmpty) ...[
                      //const SizedBox(height: 16),
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
                    //const SizedBox(height: 16),
                    _buildTextField(
                      label: 'รายละเอียดงาน',
                      controller: detailController,
                      maxLength: 500,
                      maxLines: 2,
                      isOptional: true,
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
                              fontSize: 18, fontWeight: FontWeight.bold),
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

