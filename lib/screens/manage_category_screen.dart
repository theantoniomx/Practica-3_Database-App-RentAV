import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:practica_3_database/models/category.dart';
import 'package:practica_3_database/models/equipment.dart';
import 'package:practica_3_database/services/db_service.dart';

class ManageCategoryScreen extends StatefulWidget {
  final Category category;

  const ManageCategoryScreen({super.key, required this.category});

  @override
  State<ManageCategoryScreen> createState() => _ManageCategoryScreenState();
}

class _ManageCategoryScreenState extends State<ManageCategoryScreen> {
  late Category _category;
  List<Equipment> _equipmentList = [];

  @override
  void initState() {
    super.initState();
    _category = widget.category;
    _loadEquipment();
  }

  Future<void> _loadEquipment() async {
    final items = await DBService().getEquipmentByCategory(_category.id!);
    setState(() {
      _equipmentList = items;
    });
  }

  Future<void> _editCategory() async {
    final nameController = TextEditingController(text: _category.name);
    String imagePath = _category.imagePath;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: StatefulBuilder(
            builder: (context, setStateSheet) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Editar Categoría',
                      style: TextStyle(fontSize: 18),
                    ),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                    ),
                    const SizedBox(height: 12),
                    imagePath.startsWith('assets/')
                        ? Image.asset(imagePath, height: 100)
                        : Image.file(File(imagePath), height: 100),
                    TextButton.icon(
                      onPressed: () async {
                        final picked = await ImagePicker().pickImage(
                          source: ImageSource.gallery,
                        );
                        if (picked != null) {
                          setStateSheet(() => imagePath = picked.path);
                        }
                      },
                      icon: const Icon(Icons.image),
                      label: const Text('Cambiar imagen'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final updated = Category(
                          id: _category.id,
                          name: nameController.text,
                          imagePath: imagePath,
                        );
                        await DBService().updateCategory(updated);
                        setState(() => _category = updated);
                        Navigator.pop(context);
                      },
                      child: const Text('Guardar'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _addNewEquipment() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController();
    String? imagePath;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: StatefulBuilder(
            builder: (context, setStateSheet) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Nuevo Servicio',
                        style: TextStyle(fontSize: 18),
                      ),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                      ),
                      TextField(
                        controller: descController,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                        ),
                      ),
                      TextField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Precio'),
                      ),
                      const SizedBox(height: 10),
                      imagePath != null
                          ? Image.file(File(imagePath!), height: 100)
                          : const Text('No se ha seleccionado imagen'),
                      TextButton.icon(
                        onPressed: () async {
                          final picked = await ImagePicker().pickImage(
                            source: ImageSource.gallery,
                          );
                          if (picked != null) {
                            setStateSheet(() => imagePath = picked.path);
                          }
                        },
                        icon: const Icon(Icons.image),
                        label: const Text('Seleccionar imagen'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (nameController.text.isEmpty ||
                              descController.text.isEmpty ||
                              priceController.text.isEmpty ||
                              imagePath == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Todos los campos son obligatorios',
                                ),
                              ),
                            );
                            return;
                          }

                          final newEquipment = Equipment(
                            name: nameController.text,
                            description: descController.text,
                            price: double.tryParse(priceController.text) ?? 0.0,
                            imagePath: imagePath!,
                            categoryId: _category.id!,
                          );

                          await DBService().insertEquipment(newEquipment);
                          await _loadEquipment();
                          Navigator.pop(context);
                        },
                        child: const Text('Registrar'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _deleteEquipment(int equipmentId) async {
    final isRented = await DBService().isEquipmentInAnyRent(equipmentId);
    if (isRented) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este servicio ya fue rentado y no puede eliminarse.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar Servicio'),
        content: const Text('¿Deseas eliminar este servicio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DBService().deleteEquipment(equipmentId);
      await _loadEquipment();
    }
  }

  Future<void> _editEquipment(Equipment equipment) async {
    final nameController = TextEditingController(text: equipment.name);
    final descController = TextEditingController(text: equipment.description);
    final priceController = TextEditingController(
      text: equipment.price.toString(),
    );
    String imagePath = equipment.imagePath;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: StatefulBuilder(
            builder: (context, setStateSheet) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Editar Servicio',
                      style: TextStyle(fontSize: 18),
                    ),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                    ),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                      ),
                    ),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Precio'),
                    ),
                    const SizedBox(height: 10),
                    Image.file(File(imagePath), height: 100),
                    TextButton.icon(
                      onPressed: () async {
                        final picked = await ImagePicker().pickImage(
                          source: ImageSource.gallery,
                        );
                        if (picked != null) {
                          setStateSheet(() => imagePath = picked.path);
                        }
                      },
                      icon: const Icon(Icons.image),
                      label: const Text('Cambiar imagen'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final updated = Equipment(
                          id: equipment.id,
                          name: nameController.text,
                          description: descController.text,
                          price: double.tryParse(priceController.text) ?? 0.0,
                          imagePath: imagePath,
                          categoryId: equipment.categoryId,
                        );
                        await DBService().updateEquipment(updated);
                        await _loadEquipment();
                        Navigator.pop(context);
                      },
                      child: const Text('Guardar'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _deleteCategory() async {
    if (_equipmentList.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede eliminar: tiene servicios.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar Categoría'),
        content: const Text('¿Estás seguro de eliminar esta categoría?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DBService().deleteCategory(_category.id!);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAsset = _category.imagePath.startsWith('assets/');

    return Scaffold(
      appBar: AppBar(
        title: Text('Categoría: ${_category.name}'),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _editCategory),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteCategory,
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: isAsset
                ? Image.asset(
                    _category.imagePath,
                    height: 180,
                    fit: BoxFit.cover,
                  )
                : Image.file(
                    File(_category.imagePath),
                    height: 180,
                    fit: BoxFit.cover,
                  ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Servicios (${_equipmentList.length}):',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          _equipmentList.isEmpty
              ? const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('No hay servicios registrados.'),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final eq = _equipmentList[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        title: Text(eq.name),
                        subtitle: Text(eq.description),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editEquipment(eq),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteEquipment(eq.id!),
                            ),
                          ],
                        ),
                      ),
                    );
                  }, childCount: _equipmentList.length),
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewEquipment,
        child: const Icon(Icons.add),
      ),
    );
  }
}
