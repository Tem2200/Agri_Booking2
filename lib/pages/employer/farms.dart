import 'dart:convert';
import 'package:agri_booking2/pages/employer/addFarm.dart';
import 'package:agri_booking2/pages/employer/updateFarm.dart';
import 'package:flutter/material.dart';
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
      print("ข้อมูลฟาร์ม: $data");
      return data;
    } else {
      throw Exception('ไม่พบข้อมูลฟาร์ม');
    }
  }

  Future<void> deleteFarm(int fid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('คุณต้องการลบฟาร์มนี้หรือไม่?'),
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
          const SnackBar(content: Text('ลบฟาร์มสำเร็จ')),
        );
        setState(() {
          farmsFuture = fetchFarms(widget.mid);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: ${response.body}')),
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
        title: Text('Farms Page (MID: ${widget.mid})'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('เพิ่มฟาร์มใหม่'),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddFarmPage(mid: widget.mid),
                  ),
                );

                if (result == true) {
                  // รีเฟรชข้อมูลเมื่อเพิ่มฟาร์มสำเร็จ
                  setState(() {
                    farmsFuture = fetchFarms(widget.mid);
                  });
                }
              },
            ),
          ),
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
                  return const Center(child: Text('ไม่มีข้อมูลฟาร์ม'));
                }

                final farms = snapshot.data!;

                return ListView.builder(
                  itemCount: farms.length,
                  itemBuilder: (context, index) {
                    final farm = farms[index];
                    return Card(
                      child: ListTile(
                        title: Text(farm['name_farm']),
                        subtitle: Text(
                            '${farm['subdistrict']}, ${farm['district']}, ${farm['province']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
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
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => deleteFarm(farm['fid']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
