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
        title: const Text('ผลการค้นหา'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'ค้นหารถ เช่น ชื่อรถ หรือจังหวัด',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: Icon(
                    _priceOrder == 'DECS'
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                  ),
                  onPressed: _togglePriceOrder,
                  tooltip:
                      _priceOrder == 'DECS' ? 'ราคาสูง → ต่ำ' : 'ราคาต่ำ → สูง',
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
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
                                horizontal: 10, vertical: 5),
                            child: ListTile(
                              leading: SizedBox(
                                width: 60,
                                height: 60,
                                child: Image.network(
                                  vehicle['image'] ?? '',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.broken_image, size: 60),
                                ),
                              ),
                              title:
                                  Text(vehicle['name_vehicle'] ?? 'ไม่มีชื่อ'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      '${vehicle['price']} บาท/${vehicle['unit_price']}'),
                                  Text(
                                      'โดย: ${vehicle['username_contractor']}'),
                                  Text(
                                      '${vehicle['subdistrict']} ,${vehicle['district']} ,${vehicle['province']}'),
                                  Text(
                                      'คะแนนเฉลี่ย: ${vehicle['avg_review_point']}'),
                                ],
                              ),
                              isThreeLine: true,
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
