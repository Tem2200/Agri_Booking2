import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

class ReviewCon extends StatefulWidget {
  final int midContractor; // mid_reviewed

  const ReviewCon({super.key, required this.midContractor});

  @override
  State<ReviewCon> createState() => _ReviewConState();
}

class _ReviewConState extends State<ReviewCon> {
  int selectedRating = 0;
  TextEditingController reviewController = TextEditingController();
  bool isSubmitting = false;
  bool isLoading = false;

  final ImagePicker picker = ImagePicker();
  String? imageUrl;

  Future<void> uploadImageFromImageBB() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    final bytes = await pickedFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    const apiKey = 'a051ad7a04e7037b74d4d656e7d667e9'; // ใส่ API Key จริงของคุณ
    final url = Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey');

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        url,
        body: {'image': base64Image},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final uploadedUrl = data['data']['url'];

        setState(() {
          imageUrl = uploadedUrl;
        });
      } else {
        _showErrorDialog('อัปโหลดไม่สำเร็จ', response.body);
      }
    } catch (e) {
      _showErrorDialog('เกิดข้อผิดพลาด', 'ไม่สามารถอัปโหลดรูปได้: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showErrorDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }

  Future<void> submitReview() async {
    if (reviewController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเขียนรีวิว')),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    final url = Uri.parse(
        'http://projectnodejs.thammadalok.com/AGribooking/add_reviewed');
    final now =
        DateTime.now().toString().split('.')[0]; // "2025-07-20 15:30:00"

    final body = {
      "text": reviewController.text,
      "point": selectedRating, // selectedRating = 0 ถ้าไม่เลือกดาว
      "image": imageUrl, // จะเป็น null ถ้าไม่อัปโหลด
      "date": now,
      "mid_reviewed": widget.midContractor,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ส่งรีวิวเรียบร้อยแล้ว')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('เกิดข้อผิดพลาดในการส่งรีวิว: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เชื่อมต่อไม่สำเร็จ: $e')),
      );
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  void removeImage() {
    setState(() {
      imageUrl = null;
    });
  }

  Widget buildStar(int star) {
    return IconButton(
      icon: Icon(
        Icons.star,
        color: selectedRating >= star ? Colors.orange : Colors.grey,
      ),
      onPressed: () {
        setState(() {
          // ถ้ากดดาวเดิมอีกครั้ง = ลบการเลือก
          if (selectedRating == star) {
            selectedRating = 0; // ไม่เลือกดาว
          } else {
            selectedRating = star;
          }
        });
      },
    );
  }

  @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(title: const Text('ให้คะแนนรีวิว')),
  //     body: SingleChildScrollView(
  //       padding: const EdgeInsets.all(16.0),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           const Text('ให้คะแนน', style: TextStyle(fontSize: 18)),
  //           Row(
  //             children: List.generate(5, (index) => buildStar(index + 1)),
  //           ),
  //           const SizedBox(height: 20),
  //           TextField(
  //             controller: reviewController,
  //             maxLines: 5,
  //             decoration: const InputDecoration(
  //               labelText: 'เขียนรีวิว',
  //               border: OutlineInputBorder(),
  //             ),
  //           ),
  //           const SizedBox(height: 20),
  //           if (imageUrl != null)
  //             Column(
  //               children: [
  //                 Image.network(imageUrl!, height: 150),
  //                 const SizedBox(height: 10),
  //                 Text('อัปโหลดเรียบร้อย',
  //                     style: TextStyle(color: Colors.green)),
  //               ],
  //             ),
  //           ElevatedButton.icon(
  //             onPressed: isLoading ? null : uploadImageFromImageBB,
  //             icon: const Icon(Icons.image),
  //             label: Text(
  //                 isLoading ? 'กำลังอัปโหลด...' : 'เลือกรูปรีวิว (ไม่บังคับ)'),
  //           ),
  //           const SizedBox(height: 20),
  //           ElevatedButton.icon(
  //             onPressed: isSubmitting ? null : submitReview,
  //             icon: const Icon(Icons.send),
  //             label: Text(isSubmitting ? 'กำลังส่ง...' : 'ส่งรีวิว'),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 18, 143, 9),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'ให้คะแนนรีวิว',
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
      ),
      backgroundColor: const Color(0xFFFFFBEF),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ให้คะแนน',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(5, (index) => buildStar(index + 1)),
                ),
                const SizedBox(height: 20),
                const Text(
                  'เขียนรีวิว',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: reviewController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.orange[50],
                    labelText: 'พิมพ์ข้อความรีวิวของคุณที่นี่',
                    labelStyle: const TextStyle(color: Colors.black54),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.orange),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ✅ แสดงรูปภาพและปุ่มลบ (ถ้ามี imageUrl)
                if (imageUrl != null)
                  Column(
                    children: [
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            imageUrl!,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'อัปโหลดเรียบร้อย',
                        style: TextStyle(
                            color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: removeImage,
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text(
                          'ลบรูปภาพ',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 16),

                // ✅ ปุ่มเลือกรูปใหม่
                ElevatedButton.icon(
                  onPressed: isLoading ? null : uploadImageFromImageBB,
                  icon: const Icon(Icons.image),
                  label: Text(isLoading
                      ? 'กำลังอัปโหลด...'
                      : 'เลือกรูปรีวิว (ไม่บังคับ)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[300],
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: isSubmitting ? null : submitReview,
                  icon: const Icon(Icons.send),
                  label: Text(isSubmitting ? 'กำลังส่ง...' : 'ส่งรีวิว'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[400],
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
