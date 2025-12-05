import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../products/application/kitchens_provider.dart';
import '../../products/domain/kitchen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ======= Header, búsqueda, chips y promo =======
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top bar
                    Row(
                      children: [
                        Icon(
                          Icons.place_outlined,
                          size: 20,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Enviar a',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Casa de Richart',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.favorite_outline),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.shopping_bag_outlined),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Título principal
                    Text(
                      'Descubre comida casera\ncerca de ti',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Buscador
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Buscar platillos o cocineros...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: colorScheme.surfaceVariant.withOpacity(0.6),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Chips de categorías
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: const [
                          _CategoryChip(label: 'Todos', selected: true),
                          _CategoryChip(label: 'Mexicana'),
                          _CategoryChip(label: 'Comida corrida'),
                          _CategoryChip(label: 'Postres'),
                          _CategoryChip(label: 'Vegano'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Carrusel / promo
                    SizedBox(
                      height: 140,
                      child: PageView(
                        children: const [
                          _PromoCard(
                            title: 'Envío gratis',
                            subtitle: 'En tus primeros 3 pedidos',
                          ),
                          _PromoCard(
                            title: '2x1 en postres',
                            subtitle: 'Sólo hoy en cocinas seleccionadas',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Título sección
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Cocinas cercanas',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Ver todo'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ======= Lista desde Firestore =======
            SliverToBoxAdapter(child: const SizedBox(height: 8)),
            SliverToBoxAdapter(child: const _KitchensFromFirestore()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

// =============== WIDGETS AUXILIARES ===============

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;

  const _CategoryChip({required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        labelStyle: theme.textTheme.labelMedium?.copyWith(
          color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
        ),
        selectedColor: colorScheme.primary,
        backgroundColor: colorScheme.surfaceVariant,
        onSelected: (_) {
          // TODO: filtrar por categoría cuando tengamos lógica
        },
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _PromoCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [colorScheme.primary, colorScheme.primaryContainer],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: colorScheme.onPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============== FIRESTORE ===============

class _KitchensFromFirestore extends StatelessWidget {
  const _KitchensFromFirestore();

  @override
  Widget build(BuildContext context) {
    final kitchensProvider = context.watch<KitchensProvider>();

    return StreamBuilder<List<Kitchen>>(
      stream: kitchensProvider.kitchensStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Error al cargar cocinas: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final kitchens = snapshot.data ?? [];

        if (kitchens.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24.0),
            child: Text('Aún no hay cocinas registradas en HomeBites.'),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: kitchens.length,
          itemBuilder: (context, index) {
            final kitchen = kitchens[index];
            return _KitchenCardFromModel(kitchen: kitchen);
          },
        );
      },
    );
  }
}

class _KitchenCardFromModel extends StatelessWidget {
  final Kitchen kitchen;

  const _KitchenCardFromModel({required this.kitchen});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            kitchen.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
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
    );
  }
}
