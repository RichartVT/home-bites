import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/presentation/auth_gate.dart';
import 'onboarding_screen.dart';

class StartupGate extends StatelessWidget {
  const StartupGate({super.key});

  static const _onboardingKey = 'onboarding_completed';

  Future<bool> _hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasCompletedOnboarding(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final completed = snapshot.data ?? false;

        if (completed) {
          return const AuthGate();
        } else {
          return const OnboardingScreen();
        }
      },
    );
  }
}
