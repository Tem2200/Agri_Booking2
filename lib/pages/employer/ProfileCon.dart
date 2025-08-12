import 'dart:convert';
import 'package:agri_booking2/pages/employer/DetailVehc_emp.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// !!! นำเข้าหน้าจอที่เกี่ยวข้อง (เช่น AddVehicle, Detailvehicle)
// import 'package:your_app/pages/AddVehicle.dart';
// import 'package:your_app/pages/Detailvehicle.dart';

class ProfileCon extends StatefulWidget {
  final int mid_con;
  final int mid_emp;
  final dynamic farm;

  const ProfileCon({
    super.key,
    required this.mid_con,
    required this.mid_emp,
    required this.farm,
  });

  @override
  State<ProfileCon> createState() => _ProfileConState();
}

class _ProfileConState extends State<ProfileCon> {
  Future<Map<String, dynamic>>? _memberDataFuture;
  Future<List<dynamic>>? _vehicleListFuture;
  Future<List<dynamic>>? _reviewFuture;

  late int _currentMid;
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    print("farm: ${widget.farm}");
    _currentMid = widget.mid_con;

    _memberDataFuture = fetchCon(widget.mid_con);
    _vehicleListFuture = fetchVehicles(widget.mid_con);
    _reviewFuture = fetchReviews(widget.mid_con);
  }

  Future<Map<String, dynamic>> fetchCon(int mid) async {
    final url = Uri.parse(
        'http://projectnodejs.thammadalok.com/AGribooking/members/$mid');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("ข้อมูลสมาชิก: $data");
      return data;
    } else {
      throw Exception('ไม่พบข้อมูลสมาชิก');
    }
  }

  Future<List<dynamic>> fetchVehicles(int mid) async {
    final url = Uri.parse(
        'http://projectnodejs.thammadalok.com/AGribooking/get_vehicle/$mid');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty) {
        return jsonDecode(response.body);
      }
      return [];
    } else {
      print("Error fetching vehicles: ${response.statusCode}");
      return [];
    }
  }

  Future<List<dynamic>> fetchReviews(int mid) async {
    final url = Uri.parse(
        'http://projectnodejs.thammadalok.com/AGribooking/get_reviewed/$mid');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty) {
        return jsonDecode(response.body);
      }
      return [];
    } else {
      throw Exception('ไม่สามารถโหลดข้อมูลรีวิว');
    }
  }

  Future<void> _reportReview(int rid) async {
    final midReporter = widget.mid_emp;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("ยืนยันการรายงาน"),
          content: const Text("คุณต้องการรายงานรีวิวนี้หรือไม่?"),
          actions: [
            TextButton(
              child: const Text("ยกเลิก"),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              child: const Text("รายงาน"),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() {
        isLoading = true;
      });

      final url = Uri.parse(
          'http://projectnodejs.thammadalok.com/AGribooking/reporter');
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "rid": rid,
          "mid_reporter": midReporter,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("รายงานรีวิวสำเร็จ")),
        );
        setState(() {
          _reviewFuture = fetchReviews(_currentMid);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("เกิดข้อผิดพลาด: ${response.body}")),
        );
      }

      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String farmInfo = "-";
    if (widget.farm is Map) {
      farmInfo =
          widget.farm.entries.map((e) => "${e.key}: ${e.value}").join("\n");
    } else {
      farmInfo = widget.farm?.toString() ?? "-";
    }

    // return DefaultTabController(
    //   length: 2,
    //   child: Scaffold(
    //     appBar: AppBar(
    //       backgroundColor: const Color.fromARGB(255, 255, 158, 60),
    //       centerTitle: true,
    //       //automaticallyImplyLeading: false,
    //       title: const Text(
    //         'จองคิวรถ',
    //         style: TextStyle(
    //           fontSize: 22,
    //           fontWeight: FontWeight.bold,
    //           color: Colors.white,
    //           shadows: [
    //             Shadow(
    //               color: Color.fromARGB(115, 253, 237, 237),
    //               blurRadius: 3,
    //               offset: Offset(1.5, 1.5),
    //             ),
    //           ],
    //         ),
    //       ),
    //       leading: IconButton(
    //         color: Colors.white,
    //         icon: const Icon(Icons.arrow_back),
    //         onPressed: () {
    //           Navigator.pop(context); // ✅ กลับหน้าก่อนหน้า
    //         },
    //       ),
    //     ),
    //     body: Column(
    //       children: [
    //         // เปลี่ยน Expanded เป็น Flexible หรือ SizedBox กำหนดความสูงพอดี
    //         Flexible(
    //           child: FutureBuilder<Map<String, dynamic>>(
    //             future: _memberDataFuture,
    //             builder: (context, snapshot) {
    //               if (snapshot.connectionState == ConnectionState.waiting) {
    //                 return const Padding(
    //                   padding: EdgeInsets.all(12),
    //                   child: CircularProgressIndicator(),
    //                 );
    //               } else if (snapshot.hasError) {
    //                 return Padding(
    //                   padding: const EdgeInsets.all(12),
    //                   child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
    //                 );
    //               } else if (!snapshot.hasData || snapshot.data == null) {
    //                 return const Padding(
    //                   padding: EdgeInsets.all(12),
    //                   child: Text('ไม่พบข้อมูลสมาชิก'),
    //                 );
    //               }

    //               final member = snapshot.data!;

    //               return Padding(
    //                 padding:
    //                     const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    //                 child: Material(
    //                   borderRadius: BorderRadius.circular(12),
    //                   elevation: 4,
    //                   child: ClipRRect(
    //                     borderRadius: BorderRadius.circular(12),
    //                     child: ExpansionTile(
    //                       backgroundColor: Colors.white,
    //                       collapsedBackgroundColor: Colors.white,
    //                       tilePadding: const EdgeInsets.symmetric(
    //                           horizontal: 16, vertical: 12),
    //                       childrenPadding:
    //                           const EdgeInsets.fromLTRB(24, 8, 24, 16),
    //                       title: Row(
    //                         mainAxisAlignment: MainAxisAlignment.center,
    //                         children: [
    //                           ClipOval(
    //                             child: Image.network(
    //                               member['image'] ?? '',
    //                               width: 60,
    //                               height: 60,
    //                               fit: BoxFit.cover,
    //                               errorBuilder: (context, error, stackTrace) =>
    //                                   const Icon(Icons.person, size: 48),
    //                             ),
    //                           ),
    //                           const SizedBox(width: 12),
    //                           Flexible(
    //                             child: Text(
    //                               member['username'] ?? '-',
    //                               style: const TextStyle(
    //                                 fontSize: 18,
    //                                 fontWeight: FontWeight.bold,
    //                               ),
    //                               overflow: TextOverflow.ellipsis,
    //                             ),
    //                           ),
    //                         ],
    //                       ),
    //                       children: [
    //                         Column(
    //                           crossAxisAlignment: CrossAxisAlignment.start,
    //                           children: [
    //                             Row(
    //                               children: [
    //                                 const Icon(Icons.phone,
    //                                     size: 20, color: Colors.green),
    //                                 const SizedBox(width: 6),
    //                                 Text(member['phone'] ?? '-'),
    //                               ],
    //                             ),
    //                             const SizedBox(height: 6),
    //                             Row(
    //                               crossAxisAlignment: CrossAxisAlignment.start,
    //                               children: [
    //                                 const Icon(Icons.email,
    //                                     size: 20, color: Colors.redAccent),
    //                                 const SizedBox(width: 6),
    //                                 Expanded(
    //                                   child: Text(member['email'] ?? '-',
    //                                       softWrap: true),
    //                                 ),
    //                               ],
    //                             ),
    //                             const SizedBox(height: 6),
    //                             Row(
    //                               crossAxisAlignment: CrossAxisAlignment.start,
    //                               children: [
    //                                 const Icon(Icons.location_on,
    //                                     size: 20, color: Colors.orange),
    //                                 const SizedBox(width: 6),
    //                                 Expanded(
    //                                   child: Text(
    //                                     'ที่อยู่: ${member['detail_address'] ?? '-'} ต.${member['subdistrict'] ?? '-'} อ.${member['district'] ?? '-'} จ.${member['province'] ?? '-'}',
    //                                   ),
    //                                 ),
    //                               ],
    //                             ),
    //                           ],
    //                         ),
    //                       ],
    //                     ),
    //                   ),
    //                 ),
    //               );
    //             },
    //           ),
    //         ),

    //         Expanded(
    //           child: Column(
    //             children: [
    //               // ✅ แถบแท็บนูนด้วย Card
    //               Padding(
    //                 padding: const EdgeInsets.all(8),
    //                 child: Card(
    //                   shape: RoundedRectangleBorder(
    //                     borderRadius: BorderRadius.circular(16),
    //                   ),
    //                   elevation: 6,
    //                   child: Padding(
    //                     padding: const EdgeInsets.symmetric(
    //                         vertical: 12, horizontal: 8),
    //                     child: TabBar(
    //                       indicator: BoxDecoration(
    //                         borderRadius: BorderRadius.circular(8),
    //                         gradient: LinearGradient(
    //                           colors: [
    //                             Color.fromARGB(255, 190, 255, 189)!,
    //                             Color.fromARGB(255, 37, 189, 35)!,
    //                             Colors.green[800]!,

    //                             // Color.fromARGB(255, 255, 244, 189)!,
    //                             // Color.fromARGB(255, 254, 187, 42)!,
    //                             // Color.fromARGB(255, 218, 140, 22)!,
    //                           ],
    //                           begin: Alignment.topLeft,
    //                           end: Alignment.bottomRight,
    //                         ),
    //                         boxShadow: [
    //                           BoxShadow(
    //                             color: Colors.black26,
    //                             blurRadius: 4,
    //                             offset: Offset(0, 2),
    //                           ),
    //                         ],
    //                       ),
    //                       labelColor: Colors.white,
    //                       unselectedLabelColor: Colors.black87,
    //                       indicatorSize: TabBarIndicatorSize.tab,
    //                       labelStyle: const TextStyle(
    //                         fontSize: 14,
    //                         fontWeight: FontWeight.bold,
    //                       ),
    //                       tabs: const [
    //                         Tab(
    //                           child: SizedBox(
    //                             width: 110,
    //                             child: Center(child: Text('รายการรถ')),
    //                           ),
    //                         ),
    //                         Tab(
    //                           child: SizedBox(
    //                             width: 110,
    //                             child: Center(child: Text('รีวิว')),
    //                           ),
    //                         ),
    //                       ],
    //                     ),
    //                   ),
    //                 ),
    //               ),

    //               // ✅ เนื้อหาภายในแต่ละแท็บ
    //               Expanded(
    //                 child: TabBarView(
    //                   children: [
    //                     _buildVehicleTab(),
    //                     _buildReviewTab(),
    //                   ],
    //                 ),
    //               ),
    //             ],
    //           ),
    //         ),
    //       ],
    //     ),
    //   ),
    // );

    return DefaultTabController(
      length: 2, // 2 แท็บ: รายการรถ และ รีวิว
      child: Scaffold(
        //backgroundColor: const Color.fromARGB(255, 255, 158, 60),
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 18, 143, 9),
          centerTitle: true,
          //automaticallyImplyLeading: false,
          title: const Text(
            'โปรไฟล์ผู้รับจ้าง',
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
        body: Column(
          children: [
            // 🔹 FutureBuilder: แสดงข้อมูลผู้รับจ้าง
            FutureBuilder<Map<String, dynamic>>(
              future: _memberDataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  );
                } else if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
                  );
                } else if (!snapshot.hasData || snapshot.data == null) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('ไม่พบข้อมูลสมาชิก'),
                  );
                }

                final member = snapshot.data!;
                return Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 255,
                        255), // สีพื้นอ่อนๆ เพื่อให้เห็นความนูนชัดเจน
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      // เงาสว่างด้านบนซ้าย
                      BoxShadow(
                        color: Color.fromARGB(209, 67, 66, 66),
                        offset: Offset(-4, -4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                      // เงามืดด้านล่างขวา
                      BoxShadow(
                        color: Color.fromARGB(209, 67, 66, 66),
                        offset: Offset(4, 4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.all(12),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipOval(
                            child: Image.network(
                              member['image'] ?? '',
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.person, size: 48),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            member['username'] ?? '-',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.phone,
                                      size: 20, color: Colors.green),
                                  const SizedBox(width: 6),
                                  Text(member['phone'] ?? '-'),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.email,
                                      size: 20, color: Colors.redAccent),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(member['email'] ?? '-',
                                        softWrap: true),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.description,
                                      size: 20, color: Colors.redAccent),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      (member['other'] != null &&
                                              member['other']
                                                  .toString()
                                                  .trim()
                                                  .isNotEmpty)
                                          ? member['other']
                                          : '-',
                                      softWrap: true,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.location_on,
                                      size: 20, color: Colors.orange),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'ที่อยู่: ${member['detail_address'] ?? '-'} ต.${member['subdistrict'] ?? '-'} อ.${member['district'] ?? '-'} จ.${member['province'] ?? '-'}',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            Expanded(
              child: Column(
                children: [
                  // ✅ แถบแท็บนูนด้วย Card
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 6,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 8),
                        child: TabBar(
                          indicator: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                              colors: [
                                Color.fromARGB(255, 190, 255, 189)!,
                                Color.fromARGB(255, 37, 189, 35)!,
                                Colors.green[800]!,

                                // Color.fromARGB(255, 255, 244, 189)!,
                                // Color.fromARGB(255, 254, 187, 42)!,
                                // Color.fromARGB(255, 218, 140, 22)!,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
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
                          tabs: const [
                            Tab(
                              child: SizedBox(
                                width: 110,
                                child: Center(child: Text('รายการรถ')),
                              ),
                            ),
                            Tab(
                              child: SizedBox(
                                width: 110,
                                child: Center(child: Text('รีวิว')),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ✅ เนื้อหาภายในแต่ละแท็บ
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildVehicleTab(),
                        _buildReviewTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),

// Expanded(
            //   child: Column(
            //     children: [
            //       // ✅ แถบแท็บนูนด้วย Card
            //       Padding(
            //         padding: const EdgeInsets.all(16),
            //         child: Card(
            //           shape: RoundedRectangleBorder(
            //             borderRadius: BorderRadius.circular(16),
            //           ),
            //           elevation: 6,
            //           child: Padding(
            //             padding: const EdgeInsets.symmetric(
            //                 vertical: 12, horizontal: 8),
            //             child: TabBar(
            //               indicator: BoxDecoration(
            //                 borderRadius: BorderRadius.circular(8),
            //                 color: Colors.green[900],
            //                 boxShadow: [
            //                   BoxShadow(
            //                     color: Colors.black26,
            //                     blurRadius: 4,
            //                     offset: Offset(0, 2),
            //                   ),
            //                 ],
            //               ),
            //               labelColor: Colors.white,
            //               unselectedLabelColor: Colors.black87,
            //               indicatorSize: TabBarIndicatorSize.tab,
            //               labelStyle: const TextStyle(
            //                 fontSize: 14,
            //                 fontWeight: FontWeight.bold,
            //               ),
            //               tabs: const [
            //                 Tab(
            //                   child: SizedBox(
            //                     width: 120,
            //                     child: Center(child: Text('รายการรถ')),
            //                   ),
            //                 ),
            //                 Tab(
            //                   child: SizedBox(
            //                     width: 120,
            //                     child: Center(child: Text('รีวิว')),
            //                   ),
            //                 ),
            //               ],
            //             ),
            //           ),
            //         ),
            //       ),

            //       // ✅ เนื้อหาภายในแต่ละแท็บ
            //       Expanded(
            //         child: TabBarView(
            //           children: [
            //             Center(child: _buildVehicleTab()),
            //             Center(child: _buildReviewTab()),
            //           ],
            //         ),
            //       ),
            //     ],
            //   ),
            // ),

            //แถบเมนูแบบมีปุ่ม
            // Expanded(
            //   child: Column(
            //     children: [
            //       // ✅ แถบแท็บนูนด้วย Card
            //       Padding(
            //         padding: const EdgeInsets.all(16),
            //         child: Card(
            //           shape: RoundedRectangleBorder(
            //             borderRadius: BorderRadius.circular(16),
            //           ),
            //           elevation: 6,
            //           child: Padding(
            //             padding: const EdgeInsets.symmetric(
            //                 vertical: 12, horizontal: 8),
            //             child: TabBar(
            //               indicator: BoxDecoration(
            //                 borderRadius: BorderRadius.circular(8),
            //                 color: Colors.green[900],
            //                 boxShadow: [
            //                   BoxShadow(
            //                     color: Colors.black26,
            //                     blurRadius: 4,
            //                     offset: Offset(0, 2),
            //                   ),
            //                 ],
            //               ),
            //               labelColor: Colors.white,
            //               unselectedLabelColor: Colors.black87,
            //               indicatorSize: TabBarIndicatorSize.tab,
            //               labelStyle: const TextStyle(
            //                 fontSize: 14,
            //                 fontWeight: FontWeight.bold,
            //               ),
            //               tabs: const [
            //                 Tab(
            //                   child: SizedBox(
            //                     width: 120,
            //                     child: Center(child: Text('รายการรถ')),
            //                   ),
            //                 ),
            //                 Tab(
            //                   child: SizedBox(
            //                     width: 120,
            //                     child: Center(child: Text('รีวิว')),
            //                   ),
            //                 ),
            //               ],
            //             ),
            //           ),
            //         ),
            //       ),

            //       // ✅ เนื้อหาภายในแต่ละแท็บ
            //       Expanded(
            //         child: TabBarView(
            //           children: [
            //             Center(child: _buildVehicleTab()),
            //             Center(child: _buildReviewTab()),
            //           ],
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleTab() {
    return FutureBuilder<List<dynamic>>(
      future: _vehicleListFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text("เกิดข้อผิดพลาดในการโหลดข้อมูลรถ"));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("ไม่พบข้อมูลรถ"));
        }

        // ✅ กรองเฉพาะรถที่ status_vehicle = 1
        final vehicles =
            snapshot.data!.where((v) => v['status_vehicle'] == 1).toList();

        if (vehicles.isEmpty) {
          return const Center(
            child: Text("ไม่มีรถที่เปิดให้บริการ"),
          );
        }

        return ListView.builder(
          itemCount: vehicles.length,
          itemBuilder: (context, index) {
            final vehicle = vehicles[index];
            // return Card(
            //   margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            //   elevation: 3,
            //   child: Padding(
            //     padding: const EdgeInsets.all(12),
            //     child: Row(
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [
            //         // ✅ รูปภาพทางซ้าย
            //         vehicle['image'] != null &&
            //                 vehicle['image'].toString().isNotEmpty
            //             ? ClipRRect(
            //                 borderRadius: BorderRadius.circular(8),
            //                 child: Image.network(
            //                   vehicle['image'],
            //                   width: 100,
            //                   height: 80,
            //                   fit: BoxFit.cover,
            //                   errorBuilder: (context, error, stackTrace) =>
            //                       Container(
            //                     width: 100,
            //                     height: 80,
            //                     color: Colors.grey[300],
            //                     child: const Icon(Icons.broken_image),
            //                   ),
            //                 ),
            //               )
            //             : Container(
            //                 width: 100,
            //                 height: 80,
            //                 color: Colors.grey[200],
            //                 child: const Icon(Icons.directions_car, size: 40),
            //               ),

            //         const SizedBox(width: 12),

            //         // ✅ ข้อมูลรถทางขวา
            //         Expanded(
            //           child: Column(
            //             crossAxisAlignment: CrossAxisAlignment.start,
            //             children: [
            //               Text(
            //                 vehicle['name_vehicle'] ?? '-',
            //                 style: const TextStyle(
            //                   fontSize: 16,
            //                   fontWeight: FontWeight.bold,
            //                 ),
            //               ),
            //               const SizedBox(height: 4),
            //               Text(
            //                 vehicle['detail'] ?? '-',
            //                 maxLines: 2,
            //                 overflow: TextOverflow.ellipsis,
            //                 style: const TextStyle(fontSize: 14),
            //               ),
            //               const SizedBox(height: 8),
            //               Align(
            //                 alignment: Alignment.centerRight,
            //                 child: ElevatedButton(
            //                   onPressed: () {
            //                     Navigator.push(
            //                       context,
            //                       MaterialPageRoute(
            //                         builder: (context) => DetailvehcEmp(
            //                           vid: vehicle['vid'] ?? 0,
            //                           mid: widget.mid_emp,
            //                           fid: widget.farm['fid'] ?? 0,
            //                           farm: widget.farm,
            //                         ),
            //                       ),
            //                     );
            //                   },
            //                   child: const Text('รายละเอียดเพิ่มเติม'),
            //                   style: ElevatedButton.styleFrom(
            //                     backgroundColor: Colors.orange,
            //                     foregroundColor: Colors.white,
            //                     padding: const EdgeInsets.symmetric(
            //                         horizontal: 12, vertical: 8),
            //                     textStyle: const TextStyle(fontSize: 14),
            //                     shape: RoundedRectangleBorder(
            //                       borderRadius: BorderRadius.circular(8),
            //                     ),
            //                   ),
            //                 ),
            //               ),
            //             ],
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // );
            return Padding(
              // padding: const EdgeInsets.only(bottom: 25),
              padding:
                  const EdgeInsets.fromLTRB(11, 0, 11, 25), // ซ้าย-ขวา-ล่าง
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.orange.withOpacity(0.3), // เงาส้มอ่อนโปร่งใส
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 4), // เงาลงด้านล่างเล็กน้อย
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ รูปภาพทางซ้าย
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: vehicle['image'] != null &&
                              vehicle['image'].toString().isNotEmpty
                          ? Image.network(
                              vehicle['image'],
                              height: 150,
                              width: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                height: 150,
                                width: 120,
                                color: Colors.grey[300],
                                alignment: Alignment.center,
                                child: const Icon(Icons.broken_image, size: 48),
                              ),
                            )
                          : Container(
                              height: 150,
                              width: 120,
                              color: Colors.grey[200],
                              alignment: Alignment.center,
                              child: const Icon(Icons.image_not_supported,
                                  size: 48),
                            ),
                    ),

                    const SizedBox(width: 12),

                    // ✅ ข้อมูลทางขวา
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min, // ขนาดพอดีกับเนื้อหา
                        children: [
                          Text(
                            vehicle['name_vehicle'] ?? 'ไม่มีชื่อรถ',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // 🔹 รายละเอียดพร้อมไอคอน
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.description,
                                  size: 18, color: Colors.orange),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${vehicle['detail']}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          // 🔹 ราคา พร้อมไอคอน
                          Row(
                            children: [
                              const Icon(Icons.attach_money,
                                  size: 18, color: Colors.green),
                              const SizedBox(width: 6),
                              Text(
                                '${vehicle['price']} บาท / ${vehicle['unit_price']}',
                                style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // ✅ ปุ่ม + สวิตช์ + สถานะด้านล่าง
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // 🔹 ปุ่มรายละเอียดเพิ่มเติมแบบนูน
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.white,
                                      offset: Offset(-2, -2),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                    BoxShadow(
                                      color: Colors.black26,
                                      offset: Offset(2, 2),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    elevation:
                                        0, // ปิดเงา ElevatedButton เพื่อใช้เงาจาก Container แทน
                                    backgroundColor: const Color(0xFFF8A100),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 5),

                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () {
                                    // แสดง SnackBar แจ้งเตือนถ้าไร่ยังไม่มีข้อมูล
                                    // if (widget.farm == null ||
                                    //     widget.farm['fid'] == null) {
                                    //   ScaffoldMessenger.of(context)
                                    //       .showSnackBar(
                                    //     const SnackBar(
                                    //       content: Text(
                                    //           'ขณะนี้คุณไม่มีไร่นาที่เพิ่มไว้ กรุณาเพิ่มไร่นาก่อนจองคิวรถ หรือเพิ่มระหว่างจองคิวรถ'),
                                    //       backgroundColor:
                                    //           Color.fromARGB(255, 255, 110, 84),
                                    //       duration: Duration(seconds: 10),
                                    //     ),
                                    //   );
                                    // }
                                    // เข้าไปหน้ารายละเอียดได้ปกติเลย
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DetailvehcEmp(
                                          vid: vehicle['vid'] ?? 0,
                                          mid: widget.mid_emp,
                                          fid: widget.farm?['fid'] ?? 0,
                                          farm: widget.farm,
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text('รายละเอียดเพิ่มเติม'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReviewTab() {
    return FutureBuilder<List<dynamic>>(
      future: _reviewFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("เกิดข้อผิดพลาด: ${snapshot.error}"));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("ยังไม่มีรีวิว"));
        }

        final reviews = snapshot.data!;

        return ListView.builder(
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final review = reviews[index];

            final reportedList =
                jsonDecode(review['reporters'] ?? '[]') as List<dynamic>;
            final isReported = reportedList.contains(_currentMid);

            // return ListTile(
            //   title: Text(review['text'] ?? "-"),
            //   subtitle: Text(
            //       "คะแนน: ${review['point'] ?? '-'} / 5\nวันที่รีวิว: ${review['date']?.toString().substring(0, 10) ?? '-'}"),
            //   trailing: ElevatedButton(
            //     onPressed:
            //         isReported ? null : () => _reportReview(review['rid']),
            //     child: Text(isReported ? "รายงานแล้ว" : "รายงาน"),
            //   ),
            // );
            return Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8), // เว้นขอบซ้ายขวา
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // รูปภาพรีวิว (ถ้ามี)
                      if (review['image_url'] != null &&
                          review['image_url'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Image.network(
                            review['image_url'],
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Text('โหลดรูปไม่สำเร็จ'),
                          ),
                        ),

                      // ผู้รีวิว + ดาว
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person,
                              color: Colors.grey, size: 20),
                          const SizedBox(width: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(5, (i) {
                              return Icon(
                                i < (review['point'] ?? 0)
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 20,
                              );
                            }),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${review['point'] ?? '-'} / 5',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),

                      // ข้อความรีวิว
                      Text(
                        review['text'] ?? '-',
                        style: const TextStyle(fontSize: 16),
                      ),

                      const SizedBox(height: 6),

                      if (review['image'] != null && review['image'].isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Image.network(
                            review['image'],
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.image_not_supported),
                          ),
                        ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'วันที่รีวิว: ${review['date'].toString().substring(0, 10)}',
                            style:
                                const TextStyle(color: Colors.grey), // ใส่สีเทา
                          ),
                        ],
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: isReported
                              ? null
                              : () => _reportReview(review['rid']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isReported ? Colors.grey : Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            isReported ? 'รายงานแล้ว' : 'รายงานรีวิว',
                            style: const TextStyle(
                                fontSize:
                                    14), // กำหนดขนาดถ้าต้องการ แต่ไม่กำหนด fontFamily
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
