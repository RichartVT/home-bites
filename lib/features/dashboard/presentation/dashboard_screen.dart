import 'package:flutter/material.dart';
import 'package:homebites_app/features/orders/presentation/cart_fab.dart';
import 'package:provider/provider.dart';

import '../../auth/application/auth_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('HomeBites – Dashboard'),
        actions: [
          IconButton(
            onPressed: () => authProvider.signOut(),
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (user?.photoURL != null)
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(user!.photoURL!),
              ),
            const SizedBox(height: 16),
            Text(
              user?.displayName ?? 'Usuario',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(user?.email ?? '', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            const Text('Aquí después va el listado de platillos, etc.'),
          ],
        ),
      ),

      // 🔴 Botón de carrito persistente
      floatingActionButton: const CartFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
