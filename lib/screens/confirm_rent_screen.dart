import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:practica_3_database/screens/calendar_screen.dart';
import 'package:practica_3_database/providers/cart_provider.dart';
import 'package:practica_3_database/models/rent.dart';
import 'package:practica_3_database/models/rent_detail.dart';
import 'package:practica_3_database/models/user.dart';
import 'package:practica_3_database/models/equipment.dart';
import 'package:practica_3_database/services/db_service.dart';
import 'package:practica_3_database/services/notification_service.dart';

class ConfirmRentScreen extends StatelessWidget {
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final User user;
  final Map<int, int> items;

  const ConfirmRentScreen({
    super.key,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.user,
    required this.items,
  });

  Future<List<Map<String, dynamic>>> _getCartDetails(int days) async {
    final List<Map<String, dynamic>> details = [];

    for (var entry in items.entries) {
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

  Future<void> _submit(BuildContext context, double total) async {
    final reminderDate = startDate.subtract(const Duration(days: 2));
    final rent = Rent(
      title: title,
      startDate: startDate.toIso8601String(),
      endDate: endDate.toIso8601String(),
      status: 'Por cumplir',
      reminderDate: reminderDate.toIso8601String(),
      userId: user.id!,
      total: total,
    );

    final db = DBService();
    final rentId = await db.insertRent(rent);

    for (var entry in items.entries) {
      final detail = RentDetail(
        rentId: rentId,
        equipmentId: entry.key,
        quantity: entry.value,
      );
      await db.insertRentDetail(detail);
    }

    await NotificationService.scheduleRentReminder(
      id: rentId,
      title: title,
      startDate: startDate,
    );

    Provider.of<CartProvider>(context, listen: false).clearCart();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Renta registrada'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 60),
            SizedBox(height: 12),
            Text('La renta ha sido registrada exitosamente.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const CalendarScreen()),
                (route) => false,
              );
            },
            child: const Text('Ir al calendario'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int days = endDate.difference(startDate).inDays + 1;

    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar Renta')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getCartDetails(days),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final details = snapshot.data!;
          final total = details.fold<double>(
            0,
            (sum, item) => sum + (item['subtotal'] as double),
          );

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cliente: ${user.name}',
                  style: const TextStyle(fontSize: 16),
                ),
                Text('Título: $title', style: const TextStyle(fontSize: 16)),
                Text(
                  'Fechas: ${startDate.toLocal().toString().split(' ')[0]} → ${endDate.toLocal().toString().split(' ')[0]}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Chip(
                  avatar: const Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Renta por $days día(s)',
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                const SizedBox(height: 16),
                const Text(
                  'Productos seleccionados:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: details.length,
                    itemBuilder: (context, index) {
                      final equipment =
                          details[index]['equipment'] as Equipment;
                      final qty = details[index]['quantity'];
                      final subtotal = details[index]['subtotal'];

                      return ListTile(
                        title: Text(equipment.name),
                        subtitle: Text(
                          'Cantidad: $qty | Subtotal: \$${subtotal.toStringAsFixed(2)}',
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Registrar Renta'),
                    onPressed: () => _submit(context, total),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
