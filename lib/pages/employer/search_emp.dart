import 'dart:convert';

import 'package:agri_booking2/pages/employer/DetailVehc_emp.dart';
import 'package:agri_booking2/pages/employer/Tabbar.dart';
import 'package:agri_booking2/pages/employer/farms.dart';
import 'package:agri_booking2/pages/employer/searchEnter.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

class SearchEmp extends StatefulWidget {
  final int mid;
  const SearchEmp({super.key, required this.mid});

  @override
  State<SearchEmp> createState() => _SearchEmpState();
}

class _SearchEmpState extends State<SearchEmp> {
  TextEditingController searchController = TextEditingController();

  List<dynamic> farmList = [];
  dynamic selectedFarm;
  double? selectedFarmLat;
  double? selectedFarmLng;

  List<dynamic> allVehicles = [];
  List<dynamic> filteredVehicles = [];

  bool isLoading = false;
  bool hasFarm = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startLongPolling();
    print("mid at SearchEmp: ${widget.mid}");
    print("Selected Farm Lat: $selectedFarmLat");
    print("Selected Farm Lng: $selectedFarmLng");
    print("Selected Farm: $selectedFarm");
  }

  void _startLongPolling() async {
    while (mounted) {
      try {
        final url = Uri.parse(
            'http://projectnodejs.thammadalok.com/AGribooking/long-poll');
        final response = await http.get(url);
        if (response.statusCode == 200 && response.body.isNotEmpty) {
          final data = jsonDecode(response.body);
          if (data['event'] == 'vehicle_status_updated') {
            setState(() {
              _loadVehicles(); // โหลดข้อมูลรถใหม่s
            });
          }
        }
      } catch (e) {
        await Future.delayed(const Duration(seconds: 2));
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  // Future<void> _loadData() async {
  //   setState(() => isLoading = true);
  //   try {
  //     await Future.wait([
  //       _loadFarms(),
  //       _loadVehicles(),
  //     ]);

  //     if (farmList.isNotEmpty) {
  //       selectedFarm = farmList[0];
  //       selectedFarmLat = _parseLatLng(selectedFarm['latitude']);
  //       selectedFarmLng = _parseLatLng(selectedFarm['longitude']);
  //       await _calculateDistances();
  //     } else {
  //       hasFarm = false;
  //       _sortByReview();
  //     }
  //   } finally {
  //     setState(() => isLoading = false);
  //   }
  // }
  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      // ✅ โหลด farms ก่อน เพื่อให้เลือก farm ได้เร็ว
      await _loadFarms();

      if (farmList.isNotEmpty) {
        selectedFarm = farmList[0];
        selectedFarmLat = _parseLatLng(selectedFarm['latitude']);
        selectedFarmLng = _parseLatLng(selectedFarm['longitude']);

        // ✅ โหลด vehicles + คำนวณระยะทางไปพร้อมกัน
        await _loadVehicles();
        _calculateDistances(); // 🔥 ยิงไป background ไม่ต้องรอ
      } else {
        hasFarm = false;
        await _loadVehicles();
        _sortByReview();
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  double _parseLatLng(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  Future<void> _loadFarms() async {
    try {
      final url = Uri.parse(
          'http://projectnodejs.thammadalok.com/AGribooking/get_farms/${widget.mid}');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        farmList = data;
      }
    } catch (e) {
      print('Error loading farms: $e');
    }
  }

  Future<void> _loadVehicles() async {
    try {
      final url = Uri.parse(
          'http://projectnodejs.thammadalok.com/AGribooking/get_vehicle_HomeMem');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final vehicles = jsonDecode(res.body);
        allVehicles = vehicles;
        filteredVehicles = vehicles;
      }
    } catch (e) {
      print('Error loading vehicles: $e');
    }
  }

  void _sortByReview() {
    allVehicles.sort((a, b) {
      final aPoint =
          num.tryParse(a['avg_review_point']?.toString() ?? "0") ?? 0;
      final bPoint =
          num.tryParse(b['avg_review_point']?.toString() ?? "0") ?? 0;
      return bPoint.compareTo(aPoint);
    });
    filteredVehicles = allVehicles;
  }

<<<<<<< HEAD
  // Future<void> _calculateDistances() async {
  //   if (selectedFarm == null ||
  //       selectedFarmLat == null ||
  //       selectedFarmLng == null) return;

  //   setState(() => isLoading = true);

  //   try {
  //     var destinationsVehicles = allVehicles
  //         .where((v) {
  //           final lat = _parseLatLng(v['latitude']);
  //           final lng = _parseLatLng(v['longitude']);
  //           return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  //         })
  //         .take(20)
  //         .toList();

  //     if (destinationsVehicles.isEmpty) {
  //       filteredVehicles = [];
  //       return;
  //     }

  //     for (var i = 0; i < destinationsVehicles.length; i++) {
  //       final v = destinationsVehicles[i];

  //       if (v['distance_cache'] != null) {
  //         v['distance_text'] = v['distance_cache']['text'];
  //         v['distance_value'] = v['distance_cache']['value'];
  //         continue;
  //       }

  //       final endLat = _parseLatLng(v['latitude']);
  //       final endLng = _parseLatLng(v['longitude']);

  //       // ✅ ใช้ OSRM Public Server
  //       final url =
  //           Uri.parse('https://router.project-osrm.org/route/v1/driving/'
  //               '$selectedFarmLng,$selectedFarmLat;$endLng,$endLat'
  //               '?overview=false');

  //       try {
  //         final res = await http.get(url);
  //         if (res.statusCode == 200) {
  //           final data = jsonDecode(res.body);
  //           if (data['routes'] != null && data['routes'].isNotEmpty) {
  //             final meters = data['routes'][0]['distance'];
  //             final km = meters / 1000;
  //             v['distance_text'] = '${km.toStringAsFixed(2)} กม.';
  //             v['distance_value'] = km;
  //             v['distance_cache'] = {
  //               'text': v['distance_text'],
  //               'value': km,
  //             };
  //           } else {
  //             v['distance_text'] = '-';
  //             v['distance_value'] = double.infinity;
  //           }
  //         } else {
  //           print('OSRM API error: ${res.body}');
  //           v['distance_text'] = '-';
  //           v['distance_value'] = double.infinity;
  //         }
  //       } catch (e) {
  //         v['distance_text'] = '-';
  //         v['distance_value'] = double.infinity;
  //       }

  //       // ✅ กัน overload server: พัก 100 ms ต่อ request
  //       await Future.delayed(const Duration(milliseconds: 100));
  //     }

  //     destinationsVehicles.sort((a, b) =>
  //         (a['distance_value'] ?? 0).compareTo(b['distance_value'] ?? 0));

  //     filteredVehicles = destinationsVehicles;
  //   } finally {
  //     setState(() => isLoading = false);
  //   }
  // }
=======
>>>>>>> Whan
  Future<void> _calculateDistances({bool forceReload = false}) async {
    if (selectedFarm == null ||
        selectedFarmLat == null ||
        selectedFarmLng == null) return;

    setState(() => isLoading = true);

    try {
      // ใช้ทั้งหมด ไม่ limit 20
      var destinationsVehicles = allVehicles.where((v) {
        final lat = _parseLatLng(v['latitude']);
        final lng = _parseLatLng(v['longitude']);
        return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
      }).toList();

      if (destinationsVehicles.isEmpty) {
        filteredVehicles = [];
        return;
      }

      for (var i = 0; i < destinationsVehicles.length; i++) {
        final v = destinationsVehicles[i];

        // ถ้ามี cache และไม่ได้บังคับ reload → ใช้ cache เลย
        if (v['distance_cache'] != null && !forceReload) {
          v['distance_text'] = v['distance_cache']['text'];
          v['distance_value'] = v['distance_cache']['value'];
          continue;
        }

        final endLat = _parseLatLng(v['latitude']);
        final endLng = _parseLatLng(v['longitude']);
        final url =
            Uri.parse('https://router.project-osrm.org/route/v1/driving/'
                '$selectedFarmLng,$selectedFarmLat;$endLng,$endLat'
                '?overview=false');

        try {
          final res = await http.get(url);
          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);
            if (data['routes'] != null && data['routes'].isNotEmpty) {
              final meters = data['routes'][0]['distance'];
              final km = meters / 1000;
              v['distance_text'] = '${km.toStringAsFixed(2)} กม.';
              v['distance_value'] = km;
              v['distance_cache'] = {
                'text': v['distance_text'],
                'value': km,
              };
            } else {
              v['distance_text'] = '-';
              v['distance_value'] = double.infinity;
            }
          } else {
            v['distance_text'] = '-';
            v['distance_value'] = double.infinity;
          }
        } catch (e) {
          v['distance_text'] = '-';
          v['distance_value'] = double.infinity;
        }

        // พัก 100ms กัน overload server
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // เรียงตามระยะทาง
      destinationsVehicles.sort((a, b) =>
          (a['distance_value'] ?? 0).compareTo(b['distance_value'] ?? 0));

      filteredVehicles = destinationsVehicles;
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _onSearch() {
    final query = searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกคำค้นหา')),
      );
      return;
    }

    final Map<String, dynamic> payload = {
      "keyword": query,
      "order": "desc",
      "latitude": selectedFarmLat,
      "longitude": selectedFarmLng,
      "mid": widget.mid,
      "farm": selectedFarm,
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchEnter(
          mid: widget.mid,
          payload: payload,
          selectedFarmLat: selectedFarmLat,
          selectedFarmLng: selectedFarmLng,
        ),
      ),
    );

    setState(() {
      filteredVehicles = allVehicles.where((v) {
        final name = v['name_vehicle']?.toString().toLowerCase() ?? '';
        final username =
            v['username_contractor']?.toString().toLowerCase() ?? '';
        return name.contains(query) || username.contains(query);
      }).toList();
    });
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 18, 143, 9),
        //backgroundColor: const Color.fromARGB(255, 255, 158, 60),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false, // ✅ ลบปุ่มย้อนกลับ
        title: const Text(
          'หน้าแรก (ผู้จ้าง)',
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
                        builder: (context) => Tabbar(
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'เลือกที่นาเพื่อหารถที่อยู่ใกล้ที่สุด',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                // 🔍 ช่องค้นหา (ใหญ่กว่า)
                Expanded(
                  flex: 3, // สัดส่วน 2 ส่วน
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'ค้นหา',
                      filled: true,
                      fillColor: const Color.fromARGB(123, 229, 224, 224),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Colors.orange),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _onSearch,
                      ),
                    ),
                    onSubmitted: (_) => _onSearch(),
                  ),
                ),

                const SizedBox(width: 8), // ระยะห่างระหว่างช่อง

                // 🏞️ ปุ่มเลือกฟาร์ม
                Expanded(
                  flex: 1, // สัดส่วน 1 ส่วน
                  child: ElevatedButton(
                    onPressed: farmList.isEmpty ? null : _showFarmPicker,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color.fromARGB(255, 251, 160, 76),
                      foregroundColor: const Color.fromARGB(255, 34, 31, 31),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      selectedFarm?['name_farm'] ?? 'เลือกที่นา',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                // Expanded(
                //   flex: 1,
                //   child: ElevatedButton(
                //     onPressed: farmList.isEmpty
                //         ? () {
                //             // ไม่มีที่นา → ไปหน้าเพิ่มที่นา
                //             Navigator.push(
                //               context,
                //               MaterialPageRoute(
                //                 builder: (context) =>
                //                     FarmsPage(mid: widget.mid),
                //               ),
                //             );
                //           }
                //         : _showFarmPicker, // มีที่นา → เลือกที่นา
                //     style: ElevatedButton.styleFrom(
                //       padding: const EdgeInsets.symmetric(vertical: 16),
                //       backgroundColor: const Color.fromARGB(255, 251, 160, 76),
                //       foregroundColor: const Color.fromARGB(255, 34, 31, 31),
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(12),
                //       ),
                //     ),
                //     child: Text(
                //       farmList.isEmpty
                //           ? 'เพิ่มที่นา'
                //           : (selectedFarm?['name_farm'] ?? 'เลือกที่นา'),
                //       overflow: TextOverflow.ellipsis,
                //     ),
                //   ),
                // ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Column(
                children: [
                  // 🔄 สไลด์โชว์ภาพ
                  CarouselSlider(
                    options: CarouselOptions(
                      height: 140,
                      autoPlay: true,
                      enlargeCenterPage: true,
                      viewportFraction: 0.99,
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
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'รถที่ให้บริการ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  // 🔽 ส่วนแสดงรายการ
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : filteredVehicles.isEmpty
                            ? Center(
                                // child: hasFarm
                                //     ? const Text(
                                //         'ไม่พบรถที่สามารถคำนวณระยะทางได้ หรือพิกัดผิด')
                                //     : const Text(
                                //         'ไม่พบข้อมูลรถที่ตรงกับการค้นหา'),
                                child: Text(
                                  hasFarm
                                      ? 'ไม่พบรถที่สามารถคำนวณระยะทางได้ หรือพิกัดผิด'
                                      : 'ไม่พบข้อมูลรถที่ตรงกับการค้นหา',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              )
                            : ListView.builder(
                                itemCount: filteredVehicles.length,
                                itemBuilder: (context, index) {
                                  final v = filteredVehicles[index];

                                  return Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(0, 0, 0, 25),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.orange[50],
                                        border:
                                            Border.all(color: Colors.orange),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.orange.withOpacity(0.3),
                                            spreadRadius: 1,
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // ✅ รูปภาพ
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: v['image'] != null &&
                                                    v['image']
                                                        .toString()
                                                        .isNotEmpty
                                                ? CachedNetworkImage(
                                                    imageUrl: v['image'],
                                                    width: 120,
                                                    height: 220,
                                                    fit: BoxFit.cover,
                                                    placeholder:
                                                        (context, url) =>
                                                            const Center(
                                                      child: SizedBox(
                                                        width: 32,
                                                        height: 32,
                                                        child:
                                                            CircularProgressIndicator(
                                                                strokeWidth: 2),
                                                      ),
                                                    ),
                                                    errorWidget: (context, url,
                                                            error) =>
                                                        const Icon(
                                                            Icons.broken_image,
                                                            size: 48),
                                                  )
                                                : Container(
                                                    width: 120,
                                                    height: 220,
                                                    color: Colors.grey[200],
                                                    alignment: Alignment.center,
                                                    child: const Icon(
                                                        Icons
                                                            .image_not_supported,
                                                        size: 48),
                                                  ),
                                          ),

                                          const SizedBox(width: 12),

                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  v['name_vehicle'] ??
                                                      'ไม่มีชื่อรถ',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                                const SizedBox(height: 6),

                                                // 🔸 ผู้รับจ้าง
                                                Row(
                                                  children: [
                                                    const Icon(Icons.person,
                                                        size: 18,
                                                        color: Colors.orange),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(
                                                        'ผู้รับจ้าง: ${v['username_contractor'] ?? '-'}',
                                                        style: const TextStyle(
                                                            fontSize: 14),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        maxLines: 1,
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                                const SizedBox(height: 4),

                                                // 🔸 ราคา
                                                Row(
                                                  children: [
                                                    const Icon(
                                                        Icons.attach_money,
                                                        size: 18,
                                                        color: Colors.green),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(
                                                        '${v['price']} บาท/${v['unit_price']}',
                                                        style: const TextStyle(
                                                          fontSize: 15,
                                                          color: Colors.green,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis, // ตัดเป็น ...
                                                        maxLines:
                                                            1, // ให้แสดงแค่บรรทัดเดียว
                                                        softWrap:
                                                            false, // ไม่ตัดบรรทัด
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                                const SizedBox(height: 4),

                                                // 🔸 คะแนน
                                                Row(
                                                  children: [
                                                    const Icon(Icons.star,
                                                        size: 18,
                                                        color: Colors.amber),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      // ครอบเพื่อจำกัดพื้นที่
                                                      child: Text(
                                                        'คะแนนรีวิว: ${double.tryParse(v['avg_review_point'] ?? '0')?.toStringAsFixed(2) ?? '0.00'}',
                                                        style: const TextStyle(
                                                            fontSize: 14),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        maxLines: 1,
                                                        softWrap: false,
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                        Icons.location_on,
                                                        size: 18,
                                                        color:
                                                            Colors.redAccent),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(
                                                        '${v['province']},${v['district']},${v['subdistrict']}',
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                            fontSize: 15),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),

                                                // 🔸 ระยะทาง (ถ้ามีฟาร์ม)
                                                if (hasFarm)
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.map,
                                                          size: 18,
                                                          color: Colors.blue),
                                                      const SizedBox(width: 6),
                                                      Expanded(
                                                        child: Text(
                                                          'ระยะทาง: ${v['distance_text'] ?? '-'}',
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 14),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          maxLines: 1,
                                                        ),
                                                      ),
                                                    ],
                                                  ),

                                                const SizedBox(height: 12),

                                                // 🔸 ปุ่มรายละเอียดเพิ่มเติม
                                                Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: OutlinedButton(
                                                    style: OutlinedButton
                                                        .styleFrom(
                                                      side: const BorderSide(
                                                          color: Color.fromARGB(
                                                              255,
                                                              174,
                                                              134,
                                                              182)), // สีกรอบ
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                20), // มุมโค้ง
                                                      ),
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 12,
                                                          vertical: 8),
                                                    ),
                                                    onPressed: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              DetailvehcEmp(
                                                            vid: v['vid'] ?? 0,
                                                            mid: widget.mid,
                                                            fid: selectedFarm?[
                                                                    'fid'] ??
                                                                0,
                                                            farm: selectedFarm,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    child: const Text(
                                                        'รายละเอียดเพิ่มเติม'),
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
                              ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

//pop up farm
  void _showFarmPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return ListView.builder(
          shrinkWrap: true,
          itemCount: farmList.length,
          itemBuilder: (context, index) {
            final farm = farmList[index];
            return ListTile(
              title: Text(farm['name_farm'] ?? '-'),
              onTap: () {
                setState(() {
                  selectedFarm = farm;
                  selectedFarmLat = _parseLatLng(farm['latitude']);
                  selectedFarmLng = _parseLatLng(farm['longitude']);
                });
                _calculateDistances();
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }
}
