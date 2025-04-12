// dish_detail_bottom_sheet.dart
import 'package:flutter/material.dart';

class DishDetailBottomSheet extends StatelessWidget {
  final Map<String, dynamic> dish;

  const DishDetailBottomSheet({super.key, required this.dish});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              dish['name'],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Nguyên liệu đã dùng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            dish['ingredients']
                .entries
                .map((e) => '- ${e.key}: ${e.value}')
                .join('\n'),
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          const Text('Ngày nấu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(dish['date'].toString().substring(0, 10), style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 30),
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: Colors.green,
              ),
              child: const Text('Đóng', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
