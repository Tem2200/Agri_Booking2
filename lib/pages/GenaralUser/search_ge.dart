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
  late String _priceOrder;

  @override
  void initState() {
    super.initState();
    _priceOrder = widget.initialOrder;
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
          "order": _priceOrder,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          vehicles = data;
          print("Fetched vehicles: $vehicles");
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
      fetchVehicles(searchKeyword: text.trim());
    });
  }

  void _togglePriceOrder() {
    setState(() {
      _priceOrder = _priceOrder == 'DECS' ? 'ASC' : 'DECS';
    });
    fetchVehicles(searchKeyword: _searchController.text.trim());
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
        iconTheme: const IconThemeData(
          color: Colors.white, // ✅ ลูกศรย้อนกลับสีขาว
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
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
                IconButton(
                  icon: Icon(
                    _priceOrder == 'DECS'
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                  ),
                  onPressed: _togglePriceOrder,
                  tooltip:
                      _priceOrder == 'DECS' ? 'ราคาสูง → ต่ำ' : 'ราคาต่ำ → สูง',
                ),
              ],
            ),
          ),

          // Expanded(
          //   child: isLoading
          //       ? const Center(child: CircularProgressIndicator())
          //       : vehicles.isEmpty
          //           ? const Center(child: Text('ไม่พบข้อมูลรถ'))
          //           : ListView.builder(
          //               itemCount: vehicles.length,
          //               itemBuilder: (context, index) {
          //                 final vehicle = vehicles[index];
          //                 return Card(
          //                   margin: const EdgeInsets.symmetric(
          //                       horizontal: 10, vertical: 5),
          //                   child: ListTile(
          //                     leading: SizedBox(
          //                       width: 60,
          //                       height: 60,
          //                       child: Image.network(
          //                         vehicle['image'] ?? '',
          //                         fit: BoxFit.cover,
          //                         errorBuilder: (context, error, stackTrace) =>
          //                             const Icon(Icons.broken_image, size: 60),
          //                       ),
          //                     ),
          //                     title:
          //                         Text(vehicle['name_vehicle'] ?? 'ไม่มีชื่อ'),
          //                     subtitle: Column(
          //                       crossAxisAlignment: CrossAxisAlignment.start,
          //                       children: [
          //                         Text(
          //                             '${vehicle['price']} บาท/${vehicle['unit_price']}'),
          //                         Text(
          //                             'โดย: ${vehicle['username_contractor']}'),
          //                         Text(
          //                             '${vehicle['subdistrict']} ,${vehicle['district']} ,${vehicle['province']}'),
          //                         Text(
          //                             'คะแนนเฉลี่ย: ${vehicle['avg_review_point']}'),
          //                       ],
          //                     ),
          //                     isThreeLine: true,
          //                   ),
          //                 );
          //               },
          //             ),
          // ),

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
                                      height: 180,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const SizedBox(
                                        width: 100,
                                        height: 180,
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
                                        const SizedBox(height: 4),
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
                                            // Text(
                                            //   vehicle['avg_review_point'] ==
                                            //           null
                                            //       ? 'ยังไม่มีรีวิว'
                                            //       : 'คะแนนเฉลี่ย: ${(vehicle['avg_review_point']).toStringAsFixed(2)}',
                                            //   style:
                                            //       const TextStyle(fontSize: 15),
                                            // ),
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
