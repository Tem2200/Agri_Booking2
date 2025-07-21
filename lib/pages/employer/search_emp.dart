import 'dart:convert';

import 'package:agri_booking2/pages/employer/DetailVehc_emp.dart';
import 'package:agri_booking2/pages/employer/searchEnter.dart';
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
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      await Future.wait([
        _loadFarms(),
        _loadVehicles(),
      ]);

      if (farmList.isNotEmpty) {
        selectedFarm = farmList[0];
        selectedFarmLat = _parseLatLng(selectedFarm['latitude']);
        selectedFarmLng = _parseLatLng(selectedFarm['longitude']);
        await _calculateDistances();
      } else {
        hasFarm = false;
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

  Future<void> _calculateDistances() async {
    if (selectedFarm == null ||
        selectedFarmLat == null ||
        selectedFarmLng == null) return;

    setState(() => isLoading = true);

    try {
      var destinationsVehicles = allVehicles
          .where((v) {
            final lat = _parseLatLng(v['latitude']);
            final lng = _parseLatLng(v['longitude']);
            return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
          })
          .take(20)
          .toList();

      if (destinationsVehicles.isEmpty) {
        filteredVehicles = [];
        return;
      }

      const apiKey =
          'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6ImMyOWE5ZDkxMmUyZDQzMDc4ODNlZWQ0MjQzZDQ2NTk1IiwiaCI6Im11cm11cjY0In0=';

      await Future.wait(destinationsVehicles.map((v) async {
        if (v['distance_cache'] != null) {
          v['distance_text'] = v['distance_cache']['text'];
          v['distance_value'] = v['distance_cache']['value'];
          return;
        }

        final endLat = _parseLatLng(v['latitude']);
        final endLng = _parseLatLng(v['longitude']);

        final url = Uri.parse(
            'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$apiKey&start=$selectedFarmLng,$selectedFarmLat&end=$endLng,$endLat');

        try {
          final res = await http.get(url);
          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);
            final meters =
                data['features'][0]['properties']['segments'][0]['distance'];
            final km = meters / 1000;
            v['distance_text'] = '${km.toStringAsFixed(2)} กม.';
            v['distance_value'] = km;
            v['distance_cache'] = {
              'text': v['distance_text'],
              'value': km,
            };
          } else {
            print('OpenRoute API error: ${res.body}');
            v['distance_text'] = '-';
            v['distance_value'] = double.infinity;
          }
        } catch (e) {
          v['distance_text'] = '-';
          v['distance_value'] = double.infinity;
        }
      }));

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('ค้นหารถรับจ้าง'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'ค้นหา',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _onSearch,
                ),
              ),
              onSubmitted: (_) => _onSearch(),
            ),
            const SizedBox(height: 16),
            if (farmList.isEmpty)
              const Text('ไม่มีฟาร์มที่บันทึกไว้ กรุณาเพิ่มฟาร์มที่เมนู "ฉัน"')
            else
              const Text('เลือกฟาร์มที่ต้องการค้นหารถรับจ้าง'),
            if (hasFarm) ...[
              DropdownButtonFormField<dynamic>(
                value: selectedFarm,
                items: farmList.map<DropdownMenuItem<dynamic>>((farm) {
                  return DropdownMenuItem(
                    value: farm,
                    child: Text(farm['name_farm'] ?? '-'),
                  );
                }).toList(),
                onChanged: farmList.isEmpty
                    ? null
                    : (value) {
                        setState(() {
                          selectedFarm = value;
                          selectedFarmLat = _parseLatLng(value['latitude']);
                          selectedFarmLng = _parseLatLng(value['longitude']);
                        });
                        _calculateDistances();
                      },
                decoration: const InputDecoration(
                  labelText: 'เลือกฟาร์ม',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredVehicles.isEmpty
                      ? Center(
                          child: hasFarm
                              ? const Text(
                                  'ไม่พบรถที่สามารถคำนวณระยะทางได้ หรือพิกัดผิด')
                              : const Text('ไม่พบข้อมูลรถที่ตรงกับการค้นหา'),
                        )
                      : ListView.builder(
                          itemCount: filteredVehicles.length,
                          itemBuilder: (context, index) {
                            final v = filteredVehicles[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                leading: v['image'] != null
                                    ? CachedNetworkImage(
                                        imageUrl: v['image'],
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            const CircularProgressIndicator(),
                                        errorWidget: (context, url, error) =>
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
                                        'ราคา: ${v['price'] ?? '-'} บาท/${v['unit_price'] ?? '-'}'),
                                    Text(
                                        'คะแนนเฉลี่ยรีวิว: ${v['avg_review_point'] ?? '-'}'),
                                    if (hasFarm)
                                      Text(
                                        'ระยะทาง: ${v['distance_text'] ?? '-'}',
                                      ),
                                    const SizedBox(height: 8),
                                    OutlinedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => DetailvehcEmp(
                                              vid: v['vid'] ?? 0,
                                              mid: widget.mid,
                                              fid: selectedFarm?['fid'] ?? 0,
                                              farm: selectedFarm,
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Text('รายละเอียดเพิ่มเติม'),
                                    ),
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
      ),
    );
  }
}
