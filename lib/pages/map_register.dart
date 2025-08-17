import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapRegister extends StatefulWidget {
  const MapRegister({super.key});

  @override
  State<MapRegister> createState() => _MapRegisterState();
}

class _MapRegisterState extends State<MapRegister> {
  final Completer<GoogleMapController> _controller = Completer();
  Marker? _selectedMarker;
  LatLng? _initialPosition;
  TextEditingController searchController = TextEditingController();

  Set<Marker> _placesMarkers = {};

  // ใส่ API Key Google Places API ของคุณตรงนี้
  final String googleApiKey = 'AIzaSyCjle5TSSjk8BnEI_mBrwAtVxrefVCMJAU';

  @override
  void initState() {
    super.initState();
    _loadSavedMarker();
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
      await _fetchNearbyPlaces(_initialPosition!); // ดึงสถานที่รอบ ๆ
    } else {
      await _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return;

    Position position = await Geolocator.getCurrentPosition();
    _initialPosition = LatLng(position.latitude, position.longitude);
    final controller = await _controller.future;

    setState(() {});

    controller.animateCamera(
      CameraUpdate.newLatLngZoom(_initialPosition!, 15),
    );

    await _fetchNearbyPlaces(_initialPosition!); // ดึงสถานที่รอบ ๆ
  }

  Future<void> _fetchNearbyPlaces(LatLng location) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
      '?location=${location.latitude},${location.longitude}'
      '&radius=1500'
      '&type=restaurant|gas_station'
      '&key=$googleApiKey',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final List places = data['results'];

          Set<Marker> newMarkers = {};

          for (var place in places) {
            final marker = Marker(
              markerId: MarkerId(place['place_id']),
              position: LatLng(
                place['geometry']['location']['lat'],
                place['geometry']['location']['lng'],
              ),
              infoWindow: InfoWindow(
                title: place['name'],
                snippet: place['vicinity'],
              ),
            );
            newMarkers.add(marker);
          }

          setState(() {
            _placesMarkers = newMarkers;
          });
        }
      }
    } catch (e) {
      // handle error silently or show message
      print('Failed to fetch nearby places: $e');
    }
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

    await _fetchNearbyPlaces(latLng); // ดึงสถานที่รอบ ๆ จุดที่เลือกใหม่
  }

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

// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:google_fonts/google_fonts.dart';

// class MapRegister extends StatefulWidget {
//   const MapRegister({super.key});

//   @override
//   State<MapRegister> createState() => _MapRegisterState();
// }

// class _MapRegisterState extends State<MapRegister> {
//   Completer<GoogleMapController> _controller = Completer();
//   Marker? _selectedMarker;
//   LatLng? _initialPosition;
//   TextEditingController searchController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     _loadSavedMarker(); // โหลดพิกัดที่เคยบันทึกไว้
//   }

//   Future<void> _loadSavedMarker() async {
//     final prefs = await SharedPreferences.getInstance();
//     final lat = prefs.getDouble('saved_lat');
//     final lng = prefs.getDouble('saved_lng');

//     if (lat != null && lng != null) {
//       _initialPosition = LatLng(lat, lng);
//       setState(() {
//         _selectedMarker = Marker(
//           markerId: const MarkerId('saved_location'),
//           position: _initialPosition!,
//         );
//       });
//     } else {
//       _getCurrentLocation(); // ถ้าไม่มีให้ใช้ตำแหน่งปัจจุบัน
//     }
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
//       CameraUpdate.newLatLngZoom(_initialPosition!, 15),
//     );
//   }

//   void _onMapTap(LatLng latLng) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setDouble('saved_lat', latLng.latitude);
//     await prefs.setDouble('saved_lng', latLng.longitude);

//     setState(() {
//       _selectedMarker = Marker(
//         markerId: const MarkerId('selected_location'),
//         position: latLng,
//       );
//     });
//   }

//   // Future<void> _searchPlace(String query) async {
//   //   try {
//   //     List<Location> locations = await locationFromAddress(query);
//   //     if (locations.isNotEmpty) {
//   //       final location = locations.first;
//   //       LatLng latLng = LatLng(location.latitude, location.longitude);

//   //       final controller = await _controller.future;
//   //       controller.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));

//   //       _onMapTap(latLng); // ใช้ _onMapTap เพื่อบันทึกหมุดและแสดง
//   //     }
//   //   } catch (e) {
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       SnackBar(content: Text('ไม่พบสถานที่: $e')),
//   //     );
//   //   }
//   // }

//   Future<void> _searchPlace(String query) async {
//     try {
//       List<Location> locations = await locationFromAddress(query);
//       if (locations.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('ไม่พบสถานที่')),
//         );
//         return;
//       }

