import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting

class ManageScreen extends StatefulWidget {
  const ManageScreen({super.key});

  @override
  _ManageScreenState createState() => _ManageScreenState();
}

class _ManageScreenState extends State<ManageScreen> {
  String _searchQuery = '';
  String _filterOption = 'Tất cả';
  String _sortOption = 'Tên';

  // Filter and sort ingredients without calling setState()
  List<Map<String, dynamic>> _filterAndSortIngredients(
      List<Map<String, dynamic>> ingredients) {
    List<Map<String, dynamic>> filteredIngredients = ingredients.where((item) {
      final matchesSearch =
          item['name'].toLowerCase().contains(_searchQuery.toLowerCase());
      if (_filterOption == 'Sắp hết hạn') {
        return matchesSearch &&
            item['expiry'].difference(DateTime.now()).inDays <= 3;
      } else if (_filterOption == 'Còn nhiều') {
        return matchesSearch && item['quantity'] > 2;
      }
      return matchesSearch;
    }).toList();

    if (_sortOption == 'Tên') {
      filteredIngredients.sort((a, b) => a['name'].compareTo(b['name']));
    } else if (_sortOption == 'Ngày hết hạn') {
      filteredIngredients.sort((a, b) => a['expiry'].compareTo(b['expiry']));
    }

    return filteredIngredients;
  }

