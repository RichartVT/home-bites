import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../domain/kitchen.dart';

class KitchensProvider extends ChangeNotifier {
  final _collection = FirebaseFirestore.instance.collection(
    'kitchens',
  ); // nombre tal cual en Firestore

  // Stream de cocinas para usar en la Home
  Stream<List<Kitchen>> get kitchensStream {
    return _collection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Kitchen.fromFirestore(doc.id, doc.data());
      }).toList();
    });
  }

  // Si más adelante quieres cargar una sola vez:
  Future<List<Kitchen>> fetchOnce() async {
    final snap = await _collection.get();
    return snap.docs
        .map((doc) => Kitchen.fromFirestore(doc.id, doc.data()))
        .toList();
  }
}
