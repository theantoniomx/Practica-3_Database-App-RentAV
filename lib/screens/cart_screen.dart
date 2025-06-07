import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:practica_3_database/models/equipment.dart';
import 'package:practica_3_database/models/user.dart';
import 'package:practica_3_database/providers/cart_provider.dart';
import 'package:practica_3_database/services/db_service.dart';
import 'confirm_rent_screen.dart';

class CartScreen extends StatelessWidget {
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final User user;

  const CartScreen({
    super.key,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.user,
  });

  Future<List<Map<String, dynamic>>> _getCartDetails(
    Map<int, int> cartItems,
    int days,
  ) async {
    final List<Map<String, dynamic>> details = [];
    for (var entry in cartItems.entries) {
      final equipment = await DBService().getEquipmentById(entry.key);
      if (equipment != null) {
        details.add({
          'equipment': equipment,
          'quantity': entry.value,
          'subtotal': equipment.price * entry.value * days,
        });
      }
    }
    return details;
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final cartItems = cartProvider.cartItems;
    final int days = endDate.difference(startDate).inDays + 1;

    return Scaffold(
      appBar: AppBar(title: const Text('Carrito de renta')),
      body: cartItems.isEmpty
          ? const Center(child: Text('Tu carrito está vacío'))
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: _getCartDetails(cartItems, days), 
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final cartDetails = snapshot.data!;
                final total = cartDetails.fold<double>(
                  0,
                  (sum, item) => sum + (item['subtotal'] as double),
                );

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: cartDetails.length,
                        itemBuilder: (context, index) {
                          final equipment =
                              cartDetails[index]['equipment'] as Equipment;
                          final quantity = cartDetails[index]['quantity'];
                          final subtotal = cartDetails[index]['subtotal'];

                          return Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(quantity.toString()),
                              ),
                              title: Text(equipment.name),
                              subtitle: Text(
                                'Precio unitario: \$${equipment.price.toStringAsFixed(2)} x $days días\nSubtotal: \$${subtotal.toStringAsFixed(2)}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () =>
                                    cartProvider.removeFromCart(equipment.id!),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            '\$${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Confirmar Renta'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ConfirmRentScreen(
                                title: title,
                                startDate: startDate,
                                endDate: endDate,
                                user: user,
                                items: cartItems,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
