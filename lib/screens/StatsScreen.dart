import 'package:flutter/material.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  // Dữ liệu mẫu (có thể thay bằng dữ liệu từ Firebase)
  final List<Map<String, dynamic>> _ingredientUsage = [
    {'name': 'Trứng', 'quantity': 10, 'unit': 'quả', 'usedDate': DateTime(2025, 4, 4)},
    {'name': 'Sữa', 'quantity': 3, 'unit': 'lít', 'usedDate': DateTime(2025, 4, 5)},
    {'name': 'Cà chua', 'quantity': 5, 'unit': 'quả', 'usedDate': DateTime(2025, 4, 3)},
  ];

  final List<Map<String, dynamic>> _cookedDishes = [
    {
      'name': 'Trứng chiên cà chua',
      'date': DateTime(2025, 4, 4),
      'ingredients': {'Trứng': 2, 'Cà chua': 1}
    },
    {
      'name': 'Cơm chiên trứng',
      'date': DateTime(2025, 4, 5),
      'ingredients': {'Cơm': 1, 'Trứng': 1}
    },
  ];

  String _selectedPeriod = '7 ngày'; // Tùy chọn thời gian
  List<Map<String, dynamic>> _filteredIngredients = [];
  List<Map<String, dynamic>> _filteredDishes = [];
  Map<String, int> _suggestedPurchases = {};

  @override
  void initState() {
    super.initState();
    _filterStats();
    _calculateSuggestions();
  }

  // Lọc dữ liệu theo khoảng thời gian
  void _filterStats() {
    final now = DateTime.now();
    DateTime startDate;
    switch (_selectedPeriod) {
      case '7 ngày':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case '30 ngày':
        startDate = now.subtract(const Duration(days: 30));
        break;
      case 'Tất cả':
      default:
        startDate = DateTime(2000); // Lấy tất cả
        break;
    }

    setState(() {
      _filteredIngredients = _ingredientUsage
          .where((item) => item['usedDate'].isAfter(startDate))
          .toList();
      _filteredDishes = _cookedDishes
          .where((dish) => dish['date'].isAfter(startDate))
          .toList();
    });
  }

  // Tính toán nguyên liệu cần mua
  void _calculateSuggestions() {
    Map<String, int> totalUsed = {};
    for (var dish in _filteredDishes) {
      dish['ingredients'].forEach((ingredient, qty) {
        if (totalUsed.containsKey(ingredient)) {
          totalUsed[ingredient] = totalUsed[ingredient]! + (qty as int);
        } else {
          totalUsed[ingredient] = qty;
        }
      });
    }
    setState(() {
      _suggestedPurchases = totalUsed.map((key, value) => MapEntry(key, value ~/ 2 + 1)); // Gợi ý mua thêm
    });
  }

  // Xóa lịch sử
  void _clearHistory() {
    setState(() {
      _ingredientUsage.clear();
      _cookedDishes.clear();
      _filteredIngredients.clear();
      _filteredDishes.clear();
      _suggestedPurchases.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xóa lịch sử')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê'),
        backgroundColor: Colors.green,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Xóa lịch sử'),
                    content: const Text('Bạn có chắc muốn xóa toàn bộ lịch sử không?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Hủy'),
                      ),
                      TextButton(
                        onPressed: () {
                          _clearHistory();
                          Navigator.pop(context);
                        },
                        child: const Text('Xóa'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tùy chọn thời gian
            const Text('Khoảng thời gian', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            DropdownButton<String>(
              value: _selectedPeriod,
              items: ['7 ngày', '30 ngày', 'Tất cả'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPeriod = value!;
                  _filterStats();
                  _calculateSuggestions();
                });
              },
              isExpanded: true,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(height: 20),

            // Thống kê nguyên liệu
            const Text('Thống kê nguyên liệu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: _filteredIngredients.isEmpty
                      ? [const Text('Chưa có dữ liệu')]
                      : _filteredIngredients.map((item) {
                          return ListTile(
                            title: Text('${item['name']}'),
                            subtitle: Text('Đã dùng: ${item['quantity']} ${item['unit']}'),
                            trailing: Text(item['usedDate'].toString().substring(0, 10)),
                          );
                        }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Món ăn đã nấu
            const Text('Món ăn đã nấu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredDishes.length,
              itemBuilder: (context, index) {
                final dish = _filteredDishes[index];
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(dish['name']),
                    subtitle: Text(dish['date'].toString().substring(0, 10)),
                    trailing: IconButton(
                      icon: const Icon(Icons.info),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (context) => Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Text(
                                    dish['name'],
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Nguyên liệu đã dùng',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  dish['ingredients']
                                      .entries
                                      .map((e) => '- ${e.key}: ${e.value}')
                                      .join('\n'),
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Ngày nấu',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  dish['date'].toString().substring(0, 10),
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 30),
                                Center(
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      backgroundColor: Colors.green,
                                    ),
                                    child: const Text(
                                      'Đóng',
                                      style: TextStyle(fontSize: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Dự báo nguyên liệu cần mua
            const Text('Cần mua', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: _suggestedPurchases.isEmpty
                      ? [const Text('Chưa có gợi ý')]
                      : _suggestedPurchases.entries.map((entry) {
                          return ListTile(
                            title: Text(entry.key),
                            subtitle: Text('Cần mua: ${entry.value}'),
                          );
                        }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}