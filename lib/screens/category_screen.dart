import 'package:flutter/material.dart';
import 'package:practica_3_database/screens/cart_screen.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;

import 'package:practica_3_database/models/category.dart';
import 'package:practica_3_database/models/user.dart';
import 'package:practica_3_database/services/db_service.dart';
import 'package:practica_3_database/widgets/category_card.dart';
import 'package:practica_3_database/providers/cart_provider.dart';

class CategoryScreen extends StatefulWidget {
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final User user;

  const CategoryScreen({
    super.key,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.user,
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await DBService().getAllCategories();
    setState(() {
      _categories = categories;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
        actions: [
          Consumer<CartProvider>(
            builder: (_, cartProvider, __) {
              return IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CartScreen(
                        title: widget.title,
                        startDate: widget.startDate,
                        endDate: widget.endDate,
                        user: widget.user,
                      ),
                    ),
                  );
                },
                icon: badges.Badge(
                  position: badges.BadgePosition.topEnd(top: -4, end: -4),
                  showBadge: cartProvider.totalItems > 0,
                  badgeContent: Text(
                    cartProvider.totalItems.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  child: const Icon(Icons.shopping_cart),
                ),
              );
            },
          ),
        ],
      ),
      body: _categories.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                return CategoryCard(category: _categories[index]);
              },
            ),
    );
  }
}
