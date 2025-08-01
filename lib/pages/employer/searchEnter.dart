import 'dart:convert';
import 'package:agri_booking2/pages/employer/DetailVehc_emp.dart';
import 'package:agri_booking2/pages/employer/Tabbar.dart';
import 'package:agri_booking2/pages/employer/search_emp.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:http/http.dart' as http;

class SearchEnter extends StatefulWidget {
  final int mid;
  final Map<String, dynamic> payload;

  const SearchEnter({
    super.key,
    required this.mid,
    required this.payload,
  });

  @override
  State<SearchEnter> createState() => _SearchEnterState();
}

class _SearchEnterState extends State<SearchEnter> {
  Timer? _debounce;

  bool isLoading = false;
  List<dynamic> vehicles = [];
  String currentOrder = "asc";
  bool sortByDistance = false;
  TextEditingController _searchController = TextEditingController();
  String searchQuery = "";

  double? userLat;
  double? userLng;
  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    currentOrder = widget.payload["order"] ?? "asc";
    userLat = widget.payload["latitude"];
    userLng = widget.payload["longitude"];
    searchQuery = widget.payload["keyword"] ?? "";
    // _searchController.addListener(() {
    //   if (_debounce?.isActive ?? false) _debounce!.cancel();
    //   _debounce = Timer(const Duration(milliseconds: 500), () {
    //     setState(() {
    //       searchQuery = _searchController.text;
    //     });
    //     _searchVehicle();
    //   });
    // });

