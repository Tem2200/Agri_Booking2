import 'dart:convert';
import 'package:agri_booking2/pages/employer/addFarm.dart';
import 'package:agri_booking2/pages/employer/homeEmp.dart';
import 'package:agri_booking2/pages/employer/updateFarm.dart';
import 'package:agri_booking2/pages/employer/Tabbar.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

class FarmsPage extends StatefulWidget {
  final int mid;
  const FarmsPage({super.key, required this.mid});

  @override
  State<FarmsPage> createState() => _FarmsPageState();
}

class _FarmsPageState extends State<FarmsPage> {
  Future<List<dynamic>>? farmsFuture;

  @override
  void initState() {
    super.initState();
    farmsFuture = fetchFarms(widget.mid);
  }

  Future<List<dynamic>> fetchFarms(int mid) async {
    final url = Uri.parse(
      'http://projectnodejs.thammadalok.com/AGribooking/get_farms/$mid',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("ข้อมูลไร่นา: $data");
      return data;
    } else {
      // Fluttertoast.showToast(
      //   msg: 'ไม่พบข้อมูลไร่นา',
      //   toastLength: Toast.LENGTH_SHORT,
      //   gravity: ToastGravity.CENTER, // แสดงตรงกลางจอ
      //   //gravity: ToastGravity.TOP,
      //   timeInSecForIosWeb: 2,
      //   backgroundColor: Colors.red,
      //   textColor: Colors.white,
      //   fontSize: 16.0,
      // );
      return []; // หรือ [] แล้วแต่ฟังก์ชันคุณรองรับอะไร
    }
  }

  Future<void> deleteFarm(int fid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'ยืนยันการลบ',
          textAlign: TextAlign.center,
        ),
        content: const Text('คุณต้องการลบไร่นานี้หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final url = Uri.parse(
        'http://projectnodejs.thammadalok.com/AGribooking/delete_farm/$fid');

