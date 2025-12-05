import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:homebites_app/features/orders/application/cart_provider.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'features/auth/application/auth_provider.dart';
import 'features/onboarding/presentation/startup_gate.dart';
import 'features/products/application/kitchens_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
      ],
      child: MaterialApp(
        title: 'HomeBites',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF0CAF60),
        ),
        home: const StartupGate(), // 👈 aquí entra el flujo completo
      ),
    );
  }
}
