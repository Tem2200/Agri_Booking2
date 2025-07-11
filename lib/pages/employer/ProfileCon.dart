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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("โปรไฟล์ผู้รับจ้าง"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "รายการรถ"),
              Tab(text: "รีวิว"),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              flex: 1,
              child: FutureBuilder<Map<String, dynamic>>(
                future: _memberDataFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                        child: Text("เกิดข้อผิดพลาด: ${snapshot.error}"));
                  } else if (!snapshot.hasData) {
                    return const Center(child: Text("ไม่พบข้อมูลสมาชิก"));
                  }

                  final member = snapshot.data!;

                  return Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: member['image'] != null
                                  ? NetworkImage(member['image'])
                                  : null,
                              child: member['image'] == null
                                  ? const Icon(Icons.person, size: 30)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              member['username'] ?? "-",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.phone, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(member['phone'] ?? "-"),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on, color: Colors.orange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                member['detail_address'] != null
                                    ? "${member['detail_address']} ต.${member['subdistrict']} อ.${member['district']} จ.${member['province']}"
                                    : "-",
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
            Expanded(
              flex: 2,
              child: TabBarView(
                children: [
                  _buildVehicleTab(),
                  _buildReviewTab(),
                ],
              ),
            )
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
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ รูปภาพทางซ้าย
                    vehicle['image'] != null &&
                            vehicle['image'].toString().isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              vehicle['image'],
                              width: 100,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                width: 100,
                                height: 80,
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image),
                              ),
                            ),
                          )
                        : Container(
                            width: 100,
                            height: 80,
                            color: Colors.grey[200],
                            child: const Icon(Icons.directions_car, size: 40),
                          ),

                    const SizedBox(width: 12),

                    // ✅ ข้อมูลรถทางขวา
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehicle['name_vehicle'] ?? '-',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            vehicle['detail'] ?? '-',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetailvehcEmp(
                                      vid: vehicle['vid'] ?? 0,
                                      mid: widget.mid_emp,
                                      fid: widget.farm['fid'] ?? 0,
                                      farm: widget.farm,
                                    ),
                                  ),
                                );
                              },
                              child: const Text('รายละเอียดเพิ่มเติม'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                textStyle: const TextStyle(fontSize: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
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

            return ListTile(
              title: Text(review['text'] ?? "-"),
              subtitle: Text(
                  "คะแนน: ${review['point'] ?? '-'} / 5\nวันที่รีวิว: ${review['date']?.toString().substring(0, 10) ?? '-'}"),
              trailing: ElevatedButton(
                onPressed:
                    isReported ? null : () => _reportReview(review['rid']),
                child: Text(isReported ? "รายงานแล้ว" : "รายงาน"),
              ),
            );
          },
        );
      },
    );
  }
}
