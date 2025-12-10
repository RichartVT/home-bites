import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:homebites_app/features/dashboard/presentation/main_shell_screen.dart';
import 'package:lottie/lottie.dart';

class PedidoEnCaminoScreen extends StatefulWidget {
  final String orderId;

  const PedidoEnCaminoScreen({super.key, required this.orderId});

  @override
  State<PedidoEnCaminoScreen> createState() => _PedidoEnCaminoScreenState();
}

class _PedidoEnCaminoScreenState extends State<PedidoEnCaminoScreen> {
  bool _entregado = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    // Simular entrega
    Timer(const Duration(seconds: 10), () async {
      await _marcarComoEntregado();
    });
  }

  Future<void> _marcarComoEntregado() async {
    final docRef = FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId);

    await docRef.update({'status': 'delivered'});

    if (!mounted) return;

    setState(() {
      _entregado = true;
      _loading = false;
    });

    // Espera 3 segundos, luego navega a Pedidos
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const MainShellScreen(tabIndex: 1), // 👈 Pedidos
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Seguimiento del pedido'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                child: _entregado
                    ? Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green,
                        size: 120,
                        key: const ValueKey('check'),
                      )
                    : Lottie.asset('assets/lottie/delivery.json', width: 180),
              ),
              const SizedBox(height: 24),
              Text(
                _entregado
                    ? '¡Pedido entregado con éxito! 🎉'
                    : 'Tu pedido está en camino...',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _entregado ? Colors.green : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: _entregado
                    ? Text(
                        'Gracias por tu compra. Esperamos verte pronto 🥗',
                        key: const ValueKey('entregado'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      )
                    : Column(
                        key: const ValueKey('en_camino'),
                        children: [
                          Text(
                            'Un repartidor está en camino a tu dirección.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Recuerda recomendarnos si te gusta nuestra plataforma.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 24),
              if (_loading)
                const CircularProgressIndicator()
              else
                const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}
