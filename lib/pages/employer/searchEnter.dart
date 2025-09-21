import 'dart:convert';
import 'dart:math';
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
  bool hasFarm = true;
  List<dynamic> allVehicles = [];
  List<dynamic> filteredVehicles = [];
  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    print("Payload at initState: ${widget.payload}");
    print("Selected Farm Lat: ${widget.selectedFarmLat}");
    print("Selected Farm Lng: ${widget.selectedFarmLng}");
    currentOrder = widget.payload["order"] ?? "asc";
    userLat = widget.payload["latitude"];
    userLng = widget.payload["longitude"];
    searchQuery = widget.payload["keyword"] ?? "";
    _searchController.text = widget.payload["keyword"].toString();
    //fetchVehicles(searchKeyword: searchQuery);
    fetchVehicles(searchKeyword: searchQuery).then((_) {
      if (widget.selectedFarmLat != null && widget.selectedFarmLng != null) {
        _calculateDistances(); // คำนวณทันที แต่ไม่เรียง
      } else {
        hasFarm = false;
        _searchVehicle();
      }
    });
    //_searchVehicle();
  }

  void _togglePriceOrder() {
    setState(() {
      currentSortBy = "price";
      currentOrder = currentOrder == "asc" ? "desc" : "asc";

      filteredVehicles.sort((a, b) {
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
      currentSortBy = "review";
      currentOrder = currentOrder == "asc" ? "desc" : "asc";

      filteredVehicles.sort((a, b) {
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
          allVehicles = data; // 👈 อัปเดตด้วย
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
      // if (response.statusCode == 200) {
      //   final data = json.decode(response.body);
      //   setState(() {
      //     allVehicles = data;
      //     vehicles = data;
      //     isLoading = false;
      //   });
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          allVehicles = data;
          vehicles = data; // สำหรับ UI legacy
          filteredVehicles = data.take(20).toList(); // สำหรับ distance
        });
        await _calculateDistances(); // คำนวณระยะทาง
      } else {
        throw Exception('โหลดข้อมูลไม่สำเร็จ');
      }
    } catch (e) {
      print("เกิดข้อผิดพลาด: $e");
      setState(() => isLoading = false);
    }
  }

  double _parseLatLng(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  Future<void> _calculateDistances() async {
    if (widget.selectedFarmLat == null || widget.selectedFarmLng == null)
      return;

    setState(() => isLoading = true);

    try {
      var destinationsVehicles = allVehicles.where((v) {
        final lat = _parseLatLng(v['latitude']);
        final lng = _parseLatLng(v['longitude']);
        return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
      }).toList();

      if (destinationsVehicles.isEmpty) {
        filteredVehicles = [];
        return;
      }

      const batchSize = 5; // ยิงทีละ 5 request
      for (int i = 0; i < destinationsVehicles.length; i += batchSize) {
        final batch = destinationsVehicles.skip(i).take(batchSize).toList();

        await Future.wait(batch.map((v) async {
          if (v['distance_cache'] != null) {
            v['distance_text'] = v['distance_cache']['text'];
            v['distance_value'] = v['distance_cache']['value'];
            return;
          }

          final endLat = _parseLatLng(v['latitude']);
          final endLng = _parseLatLng(v['longitude']);
          final url = Uri.parse(
              'https://router.project-osrm.org/route/v1/driving/'
              '${widget.selectedFarmLng},${widget.selectedFarmLat};$endLng,$endLat'
              '?overview=false');

          try {
            final res = await http.get(url);
            if (res.statusCode == 200) {
              final data = jsonDecode(res.body);
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
          } catch (e) {
            v['distance_text'] = '-';
            v['distance_value'] = double.infinity;
          }
        }));

        // update UI หลัง batch เสร็จ
        setState(() {
          filteredVehicles = List.from(destinationsVehicles);
        });
      }

      // เรียงตามระยะทาง
      filteredVehicles.sort((a, b) =>
          (a['distance_value'] ?? 0).compareTo(b['distance_value'] ?? 0));
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _toggleDistanceOrder() {
    setState(() {
      currentSortBy = "distance";
      currentOrder = currentOrder == "asc" ? "desc" : "asc";
    });

    if (filteredVehicles.isNotEmpty) {
      filteredVehicles.sort((a, b) {
        final aVal = a['distance_value'] ?? double.infinity;
        final bVal = b['distance_value'] ?? double.infinity;
        return currentOrder == "asc"
            ? aVal.compareTo(bVal)
            : bVal.compareTo(aVal);
      });
    }
  }

  void _toggleDistanceOrder() {
    setState(() {
      currentSortBy = "distance";
      currentOrder = currentOrder == "asc" ? "desc" : "asc";
    });

    if (filteredVehicles.isNotEmpty) {
      filteredVehicles.sort((a, b) {
        final aVal = a['distance_value'] ?? double.infinity;
        final bVal = b['distance_value'] ?? double.infinity;
        return currentOrder == "asc"
            ? aVal.compareTo(bVal)
            : bVal.compareTo(aVal);
      });
    }
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
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _togglePriceOrder,
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              currentSortBy == "price" && currentOrder == "desc"
                                  ? "ราคา: มาก → น้อย"
                                  : "ราคา: น้อย → มาก",
                              maxLines: 1,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                currentSortBy == "price" ? Colors.green : null,
                            foregroundColor:
                                currentSortBy == "price" ? Colors.white : null,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero, // ไม่มีโค้ง
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _toggleReviewOrder,
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              currentSortBy == "review" &&
                                      currentOrder == "desc"
                                  ? "รีวิว: มาก → น้อย"
                            foregroundColor:
                                currentSortBy == "review" ? Colors.white : null,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: (widget.selectedFarmLat != null &&
                                  widget.selectedFarmLng != null)
                              ? _toggleDistanceOrder
                              : null,
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              currentSortBy == "distance" &&
                                      currentOrder == "desc"
                                  ? "ระยะทาง: ไกล → ใกล้"
                                  : "ระยะทาง: ใกล้ → ไกล",
                              maxLines: 1,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: currentSortBy == "distance"
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: filteredVehicles.isEmpty
                      ? const Center(child: Text('ไม่พบข้อมูลรถ'))
                      : ListView.builder(
                          itemCount: filteredVehicles.length,
                          itemBuilder: (context, index) {
                            final v = filteredVehicles[
                                index]; // <-- ใช้ filteredVehicles

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
