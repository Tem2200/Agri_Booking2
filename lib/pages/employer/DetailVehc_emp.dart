import 'package:flutter/material.dart';

class DetailvehcEmp extends StatefulWidget {
  final int vid;
  final int mid;
  const DetailvehcEmp({super.key, required this.vid, required this.mid});

  @override
  State<DetailvehcEmp> createState() => _DetailvehcEmpState();
}

class _DetailvehcEmpState extends State<DetailvehcEmp> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดรถผู้รับจ้าง'),
      ),
      body: Center(
        child: Text('Vehicle ID: ${widget.vid}\nMember ID: ${widget.mid}'),
      ),
    );
  }
}
