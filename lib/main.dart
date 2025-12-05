import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'features/auth/application/auth_provider.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'features/products/application/kitchens_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Opcional: habilitar offline persistence (ya viene on por defecto,
  // pero lo dejamos explícito)
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

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
      ],
      child: MaterialApp(
        title: 'HomeBites',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF0CAF60),
        ),
        home: const AuthGate(),
      ),
    );
  }
}