    try {
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบไร่นาสำเร็จ')),
        );
        setState(() {
          farmsFuture = fetchFarms(widget.mid);
        });
      } else {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('เกิดข้อผิดพลาด: ${response.body}')),
        // );
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('ไม่สามารถลบไร่นาได้'),
              content: const Text(
                  'เนื่องจากมีการจองที่ยังไม่เสร็จสิ้นหรือกำลังดำเนินงานอยู่'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // ปิดป๊อปอัพ
                  },
                  child: const Text('ปิด'),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 18, 143, 9),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            int currentMonth = DateTime.now().month;
            int currentYear = DateTime.now().year;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => Tabbar(
                  mid: widget.mid,
                  value: 2,
                  month: currentMonth,
                  year: currentYear,
                ),
              ),
            );
          },
        ),

        //iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'ไร่นาของฉัน',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 255, 255, 255),
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
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: farmsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                      child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('ไม่มีข้อมูลไร่นา'));
                }

                final farms = snapshot.data!;

                return ListView.builder(
                  itemCount: farms.length,
                  itemBuilder: (context, index) {
                    final farm = farms[index];
                    // return Card(
                    //   child: ListTile(
                    //     title: Text(farm['name_farm']),
                    //     subtitle: Text(
                    //         '${farm['subdistrict']}, ${farm['district']}, ${farm['province']}'),
                    //     trailing: Row(
                    //       mainAxisSize: MainAxisSize.min,
                    //       children: [
                    //         IconButton(
                    //           icon: const Icon(Icons.edit, color: Colors.blue),
                    //           onPressed: () async {
                    //             final result = await Navigator.push(
                    //               context,
                    //               MaterialPageRoute(
                    //                 builder: (_) => UpdateFarmPage(
                    //                   fid: farm['fid'],
                    //                   farmData: farm,
                    //                 ),
                    //               ),
                    //             );

                    //             if (result == true) {
                    //               setState(() {
                    //                 farmsFuture = fetchFarms(widget.mid);
                    //               });
                    //             }
                    //           },
                    //         ),
                    //         IconButton(
                    //           icon: const Icon(Icons.delete, color: Colors.red),
                    //           onPressed: () => deleteFarm(farm['fid']),
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    // );

                    //ui new
                    return Card(
                      elevation: 8, // เงาชัดเจน
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16), // มุมโค้งมนสวย
                      ),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10), // เว้นขอบการ์ด
                      shadowColor: Colors.black54, // เงาสีเข้มขึ้นเล็กน้อย
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12), // ระยะห่างในการ์ด
                        child: ListTile(
                          title: Text(
                            farm['name_farm'],
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
                          subtitle: Text(
                            '${farm['subdistrict']}, ${farm['district']}, ${farm['province']}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                color:
                                    Colors.blue.shade700, // สีน้ำเงินเข้มสบายตา
                                tooltip: 'แก้ไขข้อมูลไร่นา',
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => UpdateFarmPage(
                                        fid: farm['fid'],
                                        farmData: farm,
                                      ),
                                    ),
                                  );
                                  if (result == true) {
                                    setState(() {
                                      farmsFuture = fetchFarms(widget.mid);
                                    });
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                color: Colors.red.shade700, // สีแดงเข้ม
                                tooltip: 'ลบไร่นา',
                                onPressed: () => deleteFarm(farm['fid']),
                              ),
                            ],
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 0), // จัดระยะห่างภายใน ListTile
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          //เพิ่มไรนามีปุ่มปกติ
          // Padding(
          //   padding: const EdgeInsets.all(12),
          //   child: ElevatedButton.icon(
          //     icon: const Icon(Icons.add),
          //     label: const Text('เพิ่มไร่นาใหม่'),
          //     onPressed: () async {
          //       final result = await Navigator.push(
          //         context,
          //         MaterialPageRoute(
          //           builder: (_) => AddFarmPage(mid: widget.mid),
          //         ),
          //       );

          //       if (result == true) {
          //         // รีเฟรชข้อมูลเมื่อเพิ่มฟาร์มสำเร็จ
          //         setState(() {
          //           farmsFuture = fetchFarms(widget.mid);
          //         });
          //       }
          //     },
          //   ),
          // ),

          //เพิ่มไร่นาปุ่มไล่สี
          // Padding(
          //   padding: const EdgeInsets.fromLTRB(12, 12, 12, 25), // ด้านล่าง = 0

          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.end,
          //     children: [
          //       GestureDetector(
          //         onTap: () async {
          //           final result = await Navigator.push(
          //             context,
          //             MaterialPageRoute(
          //               builder: (_) => AddFarmPage(mid: widget.mid),
          //             ),
          //           );
          //           if (result == true) {
          //             setState(() {
          //               farmsFuture = fetchFarms(widget.mid);
          //             });
          //           }
          //         },
          //         child: Container(
          //           padding: const EdgeInsets.symmetric(
          //               horizontal: 20, vertical: 14),
          //           decoration: BoxDecoration(
          //             gradient: const LinearGradient(
          //               colors: [
          //                 Color.fromARGB(255, 190, 255, 189),
          //                 Color.fromARGB(255, 37, 189, 35),
          //                 Color.fromARGB(255, 46, 125, 50),
          //               ], // ไล่เฉดสีเขียว
          //               begin: Alignment.topLeft,
          //               end: Alignment.bottomRight,
          //             ),
          //             borderRadius: BorderRadius.circular(12),
          //             boxShadow: const [
          //               BoxShadow(
          //                 color: Colors.black26,
          //                 blurRadius: 6,
          //                 offset: Offset(2, 2),
          //               ),
          //             ],
          //           ),
          //           child: const Row(
          //             mainAxisSize: MainAxisSize.min,
          //             children: [
          //               Icon(Icons.add, color: Colors.white),
          //               SizedBox(width: 8),
          //               Text(
          //                 'เพิ่มไร่นาใหม่',
          //                 style: TextStyle(
          //                   color: Colors.white,
          //                   fontSize: 18,
          //                   fontWeight: FontWeight.w600,
          //                 ),
          //               ),
          //             ],
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end, // ✅ ชิดขวา
              children: [
                GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddFarmPage(mid: widget.mid),
                      ),
                    );
                    if (result == true) {
                      setState(() {
                        farmsFuture = fetchFarms(widget.mid);
                      });
                    }
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add,
                        color: Color(0xFFFF8C00), // สีส้ม
                        size: 60, // ✅ ขนาดไอคอน (ค่าเริ่มต้นคือ 24)
                      ),
                      Text(
                        'เพิ่มไร่นา',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors
                              .black87, // สีข้อความ (เปลี่ยนได้ตามต้องการ)
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
