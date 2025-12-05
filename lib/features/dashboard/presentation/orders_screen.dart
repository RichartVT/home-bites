// TODO Implement this library.
import 'package:flutter/material.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis pedidos')),
      body: const Center(
        child: Text('Aquí aparecerán tus pedidos de HomeBites'),
      ),
    );
  }
}
