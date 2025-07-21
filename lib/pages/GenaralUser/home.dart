import 'package:agri_booking2/pages/login.dart';
import 'package:flutter/material.dart';

class HomeGe extends StatefulWidget {
  const HomeGe({super.key});

  @override
  State<HomeGe> createState() => _HomeGeState();
}

class _HomeGeState extends State<HomeGe> {
  String displayedText = "สวัสดีครับ! นี่คือข้อมูลตัวอย่าง";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('หน้า HomeGe'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              displayedText,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => Login()),
                );
              },
              child: const Text('ไปหน้า Login'),
            ),
          ],
        ),
      ),
    );
  }
}
