import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:http/http.dart' as http;

class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final int price; // MXN
  final List<String> benefits;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.benefits,
  });
}

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _plans = const [
    SubscriptionPlan(
      id: 'basic',
      name: 'Plan Básico',
      description: 'Hasta 3 pedidos al mes con envío con descuento.',
      price: 99,
      benefits: [
        '3 pedidos al mes con envío con descuento.',
        'Acceso a promociones básicas.',
      ],
    ),
    SubscriptionPlan(
      id: 'foodie',
      name: 'Plan Cocinero Frecuente',
      description: 'Hasta 8 pedidos al mes y promociones especiales.',
      price: 199,
      benefits: [
        'Hasta 8 pedidos al mes.',
        'Promociones exclusivas y prioridad en ofertas.',
      ],
    ),
    SubscriptionPlan(
      id: 'family',
      name: 'Plan Familiar',
      description: 'Pedidos ilimitados con envío preferente.',
      price: 349,
      benefits: [
        'Pedidos ilimitados al mes.',
        'Envío preferente y soporte prioritario.',
      ],
    ),
  ];

  SubscriptionPlan? _selectedPlan;
  SubscriptionPlan? _activePlan;
  bool _loading = false;
  bool _initialLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentSubscription();
  }

  Future<void> _loadCurrentSubscription() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _initialLoading = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('subscriptions')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final status = data['status'] as String? ?? 'inactive';
        final planId = data['planId'] as String? ?? '';

        if (status == 'active') {
          final plan = _plans.firstWhere(
            (p) => p.id == planId,
            orElse: () => _plans[0],
          );
          setState(() {
            _activePlan = plan;
            _selectedPlan = plan; // por defecto seleccionamos el actual
          });
        }
      }
    } catch (e) {
      debugPrint('Error cargando suscripción actual: $e');
    } finally {
      if (mounted) {
        setState(() {
          _initialLoading = false;
        });
      }
    }
  }

  Future<void> _startStripePayment() async {
    if (_selectedPlan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un plan de suscripción')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicia sesión para suscribirte')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final amountInCents = _selectedPlan!.price * 100;

      debugPrint('Iniciando pago para plan: ${_selectedPlan!.id}');

      // 1) Crear PaymentIntent en tu backend
      final response = await http.post(
        Uri.parse('http://localhost:4242/create-payment-intent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': amountInCents, 'currency': 'mxn'}),
      );

      debugPrint(
        'Respuesta backend Stripe: ${response.statusCode} ${response.body}',
      );

      if (response.statusCode != 200) {
        throw Exception('Error al crear PaymentIntent');
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

      // 4) Guardar/actualizar suscripción en Firestore
      await FirebaseFirestore.instance
          .collection('subscriptions')
          .doc(user.uid)
          .set({
            'userId': user.uid,
            'planId': _selectedPlan!.id,
            'planName': _selectedPlan!.name,
            'price': _selectedPlan!.price,
            'currency': 'MXN',
            'status': 'active',
            'createdAt': FieldValue.serverTimestamp(),
          });

      setState(() {
        _activePlan = _selectedPlan;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Suscripción activada: ${_selectedPlan!.name}')),
      );
    } on stripe.StripeException catch (e) {
      debugPrint('Stripe cancelado: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pago cancelado')));
    } catch (e) {
      debugPrint('Error pago Stripe: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ocurrió un error al procesar el pago')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancelSubscription() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _activePlan == null) return;

    setState(() => _loading = true);

    try {
      await FirebaseFirestore.instance
          .collection('subscriptions')
          .doc(user.uid)
          .update({
            'status': 'cancelled',
            'cancelledAt': FieldValue.serverTimestamp(),
          });

      setState(() {
        _activePlan = null;
        // dejamos _selectedPlan como estaba, el usuario podría elegir otra
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Suscripción cancelada. No se realizarán reembolsos.'),
        ),
      );
    } catch (e) {
      debugPrint('Error cancelando suscripción: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo cancelar la suscripción.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_initialLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final hasActive = _activePlan != null;
    final isChangingPlan =
        hasActive &&
        _selectedPlan != null &&
        _selectedPlan!.id != _activePlan!.id;

    String mainButtonText;
    if (!hasActive) {
      mainButtonText = 'Pagar con tarjeta (Stripe Test)';
    } else if (isChangingPlan) {
      mainButtonText = 'Cambiar de plan (Stripe Test)';
    } else {
      mainButtonText = 'Actualizar pago de suscripción';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suscripción HomeBites'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasActive) ...[
              Text(
                'Tu suscripción actual',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 1.2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _activePlan!.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${_activePlan!.price} MXN / mes',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Beneficios de tu plan:',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ..._activePlan!.benefits.map(
                        (b) => Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• '),
                            Expanded(child: Text(b)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _loading ? null : _cancelSubscription,
                          child: const Text(
                            'Cancelar suscripción',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            Text(
              'Elige tu plan',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ..._plans.map((plan) {
              final isSelected = _selectedPlan?.id == plan.id;
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : Colors.grey.shade200,
                    width: 1.2,
                  ),
                ),
                child: RadioListTile<SubscriptionPlan>(
                  value: plan,
                  groupValue: _selectedPlan,
                  onChanged: (value) {
                    setState(() {
                      _selectedPlan = value;
                    });
                  },
                  title: Text(
                    plan.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${plan.description}\n\$${plan.price} MXN / mes',
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _startStripePayment,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(mainButtonText),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'El cargo se procesa en modo prueba usando Stripe. '
              'No se realizan cargos reales.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
