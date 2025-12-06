import 'package:flutter/material.dart';
import 'package:homebites_app/features/products/presentations/kitchen_detail_screen.dart';
import 'package:homebites_app/features/products/presentations/kitchen_form_screen.dart';
import 'package:homebites_app/features/products/presentations/favorites_screen.dart';
import 'package:provider/provider.dart';

import '../../products/application/kitchens_provider.dart';
import '../../products/application/favorites_provider.dart';
import '../../products/domain/kitchen.dart';

enum KitchenSort { recommended, rating, fastest }

// ================= HOME SCREEN (STATEFUL) =================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  String _searchQuery = '';
  String _selectedCategory = 'Todos';

  KitchenSort _sort = KitchenSort.recommended;
  double? _maxDistanceKm; // null = sin límite

  final List<String> _categories = const [
    'Todos',
    'Mexicana',
    'Comida corrida',
    'Postres',
    'Vegano',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openFiltersSheet() async {
    KitchenSort tempSort = _sort;
    double? tempMaxDistance = _maxDistanceKm;

    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        final theme = Theme.of(context);

        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            top: 8,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filtros',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Ordenar por', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  RadioListTile<KitchenSort>(
                    value: KitchenSort.recommended,
                    groupValue: tempSort,
                    title: const Text('Recomendado'),
                    onChanged: (v) =>
                        setModalState(() => tempSort = v ?? tempSort),
                  ),
                  RadioListTile<KitchenSort>(
                    value: KitchenSort.rating,
                    groupValue: tempSort,
                    title: const Text('Mejor calificados'),
                    onChanged: (v) =>
                        setModalState(() => tempSort = v ?? tempSort),
                  ),
                  RadioListTile<KitchenSort>(
                    value: KitchenSort.fastest,
                    groupValue: tempSort,
                    title: const Text('Más rápidos'),
                    onChanged: (v) =>
                        setModalState(() => tempSort = v ?? tempSort),
                  ),
                  const SizedBox(height: 8),
                  Text('Distancia máxima', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Sin límite'),
                        selected: tempMaxDistance == null,
                        onSelected: (_) =>
                            setModalState(() => tempMaxDistance = null),
                      ),
                      FilterChip(
                        label: const Text('≤ 5 km'),
                        selected: tempMaxDistance == 5,
                        onSelected: (_) =>
                            setModalState(() => tempMaxDistance = 5),
                      ),
                      FilterChip(
                        label: const Text('≤ 10 km'),
                        selected: tempMaxDistance == 10,
                        onSelected: (_) =>
                            setModalState(() => tempMaxDistance = 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        setState(() {
                          _sort = tempSort;
                          _maxDistanceKm = tempMaxDistance;
                        });
                        Navigator.of(context).pop();
                      },
                      child: const Text('Aplicar filtros'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final favorites = context.watch<FavoritesProvider>();

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
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const FavoritesScreen(),
                              ),
                            );
                          },
                          icon: Icon(
                            favorites.favoriteKitchenIds.isNotEmpty
                                ? Icons.favorite
                                : Icons.favorite_outline,
                          ),
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

                    // Buscador + botón filtros
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value.trim().toLowerCase();
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Buscar platillos o cocineros...',
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest
                                  .withOpacity(0.6),
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
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          onPressed: _openFiltersSheet,
                          icon: const Icon(Icons.tune),
                          tooltip: 'Filtros',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Chips de categorías (funcionales)
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final isSelected = _selectedCategory == category;
                          return _CategoryChip(
                            label: category,
                            selected: isSelected,
                            onTap: () {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                          );
                        },
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

            // ======= Lista desde Firestore (con filtros) =======
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            SliverToBoxAdapter(
              child: _KitchensFromFirestore(
                searchQuery: _searchQuery,
                selectedCategory: _selectedCategory,
                sort: _sort,
                maxDistanceKm: _maxDistanceKm,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const KitchenFormScreen()));
        },
        icon: const Icon(Icons.store_mall_directory, color: Colors.white),
        label: const Text(
          'Nueva cocina',
          style: TextStyle(color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// =============== WIDGETS AUXILIARES ===============

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
      ),
      selectedColor: colorScheme.primary,
      backgroundColor: colorScheme.surfaceContainerHighest,
      onSelected: (_) => onTap(),
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
  final String searchQuery;
  final String selectedCategory;
  final KitchenSort sort;
  final double? maxDistanceKm;

  const _KitchensFromFirestore({
    required this.searchQuery,
    required this.selectedCategory,
    required this.sort,
    required this.maxDistanceKm,
  });

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

        final allKitchens = snapshot.data ?? [];

        // 🔍 filtro por texto
        final q = searchQuery.trim().toLowerCase();
        Iterable<Kitchen> filtered = allKitchens;

        if (q.isNotEmpty) {
          filtered = filtered.where((k) {
            final name = k.name.toLowerCase();
            final category = k.category.toLowerCase();
            return name.contains(q) || category.contains(q);
          });
        }

        // 🏷 filtro por categoría (si no es "Todos")
        if (selectedCategory != 'Todos') {
          filtered = filtered.where(
            (k) => k.category.toLowerCase() == selectedCategory.toLowerCase(),
          );
        }

        // 📍 filtro por distancia máxima
        if (maxDistanceKm != null) {
          filtered = filtered.where(
            (k) => k.distanceKm <= (maxDistanceKm ?? 9999),
          );
        }

        final kitchens = filtered.toList();

        // ↕️ ordenar
        switch (sort) {
          case KitchenSort.rating:
            kitchens.sort((a, b) => b.rating.compareTo(a.rating));
            break;
          case KitchenSort.fastest:
            kitchens.sort(
              (a, b) => a.deliveryTimeMinutes.compareTo(b.deliveryTimeMinutes),
            );
            break;
          case KitchenSort.recommended:
          default:
            // Pequeña mezcla: rating alto y luego más cercanas
            kitchens.sort((a, b) {
              final byRating = b.rating.compareTo(a.rating);
              if (byRating != 0) return byRating;
              return a.distanceKm.compareTo(b.distanceKm);
            });
        }

        if (kitchens.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24.0),
            child: Text('No encontramos cocinas con esos filtros.'),
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
              // Imagen
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    kitchen.imageUrl.isNotEmpty
                        ? Image.network(kitchen.imageUrl, fit: BoxFit.cover)
                        : Container(color: Colors.grey[300]),
                    // Rating (arriba derecha)
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
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 14,
                            ),
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
                    // Corazón (arriba izquierda)
                    Positioned(
                      left: 12,
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
