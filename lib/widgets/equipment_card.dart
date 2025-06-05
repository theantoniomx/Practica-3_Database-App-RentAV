import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:practica_3_database/models/equipment.dart';
import 'package:practica_3_database/providers/cart_provider.dart';

class EquipmentCard extends StatefulWidget {
  final Equipment equipment;
  const EquipmentCard({super.key, required this.equipment});

  @override
  State<EquipmentCard> createState() => _EquipmentCardState();
}

class _EquipmentCardState extends State<EquipmentCard> {
  int _quantity = 0;

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.equipment.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(widget.equipment.description),
            const SizedBox(height: 6),
            Text(
              '\$${widget.equipment.price.toStringAsFixed(2)} MXN',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _quantity > 0
                      ? () {
                          setState(() {
                            _quantity--;
                          });
                        }
                      : null,
                ),
                Text('$_quantity', style: const TextStyle(fontSize: 16)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    setState(() {
                      _quantity++;
                    });
                  },
                ),
                const Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Agregar'),
                  onPressed: _quantity > 0
                      ? () {
                          cartProvider.addToCart(widget.equipment, _quantity);
                          setState(() {
                            _quantity = 0;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Equipo agregado al carrito'),
                            ),
                          );
                        }
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
