import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SendEmailPage extends StatefulWidget {
  const SendEmailPage({super.key});

  @override
  State<SendEmailPage> createState() => _SendEmailPageState();
}

class _SendEmailPageState extends State<SendEmailPage> {
  Future<void> sendEmail() async {
    const serviceId = 'service_x7vmrvq';
    const templateId = 'template_1mrmj3e';
    const userId = '9pdBbRJwCa8veHOzy';

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    final response = await http.post(
      url,
      headers: {
        'origin': 'http://localhost',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': userId,
        'template_params': {
          'from_name': 'ชื่อผู้ส่ง',
          'to_name': 'ชื่อผู้รับ',
          'message': 'สวัสดีครับ ส่งมาจากแอป Flutter',
          'to_email': '65011212050@msu.ac.th'
        }
      }),
    );

    if (response.statusCode == 200) {
      print('ส่งอีเมลเรียบร้อยแล้ว');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ส่งอีเมลสำเร็จ!')),
      );
    } else {
      print('เกิดข้อผิดพลาด: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ส่งอีเมลล้มเหลว')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ส่งอีเมล')),
      body: Center(
        child: ElevatedButton(
          onPressed: sendEmail,
          child: const Text('ส่งอีเมล'),
        ),
      ),
    );
  }
}
