import 'package:flutter/material.dart';

class PurchaseSuggestionsCard extends StatelessWidget {
  final Map<String, int> suggestions;

  const PurchaseSuggestionsCard({super.key, required this.suggestions});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: suggestions.isEmpty
              ? [const Text('Chưa có gợi ý')]
              : suggestions.entries.map((entry) {
                  return ListTile(
                    title: Text(entry.key),
                    subtitle: Text('Cần mua: ${entry.value}'),
                  );
                }).toList(),
        ),
      ),
    );
  }
}
