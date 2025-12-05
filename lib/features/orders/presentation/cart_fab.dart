import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../application/cart_provider.dart';
import '../../dashboard/presentation/orders_screen.dart';

class CartFab extends StatefulWidget {
  const CartFab({super.key});

  @override
  State<CartFab> createState() => _CartFabState();
}

class _CartFabState extends State<CartFab> {
  int _prevCount = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        final hasItems = !cart.isEmpty;
        final itemCount = cart.items.length;

        // si no hay nada en el carrito, no mostramos botón
        if (!hasItems) {
          _prevCount = 0;
          return const SizedBox.shrink();
        }

        // ¿acaba de agregarse algo? -> animación ligera
        final justAdded = itemCount > _prevCount;
        _prevCount = itemCount;

        return AnimatedScale(
          scale: justAdded ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 180),
          child: FloatingActionButton.extended(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const OrdersScreen()));
            },
            backgroundColor: Colors.red, // 🔴 “salta en rojo” cuando hay items
            icon: const Icon(Icons.shopping_bag_outlined),
            label: Text(
              '$itemCount · \$${cart.total.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        );
      },
    );
  }
}
