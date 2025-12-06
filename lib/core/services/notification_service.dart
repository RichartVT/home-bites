// lib/core/services/notification_service.dart
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    // 1. Solicitar permisos (especialmente iOS)
    await _requestPermissions();

    // 2. Configurar notificaciones locales
    await _initLocalNotifications();

    // 3. Manejar mensajes en foreground
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    _initialized = true;
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosInit = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(initSettings);
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _showLocalNotification(
      notification.title ?? 'HomeBites',
      notification.body ?? '',
    );
  }

  Future<void> _showLocalNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'homebites_channel',
      'HomeBites Notificaciones',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  // ======================
  // Suscripción a temas
  // ======================

  Future<void> subscribeToPromos() async {
    await _messaging.subscribeToTopic('promos_homebites');
  }

  Future<void> unsubscribeFromPromos() async {
    await _messaging.unsubscribeFromTopic('promos_homebites');
  }
}
