import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../domain/kitchen.dart';

class FavoritesProvider extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _favSub;

  final Set<String> _favoriteKitchenIds = {};

  FavoritesProvider() {
    _init();
  }

  void _init() {
    _authSub = _auth.authStateChanges().listen((user) {
      _favSub?.cancel();
      _favoriteKitchenIds.clear();

      if (user != null) {
        _favSub = _db
            .collection('users')
            .doc(user.uid)
            .collection('favorite_kitchens')
            .snapshots()
            .listen((snapshot) {
              _favoriteKitchenIds
                ..clear()
                ..addAll(snapshot.docs.map((d) => d.id));
              notifyListeners();
            });
      } else {
        notifyListeners();
      }
    });
  }

  List<String> get favoriteKitchenIds =>
      _favoriteKitchenIds.toList(growable: false);

  bool isFavorite(String kitchenId) => _favoriteKitchenIds.contains(kitchenId);

  Future<void> toggleFavorite(Kitchen kitchen) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        message: 'Debes iniciar sesión para usar favoritos',
      );
    }

    final docRef = _db
        .collection('users')
        .doc(user.uid)
        .collection('favorite_kitchens')
        .doc(kitchen.id);

    if (isFavorite(kitchen.id)) {
      await docRef.delete();
    } else {
      await docRef.set({
        'kitchenId': kitchen.id,
        'name': kitchen.name,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _favSub?.cancel();
    super.dispose();
  }
}
