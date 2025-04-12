// cooked_dishes_list.dart
import 'package:flutter/material.dart';
import 'dish_detail_bottom_sheet.dart';

class CookedDishesList extends StatelessWidget {
  final List<Map<String, dynamic>> dishes;

  const CookedDishesList({super.key, required this.dishes});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: dishes.length,
      itemBuilder: (context, index) {
        final dish = dishes[index];
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
                  builder: (context) => DishDetailBottomSheet(dish: dish),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
