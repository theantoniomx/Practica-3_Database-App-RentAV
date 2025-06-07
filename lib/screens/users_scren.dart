import 'package:flutter/material.dart';
import 'package:practica_3_database/models/user.dart';
import 'package:practica_3_database/services/db_service.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final DBService _dbService = DBService();
  List<User> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await _dbService.getAllUsers();
    setState(() {
      _users = users;
    });
  }

  void _showUserForm({User? user}) {
    final _formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user?.name);
    final emailController = TextEditingController(text: user?.email);
    final phoneController = TextEditingController(text: user?.phone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 24,
          left: 16,
          right: 16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                user == null ? 'Nuevo Cliente' : 'Editar Cliente',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Nombre requerido'
                    : null,
              ),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Correo'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Correo requerido';
                  }
                  final emailRegex = RegExp(
                    r'^[\w\.-]+@([\w-]+\.)+(com|mx|edu\.mx|org|net|itcelaya\.edu\.mx)$',
                  );
                  if (!emailRegex.hasMatch(value.trim())) {
                    return 'Correo no válido';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Teléfono requerido';
                  }
                  final phoneRegex = RegExp(r'^\d{10}$');
                  if (!phoneRegex.hasMatch(value.trim())) {
                    return 'Debe contener exactamente 10 dígitos';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final newUser = User(
                      id: user?.id,
                      name: nameController.text,
                      email: emailController.text,
                      phone: phoneController.text,
                    );

                    if (user == null) {
                      await _dbService.insertUser(newUser);
                    } else {
                      await _dbService.updateUser(newUser);
                    }
                    Navigator.pop(context);
                    _loadUsers();
                  }
                },
                child: Text(user == null ? 'Crear' : 'Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(User user) async {
    final hasRents = await _dbService.hasUserAnyRent(user.id!);
    if (hasRents) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se puede eliminar a "${user.name}" porque tiene rentas registradas.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar Cliente'),
        content: Text('¿Estás seguro de eliminar a "${user.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await _dbService.deleteUser(user.id!);
              Navigator.pop(context);
              _loadUsers();
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Clientes'),
            floating: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.person_add),
                onPressed: () => _showUserForm(),
              ),
            ],
          ),
          _users.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No hay clientes registrados.',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final user = _users[index];
                    return ListTile(
                      title: Text(user.name),
                      subtitle: Text('${user.email}\n${user.phone}'),
                      isThreeLine: true,
                      onTap: () => _showUserForm(user: user),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _showDeleteDialog(user),
                      ),
                    );
                  }, childCount: _users.length),
                ),
        ],
      ),
    );
  }
}
