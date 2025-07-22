import 'dart:convert';
import 'package:agri_booking2/pages/employer/DetailVehc_emp.dart';
import 'package:agri_booking2/pages/employer/Tabbar.dart';
import 'package:agri_booking2/pages/employer/search_emp.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
        backgroundColor: Color.fromARGB(255, 18, 143, 9),
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
                                                  'ผู้รับจ้าง: ${v['username_contractor'] ?? '-'}',
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
                                                'คะแนนเฉลี่ยรีวิว: ${v['avg_review_point'] ?? '-'}',
                                                style: const TextStyle(
                                                    fontSize: 14),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
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
