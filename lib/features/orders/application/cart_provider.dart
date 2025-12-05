import 'package:flutter/foundation.dart';

import '../../products/domain/dish.dart';
import '../../products/domain/kitchen.dart';

class CartItem {
  final Dish dish;
  int quantity;

  CartItem({required this.dish, this.quantity = 1});

  double get lineTotal => dish.price * quantity;
}

class CartProvider extends ChangeNotifier {
  Kitchen? _kitchen; // Cocina actual del carrito
  final List<CartItem> _items = [];

  Kitchen? get kitchen => _kitchen;
  List<CartItem> get items => List.unmodifiable(_items);

  bool get isEmpty => _items.isEmpty;
  double get total => _items.fold(0.0, (sum, item) => sum + item.lineTotal);

  // Agregar platillo al carrito
  void addDish(Kitchen kitchen, Dish dish) {
    // Si el carrito es de otra cocina, lo reiniciamos
    if (_kitchen != null && _kitchen!.id != kitchen.id) {
      _kitchen = kitchen;
      _items.clear();
    } else {
      _kitchen ??= kitchen;
    }

    final index = _items.indexWhere((item) => item.dish.id == dish.id);

    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(CartItem(dish: dish));
    }

    notifyListeners();
  }

  void increaseQuantity(CartItem item) {
    item.quantity++;
    notifyListeners();
  }

  void decreaseQuantity(CartItem item) {
    if (item.quantity > 1) {
      item.quantity--;
    } else {
      _items.remove(item);
      if (_items.isEmpty) _kitchen = null;
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _kitchen = null;
    notifyListeners();
  }
}
