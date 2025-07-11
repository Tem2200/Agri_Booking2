import 'dart:convert';
import 'package:agri_booking2/pages/employer/DetailVehc_emp.dart';
import 'package:agri_booking2/pages/employer/search_emp.dart';
import 'package:flutter/material.dart';
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
  bool isLoading = false;
  List<dynamic> vehicles = [];
  String currentOrder = "asc";
  bool sortByDistance = false;

  double? userLat;
  double? userLng;

  @override
  void initState() {
    super.initState();
    currentOrder = widget.payload["order"] ?? "asc";
    userLat = widget.payload["latitude"];
    userLng = widget.payload["longitude"];
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
        "mid": widget.mid,
        ...widget.payload,
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
        title: const Text('ผลการค้นหา'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SearchEmp(
                  mid: widget.mid,
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
                  padding: const EdgeInsets.all(16.0),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _togglePriceOrder,
                        icon: Icon(
                          currentOrder == "asc"
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                        ),
                        label: Text(
                          currentOrder == "asc"
                              ? "ราคา: น้อย → มาก"
                              : "ราคา: มาก → น้อย",
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _sortByDistance,
                        icon: const Icon(Icons.route),
                        label: const Text("เรียงตามระยะทาง"),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: vehicles.isEmpty
                      ? const Center(child: Text('ไม่พบผลลัพธ์'))
                      : ListView.builder(
                          itemCount: vehicles.length,
                          itemBuilder: (context, index) {
                            final v = vehicles[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),
                              child: ListTile(
                                leading: v['image'] != null
                                    ? Image.network(
                                        v['image'],
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                                Icons.image_not_supported),
                                      )
                                    : const Icon(Icons.agriculture, size: 50),
                                title: Text(v['name_vehicle'] ?? '-'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        'ผู้รับจ้าง: ${v['username_contractor'] ?? '-'}'),
                                    Text(
                                        'คะแนนเฉลี่ยรีวิว: ${v['avg_review_point'] ?? '-'}'),
                                    Text('ราคา: ${v['price'] ?? '-'} บาท'),
                                    if (v['distance_text'] != null)
                                      Text('ระยะทาง: ${v['distance_text']}'),
                                    const SizedBox(height: 8),
                                    OutlinedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => DetailvehcEmp(
                                              vid: v['vid'] ?? 0,
                                              mid: widget.mid,
                                              fid: (widget.payload['farm'] !=
                                                          null &&
                                                      widget.payload['farm']
                                                              ['fid'] !=
                                                          null)
                                                  ? widget.payload['farm']
                                                      ['fid'] as int
                                                  : 0,
                                              farm: widget.payload["farm"],
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Text('รายละเอียดเพิ่มเติม'),
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
