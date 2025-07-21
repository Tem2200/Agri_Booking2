import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MapFarm extends StatefulWidget {
  const MapFarm({super.key});

  @override
  State<MapFarm> createState() => _MapFarmState();
}

class _MapFarmState extends State<MapFarm> {
  Completer<GoogleMapController> _controller = Completer();
  Marker? _selectedMarker;
  LatLng? _initialPosition;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedMarker(); // โหลดพิกัดที่เคยบันทึกไว้
  }

  Future<void> _loadSavedMarker() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('saved_lat');
    final lng = prefs.getDouble('saved_lng');

    if (lat != null && lng != null) {
      _initialPosition = LatLng(lat, lng);
      setState(() {
        _selectedMarker = Marker(
          markerId: const MarkerId('saved_location'),
          position: _initialPosition!,
        );
      });
    } else {
      _getCurrentLocation(); // ถ้าไม่มีให้ใช้ตำแหน่งปัจจุบัน
    }
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return;

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _initialPosition = LatLng(position.latitude, position.longitude);
    });
    final controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newLatLngZoom(_initialPosition!, 15),
    );
  }

  void _onMapTap(LatLng latLng) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('saved_lat', latLng.latitude);
    await prefs.setDouble('saved_lng', latLng.longitude);

    setState(() {
      _selectedMarker = Marker(
        markerId: const MarkerId('selected_location'),
        position: latLng,
      );
    });
  }

  Future<void> _searchPlace(String query) async {
    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final location = locations.first;
        LatLng latLng = LatLng(location.latitude, location.longitude);

        final controller = await _controller.future;
        controller.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));

        _onMapTap(latLng); // ใช้ _onMapTap เพื่อบันทึกหมุดและแสดง
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่พบสถานที่: $e')),
      );
    }
  }

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

  @override
  Widget build(BuildContext context) {
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
      body: _initialPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _searchPlace(searchController.text),
                        label: const Text('ค้นหา'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFFFFCC99), // สีพื้นหลัง
                          foregroundColor: Colors.black, // สีข้อความและไอคอน
                        ),
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: GoogleMap(
                    mapType: MapType.satellite,
                    initialCameraPosition:
                        CameraPosition(target: _initialPosition!, zoom: 15),
                    onMapCreated: (controller) =>
                        _controller.complete(controller),
                    onTap: _onMapTap,
                    markers: _selectedMarker != null
                        ? {_selectedMarker!}
                        : <Marker>{},
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                  ),
                ),
              ],
            ),
    );
  }
}
