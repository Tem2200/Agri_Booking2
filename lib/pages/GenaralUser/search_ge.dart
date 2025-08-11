// หน้า search_ge.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SearchGe extends StatefulWidget {
  final String keyword;
  final String initialOrder;

  const SearchGe(
      {super.key, required this.keyword, required this.initialOrder});

  @override
  State<SearchGe> createState() => _SearchGeState();
}

class _SearchGeState extends State<SearchGe> {
  List<dynamic> vehicles = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  // ตัวแปรสำหรับสถานะการเรียง
  String currentSortBy = "price"; // 'price' หรือ 'review'
  String currentOrder = "asc"; // 'asc' หรือ 'desc'

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.keyword;
    fetchVehicles(searchKeyword: widget.keyword);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
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
          "order": widget.initialOrder,
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          vehicles = data;
          isLoading = false;
        });
        _sortVehicles(); // เรียกใช้ฟังก์ชันเรียงลำดับเมื่อได้ข้อมูลมาแล้ว
      } else {
        throw Exception('โหลดข้อมูลไม่สำเร็จ');
      }
    } catch (e) {
      print("เกิดข้อผิดพลาด: $e");
      setState(() => isLoading = false);
    }
  }

  void _sortVehicles() {
    setState(() {
      if (currentSortBy == "price") {
        vehicles.sort((a, b) {
          final aPrice = double.tryParse(a['price']?.toString() ?? '0') ?? 0.0;
          final bPrice = double.tryParse(b['price']?.toString() ?? '0') ?? 0.0;
          return currentOrder == "asc"
              ? aPrice.compareTo(bPrice)
              : bPrice.compareTo(aPrice);
        });
      } else if (currentSortBy == "review") {
        vehicles.sort((a, b) {
          final aReview =
              double.tryParse(a['avg_review_point']?.toString() ?? '0') ?? 0.0;
          final bReview =
              double.tryParse(b['avg_review_point']?.toString() ?? '0') ?? 0.0;
          return currentOrder == "asc"
              ? aReview.compareTo(bReview)
              : bReview.compareTo(aReview);
        });
      }
    });
  }

  void _togglePriceOrder() {
    setState(() {
      if (currentSortBy == "price") {
        currentOrder = currentOrder == "asc" ? "desc" : "asc";
      } else {
        currentSortBy = "price";
        currentOrder = "asc"; // ตั้งค่าเริ่มต้นเป็น น้อยไปมาก
      }
      _sortVehicles();
    });
  }

  void _toggleReviewOrder() {
    setState(() {
      if (currentSortBy == "review") {
        currentOrder = currentOrder == "asc" ? "desc" : "asc";
      } else {
        currentSortBy = "review";
        currentOrder =
            "desc"; // ตั้งค่าเริ่มต้นเป็น มากไปน้อย (นิยมสำหรับรีวิว)
      }
      _sortVehicles();
    });
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
            shadows: [
              Shadow(
                color: Color.fromARGB(115, 253, 237, 237),
                blurRadius: 3,
                offset: Offset(1.5, 1.5),
              ),
            ],
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
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
                      if (keyword.isNotEmpty) {
                        fetchVehicles(searchKeyword: keyword);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  //icon: const Icon(Icons.search),
                  label: const Text("ค้นหา"),
                  onPressed: () {
                    final keyword = _searchController.text.trim();
                    if (keyword.isNotEmpty) {
                      fetchVehicles(searchKeyword: keyword);
                    }
                  },
                ),
              ],
            ),
          ),
          // 💡 ส่วนนี้คือปุ่มเรียงลำดับที่เพิ่มเข้ามา
          // Padding(
          //   padding: const EdgeInsets.all(8.0),
          //   child: Wrap(
          //     spacing: 8.0,
          //     runSpacing: 8.0,
          //     children: [
          //       ElevatedButton.icon(
          //         onPressed: _togglePriceOrder,
          //         icon: Icon(
          //           currentSortBy == "price" && currentOrder == "asc"
          //               ? Icons.arrow_downward
          //               : Icons.arrow_upward,
          //         ),
          //         label: Text(
          //           currentSortBy == "price" && currentOrder == "asc"
          //               ? "ราคา: น้อย → มาก"
          //               : "ราคา: มาก → น้อย",
          //         ),
          //         style: ElevatedButton.styleFrom(
          //           backgroundColor:
          //               currentSortBy == "price" ? Colors.green : null,
          //           foregroundColor:
          //               currentSortBy == "price" ? Colors.white : null,
          //         ),
          //       ),
          //       ElevatedButton.icon(
          //         onPressed: _toggleReviewOrder,
          //         icon: Icon(
          //           currentSortBy == "review" && currentOrder == "desc"
          //               ? Icons.arrow_downward
          //               : Icons.arrow_upward,
          //         ),
          //         label: Text(
          //           currentSortBy == "review" && currentOrder == "desc"
          //               ? "รีวิว: มาก → น้อย"
          //               : "รีวิว: น้อย → มาก",
          //         ),
          //         style: ElevatedButton.styleFrom(
          //           backgroundColor:
          //               currentSortBy == "review" ? Colors.green : null,
          //           foregroundColor:
          //               currentSortBy == "review" ? Colors.white : null,
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _togglePriceOrder,
                    icon: Icon(
                      currentSortBy == "price" && currentOrder == "asc"
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                    ),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        currentSortBy == "price" && currentOrder == "asc"
                            ? "ราคา: น้อย → มาก"
                            : "ราคา: มาก → น้อย",
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
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _toggleReviewOrder,
                    icon: Icon(
                      currentSortBy == "review" && currentOrder == "desc"
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                    ),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        currentSortBy == "review" && currentOrder == "desc"
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
              ],
            ),
          ),

          const SizedBox(height: 16),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : vehicles.isEmpty
                    ? const Center(child: Text('ไม่พบข้อมูลรถ'))
                    : ListView.builder(
                        itemCount: vehicles.length,
                        itemBuilder: (context, index) {
                          final vehicle = vehicles[index];
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
                                      height: 140,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const SizedBox(
                                        width: 100,
                                        height: 140,
                                        child: Icon(Icons.broken_image,
                                            size: 48, color: Colors.grey),
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
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.person,
                                                size: 18,
                                                color: Colors.blueGrey),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                'ผู้รับจ้าง: ${vehicle['username']}',
                                                style: const TextStyle(
                                                    fontSize: 15),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.attach_money,
                                                size: 18, color: Colors.green),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                '${vehicle['price']} บาท/${vehicle['unit_price']}',
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                overflow: TextOverflow
                                                    .ellipsis, // ตัดเป็น ...
                                                maxLines:
                                                    1, // ให้แสดงแค่บรรทัดเดียว
                                                softWrap: false, // ไม่ตัดบรรทัด
                                              ),
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
                                                '${vehicle['province']},${vehicle['district']},${vehicle['subdistrict']}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    fontSize: 15),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.star,
                                                size: 18, color: Colors.amber),
                                            const SizedBox(width: 6),
                                            Text(
                                              'คะแนนรีวิว: ${double.tryParse(vehicle['avg_review_point'] ?? '0')?.toStringAsFixed(2) ?? '0.00'}',
                                              style:
                                                  const TextStyle(fontSize: 15),
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
          ),
        ],
      ),
    );
  }
}





