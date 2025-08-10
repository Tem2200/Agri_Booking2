// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:geolocator/geolocator.dart';

// class MapRegister extends StatefulWidget {
//   const MapRegister({super.key});

//   @override
//   State<MapRegister> createState() => _MapRegisterState();
// }

// class _MapRegisterState extends State<MapRegister> {
//   Completer<GoogleMapController> _controller = Completer();
//   Marker? _selectedMarker;
//   LatLng _initialPosition = const LatLng(13.7563, 100.5018); // Default: Bangkok
//   TextEditingController searchController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     _getCurrentLocation();
//   }

//   Future<void> _getCurrentLocation() async {
//     LocationPermission permission = await Geolocator.requestPermission();
//     if (permission == LocationPermission.denied) return;

//     Position position = await Geolocator.getCurrentPosition();
//     setState(() {
//       _initialPosition = LatLng(position.latitude, position.longitude);
//     });
//     final controller = await _controller.future;
//     controller.animateCamera(
//       CameraUpdate.newLatLngZoom(_initialPosition, 15),
//     );
//   }

//   void _onMapTap(LatLng latLng) {
//     setState(() {
//       _selectedMarker = Marker(
//         markerId: const MarkerId('selected_location'),
//         position: latLng,
//       );
//     });
//   }

//   Future<void> _searchPlace(String query) async {
//     try {
//       List<Location> locations = await locationFromAddress(query);
//       if (locations.isNotEmpty) {
//         final location = locations.first;
//         LatLng latLng = LatLng(location.latitude, location.longitude);

//         final controller = await _controller.future;
//         controller.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));

//         setState(() {
//           _selectedMarker = Marker(
//             markerId: const MarkerId('searched_location'),
//             position: latLng,
//           );
//         });
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('ไม่พบสถานที่: $e')),
//       );
//     }
//   }

//   void _confirmLocation() {
//     if (_selectedMarker != null) {
//       Navigator.pop(context, {
//         'lat': _selectedMarker!.position.latitude,
//         'lng': _selectedMarker!.position.longitude,
//       });
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('กรุณาเลือกตำแหน่งบนแผนที่')),
//       );
//     }
//   }

//   void _onMapCreated(GoogleMapController controller) {
//     _controller.complete(controller);
//     setState(() {
//       _selectedMarker = Marker(
//         markerId: const MarkerId('test_marker'),
//         position: _initialPosition,
//       );
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('เลือกตำแหน่งบนแผนที่'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.check),
//             onPressed: _confirmLocation,
//           )
//         ],
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: searchController,
//                     decoration: const InputDecoration(
//                       hintText: 'ค้นหาสถานที่',
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 ElevatedButton(
//                   onPressed: () => _searchPlace(searchController.text),
//                   child: const Text('ค้นหา'),
//                 )
//               ],
//             ),
//           ),
//           Expanded(
//             child: GoogleMap(
//               initialCameraPosition:
//                   CameraPosition(target: _initialPosition, zoom: 15),
//               onMapCreated: _onMapCreated,
//               onTap: _onMapTap,
//               markers:
//                   _selectedMarker != null ? {_selectedMarker!} : <Marker>{},
//               myLocationEnabled: true,
//               myLocationButtonEnabled: true,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class MapRegister extends StatefulWidget {
  const MapRegister({super.key});

  @override
  State<MapRegister> createState() => _MapRegisterState();
}

class _MapRegisterState extends State<MapRegister> {
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
        backgroundColor: const Color.fromARGB(255, 18, 143, 9),
        centerTitle: true, // ✅ บังคับให้อยู่ตรงกลาง
        title: const Text(
          'เลือกตำแหน่งบนแผนที่',
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
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
                              Color.fromARGB(255, 255, 158, 60), // สีพื้นหลัง
                          foregroundColor: const Color.fromARGB(
                              255, 255, 254, 254), // สีข้อความและไอคอน
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
