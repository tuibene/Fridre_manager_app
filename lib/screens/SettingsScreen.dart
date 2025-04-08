import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:badges/badges.dart' as badges; // Import badges

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  String _warningPeriod = '3 ngày';
  String _language = 'VN';
  bool _darkMode = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    clientId: kIsWeb
        ? '639819162925-sil813n2r3b0e68paq7pu17f8avjfepc.apps.googleusercontent.com'
        : null,
  );

  Future<void> _logout() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đăng xuất')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi đăng xuất: $e')),
        );
      }
    }
  }

  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu cài đặt')),
    );
    print(
        'Ngôn ngữ: $_language, Chế độ tối: $_darkMode, Thông báo: $_notificationsEnabled, Cảnh báo sớm: $_warningPeriod');
  }

  List<Map<String, String>> _getExpiringIngredients(List<Map<String, dynamic>> ingredients) {
    final int warningDays = int.parse(_warningPeriod.split(' ')[0]);
    final now = DateTime.now();
    final formatter = DateFormat('dd/MM/yyyy HH:mm');

    return ingredients
        .where((item) {
          final expiryDate = item['expiry'] as DateTime;
          final daysLeft = expiryDate.difference(now).inDays;
          print('Checking ${item['name']}: Expiry ${formatter.format(expiryDate)}, Days left: $daysLeft');
          return daysLeft <= warningDays && daysLeft >= 0;
        })
        .map((item) => {
              'title': '${item['name']} sắp hết hạn',
              'time': formatter.format(item['expiry'] as DateTime),
            })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, authSnapshot) {
        bool isLoggedIn = authSnapshot.hasData;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Cài đặt'),
            backgroundColor: Colors.green,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    title: const Text('Tài khoản'),
                    subtitle: Text(isLoggedIn
                        ? _auth.currentUser?.email ?? 'Đã đăng nhập'
                        : 'Chưa đăng nhập'),
                    trailing: TextButton(
                      onPressed: () {
                        if (isLoggedIn) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Đăng xuất'),
                              content: const Text('Bạn có chắc muốn đăng xuất không?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Hủy'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    _logout();
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Đăng xuất'),
                                ),
                              ],
                            ),
                          );
                        } else {
                          Navigator.pushNamed(context, '/login');
                        }
                      },
                      child: Text(isLoggedIn ? 'Đăng xuất' : 'Đăng nhập'),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Thông báo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('ingredients').snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            print('Error: ${snapshot.error}');
                            return const ListTile(title: Text('Lỗi khi tải dữ liệu'));
                          }
                          if (!snapshot.hasData) {
                            return const ListTile(
                              title: Text('Đang tải...'),
                              trailing: CircularProgressIndicator(),
                            );
                          }

                          List<Map<String, dynamic>> ingredients = snapshot.data!.docs.map((doc) {
                            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                            return {
                              'id': doc.id,
                              'name': data['name'] ?? '',
                              'quantity': data['quantity'] ?? 0,
                              'unit': data['unit'] ?? '',
                              'expiry': (data['expiry'] as Timestamp?)?.toDate() ?? DateTime.now(),
                            };
                          }).toList();

                          if (ingredients.isEmpty) {
                            print('No ingredients found');
                          } else {
                            print('Found ${ingredients.length} ingredients');
                          }

                          List<Map<String, String>> expiringIngredients =
                              _getExpiringIngredients(ingredients);
                          int expiringCount = expiringIngredients.length; // Số lượng nguyên liệu hết hạn

                          return badges.Badge(
                            badgeContent: Text(
                              expiringCount.toString(),
                              style: const TextStyle(color: Colors.white),
                            ),
                            badgeStyle: badges.BadgeStyle(
                              shape: badges.BadgeShape.circle,
                              badgeColor: Colors.red,
                              padding: const EdgeInsets.all(5),
                            ),
                            position: badges.BadgePosition.topEnd(top: -10, end: -10),
                            child: ListTile(
                              title: const Text('Xem danh sách thông báo'),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () {
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
                                        const Center(
                                          child: Text(
                                            'Danh sách thông báo',
                                            style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Expanded(
                                          child: expiringIngredients.isEmpty
                                              ? const Center(child: Text('Chưa có thông báo hết hạn'))
                                              : ListView.builder(
                                                  itemCount: expiringIngredients.length,
                                                  itemBuilder: (context, index) {
                                                    return ListTile(
                                                      title: Text(expiringIngredients[index]['title']!),
                                                      subtitle: Text(expiringIngredients[index]['time']!),
                                                    );
                                                  },
                                                ),
                                        ),
                                        const SizedBox(height: 20),
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
                          );
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Bật thông báo'),
                        value: _notificationsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _notificationsEnabled = value;
                          });
                        },
                      ),
                      ListTile(
                        title: const Text('Cảnh báo sớm'),
                        trailing: DropdownButton<String>(
                          value: _warningPeriod,
                          items: ['1 ngày', '2 ngày', '3 ngày'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _warningPeriod = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Giao diện',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('Ngôn ngữ'),
                        trailing: DropdownButton<String>(
                          value: _language,
                          items: ['VN', 'EN'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value == 'VN' ? 'Tiếng Việt' : 'English'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _language = value!;
                            });
                          },
                        ),
                      ),
                      SwitchListTile(
                        title: const Text('Chế độ tối'),
                        value: _darkMode,
                        onChanged: (value) {
                          setState(() {
                            _darkMode = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: Colors.green,
                    ),
                    child: const Text(
                      'Lưu',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}