    _searchVehicle();
  }

  Future<void> _searchVehicle() async {
    setState(() {
      isLoading = true;
    });

    try {
      final url = Uri.parse(
        'http://projectnodejs.thammadalok.com/AGribooking/search_vehicle',
      );

      final body = {
        "keyword": searchQuery,
        "order": currentOrder,
      };

      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          vehicles = data;
        });
        await _calculateDistances();
      } else {
        print("Error response: ${res.body}");
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _calculateDistances() async {
    if (userLat == null || userLng == null) return;

    const apiKey =
        'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6ImMyOWE5ZDkxMmUyZDQzMDc4ODNlZWQ0MjQzZDQ2NTk1IiwiaCI6Im11cm11cjY0In0=';

    for (var v in vehicles) {
      final endLat = double.tryParse(v['latitude'].toString()) ?? 0.0;
      final endLng = double.tryParse(v['longitude'].toString()) ?? 0.0;

      final url = Uri.parse(
          'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$apiKey&start=$userLng,$userLat&end=$endLng,$endLat');

      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final meters =
            data['features'][0]['properties']['segments'][0]['distance'];
        final km = meters / 1000;

        v['distance_text'] = '${km.toStringAsFixed(2)} กม.';
        v['distance_value'] = km;
      } else {
        v['distance_text'] = '-';
        v['distance_value'] = double.infinity;
      }
    }

    if (sortByDistance) {
      vehicles.sort((a, b) => (a['distance_value'] ?? double.infinity)
          .compareTo(b['distance_value'] ?? double.infinity));
    }

    setState(() {});
  }

  void _togglePriceOrder() {
    setState(() {
      sortByDistance = false;
      currentOrder = currentOrder == "asc" ? "desc" : "asc";
    });
    _searchVehicle();
  }

  void _sortByDistance() {
    setState(() {
      sortByDistance = true;
    });
    _calculateDistances();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: const Text('ผลการค้นหา'),
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back),
        //   onPressed: () {
        //     Navigator.push(
        //       context,
        //       MaterialPageRoute(
        //         builder: (context) => SearchEmp(
        //           mid: widget.mid,
        //         ),
        //       ),
        //     );
        //   },
        // ),
        //backgroundColor: Color.fromARGB(255, 18, 143, 9),
        backgroundColor: const Color.fromARGB(255, 18, 143, 9),
        centerTitle: true,
        title: const Text(
          'ผลการค้นหา',
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

        leading: IconButton(
          color: Colors.white,
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            int currentMonth = DateTime.now().month;
            int currentYear = DateTime.now().year;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => Tabbar(
                  mid: widget.mid,
                  value: 0,
                  month: currentMonth,
                  year: currentYear,
                ),
              ),
            );
          },
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // ช่องกรอก TextField
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'ค้นหาชื่อรถหรือผู้รับจ้าง',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                          width: 8), // ระยะห่างระหว่างช่องกรอกกับปุ่ม

                      // ปุ่มค้นหา
                      ElevatedButton.icon(
                        icon: const Icon(Icons.search),
                        label: const Text('ค้นหา'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 18),
                        ),
                        onPressed: () {
                          FocusScope.of(context).unfocus(); // ปิดแป้นพิมพ์
                          setState(() {
                            searchQuery = _searchController.text;
                          });
                          _searchVehicle();
                        },
                      ),
                    ],
                  ),
                ),
                // Padding(
                //   padding: const EdgeInsets.all(16),
                //   child: TextField(
                //     controller: _searchController,
                //     decoration: InputDecoration(
                //       hintText: 'ค้นหาชื่อรถหรือผู้รับจ้าง',
                //       prefixIcon: Icon(Icons.search),
                //       border: OutlineInputBorder(
                //         borderRadius: BorderRadius.circular(12),
                //       ),
                //     ),
                //   ),
                // ),
                // Padding(
                //   padding: const EdgeInsets.symmetric(horizontal: 16),
                //   child: SizedBox(
                //     width: double.infinity,
                //     child: ElevatedButton.icon(
                //       icon: const Icon(Icons.search),
                //       label: const Text('ค้นหา'),
                //       onPressed: () {
                //         setState(() {
                //           searchQuery = _searchController.text;
                //         });
                //         _searchVehicle();
                //       },
                //     ),
                //   ),
                // ),

                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Align(
                    alignment: Alignment.centerLeft, // จัดให้ชิดซ้าย
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _togglePriceOrder,
                          icon: Icon(
                            currentOrder == "desc"
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                          ),
                          label: Text(
                            currentOrder == "desc"
                                ? "ราคา: มาก → น้อย"
                                : "ราคา: น้อย → มาก",
                          ),
                        ),
                        // เพิ่มปุ่มอื่นในนี้ได้ตามต้องการ
                      ],
                    ),
                  ),
                ),

                //เอาไว้ก่อนปุ่มระยะทางกับราคา
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   children: [
                //     OutlinedButton(
                //       onPressed: _sortByDistance,
                //       style: OutlinedButton.styleFrom(
                //         shape: RoundedRectangleBorder(
                //           borderRadius: BorderRadius.circular(20),
                //         ),
                //         side: const BorderSide(color: Colors.orange),
                //         padding: const EdgeInsets.symmetric(
                //             horizontal: 16, vertical: 12),
                //       ),
                //       child: const Row(
                //         children: [
                //           Text("ระยะทาง",
                //               style: TextStyle(color: Colors.black)),
                //           SizedBox(width: 4),
                //           Icon(Icons.swap_vert, color: Colors.black, size: 18),
                //         ],
                //       ),
                //     ),
                //     const SizedBox(width: 12),
                //     OutlinedButton(
                //       onPressed: _togglePriceOrder,
                //       style: OutlinedButton.styleFrom(
                //         shape: RoundedRectangleBorder(
                //           borderRadius: BorderRadius.circular(20),
                //         ),
                //         side: const BorderSide(color: Colors.orange),
                //         padding: const EdgeInsets.symmetric(
                //             horizontal: 16, vertical: 12),
                //       ),
                //       child: const Row(
                //         children: [
                //           Text("ราคา", style: TextStyle(color: Colors.black)),
                //           SizedBox(width: 4),
                //           Icon(Icons.swap_vert, color: Colors.black, size: 18),
                //         ],
                //       ),
                //     ),
                //   ],
                // ),

                Expanded(
                  child: vehicles.isEmpty
                      ? const Center(child: Text('ไม่พบผลลัพธ์'))
                      : ListView.builder(
                          itemCount: vehicles.length,
                          itemBuilder: (context, index) {
                            final v = vehicles[index];
                            // return Card(
                            //   margin: const EdgeInsets.symmetric(
                            //       vertical: 8, horizontal: 16),
                            //   child: ListTile(
                            //     leading: v['image'] != null
                            //         ? Image.network(
                            //             v['image'],
                            //             width: 60,
                            //             height: 60,
                            //             fit: BoxFit.cover,
                            //             errorBuilder: (_, __, ___) =>
                            //                 const Icon(
                            //                     Icons.image_not_supported),
                            //           )
                            //         : const Icon(Icons.agriculture, size: 50),
                            //     title: Text(v['name_vehicle'] ?? '-'),
                            //     subtitle: Column(
                            //       crossAxisAlignment: CrossAxisAlignment.start,
                            //       children: [
                            //         Text(
                            //             'ผู้รับจ้าง: ${v['username_contractor'] ?? '-'}'),
                            //         Text(
                            //             'คะแนนเฉลี่ยรีวิว: ${v['avg_review_point'] ?? '-'}'),
                            //         Text('ราคา: ${v['price'] ?? '-'} บาท'),
                            //         if (v['distance_text'] != null)
                            //           Text('ระยะทาง: ${v['distance_text']}'),
                            //         const SizedBox(height: 8),
                            //         OutlinedButton(
                            //           onPressed: () {
                            //             Navigator.push(
                            //               context,
                            //               MaterialPageRoute(
                            //                 builder: (context) => DetailvehcEmp(
                            //                   vid: v['vid'] ?? 0,
                            //                   mid: widget.mid,
                            //                   fid: (widget.payload['farm'] !=
                            //                               null &&
                            //                           widget.payload['farm']
                            //                                   ['fid'] !=
                            //                               null)
                            //                       ? widget.payload['farm']
                            //                           ['fid'] as int
                            //                       : 0,
                            //                   farm: widget.payload["farm"],
                            //                 ),
                            //               ),
                            //             );
                            //           },
                            //           child: const Text('รายละเอียดเพิ่มเติม'),
                            //         ),
                            //       ],
                            //     ),
                            //   ),
                            // );

                            return Padding(
                              padding: const EdgeInsets.fromLTRB(15, 0, 15, 25),
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
                                    // ✅ รูปภาพ
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: v['image'] != null &&
                                              v['image'].toString().isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: v['image'],
                                              width: 120,
                                              height: 180,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
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
                                                  const Icon(Icons.broken_image,
                                                      size: 48),
                                            )
                                          : Container(
                                              width: 120,
                                              height: 180,
                                              color: Colors.grey[200],
                                              alignment: Alignment.center,
                                              child: const Icon(
                                                  Icons.image_not_supported,
                                                  size: 48),
                                            ),
                                    ),

                                    const SizedBox(width: 12),

                                    // ✅ ข้อมูล
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            v['name_vehicle'] ?? 'ไม่มีชื่อรถ',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(Icons.person,
                                                  size: 18,
                                                  color: Colors.orange),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  'ผู้รับจ้าง: ${v['username'] ?? '-'}',
                                                  style: const TextStyle(
                                                      fontSize: 14),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.attach_money,
                                                  size: 18,
                                                  color: Colors.green),
                                              const SizedBox(width: 6),
                                              Text(
                                                '${v['price'] ?? '-'} บาท',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.star,
                                                  size: 18,
                                                  color: Colors.amber),
                                              const SizedBox(width: 6),
                                              Text(
                                                'คะแนนรีวิว: ${double.tryParse(v['avg_review_point'] ?? '0')?.toStringAsFixed(2) ?? '0.00'}',
                                                style: const TextStyle(
                                                    fontSize: 14),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.location_on,
                                                  size: 18,
                                                  color: Colors.redAccent),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  '${v['subdistrict']} ,${v['district']} ,${v['province']}',
                                                  maxLines: 1,
                                                  style: const TextStyle(
                                                      fontSize: 15),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          if (v['distance_text'] != null)
                                            Row(
                                              children: [
                                                const Icon(Icons.map,
                                                    size: 18,
                                                    color: Colors.blue),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    'ระยะทาง: ${v['distance_text']}',
                                                    style: const TextStyle(
                                                        fontSize: 14),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          const SizedBox(height: 12),
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: OutlinedButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        DetailvehcEmp(
                                                      vid: v['vid'] ?? 0,
                                                      mid: widget.mid,
                                                      fid: (widget.payload[
                                                                      'farm'] !=
                                                                  null &&
                                                              widget.payload[
                                                                          'farm']
                                                                      ['fid'] !=
                                                                  null)
                                                          ? widget.payload[
                                                                  'farm']['fid']
                                                              as int
                                                          : 0,
                                                      farm: widget
                                                          .payload["farm"],
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
    );
  }
}
