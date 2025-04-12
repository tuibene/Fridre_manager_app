import 'package:flutter/material.dart';

class IngredientUsageCard extends StatelessWidget {
  final List<Map<String, dynamic>> ingredients;

  const IngredientUsageCard({super.key, required this.ingredients});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: ingredients.isEmpty
              ? [const Text('Chưa có dữ liệu')]
              : ingredients.map((item) {
                  return ListTile(
                    title: Text('${item['name']}'),
                    subtitle: Text('Đã dùng: ${item['quantity']} ${item['unit']}'),
                    trailing: Text(item['usedDate'].toString().substring(0, 10)),
                  );
                }).toList(),
        ),
      ),
    );
  }
}
