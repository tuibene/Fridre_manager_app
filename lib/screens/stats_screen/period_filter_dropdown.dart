import 'package:flutter/material.dart';

class PeriodFilterDropdown extends StatelessWidget {
  final String selectedPeriod;
  final Function(String?) onChanged;

  const PeriodFilterDropdown({
    super.key,
    required this.selectedPeriod,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: selectedPeriod,
      items: ['7 ngày', '30 ngày', 'Tất cả'].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: onChanged,
      isExpanded: true,
      borderRadius: BorderRadius.circular(12),
    );
  }
}
