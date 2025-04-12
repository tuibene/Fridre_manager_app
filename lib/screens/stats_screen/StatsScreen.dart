import 'package:flutter/material.dart';
import 'package:ntb/screens/stats_screen/period_filter_dropdown.dart';
import 'package:ntb/screens/stats_screen/ingredient_usage_card.dart';
import 'package:ntb/screens/stats_screen/cooked_dishes_list.dart';
import 'package:ntb/screens/stats_screen/purchase_suggestions_card.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String selectedPeriod = '7 ngày';

  List<Map<String, dynamic>> ingredientUsage = [
    {'name': 'Cà rốt', 'quantity': 3, 'unit': 'củ', 'usedDate': DateTime.now()},
    {'name': 'Khoai tây', 'quantity': 5, 'unit': 'củ', 'usedDate': DateTime.now()},
  ];

  List<Map<String, dynamic>> cookedDishes = [
    {
      'name': 'Canh chua',
      'date': DateTime.now(),
      'ingredients': {'Cá': 1, 'Cà chua': 2}
    },
    {
      'name': 'Thịt kho',
      'date': DateTime.now(),
      'ingredients': {'Thịt ba chỉ': 0.5, 'Trứng': 2}
    },
  ];

  Map<String, int> purchaseSuggestions = {
    'Hành lá': 3,
    'Tỏi': 1,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(
          'Thống kê nấu ăn',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        
      ),
      
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'Khoảng thời gian:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            PeriodFilterDropdown(
              selectedPeriod: selectedPeriod,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedPeriod = value;
                  });
                }
              },
            ),
            const SizedBox(height: 24),

            const Text(
              'Nguyên liệu đã sử dụng',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            IngredientUsageCard(ingredients: ingredientUsage),
            const SizedBox(height: 24),

            const Text(
              'Món đã nấu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            CookedDishesList(dishes: cookedDishes),
            const SizedBox(height: 24),

            const Text(
              'Gợi ý cần mua',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            PurchaseSuggestionsCard(suggestions: purchaseSuggestions),
          ],
        ),
      ),
    );
  }
}
  