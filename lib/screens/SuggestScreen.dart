import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart'; // Import share_plus package

class SuggestScreen extends StatefulWidget {
  const SuggestScreen({super.key});

  @override
  _SuggestScreenState createState() => _SuggestScreenState();
}

class _SuggestScreenState extends State<SuggestScreen> {
  String _searchQuery = '';
  bool _filterRau = false;
  bool _filterThit = false;
  bool _filterNhanh = false;

  // Filter dishes based on search query and filter options
  List<Map<String, dynamic>> _filterDishes(List<Map<String, dynamic>> dishes) {
    return dishes.where((dish) {
      final matchesSearch = dish['name']
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          dish['ingredients'].toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter = (_filterRau && dish['type'].contains('Rau')) ||
          (_filterThit && dish['type'].contains('Thịt')) ||
          (_filterNhanh && dish['type'].contains('Nhanh')) ||
          (!_filterRau && !_filterThit && !_filterNhanh);
      return matchesSearch && matchesFilter;
    }).toList();
  }

  // Show all recipes in a modal bottom sheet
  void _showAllRecipes(List<Map<String, dynamic>> recipes) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Tất cả công thức',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: recipes.length,
                itemBuilder: (context, index) {
                  final recipe = recipes[index];
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(recipe['name']),
                      subtitle: Text(
                          'Nguyên liệu: ${recipe['ingredients']} | Thời gian: ${recipe['time']} | Loại: ${recipe['type'].join(', ')}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _showRecipeDetails(recipe);
                            },
                            child: const Text('Công thức'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.share, size: 16),
                            onPressed: () {
                              _showShareDialog(recipe);
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        _showRecipeDetails(recipe);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
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
  }

  // Show recipe details in a modal bottom sheet
  void _showRecipeDetails(Map<String, dynamic> dish) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tiêu đề món ăn
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

              // Thông tin thời gian
              Row(
                children: [
                  const Icon(Icons.timer, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Thời gian: ${dish['time']}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Nguyên liệu
              const Text(
                'Nguyên liệu',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                dish['ingredients'].split(', ').map((item) => '- $item').join('\n'),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),

              // Hướng dẫn
              const Text(
                'Hướng dẫn',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                dish['recipe'],
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),

              // Nút đóng
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
      ),
    );
  }

  // Custom sharing dialog (designed to match DashboardScreen)
  void _showShareDialog(Map<String, dynamic> dish) {
    // Format the initial share text for the recipe
    String shareText = '''
Công thức: ${dish['name']}
Nguyên liệu: ${dish['ingredients']}
Thời gian: ${dish['time']}
Loại: ${dish['type'].join(', ')}
Hướng dẫn:
${dish['recipe']}
''';

    // Controller for the editable message
    final messageController = TextEditingController(
      text: 'Chia sẻ công thức món ăn:\n\n$shareText',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Center(
            child: Text(
              'Chia sẻ công thức',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nội dung chia sẻ:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: messageController,
                  maxLines: 10,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Hủy',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // Show loading dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                );

                try {
                  // Share the edited message
                  await Share.share(
                    messageController.text,
                    subject: 'Chia sẻ công thức: ${dish['name']}',
                  );

                  // Close both dialogs
                  Navigator.pop(context); // Close loading dialog
                  Navigator.pop(context); // Close share dialog

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã chia sẻ công thức')),
                  );
                } catch (error) {
                  Navigator.pop(context); // Close loading dialog
                  Navigator.pop(context); // Close share dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi khi chia sẻ: $error')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.green,
              ),
              child: const Text(
                'Chia sẻ',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đề xuất'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Tìm món ăn',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12.0)),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 20),
            const Text('Lọc',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Checkbox(
                  value: _filterRau,
                  onChanged: (value) {
                    setState(() {
                      _filterRau = value!;
                    });
                  },
                ),
                const Text('Rau'),
                Checkbox(
                  value: _filterThit,
                  onChanged: (value) {
                    setState(() {
                      _filterThit = value!;
                    });
                  },
                ),
                const Text('Thịt'),
                Checkbox(
                  value: _filterNhanh,
                  onChanged: (value) {
                    setState(() {
                      _filterNhanh = value!;
                    });
                  },
                ),
                const Text('Nhanh'),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Món ăn đề xuất',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('recipes').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Lỗi khi tải dữ liệu'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<Map<String, dynamic>> allDishes =
                    snapshot.data!.docs.map((doc) {
                  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                  return {
                    'id': doc.id,
                    'name': data['name'] ?? '',
                    'ingredients': data['ingredients'] ?? '',
                    'time': data['time'] ?? '',
                    'type': List<String>.from(data['type'] ?? []),
                    'recipe': data['recipe'] ?? '',
                  };
                }).toList();

                List<Map<String, dynamic>> filteredDishes =
                    _filterDishes(allDishes);

                if (filteredDishes.isEmpty) {
                  return const Center(child: Text('Không có món ăn phù hợp'));
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredDishes.length > 3
                          ? 3
                          : filteredDishes.length,
                      itemBuilder: (context, index) {
                        final dish = filteredDishes[index];
                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.image),
                            title: Text(dish['name']),
                            subtitle: Text(
                                'Nguyên liệu: ${dish['ingredients']}\nThời gian: ${dish['time']}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    _showRecipeDetails(dish);
                                  },
                                  child: const Text('Công thức'),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.share),
                                  onPressed: () {
                                    _showShareDialog(dish);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    if (filteredDishes.length > 3)
                      TextButton(
                        onPressed: () => _showAllRecipes(filteredDishes),
                        child: const Text('Xem tất cả'),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}