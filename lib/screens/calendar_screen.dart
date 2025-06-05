import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter_advanced_segment/flutter_advanced_segment.dart';
import 'package:practica_3_database/models/rent.dart';
import 'package:practica_3_database/services/db_service.dart';
import 'home_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final _segmentController = ValueNotifier("Por cumplir");

  final List<String> _statuses = [
    'Por cumplir',
    'En proceso',
    'Completado',
    'Cancelado',
  ];

  String get selectedStatusLabel => _segmentController.value;

  Map<DateTime, List<Rent>> _events = {};

  @override
  void initState() {
    super.initState();
    _segmentController.addListener(() {
      _loadRents();
    });
    _loadRents();
  }

  Future<void> _loadRents() async {
    final rents = await DBService().getRentsByStatus(selectedStatusLabel);
    final Map<DateTime, List<Rent>> grouped = {};

    for (var rent in rents) {
      final date = DateTime.parse(rent.startDate);
      final key = DateTime(date.year, date.month, date.day);
      grouped.putIfAbsent(key, () => []).add(rent);
    }

    setState(() {
      _events = grouped;
    });
  }

  List<Rent> _getRentsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });

    final selectedRents = _getRentsForDay(selectedDay);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.95,
          builder: (_, controller) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Text(
                  'Rentas del ${selectedDay.day}/${selectedDay.month}/${selectedDay.year}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: selectedRents.isEmpty
                      ? const Center(child: Text('No hay rentas para este día'))
                      : ListView.builder(
                          controller: controller,
                          itemCount: selectedRents.length,
                          itemBuilder: (_, index) {
                            final rent = selectedRents[index];
                            return FutureBuilder<String>(
                              future: DBService().getUserNameById(rent.userId),
                              builder: (_, snapshot) {
                                final client = snapshot.data ?? 'Cargando...';
                                return Card(
                                  color: _getStatusColor(rent.status),
                                  child: ListTile(
                                    title: Text(rent.title),
                                    subtitle: Text(
                                      'Cliente: $client\nInicio: ${rent.startDate.split("T")[0]}',
                                    ),
                                    trailing: const Icon(
                                      Icons.arrow_forward_ios,
                                    ),
                                    onTap: () async {
                                      Navigator.of(context).pop();
                                      await Future.delayed(
                                        const Duration(milliseconds: 300),
                                      );
                                      _showRentDetailModal(rent);
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showRentDetailModal(Rent rent) async {
    final clientName = await DBService().getUserNameById(rent.userId);
    final rentDetails = await DBService().getRentDetails(rent.id!);

    final List<Map<String, dynamic>> equipmentList = [];
    double total = 0;

    for (final detail in rentDetails) {
      final equipment = await DBService().getEquipmentById(detail.equipmentId);
      if (equipment != null) {
        double subtotal = equipment.price * detail.quantity;
        total += subtotal;
        equipmentList.add({
          'name': equipment.name,
          'quantity': detail.quantity,
          'subtotal': subtotal,
        });
      }
    }

    String selectedStatus = rent.status;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Título: ${rent.title}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Confirmar eliminación'),
                                content: const Text(
                                  '¿Estás seguro de que deseas eliminar esta renta?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: const Text('Cancelar'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    child: const Text(
                                      'Eliminar',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await DBService().deleteRent(rent.id!);
                              if (mounted) Navigator.pop(context);
                              await _loadRents();

                              if (mounted) {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Renta eliminada correctamente',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('Cliente: $clientName'),
                    Text('Inicio: ${rent.startDate.split("T")[0]}'),
                    Text('Fin: ${rent.endDate.split("T")[0]}'),
                    const SizedBox(height: 16),
                    const Text(
                      'Estado:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    DropdownButtonFormField2<String>(
                      value: selectedStatus,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: _statuses.map((status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Row(
                            children: [
                              _getStatusIcon(status),
                              const SizedBox(width: 8),
                              Text(status),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) async {
                        if (value != null && value != rent.status) {
                          setModalState(() => selectedStatus = value);
                          await DBService().updateRentStatus(rent.id!, value);
                          await _loadRents();
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Equipos Rentados:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    if (equipmentList.isEmpty)
                      const Text('No hay equipos registrados.')
                    else
                      ...equipmentList.map(
                        (item) => ListTile(
                          dense: true,
                          title: Text(item['name']),
                          trailing: Text(
                            'x${item['quantity']} - \$${item['subtotal'].toStringAsFixed(2)}',
                          ),
                        ),
                      ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '\$${total.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.close),
                        label: const Text('Cerrar'),
                        onPressed: () => Navigator.pop(context),
                      ),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completado':
        return Colors.grey.shade200;
      case 'Cancelado':
        return Colors.red.shade100;
      case 'En proceso':
        return Colors.orange.shade100;
      case 'Por cumplir':
      default:
        return Colors.green.shade100;
    }
  }

  Icon _getStatusIcon(String status) {
    switch (status) {
      case 'Completado':
        return const Icon(Icons.check_circle, color: Colors.grey);
      case 'Cancelado':
        return const Icon(Icons.cancel, color: Colors.red);
      case 'En proceso':
        return const Icon(Icons.access_time, color: Colors.orange);
      case 'Por cumplir':
      default:
        return const Icon(Icons.pending, color: Colors.green);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rentas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filtrar por estado:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              AdvancedSegment(
                controller: _segmentController,
                activeStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                  color: Colors.white,
                ),
                segments: {
                  'Por cumplir': 'Por cumplir',
                  'En proceso': 'En proceso',
                  'Completado': 'Completado',
                  'Cancelado': 'Cancelado',
                },
                backgroundColor: Colors.grey.shade300,
                sliderColor: () {
                  switch (_segmentController.value) {
                    case 'Por cumplir':
                      return Colors.green;
                    case 'En proceso':
                      return Colors.orange;
                    case 'Completado':
                      return Colors.grey;
                    case 'Cancelado':
                      return Colors.red;
                    default:
                      return Colors.black87;
                  }
                }(),
              ),
              const SizedBox(height: 20),
              TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2100, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: _onDaySelected,
                eventLoader: _getRentsForDay,
                calendarStyle: CalendarStyle(
                  markerDecoration: BoxDecoration(
                    color: _getStatusColor(
                      selectedStatusLabel,
                    ).withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
