import 'package:flutter/material.dart';
import 'package:homebites_app/features/payments/presentation/subscription_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/application/auth_provider.dart';
import '../../../core/services/notification_service.dart';

import '../../payments/presentation/subscription_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;
  bool _isTogglingNotifications = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool('notifications_enabled') ?? true;
    if (mounted) {
      setState(() {
        _notificationsEnabled = value;
      });
    }
  }

  Future<void> _handleNotificationToggle(bool value) async {
    if (_isTogglingNotifications) return;

    setState(() {
      _isTogglingNotifications = true;
      _notificationsEnabled = value;
    });

    try {
      if (value) {
        await NotificationService.instance.subscribeToPromos();
      } else {
        await NotificationService.instance.unsubscribeFromPromos();
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', value);
    } catch (e) {
      // Si algo falla, revertimos el valor y mostramos mensaje
      if (mounted) {
        setState(() {
          _notificationsEnabled = !value;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudieron actualizar las notificaciones'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTogglingNotifications = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final displayName = (user?.displayName?.isNotEmpty ?? false)
        ? user!.displayName!
        : 'Usuario HomeBites';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header con avatar y nombre
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: colorScheme.primary.withOpacity(0.1),
                  backgroundImage: user?.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : null,
                  child: user?.photoURL == null
                      ? Text(
                          displayName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  displayName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                if (user?.email != null)
                  Text(
                    user!.email!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Cuenta',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: const Text('Direcciones de entrega'),
                  subtitle: const Text('Agregar o administrar direcciones'),
                  onTap: () {
                    // Luego conectamos a pantalla de direcciones
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pendiente: direcciones 🙂'),
                        duration: Duration(milliseconds: 900),
                      ),
                    );
                  },
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.payment_outlined),
                  title: const Text('Suscripción / Métodos de pago'),
                  subtitle: const Text('Gestiona tu plan de HomeBites'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SubscriptionScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Preferencias',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_outlined),
                  title: const Text('Notificaciones'),
                  subtitle: const Text('Promociones y actualizaciones'),
                  value: _notificationsEnabled,
                  onChanged: _isTogglingNotifications
                      ? null
                      : (value) => _handleNotificationToggle(value),
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Ayuda y soporte'),
                  onTap: () {
                    // Placeholder
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pendiente: ayuda/FAQ 🙂'),
                        duration: Duration(milliseconds: 900),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Sesión',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: Icon(Icons.logout, color: colorScheme.error),
              title: Text(
                'Cerrar sesión',
                style: TextStyle(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () async {
                await auth.signOut();
                // El AuthGate se encarga de mandarte al login.
              },
            ),
          ),
        ],
      ),
    );
  }
}
