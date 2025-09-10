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
  final double? selectedFarmLat; // nullable
  final double? selectedFarmLng; // nullable

  const SearchEnter({
    super.key,
    required this.mid,
    required this.payload,
    this.selectedFarmLat,
    this.selectedFarmLng,
  });

  @override
  State<SearchEnter> createState() => _SearchEnterState();
}

class _SearchEnterState extends State<SearchEnter> {
  Timer? _debounce;

  bool isLoading = false;
  List<dynamic> vehicles = [];
  String currentOrder = "asc"; // "asc" หรือ "desc"
  bool sortByDistance = false;
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";
  String currentSortBy = "price";

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
    _searchController.text = widget.payload["keyword"].toString();
    //fetchVehicles(searchKeyword: searchQuery);
    fetchVehicles(searchKeyword: searchQuery).then((_) {
      if (userLat != null && userLng != null) {
        _calculateDistances(sort: false); // คำนวณทันที แต่ไม่เรียง
      }
    });
    //_searchVehicle();
  }

  void _togglePriceOrder() {
    setState(() {
      currentSortBy = "price"; // ตั้งค่าสถานะการเรียงปัจจุบันเป็นราคา
      // สลับทิศทางการเรียง
      currentOrder = currentOrder == "asc" ? "desc" : "asc";
      // เรียงข้อมูลตามราคา
      vehicles.sort((a, b) {
        final aPrice = double.tryParse(a['price']?.toString() ?? '0') ?? 0.0;
        final bPrice = double.tryParse(b['price']?.toString() ?? '0') ?? 0.0;
        return currentOrder == "asc"
            ? aPrice.compareTo(bPrice)
            : bPrice.compareTo(aPrice);
      });
    });
  }

  void _toggleReviewOrder() {
    setState(() {
      currentSortBy = "review"; // ตั้งค่าสถานะการเรียงปัจจุบันเป็นรีวิว
      // สลับทิศทางการเรียง
      currentOrder = currentOrder == "asc" ? "desc" : "asc";
      // เรียงข้อมูลตามคะแนนรีวิว
      vehicles.sort((a, b) {
        final aReview =
            double.tryParse(a['avg_review_point']?.toString() ?? '0') ?? 0.0;
        final bReview =
            double.tryParse(b['avg_review_point']?.toString() ?? '0') ?? 0.0;
        return currentOrder == "asc"
            ? aReview.compareTo(bReview)
            : bReview.compareTo(aReview);
      });
    });
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

  Future<void> fetchVehicles({required String searchKeyword}) async {
    setState(() => isLoading = true);
    final url = Uri.parse(
        'http://projectnodejs.thammadalok.com/AGribooking/search_vehicle');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "keyword": searchKeyword,
          "order": currentOrder,
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
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

  Future<void> _calculateDistances({bool sort = false}) async {
    if (userLat == null || userLng == null) return;

    for (var v in vehicles) {
      final endLat = double.tryParse(v['latitude'].toString()) ?? 0.0;
      final endLng = double.tryParse(v['longitude'].toString()) ?? 0.0;
      const apiKey =
          'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6ImMyOWE5ZDkxMmUyZDQzMDc4ODNlZWQ0MjQzZDQ2NTk1IiwiaCI6Im11cm11cjY0In0=';

      final url = Uri.parse(
          'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$apiKey&start=$userLng,$userLat&end=$endLng,$endLat');

      try {
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
      } catch (e) {
        v['distance_text'] = '-';
        v['distance_value'] = double.infinity;
      }
    }

    if (sort) {
      vehicles.sort((a, b) {
        final aDist = a['distance_value'] ?? double.infinity;
        final bDist = b['distance_value'] ?? double.infinity;
        return currentOrder == "asc"
            ? aDist.compareTo(bDist)
            : bDist.compareTo(aDist);
      });
    }

    setState(() {});
  }

  void _toggleDistanceOrder() {
    setState(() {
      currentSortBy = "distance";
      currentOrder = currentOrder == "asc" ? "desc" : "asc";
    });

    _calculateDistances(sort: true); // เรียงตามระยะทาง
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
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            labelText: 'ค้นหารถ เช่น ชื่อรถ หรือจังหวัด',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.search),
                          ),
                          onSubmitted: (value) {
                            final keyword = _searchController.text.trim();
                            if ((widget.payload['keyword']
                                    .toString()
                                    .isNotEmpty) ||
                                searchQuery.isNotEmpty) {
                              fetchVehicles(searchKeyword: keyword);
                            }
                          },
                        ),
                      ),

                      const SizedBox(
                          width: 8), // ระยะห่างระหว่างช่องกรอกกับปุ่ม

                      // ปุ่มค้นหา
                      ElevatedButton.icon(
                        // icon: const Icon(Icons.search),
                        label: const Text('ค้นหา'),
                        // style: ElevatedButton.styleFrom(
                        //     // padding: const EdgeInsets.symmetric(
                        //     //     horizontal: 16, vertical: 8),
                        //     ),
                        onPressed: () {
                          FocusScope.of(context).unfocus(); // ปิดแป้นพิมพ์
                          setState(() {
                            searchQuery = _searchController.text;
                          });
                          fetchVehicles(searchKeyword: searchQuery);
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _togglePriceOrder,
                          icon: Icon(
                            currentSortBy == "price" && currentOrder == "desc"
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                          ),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              currentSortBy == "price" && currentOrder == "desc"
                                  ? "ราคา: มาก → น้อย"
                                  : "ราคา: น้อย → มาก",
                              maxLines: 1,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                currentSortBy == "price" ? Colors.green : null,
                            foregroundColor:
                                currentSortBy == "price" ? Colors.white : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _toggleReviewOrder,
                          icon: Icon(
                            currentSortBy == "review" && currentOrder == "desc"
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                          ),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              currentSortBy == "review" &&
                                      currentOrder == "desc"
                                  ? "รีวิว: มาก → น้อย"
                                  : "รีวิว: น้อย → มาก",
                              maxLines: 1,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                currentSortBy == "review" ? Colors.green : null,
                            foregroundColor:
                                currentSortBy == "review" ? Colors.white : null,
                          ),
                        ),
                      ),
                      // Expanded(
                      //   child: ElevatedButton.icon(
                      //     onPressed: (userLat != null && userLng != null)
                      //         ? _toggleDistanceOrder
                      //         : null, // ถ้าไม่มีพิกัด ให้ปุ่มเป็น disable
                      //     icon: Icon(
                      //       currentSortBy == "distance" &&
                      //               currentOrder == "desc"
                      //           ? Icons.arrow_upward
                      //           : Icons.arrow_downward,
                      //     ),
                      //     label: FittedBox(
                      //       fit: BoxFit.scaleDown,
                      //       child: Text(
                      //         "ระยะทาง",
                      //         maxLines: 1,
                      //       ),
                      //     ),
                      //     style: ElevatedButton.styleFrom(
                      //       backgroundColor: currentSortBy == "distance"
                      //           ? Colors.green
                      //           : null,
                      //       foregroundColor: currentSortBy == "distance"
                      //           ? Colors.white
                      //           : null,
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: vehicles.isEmpty
                      ? const Center(child: Text('ไม่พบผลลัพธ์'))
                      : ListView.builder(
                          itemCount: vehicles.length,
                          itemBuilder: (context, index) {
                            final v = vehicles[index];

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
                                              height: 200,
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
                                              height: 200,
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
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(Icons.location_on,
                                                      size: 18,
                                                      color: Colors.redAccent),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      '${v['province']}, ${v['district']}, ${v['subdistrict']}',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                          fontSize: 15),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              if (v['distance_text'] != null &&
                                                  v['distance_text'] != '-')
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
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        maxLines: 1,
                                                      ),
                                                    ),
                                                  ],
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



 // Text(
                //   'ค้นหาด้วย: $searchQuery',
                //   style: const TextStyle(fontSize: 16, color: Colors.grey),
                // ),
                // Padding(
                //   padding: const EdgeInsets.all(10.0),
                //   child: Align(
                //     alignment: Alignment.centerLeft, // จัดให้ชิดซ้าย
                //     child: Wrap(
                //       spacing: 12,
                //       runSpacing: 12,
                //       children: [
                //         // 💡 ปุ่มเรียงราคา: มีแค่ปุ่มเดียวและสลับสถานะ
                //         ElevatedButton.icon(
                //           onPressed: _togglePriceOrder,
                //           icon: Icon(
                //             currentSortBy == "price" && currentOrder == "desc"
                //                 ? Icons.arrow_upward
                //                 : Icons.arrow_downward,
                //           ),
                //           label: Text(
                //             currentSortBy == "price" && currentOrder == "desc"
                //                 ? "ราคา: มาก → น้อย"
                //                 : "ราคา: น้อย → มาก",
                //           ),
                //           style: ElevatedButton.styleFrom(
                //             backgroundColor:
                //                 currentSortBy == "price" ? Colors.green : null,
                //             foregroundColor:
                //                 currentSortBy == "price" ? Colors.white : null,
                //           ),
                //         ),

                //         // 💡 ปุ่มเรียงรีวิว: สลับสถานะเหมือนกัน
                //         ElevatedButton.icon(
                //           onPressed: _toggleReviewOrder,
                //           icon: Icon(
                //             currentSortBy == "review" && currentOrder == "desc"
                //                 ? Icons.arrow_upward
                //                 : Icons.arrow_downward,
                //           ),
                //           label: Text(
                //             currentSortBy == "review" && currentOrder == "desc"
                //                 ? "รีวิว: มาก → น้อย"
                //                 : "รีวิว: น้อย → มาก",
                //           ),
                //           style: ElevatedButton.styleFrom(
                //             backgroundColor:
                //                 currentSortBy == "review" ? Colors.green : null,
                //             foregroundColor:
                //                 currentSortBy == "review" ? Colors.white : null,
                //           ),
                //         ),
                //       ],
                //     ),
                //   ),
                // ),
                // const SizedBox(height: 1),