  // Add a new ingredient
  void _addIngredient() {
    TextEditingController nameController = TextEditingController();
    TextEditingController quantityController = TextEditingController();
    TextEditingController unitController = TextEditingController();
    DateTime? expiryDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20.0,
          right: 20.0,
          top: 20.0,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Thêm nguyên liệu',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tên nguyên liệu'),
              ),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(labelText: 'Số lượng'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: unitController,
                decoration:
                    const InputDecoration(labelText: 'Đơn vị (hộp, quả, kg, ...)'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      expiryDate = pickedDate;
                    });
                  }
                },
                child: Text(expiryDate == null
                    ? 'Chọn ngày hết hạn'
                    : 'Hết hạn: ${DateFormat('yyyy-MM-dd').format(expiryDate!)}'),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty &&
                        quantityController.text.isNotEmpty &&
                        unitController.text.isNotEmpty &&
                        expiryDate != null) {
                      try {
                        await FirebaseFirestore.instance
                            .collection('ingredients')
                            .add({
                          'name': nameController.text,
                          'quantity': int.parse(quantityController.text),
                          'unit': unitController.text,
                          'expiry': Timestamp.fromDate(expiryDate!),
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã thêm nguyên liệu')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi: $e')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Thêm',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Edit an ingredient
  void _editIngredient(Map<String, dynamic> item) {
    TextEditingController nameController =
        TextEditingController(text: item['name']);
    TextEditingController quantityController =
        TextEditingController(text: item['quantity'].toString());
    TextEditingController unitController =
        TextEditingController(text: item['unit']);
    DateTime? expiryDate = item['expiry'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20.0,
          right: 20.0,
          top: 20.0,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Chỉnh sửa nguyên liệu',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tên nguyên liệu'),
              ),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(labelText: 'Số lượng'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: unitController,
                decoration: const InputDecoration(labelText: 'Đơn vị'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: expiryDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      expiryDate = pickedDate;
                    });
                  }
                },
                child: Text(
                    'Hết hạn: ${DateFormat('yyyy-MM-dd').format(expiryDate!)}'),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await FirebaseFirestore.instance
                          .collection('ingredients')
                          .doc(item['id'])
                          .update({
                        'name': nameController.text,
                        'quantity': int.parse(quantityController.text),
                        'unit': unitController.text,
                        'expiry': Timestamp.fromDate(expiryDate!),
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã cập nhật nguyên liệu')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi: $e')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Lưu',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Delete an ingredient
  void _deleteIngredient(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa nguyên liệu'),
        content: Text('Bạn có chắc muốn xóa ${item['name']} không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('ingredients')
                    .doc(item['id'])
                    .delete();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa nguyên liệu')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: $e')),
                );
              }
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  // Add a new recipe with updated fields
  void _addRecipe() {
    TextEditingController nameController = TextEditingController();
    TextEditingController ingredientsController = TextEditingController();
    TextEditingController timeController = TextEditingController();
    TextEditingController typeController = TextEditingController();
    TextEditingController recipeController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20.0,
          right: 20.0,
          top: 20.0,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Thêm công thức',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tên món ăn'),
              ),
              TextField(
                controller: ingredientsController,
                decoration: const InputDecoration(
                    labelText: 'Nguyên liệu (cách nhau bằng dấu phẩy)'),
              ),
              TextField(
                controller: timeController,
                decoration: const InputDecoration(labelText: 'Thời gian (e.g., 10 phút)'),
              ),
              TextField(
                controller: typeController,
                decoration: const InputDecoration(
                    labelText: 'Loại món (cách nhau bằng dấu phẩy, e.g., Rau, Nhanh)'),
              ),
              TextField(
                controller: recipeController,
                decoration: const InputDecoration(labelText: 'Công thức'),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty &&
                        ingredientsController.text.isNotEmpty &&
                        timeController.text.isNotEmpty &&
                        typeController.text.isNotEmpty &&
                        recipeController.text.isNotEmpty) {
                      try {
                        await FirebaseFirestore.instance
                            .collection('recipes')
                            .add({
                          'name': nameController.text,
                          'ingredients': ingredientsController.text,
                          'time': timeController.text,
                          'type': typeController.text
                              .split(',')
                              .map((e) => e.trim())
                              .toList(),
                          'recipe': recipeController.text,
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã thêm công thức')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi: $e')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Thêm',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Edit a recipe with updated fields
  void _editRecipe(Map<String, dynamic> recipe) {
    TextEditingController nameController =
        TextEditingController(text: recipe['name']);
    TextEditingController ingredientsController =
        TextEditingController(text: recipe['ingredients']);
    TextEditingController timeController =
        TextEditingController(text: recipe['time']);
    TextEditingController typeController =
        TextEditingController(text: recipe['type'].join(', '));
    TextEditingController recipeController =
        TextEditingController(text: recipe['recipe']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20.0,
          right: 20.0,
          top: 20.0,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Chỉnh sửa công thức',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tên món ăn'),
              ),
              TextField(
                controller: ingredientsController,
                decoration: const InputDecoration(
                    labelText: 'Nguyên liệu (cách nhau bằng dấu phẩy)'),
              ),
              TextField(
                controller: timeController,
                decoration: const InputDecoration(labelText: 'Thời gian (e.g., 10 phút)'),
              ),
              TextField(
                controller: typeController,
                decoration: const InputDecoration(
                    labelText: 'Loại món (cách nhau bằng dấu phẩy, e.g., Rau, Nhanh)'),
              ),
              TextField(
                controller: recipeController,
                decoration: const InputDecoration(labelText: 'Công thức'),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await FirebaseFirestore.instance
                          .collection('recipes')
                          .doc(recipe['id'])
                          .update({
                        'name': nameController.text,
                        'ingredients': ingredientsController.text,
                        'time': timeController.text,
                        'type': typeController.text
                            .split(',')
                            .map((e) => e.trim())
                            .toList(),
                        'recipe': recipeController.text,
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã cập nhật công thức')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi: $e')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Lưu',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Delete a recipe
  void _deleteRecipe(Map<String, dynamic> recipe) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa công thức'),
        content: Text('Bạn có chắc muốn xóa ${recipe['name']} không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('recipes')
                    .doc(recipe['id'])
                    .delete();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa công thức')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: $e')),
                );
              }
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  // Show all ingredients in a modal bottom sheet
  void _showAllIngredients(List<Map<String, dynamic>> ingredients) {
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
                'Tất cả nguyên liệu',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: ingredients.length,
                itemBuilder: (context, index) {
                  final item = ingredients[index];
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(item['name']),
                      subtitle: Text(
                          '${item['quantity']} ${item['unit']} - Hết hạn: ${DateFormat('yyyy-MM-dd').format(item['expiry'])}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 16),
                            onPressed: () {
                              Navigator.pop(context);
                              _editIngredient(item);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 16),
                            onPressed: () {
                              Navigator.pop(context);
                              _deleteIngredient(item);
                            },
                          ),
                        ],
                      ),
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

  // Show all recipes in a modal bottom sheet with updated fields
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
                          IconButton(
                            icon: const Icon(Icons.edit, size: 16),
                            onPressed: () {
                              Navigator.pop(context);
                              _editRecipe(recipe);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 16),
                            onPressed: () {
                              Navigator.pop(context);
                              _deleteRecipe(recipe);
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(recipe['name']),
                            content: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Nguyên liệu:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 5),
                                  Text(recipe['ingredients']),
                                  const SizedBox(height: 10),
                                  const Text('Thời gian:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 5),
                                  Text(recipe['time']),
                                  const SizedBox(height: 10),
                                  const Text('Loại món:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 5),
                                  Text(recipe['type'].join(', ')),
                                  const SizedBox(height: 10),
                                  const Text('Công thức:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 5),
                                  Text(recipe['recipe']),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Đóng'),
                              ),
                            ],
                          ),
                        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý'),
        backgroundColor: Colors.green,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: const Icon(Icons.camera_alt),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Chức năng AR chưa được triển khai')),
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
            TextField(
              decoration: const InputDecoration(
                hintText: 'Tìm nguyên liệu',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Colors.green),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  value: _filterOption,
                  items: ['Tất cả', 'Sắp hết hạn', 'Còn nhiều']
                      .map((String value) {
                    return DropdownMenuItem<String>(
                        value: value, child: Text(value));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _filterOption = value!;
                    });
                  },
                ),
                DropdownButton<String>(
                  value: _sortOption,
                  items: ['Tên', 'Ngày hết hạn'].map((String value) {
                    return DropdownMenuItem<String>(
                        value: value, child: Text(value));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _sortOption = value!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Nguyên liệu trong tủ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('ingredients').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Lỗi khi tải dữ liệu'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<Map<String, dynamic>> ingredients = snapshot.data!.docs
                    .map((doc) {
                      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                      return {
                        'id': doc.id,
                        'name': data['name'] ?? '',
                        'quantity': data['quantity'] ?? 0,
                        'unit': data['unit'] ?? '',
                        'expiry': (data['expiry'] as Timestamp?)?.toDate() ??
                            DateTime.now(),
                      };
                    })
                    .toList();

                List<Map<String, dynamic>> filteredIngredients =
                    _filterAndSortIngredients(ingredients);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredIngredients.length > 3
                          ? 3
                          : filteredIngredients.length,
                      itemBuilder: (context, index) {
                        final item = filteredIngredients[index];
                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(item['name']),
                            subtitle: Text(
                                '${item['quantity']} ${item['unit']} - Hết hạn: ${DateFormat('yyyy-MM-dd').format(item['expiry'])}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _editIngredient(item),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _deleteIngredient(item),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    TextButton(
                      onPressed: () => _showAllIngredients(ingredients),
                      child: const Text('Xem tất cả'),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            const Text('Công thức món ăn',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('recipes').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Lỗi khi tải dữ liệu'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<Map<String, dynamic>> recipes = snapshot.data!.docs.map((doc) {
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

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recipes.length > 3 ? 3 : recipes.length,
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
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _editRecipe(recipe),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _deleteRecipe(recipe),
                                ),
                              ],
                            ),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(recipe['name']),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('Nguyên liệu:',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 5),
                                        Text(recipe['ingredients']),
                                        const SizedBox(height: 10),
                                        const Text('Thời gian:',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 5),
                                        Text(recipe['time']),
                                        const SizedBox(height: 10),
                                        const Text('Loại món:',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 5),
                                        Text(recipe['type'].join(', ')),
                                        const SizedBox(height: 10),
                                        const Text('Công thức:',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 5),
                                        Text(recipe['recipe']),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Đóng'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                    TextButton(
                      onPressed: () => _showAllRecipes(recipes),
                      child: const Text('Xem tất cả'),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('scan_history').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Lỗi khi tải dữ liệu'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<String> scanHistory =
                    snapshot.data!.docs.map((doc) => doc['entry'] as String).toList();

                return Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10.0, // Khoảng cách ngang giữa các phần tử
                  runSpacing: 10.0, // Khoảng cách dọc giữa các dòng
                  children: [
                    TextButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (context) => Container(
                            padding: const EdgeInsets.all(20.0),
                            height: 300,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Center(
                                  child: Text(
                                    'Lịch sử quét',
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: scanHistory.length,
                                    itemBuilder: (context, index) {
                                      return ListTile(
                                        title: Text(scanHistory[index]),
                                      );
                                    },
                                  ),
                                ),
                                Center(
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 40, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12)),
                                      backgroundColor: Colors.green,
                                    ),
                                    child: const Text('Đóng',
                                        style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: const Text('Lịch sử quét'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _addIngredient,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Thêm nguyên liệu'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontSize: 14),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _addRecipe,
                      icon: const Icon(Icons.book, size: 18),
                      label: const Text('Thêm công thức'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontSize: 14),
                      ),
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