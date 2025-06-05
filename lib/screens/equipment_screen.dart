import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:practica_3_database/models/equipment.dart';
import 'package:practica_3_database/services/db_service.dart';
import 'package:practica_3_database/widgets/equipment_card.dart';
import 'package:practica_3_database/providers/cart_provider.dart';

class EquipmentScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const EquipmentScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen> {
  List<Equipment> _equipmentList = [];

  @override
  void initState() {
    super.initState();
    _loadEquipment();
  }

  Future<void> _loadEquipment() async {
    final equipment = await DBService().getEquipmentByCategory(
      widget.categoryId,
    );
    setState(() {
      _equipmentList = equipment;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.categoryName)),
      body: _equipmentList.isEmpty
          ? const Center(child: Text('No hay equipos en esta categoría'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _equipmentList.length,
              itemBuilder: (context, index) {
                return EquipmentCard(equipment: _equipmentList[index]);
              },
            ),
    );
  }
}
