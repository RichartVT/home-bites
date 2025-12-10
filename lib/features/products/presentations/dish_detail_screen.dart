import 'package:flutter/material.dart';
import 'package:homebites_app/features/orders/application/cart_provider.dart';
import 'package:homebites_app/features/products/domain/dish.dart';
import 'package:homebites_app/features/products/domain/kitchen.dart';
// import '../../domain/dish.dart';
import 'package:provider/provider.dart';

class DishDetailScreen extends StatelessWidget {
  final Dish dish;

  final Kitchen kitchen;

  const DishDetailScreen({
    super.key,
    required this.dish,
    required this.kitchen,
  });

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: Text(dish.name)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Hero(
            tag: dish.id,
            child: Image.network(
              dish.imageUrl,
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              dish.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: Text(
              "\$${dish.price}",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                cartProvider.addDish(kitchen, dish); // ✅
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Platillo agregado al carrito")),
                );
              },
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text("Agregar al carrito"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
