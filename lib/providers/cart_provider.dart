import 'package:flutter/foundation.dart';
import 'package:practica_3_database/models/equipment.dart';

class CartProvider with ChangeNotifier {
  final Map<int, int> _cartItems = {};

  Map<int, int> get cartItems => _cartItems;

  void addToCart(Equipment equipment, int quantity) {
    if (_cartItems.containsKey(equipment.id)) {
      _cartItems[equipment.id!] = _cartItems[equipment.id!]! + quantity;
    } else {
      _cartItems[equipment.id!] = quantity;
    }
    notifyListeners();
  }

  void removeFromCart(int equipmentId) {
    _cartItems.remove(equipmentId);
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  int get totalItems => _cartItems.values.fold(0, (sum, item) => sum + item);
}
