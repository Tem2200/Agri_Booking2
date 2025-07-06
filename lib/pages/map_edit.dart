import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
// import 'package:shared_preferences/shared_preferences.dart'; // ไม่ใช้ SharedPreferences แล้ว

class MapEdit extends StatefulWidget {
  // เพิ่มตัวแปรสำหรับรับค่าละติจูดและลองจิจูดเริ่มต้น
  final double? initialLat;
  final double? initialLng;

  const MapEdit({
    super.key,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<MapEdit> createState() => _MapEditState();
}

class _MapEditState extends State<MapEdit> {
  Completer<GoogleMapController> _controller = Completer();
  Marker? _selectedMarker; // หมุดที่ผู้ใช้เลือกหรือค้นหา
  late LatLng _initialCameraPosition; // ตำแหน่งเริ่มต้นของกล้องแผนที่
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // กำหนดตำแหน่งเริ่มต้นของกล้อง
    // ถ้ามี initialLat/Lng ส่งมา ให้ใช้ค่านั้น
    if (widget.initialLat != null && widget.initialLng != null) {
      _initialCameraPosition = LatLng(widget.initialLat!, widget.initialLng!);
      // ตั้งค่าหมุดที่เลือกเริ่มต้นหากมีตำแหน่งส่งมา
      _selectedMarker = Marker(
        markerId: const MarkerId('initial_location'),
        position: _initialCameraPosition,
      );
    } else {
      // ถ้าไม่มีตำแหน่งส่งมา ให้ตั้งค่าเริ่มต้นชั่วคราวและดึงตำแหน่งปัจจุบัน
      _initialCameraPosition = const LatLng(
          13.7563, 100.5018); // Default: Bangkok (ค่าเริ่มต้นชั่วคราว)
      _getCurrentLocation(); // เรียกฟังก์ชันเพื่อดึงตำแหน่งปัจจุบัน
    }
  }

  // ฟังก์ชันสำหรับดึงตำแหน่งปัจจุบันของผู้ใช้
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // ตรวจสอบว่า Location services เปิดอยู่หรือไม่
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเปิด Location services')),
      );
      return;
    }

    // ตรวจสอบสิทธิ์การเข้าถึงตำแหน่ง
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่ได้รับอนุญาตให้เข้าถึงตำแหน่ง')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'ไม่ได้รับอนุญาตให้เข้าถึงตำแหน่งถาวร กรุณาไปตั้งค่าในแอป')),
      );
      return;
    }

    // ดึงตำแหน่งปัจจุบัน
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high, // เพิ่มความแม่นยำ
    );

    // อัปเดตตำแหน่งเริ่มต้นของกล้องและหมุดที่เลือกเป็นตำแหน่งปัจจุบัน
    setState(() {
      _initialCameraPosition = LatLng(position.latitude, position.longitude);
      _selectedMarker = Marker(
        markerId: const MarkerId('current_location'),
        position: _initialCameraPosition,
      );
    });

    // เลื่อนกล้องไปยังตำแหน่งปัจจุบันทันทีที่ Controller พร้อม
    if (_controller.isCompleted) {
      final controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(_initialCameraPosition, 15),
      );
    }
  }

  // ฟังก์ชันเมื่อผู้ใช้แตะบนแผนที่
  void _onMapTap(LatLng latLng) async {
    setState(() {
      _selectedMarker = Marker(
        markerId: const MarkerId('selected_location'),
        position: latLng,
      );
    });

    // เลื่อนกล้องไปยังตำแหน่งที่เพิ่งปักหมุด
    final controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newLatLng(latLng),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'เลือกตำแหน่ง: ${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}')),
    );
  }

  // ฟังก์ชันสำหรับค้นหาสถานที่
  Future<void> _searchPlace(String query) async {
    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final location = locations.first;
        LatLng latLng = LatLng(location.latitude, location.longitude);

        final controller = await _controller.future;
        controller.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));

        setState(() {
          _selectedMarker = Marker(
            markerId: const MarkerId('searched_location'),
            position: latLng,
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'พบสถานที่: ${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่พบสถานที่ที่ค้นหา')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการค้นหา: $e')),
      );
    }
  }

  // ฟังก์ชันสำหรับยืนยันตำแหน่งที่เลือกและส่งค่ากลับ
  void _confirmLocation() {
    if (_selectedMarker != null) {
      Navigator.pop(context, {
        'lat': _selectedMarker!.position.latitude,
        'lng': _selectedMarker!.position.longitude,
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกตำแหน่งบนแผนที่')),
      );
    }
  }

  // ฟังก์ชันเมื่อแผนที่ถูกสร้างขึ้น
  void _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
    // ไม่ต้องตั้งค่า _selectedMarker ที่นี่อีก เพราะทำใน initState หรือ _getCurrentLocation แล้ว
    // และการเลื่อนกล้องไปยังตำแหน่งเริ่มต้นก็ทำใน initState หรือ _getCurrentLocation
  }

  @override
  Widget build(BuildContext context) {
    // แสดง CircularProgressIndicator จนกว่า _initialCameraPosition จะถูกกำหนดค่า
    // ซึ่งจะเกิดขึ้นใน initState หรือ _getCurrentLocation
    if (_initialCameraPosition.latitude == 0 &&
        _initialCameraPosition.longitude == 0 &&
        widget.initialLat == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFFFCC99),
        title: const Text('เลือกตำแหน่งบนแผนที่'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _confirmLocation,
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: 'ค้นหาสถานที่',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _searchPlace, // ค้นหาเมื่อกด Enter
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _searchPlace(searchController.text),
                  child: const Text('ค้นหา'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFCC99), // สีพื้นหลัง
                    foregroundColor: Colors.black, // สีข้อความและไอคอน
                  ),
                )
              ],
            ),
          ),
          Expanded(
            child: GoogleMap(
              // ตำแหน่งเริ่มต้นของกล้องจะใช้ _initialCameraPosition
              initialCameraPosition:
                  CameraPosition(target: _initialCameraPosition, zoom: 15),
              onMapCreated: _onMapCreated,
              onTap: _onMapTap, // เมื่อแตะแผนที่ หมุดจะเปลี่ยน
              // markers จะอัปเดตตามค่าของ _selectedMarker ที่เปลี่ยนไป
              markers:
                  _selectedMarker != null ? {_selectedMarker!} : <Marker>{},
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
          ),
        ],
      ),
    );
  }
}
