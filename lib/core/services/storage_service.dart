import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  final _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  /// Sube una imagen a Firebase Storage y regresa la URL pública.
  /// [pathPrefix] sirve para agrupar (ej. 'kitchens', 'dishes').
  Future<String> uploadImageFile(
    File file, {
    required String pathPrefix,
  }) async {
    final fileId = _uuid.v4();
    final ref = _storage.ref().child('$pathPrefix/$fileId.jpg');

    final uploadTask = ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    final snapshot = await uploadTask.whenComplete(() {});
    final url = await snapshot.ref.getDownloadURL();

    return url;
  }
}
