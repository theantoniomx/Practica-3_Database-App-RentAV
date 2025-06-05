import 'package:flutter/material.dart';
import 'package:practica_3_database/models/user.dart';
import 'package:practica_3_database/services/db_service.dart';
import 'category_screen.dart';

class AddRentScreen extends StatefulWidget {
  const AddRentScreen({super.key});

  @override
  State<AddRentScreen> createState() => _AddRentScreenState();
}

class _AddRentScreenState extends State<AddRentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  List<User> _users = [];
  User? _selectedUser;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await DBService().getAllUsers();
    setState(() {
      _users = users;
    });
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _goToCategorySelection() {
    if (!_formKey.currentState!.validate() ||
        _selectedUser == null ||
        _startDate == null ||
        _endDate == null)
      return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryScreen(
          title: _titleController.text,
          startDate: _startDate!,
          endDate: _endDate!,
          user: _selectedUser!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar Nueva Renta')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<User>(
                value: _selectedUser,
                decoration: const InputDecoration(labelText: 'Cliente'),
                items: _users
                    .map(
                      (user) =>
                          DropdownMenuItem(value: user, child: Text(user.name)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedUser = value),
                validator: (value) =>
                    value == null ? 'Seleccione un cliente' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título de la renta',
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _selectDate(true),
                      child: Text(
                        _startDate == null
                            ? 'Fecha inicio'
                            : _startDate!.toLocal().toString().split(' ')[0],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _selectDate(false),
                      child: Text(
                        _endDate == null
                            ? 'Fecha fin'
                            : _endDate!.toLocal().toString().split(' ')[0],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.arrow_forward_ios),
                label: const Text('Continuar con selección de productos'),
                onPressed: _goToCategorySelection,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