// // หน้า search_ge.dart
// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;

// class SearchGe extends StatefulWidget {
//   final String keyword;
//   final String initialOrder;

//   const SearchGe(
//       {super.key, required this.keyword, required this.initialOrder});

//   @override
//   State<SearchGe> createState() => _SearchGeState();
// }

// class _SearchGeState extends State<SearchGe> {
//   List<dynamic> vehicles = [];
//   bool isLoading = true;
//   final TextEditingController _searchController = TextEditingController();
//   Timer? _debounce;
//   late String _priceOrder;

//   // เพิ่มตัวแปรสถานะการเรียง
//   late String _currentOrder; // 'ASC' หรือ 'DESC'
//   String _currentSortKey = 'price'; // 'price', 'review'
//   String searchQuery = "";
//   String currentSortBy = "price";

//   @override
//   void initState() {
//     super.initState();
//     _priceOrder = widget.initialOrder;
//     _searchController.text = widget.keyword;
//     fetchVehicles(searchKeyword: widget.keyword);
//   }

//   @override
//   void dispose() {
//     _debounce?.cancel();
//     _searchController.dispose();
//     super.dispose();
//   }

//   Future<void> fetchVehicles({required String searchKeyword}) async {
//     setState(() => isLoading = true);

//     final url = Uri.parse(
//         'http://projectnodejs.thammadalok.com/AGribooking/search_vehicle');

