import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Future<String?> showPlayerNameDialog(BuildContext context) async {
  final TextEditingController controller = TextEditingController();
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFF1A0033),
        title: Text(
          'Nhập tên người chơi',
          style: GoogleFonts.montserrat(
            color: const Color(0xFFFFD60A),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.montserrat(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Tên của bạn...',
            hintStyle: GoogleFonts.montserrat(color: Colors.white54),
            filled: true,
            fillColor: const Color(0xFF0F0F1A),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Hủy', style: GoogleFonts.montserrat(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD60A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.of(context).pop(name);
              }
            },
            child: Text('Xác nhận', style: GoogleFonts.montserrat(color: Colors.black)),
          ),
        ],
      );
    },
  );
}
