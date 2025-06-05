import 'package:flutter/foundation.dart';
import 'package:practica_3_database/models/rent.dart';
import 'package:practica_3_database/services/db_service.dart';

class RentProvider with ChangeNotifier {
  List<Rent> _rents = [];

  List<Rent> get rents => _rents;

  Future<void> loadRentsByStatus(String status) async {
    _rents = await DBService().getRentsByStatus(status);
    notifyListeners();
  }

  Future<void> updateRentStatus(int rentId, String newStatus) async {
    await DBService().updateRentStatus(rentId, newStatus);
    await loadRentsByStatus(newStatus);
  }

  void clearRents() {
    _rents.clear();
    notifyListeners();
  }
}
