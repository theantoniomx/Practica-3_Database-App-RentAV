import 'package:flutter/material.dart';
import 'calendar_screen.dart';
import 'add_rent_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RentAV')),
      body: GridView.count(
        padding: const EdgeInsets.all(20),
        crossAxisCount: 1,
        mainAxisSpacing: 20,
        childAspectRatio: 3,
        children: [
          _HomeButton(
            icon: Icons.add_box,
            label: 'Nueva Renta',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddRentScreen()),
            ),
          ),
          _HomeButton(
            icon: Icons.calendar_today,
            label: 'Calendario',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CalendarScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HomeButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Center(
          child: ListTile(
            leading: Icon(icon, size: 32, color: Colors.indigo),
            title: Text(
              label,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }
}
