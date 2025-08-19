import 'dart:convert';
import 'package:agri_booking2/pages/contactor/DetailWork.dart';
import 'package:agri_booking2/pages/contactor/Tabbar.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:io'; // อย่าลืม import WebSocket

class NontiPage extends StatefulWidget {
  final int mid;

  const NontiPage({super.key, required this.mid});

  @override
  State<NontiPage> createState() => _NontiPageState();
}

class _NontiPageState extends State<NontiPage> {
  Future<List<dynamic>>? _scheduleFuture;
  int _newJobsCount = 0; // จำนวนงานใหม่ (progress_status = null)
  int _cancelledJobsCount = 0; // จำนวนงานที่ถูกยกเลิก (progress_status = 5)
  late WebSocket _ws; // ✅ เพิ่มตัวแปร WebSocket
  // @override
  // void initState() {
  //   super.initState();
  //   print("MID: ${widget.mid}");
  //   setState(() {
  //     _scheduleFuture = fetchAndCountSchedule(widget.mid);
  //     //_scheduleFuture = fetchSchedule(widget.mid); // ✅ แก้ตรงนี้
  //     print("_scheduleFuture: $_scheduleFuture");
  //     // ✅ ไม่ใช้ month/year แล้ว
  //   });
  // }

  @override
  void initState() {
    super.initState();
    print("MID: ${widget.mid}");
    _scheduleFuture = fetchAndCountSchedule(widget.mid);
    //connectWebSocket(); // ✅ เพิ่มบรรทัดนี้เพื่อเชื่อมต่อ WS
  }

  // @override
  // void dispose() {
  //   if (_ws.readyState == WebSocket.open) {
  //     // ✅ เพิ่มการปิดการเชื่อมต่อ
  //     _ws.close();
  //   }
  //   super.dispose();
  // }

  // void connectWebSocket() async {
  //   try {
  //     _ws = await WebSocket.connect(
  //         'ws://projectnodejs.thammadalok.com:80/AGribooking'); // ✅ แก้ไขตรงนี้

  //     _ws.listen(
  //       (message) {
  //         final data = jsonDecode(message);
  //         // ตรวจสอบ event ที่เกี่ยวข้องกับการแจ้งเตือน
  //         if (data['event'] == 'con_reserving_update' &&
  //             data['mid'].toString() == widget.mid.toString()) {
  //           print("Received WebSocket update, fetching data...");
  //           // เรียกฟังก์ชันเพื่อดึงข้อมูลใหม่ทันที
  //           setState(() {
  //             _scheduleFuture = fetchAndCountSchedule(widget.mid);
  //           });
  //         }
  //       },
  //       onDone: () {
  //         print('WebSocket closed, retry in 5 sec');
  //         Future.delayed(const Duration(seconds: 5), connectWebSocket);
  //       },
  //       onError: (e) {
  //         print('WebSocket error: $e, retry in 5 sec');
  //         Future.delayed(const Duration(seconds: 5), connectWebSocket);
  //       },
  //     );
  //   } catch (e) {
  //     print('ฮือๆๆๆๆๆWebSocket connection error: $e, retry in 5 sec');
  //     Future.delayed(const Duration(seconds: 5), connectWebSocket);
  //   }
  // }

