import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For formatting dates
import 'package:share_plus/share_plus.dart'; // For sharing

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, dynamic>> _allIngredients = [];
  List<Map<String, dynamic>> _filteredIngredients = [];
  String _filterOption = 'Tất cả';
  String _sortOption = 'Tên';
  String _searchQuery = '';
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchIngredientsFromFirestore();
  }

  Future<void> _fetchIngredientsFromFirestore() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('ingredients').get();

      List<Map<String, dynamic>> fetchedIngredients = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'quantity': data['quantity'] ?? 0,
          'unit': data['unit'] ?? '',
          'expiry': (data['expiry'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();

      setState(() {
        _allIngredients = fetchedIngredients;
        _isLoading = false;
      });

      _filterAndSortIngredients();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi khi tải dữ liệu: $e';
      });
    }
  }

  void _filterAndSortIngredients() {
    setState(() {
      _filteredIngredients = _allIngredients.where((item) {
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
        _filteredIngredients.sort((a, b) => a['name'].compareTo(b['name']));
      } else if (_sortOption == 'Ngày hết hạn') {
        _filteredIngredients.sort((a, b) => a['expiry'].compareTo(b['expiry']));
      }
    });
  }

  double _calculateFridgePercentage() {
    const maxCapacity = 20;
    final totalItems =
        _allIngredients.fold(0, (sum, item) => sum + (item['quantity'] as int));
    return totalItems / maxCapacity;
  }

  void _showAllIngredients() {
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
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(child: Text(_errorMessage!))
                      : ListView.builder(
                          itemCount: _filteredIngredients.length,
                          itemBuilder: (context, index) {
                            final item = _filteredIngredients[index];
                            return Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(item['name']),
                                subtitle: Text(
                                    '${item['quantity']} ${item['unit']} - Hết hạn: ${DateFormat('yyyy-MM-dd').format(item['expiry'])}'),
                                trailing: const Icon(Icons.arrow_forward_ios,
                                    size: 16),
                                onTap: () {
                                  Navigator.pop(context);
                                  _showIngredientDetails(item);
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

  void _showIngredientDetails(Map<String, dynamic> item) {
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
                item['name'],
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green),
              ),
            ),
            const SizedBox(height: 20),
            Text('Số lượng: ${item['quantity']} ${item['unit']}'),
            const SizedBox(height: 10),
            Text(
                'Ngày hết hạn: ${DateFormat('yyyy-MM-dd').format(item['expiry'])}'),
            const SizedBox(height: 30),
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

  // Custom sharing dialog
  void _showShareDialog() {
    if (_allIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có nguyên liệu để chia sẻ')),
      );
      return;
    }

    // Format the initial share text
    String shareText = _allIngredients
        .map((item) =>
            '${item['name']}: ${item['quantity']} ${item['unit']} (Hết hạn: ${DateFormat('yyyy-MM-dd').format(item['expiry'])})')
        .join('\n');

    // Controller for the editable message
    final messageController = TextEditingController(
      text: 'Danh sách nguyên liệu trong tủ lạnh:\n\n$shareText',
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
              'Chia sẻ tủ lạnh',
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
                    subject: 'Danh sách nguyên liệu tủ lạnh',
                  );

                  // Close both dialogs
                  Navigator.pop(context); // Close loading dialog
                  Navigator.pop(context); // Close share dialog

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã chia sẻ tủ lạnh')),
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
        title: const Text('Tổng quan'),
        backgroundColor: Colors.green,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : SingleChildScrollView(
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
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                            _filterAndSortIngredients();
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Tổng quan tủ lạnh',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                      '${_allIngredients.length} nguyên liệu hiện có'),
                                ],
                              ),
                              CircularProgressIndicator(
                                value: _calculateFridgePercentage(),
                                strokeWidth: 8,
                                backgroundColor: Colors.grey[300],
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    Colors.green),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Nguyên liệu trong tủ',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
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
                                _filterAndSortIngredients();
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
                                _filterAndSortIngredients();
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredIngredients.length > 3
                            ? 3
                            : _filteredIngredients.length,
                        itemBuilder: (context, index) {
                          final item = _filteredIngredients[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              title: Text(item['name']),
                              subtitle: Text(
                                  '${item['quantity']} ${item['unit']} - Hết hạn: ${DateFormat('yyyy-MM-dd').format(item['expiry'])}'),
                              trailing: const Icon(Icons.arrow_forward_ios,
                                  size: 16),
                              onTap: () => _showIngredientDetails(item),
                            ),
                          );
                        },
                      ),
                      TextButton(
                        onPressed: _showAllIngredients,
                        child: const Text('Xem tất cả'),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _showShareDialog, // Updated to show custom dialog
                        icon: const Icon(Icons.share),
                        label: const Text('Chia sẻ tủ lạnh'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}