//     try {
//       final response = await http.post(
//         url,
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode({
//           "keyword": searchKeyword,
//           "order": _priceOrder,
//         }),
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         setState(() {
//           vehicles = data;
//           print("Fetched vehicles: $vehicles");
//           isLoading = false;
//         });
//       } else {
//         throw Exception('โหลดข้อมูลไม่สำเร็จ');
//       }
//     } catch (e) {
//       print("เกิดข้อผิดพลาด: $e");
//       setState(() => isLoading = false);
//     }
//   }

//   void _onSearchChanged(String text) {
//     if (_debounce?.isActive ?? false) _debounce!.cancel();

//     _debounce = Timer(const Duration(milliseconds: 500), () {
//       fetchVehicles(searchKeyword: text.trim());
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: const Color.fromARGB(255, 18, 143, 9),
//         centerTitle: true,
//         title: const Text(
//           'ผลการค้นหา',
//           style: TextStyle(
//             fontSize: 22,
//             fontWeight: FontWeight.bold,
//             color: Color.fromARGB(255, 255, 255, 255),
//             //letterSpacing: 1,
//             shadows: [
//               Shadow(
//                 color: Color.fromARGB(115, 253, 237, 237),
//                 blurRadius: 3,
//                 offset: Offset(1.5, 1.5),
//               ),
//             ],
//           ),
//         ),
//         iconTheme: const IconThemeData(
//           color: Colors.white, // ✅ ลูกศรย้อนกลับสีขาว
//         ),
//       ),
//       body: Column(
//         children: [
//           const SizedBox(height: 16),
//           Padding(
//             padding: const EdgeInsets.all(8),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _searchController,
//                     decoration: const InputDecoration(
//                       labelText: 'ค้นหารถ เช่น ชื่อรถ หรือจังหวัด',
//                       border: OutlineInputBorder(),
//                       prefixIcon: Icon(Icons.search),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 ElevatedButton.icon(
//                   icon: const Icon(Icons.search),
//                   label: const Text("ค้นหา"),
//                   onPressed: () {
//                     final keyword = _searchController.text.trim();
//                     if (keyword.isNotEmpty) {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) => SearchGe(
//                             keyword: keyword,
//                             initialOrder: _priceOrder,
//                           ),
//                         ),
//                       );
//                     }
//                   },
//                 ),
//               ],
//             ),
//           ),
//           Expanded(
//             child: isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : vehicles.isEmpty
//                     ? const Center(child: Text('ไม่พบข้อมูลรถ'))
//                     : ListView.builder(
//                         itemCount: vehicles.length,
//                         itemBuilder: (context, index) {
//                           final vehicle = vehicles[index];
//                           return Card(
//                             margin: const EdgeInsets.symmetric(
//                                 horizontal: 20, vertical: 12),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             elevation: 4,
//                             child: Container(
//                               decoration: BoxDecoration(
//                                 color: Colors.orange[50],
//                                 border: Border.all(color: Colors.orange),
//                                 borderRadius: BorderRadius.circular(12),
//                                 boxShadow: [
//                                   BoxShadow(
//                                     color: Colors.orange.withOpacity(0.3),
//                                     spreadRadius: 1,
//                                     blurRadius: 8,
//                                     offset: const Offset(0, 4),
//                                   ),
//                                 ],
//                               ),
//                               padding: const EdgeInsets.all(12),
//                               child: Row(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   ClipRRect(
//                                     borderRadius: BorderRadius.circular(10),
//                                     child: Image.network(
//                                       vehicle['image'] ?? '',
//                                       width: 120,
//                                       height: 180,
//                                       fit: BoxFit.cover,
//                                       errorBuilder:
//                                           (context, error, stackTrace) =>
//                                               const SizedBox(
//                                         width: 100,
//                                         height: 180,
//                                         child: Icon(Icons.broken_image,
//                                             size: 48, color: Colors.grey),
//                                       ),
//                                     ),
//                                   ),
//                                   const SizedBox(width: 12),
//                                   Expanded(
//                                     child: Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Text(
//                                           vehicle['name_vehicle'] ??
//                                               'ไม่มีชื่อ',
//                                           style: const TextStyle(
//                                             fontSize: 18,
//                                             fontWeight: FontWeight.bold,
//                                             color: Color(0xFF333333),
//                                           ),
//                                         ),
//                                         const SizedBox(height: 4),
//                                         Row(
//                                           children: [
//                                             const Icon(Icons.person,
//                                                 size: 18,
//                                                 color: Colors.blueGrey),
//                                             const SizedBox(width: 6),
//                                             Expanded(
//                                               child: Text(
//                                                 'ผู้รับจ้าง: ${vehicle['username']}',
//                                                 style: const TextStyle(
//                                                     fontSize: 15),
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                         const SizedBox(height: 4),
//                                         Row(
//                                           children: [
//                                             const Icon(Icons.attach_money,
//                                                 size: 18, color: Colors.green),
//                                             const SizedBox(width: 6),
//                                             Text(
//                                               '${vehicle['price']} บาท/${vehicle['unit_price']}',
//                                               style: const TextStyle(
//                                                 fontSize: 15,
//                                                 color: Colors.green,
//                                                 fontWeight: FontWeight.w600,
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                         const SizedBox(height: 4),
//                                         Row(
//                                           children: [
//                                             const Icon(Icons.location_on,
//                                                 size: 18,
//                                                 color: Colors.redAccent),
//                                             const SizedBox(width: 6),
//                                             Expanded(
//                                               child: Text(
//                                                 '${vehicle['subdistrict']} ,${vehicle['district']} ,${vehicle['province']}',
//                                                 style: const TextStyle(
//                                                     fontSize: 15),
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                         const SizedBox(height: 4),
//                                         Row(
//                                           children: [
//                                             const Icon(Icons.star,
//                                                 size: 18, color: Colors.amber),
//                                             const SizedBox(width: 6),
//                                             Text(
//                                               'คะแนนรีวิว: ${double.tryParse(vehicle['avg_review_point'] ?? '0')?.toStringAsFixed(2) ?? '0.00'}',
//                                               style:
//                                                   const TextStyle(fontSize: 15),
//                                             ),
//                                           ],
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//           ),
//         ],
//       ),
//     );
//   }
// }