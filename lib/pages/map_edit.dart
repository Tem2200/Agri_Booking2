import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
// import 'package:shared_preferences/shared_preferences.dart'; // ไม่ใช้ SharedPreferences แล้ว
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  // Completer<GoogleMapController> _controller = Completer();
  // Marker? _selectedMarker; // หมุดที่ผู้ใช้เลือกหรือค้นหา
  // late LatLng _initialCameraPosition; // ตำแหน่งเริ่มต้นของกล้องแผนที่
  // TextEditingController searchController = TextEditingController();

  // @override
  // void initState() {
  //   super.initState();
  //   // กำหนดตำแหน่งเริ่มต้นของกล้อง
  //   // ถ้ามี initialLat/Lng ส่งมา ให้ใช้ค่านั้น
  //   if (widget.initialLat != null && widget.initialLng != null) {
  //     _initialCameraPosition = LatLng(widget.initialLat!, widget.initialLng!);
  //     // ตั้งค่าหมุดที่เลือกเริ่มต้นหากมีตำแหน่งส่งมา
  //     _selectedMarker = Marker(
  //       markerId: const MarkerId('initial_location'),
  //       position: _initialCameraPosition,
  //     );
  //   } else {
  //     // ถ้าไม่มีตำแหน่งส่งมา ให้ตั้งค่าเริ่มต้นชั่วคราวและดึงตำแหน่งปัจจุบัน
  //     _initialCameraPosition = const LatLng(
  //         13.7563, 100.5018); // Default: Bangkok (ค่าเริ่มต้นชั่วคราว)
  //     _getCurrentLocation(); // เรียกฟังก์ชันเพื่อดึงตำแหน่งปัจจุบัน
  //   }
  // }

  // // ฟังก์ชันสำหรับดึงตำแหน่งปัจจุบันของผู้ใช้
  // Future<void> _getCurrentLocation() async {
  //   bool serviceEnabled;
  //   LocationPermission permission;

  //   // ตรวจสอบว่า Location services เปิดอยู่หรือไม่
  //   serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //   if (!serviceEnabled) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('กรุณาเปิด Location services')),
  //     );
  //     return;
  //   }

  //   // ตรวจสอบสิทธิ์การเข้าถึงตำแหน่ง
  //   permission = await Geolocator.checkPermission();
  //   if (permission == LocationPermission.denied) {
  //     permission = await Geolocator.requestPermission();
  //     if (permission == LocationPermission.denied) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('ไม่ได้รับอนุญาตให้เข้าถึงตำแหน่ง')),
  //       );
  //       return;
  //     }
  //   }

  //   if (permission == LocationPermission.deniedForever) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //           content: Text(
  //               'ไม่ได้รับอนุญาตให้เข้าถึงตำแหน่งถาวร กรุณาไปตั้งค่าในแอป')),
  //     );
  //     return;
  //   }

  //   // ดึงตำแหน่งปัจจุบัน
  //   Position position = await Geolocator.getCurrentPosition(
  //     desiredAccuracy: LocationAccuracy.high, // เพิ่มความแม่นยำ
  //   );

  //   // อัปเดตตำแหน่งเริ่มต้นของกล้องและหมุดที่เลือกเป็นตำแหน่งปัจจุบัน
  //   setState(() {
  //     _initialCameraPosition = LatLng(position.latitude, position.longitude);
  //     _selectedMarker = Marker(
  //       markerId: const MarkerId('current_location'),
  //       position: _initialCameraPosition,
  //     );
  //   });

  //   // เลื่อนกล้องไปยังตำแหน่งปัจจุบันทันทีที่ Controller พร้อม
  //   if (_controller.isCompleted) {
  //     final controller = await _controller.future;
  //     controller.animateCamera(
  //       CameraUpdate.newLatLngZoom(_initialCameraPosition, 15),
  //     );
  //   }
  // }

  // // ฟังก์ชันเมื่อผู้ใช้แตะบนแผนที่
  // void _onMapTap(LatLng latLng) async {
  //   setState(() {
  //     _selectedMarker = Marker(
  //       markerId: const MarkerId('selected_location'),
  //       position: latLng,
  //     );
  //   });

  //   // เลื่อนกล้องไปยังตำแหน่งที่เพิ่งปักหมุด
  //   final controller = await _controller.future;
  //   controller.animateCamera(
  //     CameraUpdate.newLatLng(latLng),
  //   );

  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //         content: Text(
  //             'เลือกตำแหน่ง: ${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}')),
  //   );
  // }

  // // ฟังก์ชันสำหรับค้นหาสถานที่
  // Future<void> _searchPlace(String query) async {
  //   try {
  //     List<Location> locations = await locationFromAddress(query);
  //     if (locations.isNotEmpty) {
  //       final location = locations.first;
  //       LatLng latLng = LatLng(location.latitude, location.longitude);

  //       final controller = await _controller.future;
  //       controller.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));

  //       setState(() {
  //         _selectedMarker = Marker(
  //           markerId: const MarkerId('searched_location'),
  //           position: latLng,
  //         );
  //       });
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //             content: Text(
  //                 'พบสถานที่: ${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}')),
  //       );
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('ไม่พบสถานที่ที่ค้นหา')),
  //       );
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('เกิดข้อผิดพลาดในการค้นหา: $e')),
  //     );
  //   }
  // }

  // // ฟังก์ชันสำหรับยืนยันตำแหน่งที่เลือกและส่งค่ากลับ
  // void _confirmLocation() {
  //   if (_selectedMarker != null) {
  //     Navigator.pop(context, {
  //       'lat': _selectedMarker!.position.latitude,
  //       'lng': _selectedMarker!.position.longitude,
  //     });
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('กรุณาเลือกตำแหน่งบนแผนที่')),
  //     );
  //   }
  // }

  // // ฟังก์ชันเมื่อแผนที่ถูกสร้างขึ้น
  // void _onMapCreated(GoogleMapController controller) {
  //   _controller.complete(controller);
  //   // ไม่ต้องตั้งค่า _selectedMarker ที่นี่อีก เพราะทำใน initState หรือ _getCurrentLocation แล้ว
  //   // และการเลื่อนกล้องไปยังตำแหน่งเริ่มต้นก็ทำใน initState หรือ _getCurrentLocation
  // }
  final Completer<GoogleMapController> _controller = Completer();
  Marker? _selectedMarker;
  LatLng? _initialPosition;
  TextEditingController searchController = TextEditingController();
  final Set<Marker> _placesMarkers = {};

  // ใส่ API Key Google Places API ของคุณตรงนี้
  final String googleApiKey = 'AIzaSyCjle5TSSjk8BnEI_mBrwAtVxrefVCMJAU';
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

  // Future<void> _searchPlace(String query) async {
  //   try {
  //     List<Location> locations = await locationFromAddress(query);
  //     if (locations.isNotEmpty) {
  //       final location = locations.first;
  //       LatLng latLng = LatLng(location.latitude, location.longitude);

  //       final controller = await _controller.future;
  //       controller.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));

  //       _onMapTap(latLng); // ใช้ _onMapTap เพื่อบันทึกหมุดและแสดง
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('ไม่พบสถานที่: $e')),
  //     );
  //   }
  // }
  Future<void> _searchPlace(String query) async {
    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่พบสถานที่')),
        );
        return;
      }

      if (locations.length == 1) {
        final location = locations.first;
        LatLng latLng = LatLng(location.latitude, location.longitude);
        final controller = await _controller.future;
        controller.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
        _onMapTap(latLng);
      } else {
        // Multiple locations found
        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return FutureBuilder<List<Placemark>>(
              future: Future.wait(locations.map((loc) async {
                final placemarks =
                    await placemarkFromCoordinates(loc.latitude, loc.longitude);
                return placemarks.first;
              })),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final placemarks = snapshot.data!;
                return ListView.builder(
                  itemCount: locations.length,
                  itemBuilder: (context, index) {
                    final location = locations[index];
                    final placemark = placemarks[index];
                    return ListTile(
                      title: Text(placemark.name ?? 'ไม่ทราบชื่อสถานที่'),
                      subtitle: Text([
                        placemark.subLocality,
                        placemark.locality,
                        placemark.administrativeArea,
                        placemark.country,
                      ].where((s) => s != null && s.isNotEmpty).join(', ')),
                      onTap: () async {
                        Navigator.pop(context);
                        LatLng latLng =
                            LatLng(location.latitude, location.longitude);
                        final controller = await _controller.future;
                        controller.animateCamera(
                            CameraUpdate.newLatLngZoom(latLng, 15));
                        _onMapTap(latLng);
                      },
                    );
                  },
                );
              },
            );
          },
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ข้อผิดพลาด'),
          content: const Text(
              'เกิดข้อผิดพลาดในการค้นหา โปรดเจาะจงชื่อสถานที่ให้ชัดเจน'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ตกลง'),
            ),
          ],
        ),
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

  // @override
  // Widget build(BuildContext context) {
  //   // แสดง CircularProgressIndicator จนกว่า _initialCameraPosition จะถูกกำหนดค่า
  //   // ซึ่งจะเกิดขึ้นใน initState หรือ _getCurrentLocation
  //   if (_initialCameraPosition.latitude == 0 &&
  //       _initialCameraPosition.longitude == 0 &&
  //       widget.initialLat == null) {
  //     return const Scaffold(
  //       body: Center(child: CircularProgressIndicator()),
  //     );
  //   }

  //   return Scaffold(
  //     appBar: AppBar(
  //       backgroundColor: const Color.fromARGB(255, 18, 143, 9),
  //       centerTitle: true, // ✅ บังคับให้อยู่ตรงกลาง
  //       title: const Text(
  //         'เลือกตำแหน่งบนแผนที่',
  //         style: TextStyle(
  //           fontSize: 22,
  //           fontWeight: FontWeight.bold,
  //           color: Color.fromARGB(255, 255, 255, 255),
  //           //letterSpacing: 1,
  //           shadows: [
  //             Shadow(
  //               color: Color.fromARGB(115, 253, 237, 237),
  //               blurRadius: 3,
  //               offset: Offset(1.5, 1.5),
  //             ),
  //           ],
  //         ),
  //       ),
  //       iconTheme: const IconThemeData(
  //         color: Colors.white, // ✅ ลูกศรย้อนกลับสีขาว
  //       ),
  //       leading: IconButton(
  //         icon: const Icon(Icons.arrow_back),
  //         onPressed: () {
  //           Navigator.pop(context, true);
  //         },
  //       ),
  //       actions: [
  //         IconButton(
  //           icon: const Icon(Icons.check),
  //           onPressed: _confirmLocation,
  //         )
  //       ],
  //     ),
  //     body: Column(
  //       children: [
  //         Padding(
  //           padding: const EdgeInsets.all(8.0),
  //           child: Row(
  //             children: [
  //               Expanded(
  //                 child: TextField(
  //                   controller: searchController,
  //                   decoration: const InputDecoration(
  //                     hintText: 'ค้นหาสถานที่',
  //                     border: OutlineInputBorder(),
  //                   ),
  //                   onSubmitted: _searchPlace, // ค้นหาเมื่อกด Enter
  //                 ),
  //               ),
  //               const SizedBox(width: 8),
  //               ElevatedButton(
  //                 onPressed: () => _searchPlace(searchController.text),
  //                 child: const Text('ค้นหา'),
  //                 style: ElevatedButton.styleFrom(
  //                   backgroundColor:
  //                       Color.fromARGB(255, 255, 158, 60), // สีพื้นหลัง
  //                   foregroundColor:
  //                       Color.fromARGB(255, 255, 251, 251), // สีข้อความและไอคอน
  //                 ),
  //               )
  //             ],
  //           ),
  //         ),
  //         Expanded(
  //           child: GoogleMap(
  //             mapType: MapType.satellite,
  //             // ตำแหน่งเริ่มต้นของกล้องจะใช้ _initialCameraPosition
  //             initialCameraPosition:
  //                 CameraPosition(target: _initialCameraPosition, zoom: 15),
  //             onMapCreated: _onMapCreated,
  //             onTap: _onMapTap, // เมื่อแตะแผนที่ หมุดจะเปลี่ยน
  //             // markers จะอัปเดตตามค่าของ _selectedMarker ที่เปลี่ยนไป
  //             markers:
  //                 _selectedMarker != null ? {_selectedMarker!} : <Marker>{},
  //             myLocationEnabled: true,
  //             myLocationButtonEnabled: true,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 18, 143, 9),
        centerTitle: true,
        title: const Text(
          'เลือกตำแหน่งบนแผนที่',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.check),
        //     onPressed: _confirmLocation,
        //   )
        // ],
      ),
      // body: _initialPosition == null
      //     ? const Center(child: CircularProgressIndicator())
      //     : Column(
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
      //                 ElevatedButton.icon(
      //                   onPressed: () => _searchPlace(searchController.text),
      //                   label: const Text('ค้นหา'),
      //                   style: ElevatedButton.styleFrom(
      //                     backgroundColor:
      //                         const Color.fromARGB(255, 255, 158, 60),
      //                     foregroundColor: Colors.white,
      //                   ),
      //                 )
      //               ],
      //             ),
      //           ),
      //           Expanded(
      //             child: GoogleMap(
      //               mapType: MapType.hybrid,
      //               initialCameraPosition:
      //                   CameraPosition(target: _initialPosition!, zoom: 15),
      //               onMapCreated: (controller) =>
      //                   _controller.complete(controller),
      //               onTap: _onMapTap,
      //               markers: {
      //                 if (_selectedMarker != null) _selectedMarker!,
      //                 ..._placesMarkers,
      //               },
      //               myLocationEnabled: true,
      //               myLocationButtonEnabled: true,
      //             ),
      //           ),
      //           Align(
      //             alignment: Alignment
      //                 .bottomCenter, // จัดตำแหน่งปุ่มให้อยู่กึ่งกลางด้านล่าง
      //             child: Padding(
      //               padding: const EdgeInsets.only(
      //                   bottom: 20.0), // เพิ่มระยะห่างจากขอบล่าง
      //               child: ElevatedButton.icon(
      //                 onPressed: _confirmLocation,
      //                 icon: const Icon(Icons.check),
      //                 label: const Text('ตกลง', style: TextStyle(fontSize: 18)),
      //                 style: ElevatedButton.styleFrom(
      //                   backgroundColor: const Color.fromARGB(255, 18, 143, 9),
      //                   foregroundColor: Colors.white,
      //                   padding: const EdgeInsets.symmetric(
      //                       horizontal: 30, vertical: 15),
      //                   shape: RoundedRectangleBorder(
      //                     borderRadius:
      //                         BorderRadius.circular(30), // ทำให้ปุ่มมีมุมโค้ง
      //                   ),
      //                 ),
      //               ),
      //             ),
      //           ),
      //         ],
      //       ),
      body: _initialPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // ส่วนของแผนที่
                GoogleMap(
                  mapType: MapType.hybrid,
                  initialCameraPosition:
                      CameraPosition(target: _initialPosition!, zoom: 15),
                  onMapCreated: (controller) =>
                      _controller.complete(controller),
                  onTap: _onMapTap,
                  markers: {
                    if (_selectedMarker != null) _selectedMarker!,
                    ..._placesMarkers,
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                ),

                // ส่วนของปุ่ม "ตกลง" ที่จะทับอยู่บนแผนที่
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: ElevatedButton.icon(
                      onPressed: _confirmLocation,
                      //icon: const Icon(Icons.check),
                      label: const Text('ตกลง', style: TextStyle(fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 18, 143, 9),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ),

                // ส่วนของช่องค้นหาที่อยู่ด้านบนสุด
                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            decoration: const InputDecoration(
                              hintText: 'ค้นหาสถานที่',
                              border: OutlineInputBorder(),
                              // เพิ่มสองบรรทัดนี้เพื่อให้พื้นหลังเป็นสีขาว
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _searchPlace(searchController.text),
                          label: const Text('ค้นหา'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 255, 158, 60),
                            foregroundColor: Colors.white,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
