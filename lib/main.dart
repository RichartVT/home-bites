import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'package:flutter_stripe/flutter_stripe.dart' as stripe;

import 'firebase_options.dart';
import 'features/orders/application/cart_provider.dart';
import 'features/auth/application/auth_provider.dart';
import 'features/onboarding/presentation/startup_gate.dart';
import 'features/products/application/kitchens_provider.dart';
import 'features/products/application/favorites_provider.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 👇 Inicializar Stripe ANTES de usarlo
  stripe.Stripe.publishableKey =
      'pk_test_51Sb6KCQgie0bAbc5p7vJcKy0kAsbnPxServDs9Np3s9HuaccVQ7RMdJrAAyRfwiFp1Kmp8L32dJ7npzWfj40Pxlq00Yze4kC9o';
  stripe.Stripe.merchantIdentifier = 'merchant.com.homebites.test';
  await stripe.Stripe.instance.applySettings();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await NotificationService.instance.init();

  runApp(const HomeBitesApp());
}

class HomeBitesApp extends StatelessWidget {
  const HomeBitesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => KitchensProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
      ],
      child: MaterialApp(
        title: 'HomeBites',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF0CAF60),
        ),
        home: const StartupGate(),
      ),
    );
  }
}
