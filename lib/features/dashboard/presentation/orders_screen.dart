import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../orders/application/cart_provider.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  // ========== Crear pedido ==========
  Future<void> _placeOrder(BuildContext context, CartProvider cart) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para hacer un pedido.'),
        ),
      );
      return;
    }

    if (cart.isEmpty || cart.kitchen == null) return;

    final firestore = FirebaseFirestore.instance;

    final orderRef = firestore.collection('orders').doc();

    // Datos extra para mostrar en el historial
    final totalItems = cart.items.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );
    final firstDishName = cart.items.isNotEmpty
        ? cart.items.first.dish.name
        : '';

    await firestore.runTransaction((transaction) async {
      transaction.set(orderRef, {
        'userId': user.uid,
        'userName': user.displayName ?? '',
        'kitchenId': cart.kitchen!.id,
        'kitchenName': cart.kitchen!.name,
        'kitchenImageUrl': cart.kitchen!.imageUrl,
        'total': cart.total,
        'status': 'pending',
        'itemsCount': totalItems,
        'firstDishName': firstDishName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final itemsCollection = orderRef.collection('items');

      for (final item in cart.items) {
        final itemRef = itemsCollection.doc();
        transaction.set(itemRef, {
          'dishId': item.dish.id,
          'name': item.dish.name,
          'price': item.dish.price,
          'quantity': item.quantity,
          'lineTotal': item.lineTotal,
        });
      }
    });

    cart.clear();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido creado correctamente 🎉')),
      );
    }
  }

  // ========== Stream de pedidos ==========
  Stream<QuerySnapshot<Map<String, dynamic>>> _ordersStream(String userId) {
    return FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ========== Helpers de UI ==========
  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'preparing':
        return 'En preparación';
      case 'onTheWay':
        return 'En camino';
      case 'delivered':
        return 'Entregado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
    }
  }

  Color _statusColor(String status, ColorScheme scheme) {
    switch (status) {
      case 'pending':
        return scheme.primary;
      case 'preparing':
        return scheme.tertiary;
      case 'onTheWay':
        return Colors.orange[700] ?? scheme.primary;
      case 'delivered':
        return Colors.green[700] ?? scheme.primary;
      case 'cancelled':
        return Colors.red[700] ?? scheme.error;
      default:
        return scheme.primary;
    }
  }

  String _formatDate(DateTime date) {
    // 4/12/2025
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Mis pedidos')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --------------------------------
          // Carrito actual
          // --------------------------------
          Text(
            'Carrito actual',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (cart.isEmpty)
            const Text(
              'Aún no tienes platillos en el carrito.',
              style: TextStyle(color: Colors.grey),
            )
          else
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    if (cart.kitchen != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          cart.kitchen!.name,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    ...cart.items.map(
                      (item) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.dish.name),
                        subtitle: Text(
                          '\$${item.dish.price.toStringAsFixed(0)} x ${item.quantity}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () => cart.decreaseQuantity(item),
                            ),
                            Text('${item.quantity}'),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => cart.increaseQuantity(item),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total'),
                        Text(
                          '\$${cart.total.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _placeOrder(context, cart),
                        child: const Text('Confirmar pedido'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),

          // --------------------------------
          // Historial
          // --------------------------------
          Text(
            'Historial',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (user == null)
            const Text(
              'Inicia sesión para ver tus pedidos.',
              style: TextStyle(color: Colors.grey),
            )
          else
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _ordersStream(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Error al cargar pedidos: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Text(
                    'Aún no tienes pedidos registrados.',
                    style: TextStyle(color: Colors.grey),
                  );
                }

                return Column(
                  children: docs.map((doc) {
                    final data = doc.data();

                    final kitchenName = data['kitchenName'] as String? ?? '';
                    final kitchenImageUrl =
                        data['kitchenImageUrl'] as String? ?? '';
                    final total = (data['total'] as num?)?.toDouble() ?? 0.0;
                    final status = data['status'] as String? ?? 'pending';
                    final createdAt = (data['createdAt'] as Timestamp?)
                        ?.toDate();
                    final itemsCount =
                        (data['itemsCount'] as num?)?.toInt() ?? 0;
                    final firstDishName =
                        data['firstDishName'] as String? ?? '';

                    final statusColor = _statusColor(status, colors);
                    final statusText = _statusLabel(status);

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Imagen
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: kitchenImageUrl.isNotEmpty
                                  ? Image.network(
                                      kitchenImageUrl,
                                      height: 60,
                                      width: 60,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      height: 60,
                                      width: 60,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.storefront),
                                    ),
                            ),
                            const SizedBox(width: 12),

                            // Textos
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          kitchenName,
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                      Text(
                                        '\$${total.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  if (createdAt != null)
                                    Text(
                                      _formatDate(createdAt),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(color: Colors.grey[700]),
                                    ),
                                  const SizedBox(height: 2),
                                  Text(
                                    itemsCount > 0
                                        ? '$itemsCount platillo(s)'
                                        : 'Sin detalle de platillos',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  if (firstDishName.isNotEmpty)
                                    Text(
                                      'Incluye: $firstDishName',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(color: Colors.grey[600]),
                                    ),
                                  const SizedBox(height: 6),
                                  // Chip de estado
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      statusText,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: statusColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }
}
