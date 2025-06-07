import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:practica_3_database/models/rent.dart';
import 'package:practica_3_database/services/db_service.dart';
import 'package:practica_3_database/services/notification_service.dart';
import 'home_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final _segmentController = ValueNotifier("Todas");

  final List<String> _statuses = [
    'Todas',
    'Por cumplir',
    'En proceso',
    'Completado',
    'Cancelado',
  ];

  final List<String> _editableStatuses = [
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
    List<Rent> rents;
    if (selectedStatusLabel == 'Todas') {
      rents = await DBService().getAllRents();
    } else {
      rents = await DBService().getRentsByStatus(selectedStatusLabel);
    }

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

    final start = DateTime.parse(rent.startDate);
    final end = DateTime.parse(rent.endDate);
    final int days = end.difference(start).inDays + 1;

    final List<Map<String, dynamic>> equipmentList = [];
    double total = 0;

    for (final detail in rentDetails) {
      final equipment = await DBService().getEquipmentById(detail.equipmentId);
      if (equipment != null) {
        double subtotal = equipment.price * detail.quantity * days;
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
                      'Estado:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    DropdownButtonFormField2<String>(
                      value: selectedStatus,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: _editableStatuses.map((status) {
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

                          if (value == 'Por cumplir' || value == 'En proceso') {
                            await NotificationService.scheduleRentReminder(
                              id: rent.id!,
                              title: rent.title,
                              startDate: DateTime.parse(rent.startDate),
                            );
                          } else if (value == 'Completado' ||
                              value == 'Cancelado') {
                            await NotificationService.cancelReminder(rent.id!);
                          }

                          await _loadRents();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Estado actualizado'),
                              ),
                            );
                          }
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
        return Colors.grey.shade300;
      case 'Cancelado':
        return Colors.red.shade300;
      case 'En proceso':
        return Colors.orange.shade300;
      case 'Por cumplir':
        return Colors.green.shade300;
      default:
        return Colors.blue.shade300;
    }
  }

  Icon _getStatusIcon(String status) {
    switch (status) {
      case 'Completado':
        return const Icon(Icons.verified, color: Colors.grey);
      case 'Cancelado':
        return const Icon(Icons.block, color: Colors.red);
      case 'En proceso':
        return const Icon(Icons.autorenew, color: Colors.orange);
      case 'Por cumplir':
        return const Icon(Icons.schedule, color: Colors.green);
      default:
        return const Icon(Icons.list, color: Colors.indigo);
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
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Filtrar por estado:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(height: 60, child: _buildStatusFilterBar()),
            ),
            const SizedBox(height: 12),
            const TabBar(
              tabs: [
                Tab(text: 'Lista'),
                Tab(text: 'Calendario'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [_buildRentListView(), _buildCalendarView()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRentListView() {
    final allRents = _events.values.expand((e) => e).toList();
    return allRents.isEmpty
        ? const Center(child: Text('No hay rentas registradas.'))
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: allRents.length,
            itemBuilder: (context, index) {
              final rent = allRents[index];
              return FutureBuilder<String>(
                future: DBService().getUserNameById(rent.userId),
                builder: (_, snapshot) {
                  final client = snapshot.data ?? '...';
                  return Card(
                    color: _getStatusColor(rent.status),
                    child: ListTile(
                      title: Text(rent.title),
                      subtitle: Text('Cliente: $client'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () => _showRentDetailModal(rent),
                    ),
                  );
                },
              );
            },
          );
  }

  Widget _buildCalendarView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: TableCalendar<Rent>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2100, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: _onDaySelected,
        eventLoader: _getRentsForDay,
        calendarStyle: const CalendarStyle(
          markersAlignment: Alignment.bottomCenter,
          markersMaxCount: 5,
        ),
        calendarBuilders: CalendarBuilders<Rent>(
          markerBuilder: (context, date, rents) {
            if (rents.isEmpty) return const SizedBox.shrink();

            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: rents.take(5).map((rent) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1.2),
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _getStatusColor(rent.status),
                    shape: BoxShape.circle,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _statuses.map((status) {
          final isSelected = selectedStatusLabel == status;
          return GestureDetector(
            onTap: () {
              _segmentController.value = status;
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getStatusIcon(status).icon,
                  color: isSelected ? _getStatusColor(status) : Colors.grey,
                ),
                if (isSelected)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(status),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
