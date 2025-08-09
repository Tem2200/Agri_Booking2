// หน้า HomeGe.dart
import 'dart:async';
import 'dart:convert';
import 'package:agri_booking2/pages/login.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'search_ge.dart'; // import หน้า SearchGe

class HomeGe extends StatefulWidget {
  const HomeGe({super.key});

  @override
  State<HomeGe> createState() => _HomeGeState();
}

class _HomeGeState extends State<HomeGe> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _priceOrder = 'ASC';
  List<dynamic> vehicles = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAllVehicles();
  }

  Future<void> fetchAllVehicles() async {
    setState(() => isLoading = true);
    final url = Uri.parse(
        'http://projectnodejs.thammadalok.com/AGribooking/get_vehicle_HomeMem');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Fetched vehicles: $data");
        setState(() {
          vehicles = data;
          isLoading = false;
        });
      } else {
        throw Exception('โหลดข้อมูลไม่สำเร็จ');
      }
    } catch (e) {
      print("เกิดข้อผิดพลาด: $e");
      setState(() => isLoading = false);
    }
  }

  void _onSearchChanged(String text) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (text.trim().isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SearchGe(
              keyword: text.trim(),
              initialOrder: _priceOrder,
            ),
          ),
        );
      } else {
        // ถ้า search ว่าง ให้โหลดข้อมูลทั้งหมดกลับมา
        fetchAllVehicles();
      }
    });
  }

  void _togglePriceOrder() {
    setState(() {
      _priceOrder = _priceOrder == 'DECS' ? 'ASC' : 'DECS';
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 18, 143, 9),
        //backgroundColor: const Color.fromARGB(255, 255, 158, 60),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false, // ✅ ลบปุ่มย้อนกลับ
        title: const Text(
          'หน้าแรก',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 255, 255, 255),
            //letterSpacing: 1,
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
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'ค้นหารถ เช่น ชื่อรถ หรือจังหวัด',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.search),
                  label: const Text("ค้นหา"),
                  onPressed: () {
                    final keyword = _searchController.text.trim();
                    if (keyword.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SearchGe(
                            keyword: keyword,
                            initialOrder: _priceOrder,
                          ),
                        ),
                      );
                    }
                  },
                ),
                // IconButton(
                //   icon: Icon(
                //     _priceOrder == 'DECS'
                //         ? Icons.arrow_downward
                //         : Icons.arrow_upward,
                //   ),
                //   onPressed: _togglePriceOrder,
                //   tooltip:
                //       _priceOrder == 'DECS' ? 'ราคาสูง → ต่ำ' : 'ราคาต่ำ → สูง',
                // ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : vehicles.isEmpty
                    ? const Center(child: Text('ไม่พบข้อมูลรถ'))
                    : ListView(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        children: [
                          // 🔄 สไลด์โชว์ภาพ
                          CarouselSlider(
                            options: CarouselOptions(
                              height: 160,
                              autoPlay: true,
                              enlargeCenterPage: true,
                              viewportFraction: 0.95,
                              aspectRatio: 16 / 9,
                              autoPlayInterval: const Duration(seconds: 3),
                            ),
                            items: [
                              'https://i.ibb.co/MqW0vC7/1.png',
                              'https://i.ibb.co/spDRtGWM/2.png',
                              'https://i.ibb.co/pBhd5QJ4/3.png',
                            ].map((imageUrl) {
                              return Builder(
                                builder: (context) => ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 16),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'รถที่ให้บริการ',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // 🔁 สร้างรายการรถจาก vehicles
                          ...vehicles.map((vehicle) {
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.orange[50],
                                  border: Border.all(color: Colors.orange),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orange.withOpacity(0.3),
                                      spreadRadius: 1,
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        vehicle['image'] ?? '',
                                        width: 120,
                                        height: 180,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const SizedBox(
                                          width: 120,
                                          height: 180,
                                          child: Icon(
                                            Icons.broken_image,
                                            size: 48,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            vehicle['name_vehicle'] ??
                                                'ไม่มีชื่อ',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF333333),
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              const Icon(Icons.person,
                                                  size: 18,
                                                  color: Colors.blueGrey),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  'ผู้รับจ้าง: ${vehicle['username_contractor']}',
                                                  style: const TextStyle(
                                                      fontSize: 15),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(Icons.attach_money,
                                                  size: 18,
                                                  color: Colors.green),
                                              const SizedBox(width: 6),
                                              Text(
                                                '${vehicle['price']} บาท/${vehicle['unit_price']}',
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              const Icon(Icons.location_on,
                                                  size: 18,
                                                  color: Colors.redAccent),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  '${vehicle['subdistrict']} ,${vehicle['district']} ,${vehicle['province']}',
                                                  style: const TextStyle(
                                                      fontSize: 15),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              const Icon(Icons.star,
                                                  size: 18,
                                                  color: Colors.amber),
                                              const SizedBox(width: 6),
                                              Text(
                                                'คะแนนรีวิว: ${double.tryParse(vehicle['avg_review_point'] ?? '0')?.toStringAsFixed(2) ?? '0.00'}',
                                                style: const TextStyle(
                                                    fontSize: 15),
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
                          }).toList(),
                        ],
                      ),
          )
        ],
      ),
    );
  }
}
