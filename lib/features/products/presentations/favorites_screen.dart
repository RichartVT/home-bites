import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../products/application/kitchens_provider.dart';
import '../../products/application/favorites_provider.dart';
import '../../products/domain/kitchen.dart';
import 'kitchen_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>();
    final favIds = favorites.favoriteKitchenIds;

    final kitchensProvider = context.watch<KitchensProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Mis favoritos')),
      body: favIds.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Aún no tienes cocinas favoritas.\n'
                  'Toca el corazón en una cocina para guardarla aquí 💚',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : StreamBuilder<List<Kitchen>>(
              stream: kitchensProvider.kitchensStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'Error al cargar favoritos: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final allKitchens = snapshot.data ?? [];
                final favKitchens = allKitchens
                    .where((k) => favIds.contains(k.id))
                    .toList();

                if (favKitchens.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'Tus favoritos ya no están disponibles.\n'
                        'Prueba agregando nuevas cocinas.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: favKitchens.length,
                  itemBuilder: (context, index) {
                    final kitchen = favKitchens[index];
                    return _FavoriteKitchenCard(kitchen: kitchen);
                  },
                );
              },
            ),
    );
  }
}

class _FavoriteKitchenCard extends StatelessWidget {
  final Kitchen kitchen;

  const _FavoriteKitchenCard({required this.kitchen});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final favorites = context.watch<FavoritesProvider>();
    final isFav = favorites.isFavorite(kitchen.id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => KitchenDetailScreen(kitchen: kitchen),
            ),
          );
        },
        child: Card(
          clipBehavior: Clip.antiAlias,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen + corazón
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    kitchen.imageUrl.isNotEmpty
                        ? Image.network(kitchen.imageUrl, fit: BoxFit.cover)
                        : Container(color: Colors.grey[300]),
                    Positioned(
                      right: 12,
                      top: 12,
                      child: IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withOpacity(0.4),
                        ),
                        icon: Icon(
                          isFav
                              ? Icons.favorite
                              : Icons.favorite_border_outlined,
                          color: isFav ? Colors.redAccent : Colors.white,
                        ),
                        onPressed: () async {
                          try {
                            await favorites.toggleFavorite(kitchen);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Error al actualizar favoritos: $e',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Info
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kitchen.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${kitchen.category} • ${kitchen.distanceKm.toStringAsFixed(1)} km',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${kitchen.minPrice.toStringAsFixed(0)} - '
                      '\$${kitchen.maxPrice.toStringAsFixed(0)} • '
                      '${kitchen.deliveryTimeMinutes} min',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