//       if (locations.length == 1) {
//         final location = locations.first;
//         LatLng latLng = LatLng(location.latitude, location.longitude);
//         final controller = await _controller.future;
//         controller.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
//         _onMapTap(latLng);
//       } else {
//         // Multiple locations found
//         showModalBottomSheet(
//           context: context,
//           builder: (BuildContext context) {
//             return FutureBuilder<List<Placemark>>(
//               future: Future.wait(locations.map((loc) async {
//                 final placemarks =
//                     await placemarkFromCoordinates(loc.latitude, loc.longitude);
//                 return placemarks.first;
//               })),
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 final placemarks = snapshot.data!;
//                 return ListView.builder(
//                   itemCount: locations.length,
//                   itemBuilder: (context, index) {
//                     final location = locations[index];
//                     final placemark = placemarks[index];
//                     // final address =
//                     //     '${placemark.name ?? ''} ${placemark.subLocality ?? ''} ${placemark.locality ?? ''} ${placemark.administrativeArea ?? ''} ${placemark.country ?? ''}';
//                     final address = [
//                       if (placemark.name != null && placemark.name!.isNotEmpty)
//                         placemark.name!,
//                       if (placemark.subLocality != null &&
//                           placemark.subLocality!.isNotEmpty)
//                         placemark.subLocality!,
//                       if (placemark.locality != null &&
//                           placemark.locality!.isNotEmpty)
//                         placemark.locality!,
//                       if (placemark.administrativeArea != null &&
//                           placemark.administrativeArea!.isNotEmpty)
//                         placemark.administrativeArea!,
//                       if (placemark.country != null &&
//                           placemark.country!.isNotEmpty)
//                         placemark.country!,
//                     ].join(' ');

//                     // return ListTile(
//                     //   title: Text(address.trim()),
//                     //   onTap: () async {
//                     //     Navigator.pop(context);
//                     //     LatLng latLng =
//                     //         LatLng(location.latitude, location.longitude);
//                     //     final controller = await _controller.future;
//                     //     controller.animateCamera(
//                     //         CameraUpdate.newLatLngZoom(latLng, 15));
//                     //     _onMapTap(latLng);
//                     //   },
//                     // );
//                     return ListTile(
//                       title: Text(placemark.name ?? 'ไม่ทราบชื่อสถานที่'),
//                       subtitle: Text([
//                         placemark.subLocality,
//                         placemark.locality,
//                         placemark.administrativeArea,
//                         placemark.country,
//                       ].where((s) => s != null && s.isNotEmpty).join(', ')),
//                       onTap: () async {
//                         Navigator.pop(context);
//                         LatLng latLng =
//                             LatLng(location.latitude, location.longitude);
//                         final controller = await _controller.future;
//                         controller.animateCamera(
//                             CameraUpdate.newLatLngZoom(latLng, 15));
//                         _onMapTap(latLng);
//                       },
//                     );
//                   },
//                 );
//               },
//             );
//           },
//         );
//       }
//     } catch (e) {
//       // ScaffoldMessenger.of(context).showSnackBar(
//       //   SnackBar(content: Text('เกิดข้อผิดพลาดในการค้นหา โปรดเจาะจงชื่อสถานที่ให้ชัดเจน')),
//       // );
//       showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: const Text('ข้อผิดพลาด'),
//           content: const Text(
//               'เกิดข้อผิดพลาดในการค้นหา โปรดเจาะจงชื่อสถานที่ให้ชัดเจน'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(), // ปิดป๊อปอัพ
//               child: const Text('ตกลง'),
//             ),
//           ],
//         ),
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

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: const Color.fromARGB(255, 18, 143, 9),
//         centerTitle: true, // ✅ บังคับให้อยู่ตรงกลาง
//         title: const Text(
//           'เลือกตำแหน่งบนแผนที่',
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
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () {
//             Navigator.pop(context, true);
//           },
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.check),
//             onPressed: _confirmLocation,
//           )
//         ],
//       ),
//       body: _initialPosition == null
//           ? const Center(child: CircularProgressIndicator())
//           : Column(
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Row(
//                     children: [
//                       Expanded(
//                         child: TextField(
//                           controller: searchController,
//                           decoration: const InputDecoration(
//                             hintText: 'ค้นหาสถานที่',
//                             border: OutlineInputBorder(),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       ElevatedButton.icon(
//                         onPressed: () => _searchPlace(searchController.text),
//                         label: const Text('ค้นหา'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor:
//                               Color.fromARGB(255, 255, 158, 60), // สีพื้นหลัง
//                           foregroundColor: const Color.fromARGB(
//                               255, 255, 254, 254), // สีข้อความและไอคอน
//                         ),
//                       )
//                     ],
//                   ),
//                 ),
//                 Expanded(
//                     child: GoogleMap(
//                   mapType: MapType.hybrid, // แสดงภาพดาวเทียมพร้อมชื่อสถานที่
//                   initialCameraPosition:
//                       CameraPosition(target: _initialPosition!, zoom: 15),
//                   onMapCreated: (controller) =>
//                       _controller.complete(controller),
//                   onTap: _onMapTap,
//                   markers:
//                       _selectedMarker != null ? {_selectedMarker!} : <Marker>{},
//                   myLocationEnabled: true,
//                   myLocationButtonEnabled: true,
//                 )
//                     ),
//               ],
//             ),
//     );
//   }
// }

