import 'package:agri_booking_app2/pages/login.dart';
import 'package:flutter/material.dart';

class HomeEmpPage extends StatefulWidget {
  final int mid;
  const HomeEmpPage({super.key, required this.mid});

  @override
  State<HomeEmpPage> createState() => _HomeEmpPageState();
}

class _HomeEmpPageState extends State<HomeEmpPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Employee'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // กลับไปหน้า Login และล้างหน้าก่อนหน้า
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const Login()),
                (route) => false,
              );
            },
          )
        ],
      ),
      body: Center(
        child: Text('ยินดีต้อนรับ MID: ${widget.mid}'),
      ),
    );
  }
}
