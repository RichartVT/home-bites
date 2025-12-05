import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/dish.dart';
import '../domain/kitchen.dart';
import '../../orders/application/cart_provider.dart';
import 'dish_form_screen.dart'; // 👈 mismo folder de presentations

class KitchenDetailScreen extends StatelessWidget {
  final Kitchen kitchen;

  const KitchenDetailScreen({super.key, required this.kitchen});

  Stream<List<Dish>> _dishesStream() {
    return FirebaseFirestore.instance
        .collection('dishes')
        .where('kitchenId', isEqualTo: kitchen.id)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => Dish.fromFirestore(
                  doc.data(), // 👈 primero el Map<String, dynamic>
                  doc.id, // 👈 luego el id
                ),
              )
              .toList();
        });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => DishFormScreen(kitchen: kitchen)),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Agregar platillo',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: colorScheme.primary,
      ),
      body: CustomScrollView(
        slivers: [
          // App bar con imagen grande
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            stretch: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.favorite_border),
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(
                start: 16,
                bottom: 16,
              ),
              title: Text(
                kitchen.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  kitchen.imageUrl.isNotEmpty
                      ? Image.network(kitchen.imageUrl, fit: BoxFit.cover)
                      : Container(color: Colors.grey[300]),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.2),
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Info básica de la cocina
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber[700], size: 18),
                      const SizedBox(width: 4),
                      Text(
                        kitchen.rating.toStringAsFixed(1),
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• ${kitchen.category}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${kitchen.distanceKm.toStringAsFixed(1)} km • '
                    '${kitchen.deliveryTimeMinutes} min aprox.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${kitchen.minPrice.toStringAsFixed(0)} - '
                    '\$${kitchen.maxPrice.toStringAsFixed(0)} por persona',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: colorScheme.outlineVariant),
                  const SizedBox(height: 8),
                  Text(
                    'Menú',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Lista de platillos desde Firestore
          SliverToBoxAdapter(
            child: StreamBuilder<List<Dish>>(
              stream: _dishesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'Error al cargar el menú: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final dishes = snapshot.data ?? [];

                if (dishes.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      'Aún no hay platillos registrados para esta cocina.',
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: dishes.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final dish = dishes[index];
                    return _DishTile(
                      dish: dish,
                      kitchen: kitchen, // 👈 usamos la cocina actual
                    );
                  },
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _DishTile extends StatelessWidget {
  final Dish dish;
  final Kitchen kitchen;

  const _DishTile({required this.dish, required this.kitchen});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cart = context.read<CartProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info del platillo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (dish.isPopular)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Popular',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.orange[800],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    Flexible(
                      child: Text(
                        dish.name,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (dish.description.isNotEmpty)
                  Text(
                    dish.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  '\$${dish.price.toStringAsFixed(0)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 32,
                  child: OutlinedButton(
                    onPressed: () {
                      cart.addDish(kitchen, dish);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${dish.name} se agregó al carrito'),
                          duration: const Duration(milliseconds: 900),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Agregar'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: dish.imageUrl.isNotEmpty
                ? Image.network(
                    dish.imageUrl,
                    height: 80,
                    width: 80,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 80,
                    width: 80,
                    color: Colors.grey[300],
                    child: const Icon(Icons.fastfood),
                  ),
          ),
        ],
      ),
    );
  }
}
