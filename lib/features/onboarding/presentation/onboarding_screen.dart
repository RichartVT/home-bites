import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/presentation/auth_gate.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _onboardingKey = 'onboarding_completed';

  final _pages = const [
    _OnboardingPageData(
      title: 'Comida casera,\ndirecto a tu puerta',
      subtitle:
          'Descubre cocinas cerca de ti con platillos hechos\ncomo en casa.',
      icon: Icons.restaurant,
    ),
    _OnboardingPageData(
      title: 'Apoya a cocineros\nlocales',
      subtitle:
          'Cada pedido impulsa el trabajo de familias y\nemprendedores de tu ciudad.',
      icon: Icons.handshake,
    ),
    _OnboardingPageData(
      title: 'Pide fácil y rápido',
      subtitle:
          'Explora menús, agrega platillos a tu pedido y\nsigue el estado en tiempo real.',
      icon: Icons.delivery_dining,
    ),
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);

    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const AuthGate()));
  }

  void _goNext() {
    if (_currentPage == _pages.length - 1) {
      _completeOnboarding();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _skip() {
    _completeOnboarding();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Botón "Saltar"
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: _skip, child: const Text('Saltar')),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return _OnboardingPage(page: page);
                },
              ),
            ),
            const SizedBox(height: 16),

            // Indicadores
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentPage == index ? 20 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? colorScheme.primary
                        : colorScheme.primary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Botón principal
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 8,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _goNext,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _currentPage == _pages.length - 1
                        ? 'Empezar con HomeBites'
                        : 'Continuar',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// -------- Datos y widget de página --------

class _OnboardingPageData {
  final String title;
  final String subtitle;
  final IconData icon;

  const _OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingPageData page;

  const _OnboardingPage({required this.page});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icono grande tipo ilustración
          Container(
            height: 180,
            width: 180,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(page.icon, size: 96, color: colorScheme.primary),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
