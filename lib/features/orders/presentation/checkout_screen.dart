import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../application/cart_provider.dart';
import 'pedido_en_camino_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _loading = false;
  List<Map<String, dynamic>> _addresses = [];
  String? _selectedAddressId;

  @override
  void initState() {
    super.initState();
    _loadUserAddresses();
  }

  Future<void> _loadUserAddresses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('addresses')
        .get();

    final addresses = snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'title': data['title'] ?? '',
        'details': data['details'] ?? '',
      };
    }).toList();

    setState(() {
      _addresses = addresses;
      if (addresses.isNotEmpty) {
        _selectedAddressId = addresses.first['id'];
      }
    });
  }

  Future<void> _addNewAddress() async {
    final controllerTitle = TextEditingController();
    final controllerDetails = TextEditingController();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar dirección'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controllerTitle,
                decoration: const InputDecoration(labelText: 'Título'),
              ),
              TextField(
                controller: controllerDetails,
                decoration: const InputDecoration(labelText: 'Dirección'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = controllerTitle.text.trim();
                final details = controllerDetails.text.trim();
                if (title.isEmpty || details.isEmpty) return;

                final docRef = FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('addresses')
                    .doc();

                await docRef.set({'title': title, 'details': details});

                Navigator.of(context).pop();
                _loadUserAddresses();
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _payCart(BuildContext context) async {
    final cart = context.read<CartProvider>();
    final user = FirebaseAuth.instance.currentUser;

    if (cart.isEmpty || cart.kitchen == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tu carrito está vacío.')));
      return;
    }

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicia sesión para pagar.')),
      );
      return;
    }

    if (_addresses.isEmpty || _selectedAddressId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega y selecciona una dirección.')),
      );
      return;
    }

    final selectedAddress = _addresses.firstWhere(
      (addr) => addr['id'] == _selectedAddressId,
    );

    final double total = cart.total;
    setState(() => _loading = true);

    try {
      final amountInCents = (total * 100).round();

      final response = await http.post(
        Uri.parse('http://localhost:4242/create-payment-intent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': amountInCents, 'currency': 'mxn'}),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al crear PaymentIntent para carrito');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final clientSecret = data['clientSecret'] as String;

      await stripe.Stripe.instance.initPaymentSheet(
        paymentSheetParameters: stripe.SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'HomeBites',
          style: ThemeMode.system,
        ),
      );

      await stripe.Stripe.instance.presentPaymentSheet();

      final firestore = FirebaseFirestore.instance;
      final orderRef = firestore.collection('orders').doc();

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
          'status': 'paid',
          'itemsCount': totalItems,
          'firstDishName': firstDishName,
          'createdAt': FieldValue.serverTimestamp(),
          'paymentMethod': 'stripe_test',
          'addressTitle': selectedAddress['title'],
          'addressDetails': selectedAddress['details'],
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

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pago realizado y pedido creado 🎉')),
      );

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PedidoEnCaminoScreen(orderId: orderRef.id),
        ),
      );
    } on stripe.StripeException catch (e) {
      debugPrint('Stripe cancelado (carrito): $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pago cancelado')));
    } catch (e) {
      debugPrint('Error pago Stripe carrito: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ocurrió un error al procesar el pago del carrito'),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final theme = Theme.of(context);
    final double total = cart.total;

    return Scaffold(
      appBar: AppBar(title: const Text('Pago de pedido'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen del pedido',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Total
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total a pagar', style: TextStyle(fontSize: 16)),
                  Text(
                    '\$${total.toStringAsFixed(0)} MXN',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Direcciones
            Text('Dirección de entrega', style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),

            if (_addresses.isEmpty)
              TextButton.icon(
                onPressed: _addNewAddress,
                icon: const Icon(Icons.add_location_alt),
                label: const Text('Agregar nueva dirección'),
              )
            else
              Column(
                children: [
                  ..._addresses.map((address) {
                    return RadioListTile<String>(
                      value: address['id'],
                      groupValue: _selectedAddressId,
                      onChanged: (value) {
                        setState(() {
                          _selectedAddressId = value;
                        });
                      },
                      title: Text(address['title']),
                      subtitle: Text(address['details']),
                    );
                  }),
                  TextButton.icon(
                    onPressed: _addNewAddress,
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar otra dirección'),
                  ),
                ],
              ),

            const SizedBox(height: 16),

            // Info
            Row(
              children: [
                const Icon(
                  Icons.delivery_dining,
                  size: 32,
                  color: Colors.green,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tu pedido será entregado a domicilio tras realizar el pago.',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'El pago se procesa con Stripe en modo prueba. No se realizan cargos reales.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[700],
              ),
            ),
            const Spacer(),

            // Botón
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.payment),
                onPressed: _loading ? null : () => _payCart(context),
                label: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Pagar pedido (Stripe Test)',
                        style: TextStyle(fontSize: 16),
                      ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