  Future<void> updateProgressStatus(dynamic rsid, int status) async {
    final url = Uri.parse(
      'http://projectnodejs.thammadalok.com/AGribooking/update_progress',
    );

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'rsid': rsid,
          'progress_status': status, // เปลี่ยนเป็น 0
        }),
      );

      if (response.statusCode == 200) {
        if (status == 0) {
          // ถ้าเปลี่ยนเป็น 0 แสดงว่ายกเลิกคิว
          Fluttertoast.showToast(
            msg: 'ยกเลิกคิวสำเร็จ',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.TOP,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        } else {
          Fluttertoast.showToast(
            msg: 'ยืนยันการจองคิวสำเร็จ',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.TOP,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        }

        // // รีเฟรชข้อมูล
        // setState(() {
        //   _scheduleFuture = fetchSchedule(widget.mid);
        // });

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => TabbarCar(
              mid: widget.mid,
              value: 1, // ค่า value ที่ต้องการส่งไป
              month: DateTime.now().month, // ใช้เดือนปัจจุบัน
              year: DateTime.now().year, // ใช้ปีปัจจุบัน
            ),
          ),
          (route) => false,
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("อัปเดตล้มเหลว"),
            content: Text("รหัสสถานะ: ${response.statusCode}"),
          ),
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("เกิดข้อผิดพลาด"),
          content: Text("ไม่สามารถเชื่อมต่อ: $e"),
        ),
      );
    }
  }

  Future<List<dynamic>> fetchAndCountSchedule(int mid) async {
    final url = Uri.parse(
        'http://projectnodejs.thammadalok.com/AGribooking/get_ConReservingNonti/$mid');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          final List<dynamic> data = jsonDecode(response.body);

          int newJobs = 0;
          int cancelledJobs = 0;

          for (var item in data) {
            final status = item['progress_status'];
            if (status == null) {
              newJobs++;
            } else if (status == 5) {
              cancelledJobs++;
            }
          }

// อัปเดตตัวแปรสถานะ
          if (mounted) {
            setState(() {
              _newJobsCount = newJobs;
              _cancelledJobsCount = cancelledJobs;
            });
          }
          return data;
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to load schedule: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  Future<List<dynamic>> fetchSchedule(int mid) async {
    final url = Uri.parse(
        'http://projectnodejs.thammadalok.com/AGribooking/get_ConReservingNonti/$mid');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        print("สถานะ NULLLLLLLLLLLL + ${response.body}");
        if (response.body.isNotEmpty) {
          return jsonDecode(response.body);
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to load schedule: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

// ฟังก์ชันแปลงวันที่ทั่วไป (ใช้กับ date_reserve)
  String formatDateReserveThai(String? dateReserve) {
    if (dateReserve == null || dateReserve.isEmpty) return '-';
    try {
      DateTime utcDate = DateTime.parse(dateReserve);
      DateTime localDate = utcDate.toUtc().add(const Duration(hours: 7));
      final formatter = DateFormat("d MMM yyyy เวลา HH:mm น.", "th_TH");
      String formatted = formatter.format(localDate);
      // แปลงปี ค.ศ. → พ.ศ.
      String yearString = localDate.year.toString();
      String buddhistYear = (localDate.year + 543).toString();
      return formatted.replaceFirst(yearString, buddhistYear);
    } catch (e) {
      return '-';
    }
  }

// ฟังก์ชันแปลงช่วงวันที่เริ่ม-สิ้นสุดงาน
  String formatDateRangeThai(String? startDate, String? endDate) {
    if (startDate == null ||
        startDate.isEmpty ||
        endDate == null ||
        endDate.isEmpty) {
      return 'ไม่ระบุวันที่';
    }

    try {
      DateTime startUtc = DateTime.parse(startDate);
      DateTime endUtc = DateTime.parse(endDate);

      DateTime startThai = startUtc.toUtc().add(const Duration(hours: 7));
      DateTime endThai = endUtc.toUtc().add(const Duration(hours: 7));

      final formatter = DateFormat('dd/MM/yyyy เวลา HH:mm', "th_TH");

      String toBuddhistYearFormat(DateTime date) {
        String formatted = formatter.format(date);
        String yearString = date.year.toString();
        String buddhistYear = (date.year + 543).toString();
        return formatted.replaceFirst(yearString, buddhistYear);
      }

      const labelStart = 'เริ่มงาน:';
      const labelEnd = 'สิ้นสุด:';
      final maxLabelLength =
          [labelStart.length, labelEnd.length].reduce((a, b) => a > b ? a : b);

      String alignLabel(String label) {
        final spaces = ' ' * (maxLabelLength - label.length);
        return '$label$spaces';
      }

      return '${alignLabel(labelStart)} ${toBuddhistYearFormat(startThai)}\n'
          '${alignLabel(labelEnd)} ${toBuddhistYearFormat(endThai)}';
    } catch (e) {
      return 'กำลังโหลดข้อมูล...';
    }
  }

// --- ฟังก์ชันสำหรับดึงข้อมูลสมาชิกใส่ appBar ---
  Future<Map<String, dynamic>> item(int mid) async {
    final urlCon = Uri.parse(
        'http://projectnodejs.thammadalok.com/AGribooking/members/$mid');
    final response = await http.get(urlCon);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("ข้อมูลสมาชิก: $data");
      return data;
    } else {
      throw Exception('ไม่พบข้อมูลสมาชิก');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 18, 143, 9),
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: const Text(
            'การแจ้งเตือน (ผู้รับจ้าง)',
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
          actions: [
            FutureBuilder<Map<String, dynamic>>(
              future: item(widget.mid), // ✅ ดึงข้อมูลสมาชิก
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.only(right: 12.0),
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  );
                }

                // ถ้า error หรือไม่มีข้อมูล -> ใช้ data = {}
                final data = snapshot.data ?? {};

                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: GestureDetector(
                    onTap: () {
                      int currentMonth = DateTime.now().month;
                      int currentYear = DateTime.now().year;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TabbarCar(
                            mid: widget.mid,
                            value: 2,
                            month: currentMonth,
                            year: currentYear,
                          ),
                        ),
                      );
                    },
                    child: ClipOval(
                      child: (data['image'] != null &&
                              data['image'].toString().isNotEmpty)
                          ? Image.network(
                              data['image'], // ✅ แสดงรูปจาก DB
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 40,
                              height: 40,
                              color: Colors.white24,
                              child: const Icon(
                                Icons.person,
                                size: 28,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                );
              },
            )
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 6,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: TabBar(
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        colors: [
                          const Color.fromARGB(255, 190, 255, 189),
                          const Color.fromARGB(255, 37, 189, 35),
                          Colors.green[800]!,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.black87,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelStyle:
                        Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                    unselectedLabelStyle:
                        Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontSize: 14,
                            ),
                    tabs: [
                      Tab(
                        child: SizedBox(
                          width: 120,
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('งานใหม่'),
                                if (_newJobsCount > 0) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$_newJobsCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      Tab(
                        child: SizedBox(
                          width: 120,
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Flexible(
                                  // ใช้ Flexible ครอบ Text
                                  child: Text(
                                    'แจ้งยกเลิกงาน',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: TextStyle(),
                                  ),
                                ),
                                if (_cancelledJobsCount > 0) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$_cancelledJobsCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildVehicleQueueList(includeHistory: false),
                  _buildCancelVehicleQueue(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildVehicleQueueList({required bool includeHistory}) {
  //   return FutureBuilder<List<dynamic>>(
  //     future: _scheduleFuture,
  //     builder: (context, snapshot) {
  //       if (snapshot.connectionState == ConnectionState.waiting) {
  //         return const Center(child: CircularProgressIndicator());
  //       } else if (snapshot.hasError) {
  //         return const Center(child: Text('ขณะนี้ยังไม่มีการแจ้งเตือนค่ะ'));
  //       } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
  //         return const Center(child: Text('ไม่มีคิวงาน'));
  //       }

  //       final scheduleList = snapshot.data!.where((item) {
  //         final status = item['progress_status'];
  //         if (includeHistory) {
  //           return status == 4;
  //         } else {
  //           return status != 4 && status != 5; // ✅ ยกเว้น 5 ออกไป
  //         }
  //       }).toList();

  //       return ListView.builder(
  //         padding: const EdgeInsets.all(8.0),
  //         itemCount: scheduleList.length,
  //         itemBuilder: (context, index) {
  //           final item = scheduleList[index];
  //           return GestureDetector(
  //             onTap: () {
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(
  //                   builder: (context) => DetailWorkPage(rsid: item['rsid']),
  //                 ),
  //               );
  //             },
  //             child: Card(
  //               margin: const EdgeInsets.symmetric(vertical: 8.0),
  //               elevation: 2.0,
  //               shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.circular(8.0),
  //               ),
  //               child: Padding(
  //                 padding: const EdgeInsets.all(16.0),
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     Text(
  //                       'ชื่อการจอง: ${item['name_rs'] ?? '-'}',
  //                       style: const TextStyle(
  //                         fontSize: 18,
  //                         fontWeight: FontWeight.bold,
  //                         color: Color.fromARGB(255, 216, 103, 27),
  //                       ),
  //                     ),
  //                     const SizedBox(height: 8.0),
  //                     Text(
  //                       '${_formatDateRange(item['date_reserve'], item['date_start'], item['date_end'])}',
  //                       style: const TextStyle(fontSize: 16),
  //                     ),
  //                     Text(
  //                       'รถที่ใช้: ${item['name_vehicle'] ?? '-'}',
  //                       style: const TextStyle(fontSize: 16),
  //                     ),
  //                     Text(
  //                       'ฟาร์ม: ${item['name_farm'] ?? '-'}, ${item['farm_district'] ?? '-'}, ${item['farm_province'] ?? '-'}',
  //                       style: const TextStyle(fontSize: 16),
  //                     ),
  //                     Text(
  //                       'จำนวนการจ้างงาน: ${item['area_amount'] ?? '-'} ${item['unit_area'] ?? '-'}',
  //                       style: const TextStyle(fontSize: 16),
  //                     ),
  //                     if (item['employee_username'] != null)
  //                       Text(
  //                         'ผู้รับจ้าง: ${item['employee_username']} (${item['employee_phone'] ?? '-'})',
  //                         style: const TextStyle(fontSize: 16),
  //                       ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  // Widget _buildCancelVehicleQueue() {
  //   return FutureBuilder<List<dynamic>>(
  //     future: _scheduleFuture,
  //     builder: (context, snapshot) {
  //       if (snapshot.connectionState == ConnectionState.waiting) {
  //         return const Center(child: CircularProgressIndicator());
  //       } else if (snapshot.hasError) {
  //         return const Center(child: Text('ขณะนี้ยังไม่มีการแจ้งเตือนค่ะ'));
  //       } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
  //         return const Center(child: Text('ไม่มีคิวที่ถูกยกเลิก'));
  //       }

  //       final cancelList = snapshot.data!
  //           .where(
  //             (item) => item['progress_status'] == 5,
  //           )
  //           .toList();

  //       if (cancelList.isEmpty) {
  //         return const Center(child: Text('ไม่มีคิวที่ถูกยกเลิก'));
  //       }

  //       return ListView.builder(
  //         padding: const EdgeInsets.all(8.0),
  //         itemCount: cancelList.length,
  //         itemBuilder: (context, index) {
  //           final item = cancelList[index];
  //           return Card(
  //             margin: const EdgeInsets.symmetric(vertical: 8.0),
  //             elevation: 2.0,
  //             shape: RoundedRectangleBorder(
  //               borderRadius: BorderRadius.circular(8.0),
  //             ),
  //             child: Padding(
  //               padding: const EdgeInsets.all(16.0),
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Text(
  //                     'ชื่อการจอง: ${item['name_rs'] ?? '-'}',
  //                     style: const TextStyle(
  //                       fontSize: 18,
  //                       fontWeight: FontWeight.bold,
  //                       color: Color.fromARGB(255, 216, 103, 27),
  //                     ),
  //                   ),
  //                   const SizedBox(height: 8.0),
  //                   Text(
  //                     '${_formatDateRange(item['date_reserve'], item['date_start'], item['date_end'])}',
  //                     style: const TextStyle(fontSize: 16),
  //                   ),
  //                   Text(
  //                     'รถที่ใช้: ${item['name_vehicle'] ?? '-'}',
  //                     style: const TextStyle(fontSize: 16),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  Widget _buildVehicleQueueList({required bool includeHistory}) {
    return FutureBuilder<List<dynamic>>(
      future: _scheduleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('ขณะนี้ยังไม่มีการแจ้งเตือน'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('ไม่มีคิวงาน'));
        }

        final scheduleList = snapshot.data!.where((item) {
          final status = item['progress_status'];
          if (includeHistory) {
            return status == 4;
          } else {
            return status != 4 && status != 5;
          }
        }).toList();

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _scheduleFuture = fetchSchedule(widget.mid); // รีโหลดข้อมูล
            });
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: scheduleList.length,
            itemBuilder: (context, index) {
              final item = scheduleList[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailWorkPage(rsid: item['rsid']),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 12.0), // เพิ่ม margin ด้านซ้ายขวา
                  elevation: 2.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item['name_rs'] ?? '-'}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 216, 103, 27),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // ผู้จ้าง (ถ้ามี)
                        if (item['employee_username'] != null)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(
                                width: 50,
                                child: Text(
                                  'ผู้จ้าง:',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '${item['employee_username']} (${item['employee_phone'] ?? '-'})',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 6),
                        // รถ
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(
                              width: 50,
                              child: Text(
                                'รถ:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${item['name_vehicle'] ?? '-'}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // ที่นา
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(
                              width: 50,
                              child: Text(
                                'ที่นา:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${item['name_farm'] ?? '-'} (ต.${item['farm_subdistrict'] ?? '-'}, อ.${item['farm_district'] ?? '-'}, จ.${item['farm_province'] ?? '-'})',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // พื้นที่
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(
                              width: 50,
                              child: Text(
                                'พื้นที่:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${item['area_amount'] ?? '-'} ${item['unit_area'] ?? '-'}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),

                        const Divider(
                          color: Colors.grey,
                          thickness: 1,
                          height: 24,
                        ),
                        Row(
                          children: [
                            const SizedBox(
                              width: 65,
                              child: Text(
                                'วันที่จอง:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey, // กำหนดสีเทา
                                ),
                              ),
                            ),
                            Text(
                              formatDateReserveThai(item['date_reserve']),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey, // กำหนดสีเทา
                              ),
                            ),
                          ],
                        ),

                        Row(
                          children: [
                            const SizedBox(
                              width: 65,
                              child: Text(
                                'เริ่มงาน:',
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              formatDateReserveThai(item[
                                  'date_start']), // ใช้ฟังก์ชันที่รับ 1 ตัว
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const SizedBox(
                              width: 65,
                              child: Text(
                                'สิ้นสุด:',
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              formatDateReserveThai(
                                  item['date_end']), // ใช้ฟังก์ชันที่รับ 1 ตัว
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                        const Divider(
                          color: Colors.grey,
                          thickness: 1,
                          height: 24,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // ปุ่มยกเลิก
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('ยืนยันการยกเลิก'),
                                    content: const Text(
                                        'คุณต้องการยกเลิกคิวนี้หรือไม่?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('ไม่ใช่'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          Navigator.pop(context);
                                          await updateProgressStatus(
                                              item['rsid'], 0); // เปลี่ยนเป็น 0
                                        },
                                        child: const Text('ใช่'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: const Text('ยกเลิก'),
                            ),
                            const SizedBox(width: 8),
                            // ปุ่มยืนยัน
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('ยืนยันการจอง'),
                                    content: const Text(
                                        'คุณต้องการยืนยันคิวนี้หรือไม่?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('ไม่ใช่'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          Navigator.pop(context);
                                          await updateProgressStatus(
                                              item['rsid'], 1); // เปลี่ยนเป็น 1
                                        },
                                        child: const Text('ใช่'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: const Text('ยืนยัน'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCancelVehicleQueue() {
    return FutureBuilder<List<dynamic>>(
      future: _scheduleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('ขณะนี้ยังไม่มีการแจ้งเตือน'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('ไม่มีคิวที่ถูกยกเลิก'));
        }

        final cancelList = snapshot.data!
            .where((item) => item['progress_status'] == 5)
            .toList();

        if (cancelList.isEmpty) {
          return const Center(child: Text('ไม่มีคิวที่ถูกยกเลิก'));
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _scheduleFuture = fetchSchedule(widget.mid); // รีโหลดข้อมูล
            });
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: cancelList.length,
            itemBuilder: (context, index) {
              final item = cancelList[index];
              return InkWell(
                onTap: () {
                  // เมื่อผู้ใช้กดที่การ์ดนี้ ทำอะไรก็ใส่ที่นี่
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailWorkPage(rsid: item['rsid']),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 12.0), // เพิ่ม margin ด้านซ้ายขวา
                  elevation: 2.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item['name_rs'] ?? '-'}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 216, 103, 27),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // ผู้จ้าง (ถ้ามี)
                        if (item['employee_username'] != null)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(
                                width: 50,
                                child: Text(
                                  'ผู้จ้าง:',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '${item['employee_username']} (${item['employee_phone'] ?? '-'})',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 8.0),
                        // Text(
                        //   '${_formatDateRange(item['date_reserve'], item['date_start'], item['date_end'])}',
                        //   style: const TextStyle(fontSize: 16),
                        // ),

                        // รถ
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(
                              width: 50,
                              child: Text(
                                'รถ:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${item['name_vehicle'] ?? '-'}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // ที่นา
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(
                              width: 50,
                              child: Text(
                                'ที่นา:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${item['name_farm'] ?? '-'} (ต.${item['farm_subdistrict'] ?? '-'}, อ.${item['farm_district'] ?? '-'}, จ.${item['farm_province'] ?? '-'})',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // พื้นที่
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(
                              width: 50,
                              child: Text(
                                'พื้นที่:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${item['area_amount'] ?? '-'} ${item['unit_area'] ?? '-'}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),

                        const Divider(
                          color: Colors.grey,
                          thickness: 1,
                          height: 24,
                        ),
                        Row(
                          children: [
                            const SizedBox(
                              width: 65,
                              child: Text(
                                'วันที่จอง:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey, // กำหนดสีเทา
                                ),
                              ),
                            ),
                            Text(
                              formatDateReserveThai(item['date_reserve']),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey, // กำหนดสีเทา
                              ),
                            ),
                          ],
                        ),

                        Row(
                          children: [
                            const SizedBox(
                              width: 65,
                              child: Text(
                                'เริ่มงาน:',
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              formatDateReserveThai(item[
                                  'date_start']), // ใช้ฟังก์ชันที่รับ 1 ตัว
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const SizedBox(
                              width: 65,
                              child: Text(
                                'สิ้นสุด:',
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              formatDateReserveThai(
                                  item['date_end']), // ใช้ฟังก์ชันที่รับ 1 ตัว
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                        const Divider(
                          color: Colors.grey,
                          thickness: 1,
                          height: 24,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                              ),
                              onPressed: () {
                                // แสดง dialog ยืนยัน
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('ยืนยันการยกเลิก'),
                                    content: const Text(
                                        'คุณต้องการยกเลิกคิวนี้หรือไม่?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(
                                            context), // ยกเลิก dialog
                                        child: const Text('ไม่ใช่'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          Navigator.pop(
                                              context); // ปิด dialog ก่อน
                                          await updateProgressStatus(
                                              item['rsid'], 0);
                                        },
                                        child: const Text('ใช่'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: const Text('ยกเลิก'),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     //backgroundColor: const Color.fromARGB(255, 255, 158, 60),
  //     appBar: AppBar(
  //       //backgroundColor: const Color(0xFF006000),
  //       //backgroundColor: const Color.fromARGB(255, 255, 158, 60),
  //       backgroundColor: const Color.fromARGB(255, 18, 143, 9),
  //       centerTitle: true,
  //       automaticallyImplyLeading: false, // ✅ ลบปุ่มย้อนกลับ
  //       title: const Text(
  //         'การแจ้งเตือน',
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
  //     body: Column(
  //         children: [
  //           // ✅ แถบแท็บนูนด้วย Card
  //           Padding(
  //             padding: const EdgeInsets.all(16),
  //             child: Card(
  //               shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.circular(16),
  //               ),
  //               elevation: 6,
  //               child: Padding(
  //                 padding:
  //                     const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
  //                 child: TabBar(

  //                   indicator: BoxDecoration(
  //                     borderRadius: BorderRadius.circular(8),
  //                     gradient: LinearGradient(
  //                       colors: [
  //                         Color.fromARGB(255, 190, 255, 189)!,
  //                         Color.fromARGB(255, 37, 189, 35)!,
  //                         Colors.green[800]!,

  //                       ],
  //                       begin: Alignment.topLeft,
  //                       end: Alignment.bottomRight,
  //                     ),
  //                     boxShadow: [
  //                       BoxShadow(
  //                         color: Colors.black26,
  //                         blurRadius: 4,
  //                         offset: Offset(0, 2),
  //                       ),
  //                     ],
  //                   ),
  //                   labelColor: Colors.white,
  //                   unselectedLabelColor: Colors.black87,
  //                   indicatorSize: TabBarIndicatorSize.tab,
  //                   labelStyle: const TextStyle(
  //                     fontSize: 14,
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                   tabs: const [
  //                     Tab(
  //                       child: SizedBox(
  //                         width: 120,
  //                         child: Center(child: Text('ตารางงาน')),
  //                       ),
  //                     ),
  //                     Tab(
  //                       child: SizedBox(
  //                         width: 120,
  //                         child: Center(child: Text('ประวัติการรับงาน')),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //           ),

  //           Expanded(
  //             child: TabBarView(
  //               children: [
  //                 //การแจ้งเตือน
  //                 Center(
  //                   child: (),
  //                 ),

  //                 // แจ้งเตือนยกเลิกการจองคิวรถ
  //                 Center(
  //                   child: (includeHistory: true),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),

  //     body: FutureBuilder<List<dynamic>>(
  //       future: _scheduleFuture,
  //       builder: (context, snapshot) {
  //         if (snapshot.connectionState == ConnectionState.waiting) {
  //           return const Center(child: CircularProgressIndicator());
  //         } else if (snapshot.hasError) {
  //           //return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
  //           return Center(child: Text('ขณะนี้ยังไม่มีการแจ้งเตือนค่ะ'));
  //         } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
  //           return const Center(child: Text('ไม่มีคิวงาน'));
  //         }

  //         final scheduleList = snapshot.data!
  //             .where((item) => item['progress_status'] != 4)
  //             .toList();

  //         return ListView.builder(
  //           padding: const EdgeInsets.all(8.0),
  //           itemCount: scheduleList.length,
  //           itemBuilder: (context, index) {
  //             final item = scheduleList[index];
  //             return GestureDetector(
  //               // 👈 เปลี่ยนตรงนี้
  //               onTap: () {
  //                 Navigator.push(
  //                   context,
  //                   MaterialPageRoute(
  //                     builder: (context) => DetailWorkPage(rsid: item['rsid']),
  //                   ),
  //                 );
  //               },
  //               child: Card(
  //                 margin: const EdgeInsets.symmetric(vertical: 8.0),
  //                 elevation: 2.0,
  //                 shape: RoundedRectangleBorder(
  //                   borderRadius: BorderRadius.circular(8.0),
  //                 ),
  //                 child: Padding(
  //                   padding: const EdgeInsets.all(16.0),
  //                   child: Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       Text(
  //                         'ชื่อการจอง: ${item['name_rs'] ?? '-'}',
  //                         style: const TextStyle(
  //                             fontSize: 18,
  //                             fontWeight: FontWeight.bold,
  //                             color: Color.fromARGB(255, 216, 103, 27)),
  //                       ),
  //                       const SizedBox(height: 8.0),
  //                       Text(
  //                         '${_formatDateRange(item['date_reserve'], item['date_start'], item['date_end'])}',
  //                         style: const TextStyle(fontSize: 16),
  //                       ),
  //                       Text(
  //                         'รถที่ใช้: ${item['name_vehicle'] ?? '-'}',
  //                         style: const TextStyle(fontSize: 16),
  //                       ),
  //                       Text(
  //                         'ฟาร์ม: ${item['name_farm'] ?? '-'}, ${item['farm_district'] ?? '-'}, ${item['farm_province'] ?? '-'}',
  //                         style: const TextStyle(fontSize: 16),
  //                       ),
  //                       Text(
  //                         'จำนวนการจ้างงาน: ${item['area_amount'] ?? '-'} ${item['unit_area'] ?? '-'}',
  //                         style: const TextStyle(fontSize: 16),
  //                       ),
  //                       if (item['employee_username'] != null)
  //                         Text(
  //                           'ผู้รับจ้าง: ${item['employee_username']} (${item['employee_phone'] ?? '-'})',
  //                           style: const TextStyle(fontSize: 16),
  //                         ),
  //                       // ลบปุ่มออก
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //             );
  //           },
  //         );
  //       },
  //     ),
  //   );
  // }
}
