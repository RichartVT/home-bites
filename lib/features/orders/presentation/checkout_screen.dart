import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../application/cart_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _loading = false;

  Future<void> _payCart(BuildContext context) async {
    final cart = context.read<CartProvider>();
    final user = FirebaseAuth.instance.currentUser;

    // mismo criterio que en _placeOrder
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

    final double total = cart.total;

    setState(() => _loading = true);

    try {
      final amountInCents = (total * 100).round();

      debugPrint(
        'Iniciando pago de carrito. Total: $total, centavos: $amountInCents',
      );

      // 1) Crear PaymentIntent en tu backend
      final response = await http.post(
        Uri.parse('http://localhost:4242/create-payment-intent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': amountInCents, 'currency': 'mxn'}),
      );

      debugPrint(
        'Respuesta backend Stripe (carrito): '
        '${response.statusCode} ${response.body}',
      );

      if (response.statusCode != 200) {
        throw Exception('Error al crear PaymentIntent para carrito');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final clientSecret = data['clientSecret'] as String;

      // 2) Inicializar PaymentSheet
      await stripe.Stripe.instance.initPaymentSheet(
        paymentSheetParameters: stripe.SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'HomeBites',
          style: ThemeMode.system,
        ),
      );

      // 3) Mostrar PaymentSheet
      await stripe.Stripe.instance.presentPaymentSheet();

      // 4) Si no hay excepción, consideramos el pago exitoso
      final firestore = FirebaseFirestore.instance;
      final orderRef = firestore.collection('orders').doc();

      // datos extra igual que en _placeOrder
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
          'status': 'paid', // 👈 pagado con Stripe
          'itemsCount': totalItems,
          'firstDishName': firstDishName,
          'createdAt': FieldValue.serverTimestamp(),
          'paymentMethod': 'stripe_test',
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

      // 5) Vaciar carrito
      cart.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pago realizado y pedido creado 🎉')),
      );

      Navigator.of(context).pop();
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen del pedido',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total a pagar'),
                    Text(
                      '\$${total.toStringAsFixed(0)} MXN',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'El pago se procesa con Stripe en modo prueba. '
              'No se realizan cargos reales.',
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : () => _payCart(context),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Pagar pedido (Stripe Test)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
