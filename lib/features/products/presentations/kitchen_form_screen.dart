import 'dart:io';

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:homebites_app/features/products/domain/kitchen.dart';
import 'package:image_picker/image_picker.dart';

class KitchenFormScreen extends StatefulWidget {
  final Kitchen? kitchen; // 👈 NUEVO (cocina a editar, si existe)

  const KitchenFormScreen({super.key, this.kitchen});

  bool get isEditing => kitchen != null; // 👈 helper

  @override
  State<KitchenFormScreen> createState() => _KitchenFormScreenState();
}

class _KitchenFormScreenState extends State<KitchenFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController(text: 'Comida corrida');
  final _minPriceCtrl = TextEditingController(text: '70');
  final _maxPriceCtrl = TextEditingController(text: '150');
  final _deliveryTimeCtrl = TextEditingController(text: '25');
  final _distanceCtrl = TextEditingController(text: '1.2');
  final _ratingCtrl = TextEditingController(text: '4.8');

  final _imageUrlCtrl = TextEditingController(
    text:
        'https://images.pexels.com/photos/262978/pexels-photo-262978.jpeg', // valor por defecto opcional
  );

  final _picker = ImagePicker();
  File? _imageFile;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final k = widget.kitchen;
    if (k != null) {
      _nameCtrl.text = k.name;
      _categoryCtrl.text = k.category;
      _minPriceCtrl.text = k.minPrice.toStringAsFixed(0);
      _maxPriceCtrl.text = k.maxPrice.toStringAsFixed(0);
      _deliveryTimeCtrl.text = k.deliveryTimeMinutes.toString();
      _distanceCtrl.text = k.distanceKm.toString();
      _ratingCtrl.text = k.rating.toString();
      _imageUrlCtrl.text = k.imageUrl; // 👈 importante
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _minPriceCtrl.dispose();
    _maxPriceCtrl.dispose();
    _deliveryTimeCtrl.dispose();
    _distanceCtrl.dispose();
    _ratingCtrl.dispose();
    _imageUrlCtrl.dispose();

    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 80,
    );

    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<void> _saveKitchen() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final name = _nameCtrl.text.trim();
      final category = _categoryCtrl.text.trim();
      final minPrice = double.tryParse(_minPriceCtrl.text.trim()) ?? 0;
      final maxPrice = double.tryParse(_maxPriceCtrl.text.trim()) ?? 0;
      final deliveryTime = int.tryParse(_deliveryTimeCtrl.text.trim()) ?? 0;
      final distanceKm = double.tryParse(_distanceCtrl.text.trim()) ?? 0;
      final rating = double.tryParse(_ratingCtrl.text.trim()) ?? 0;

      // Imagen por URL
      const defaultImageUrl =
          'https://images.pexels.com/photos/262978/pexels-photo-262978.jpeg';

      final imageUrlText = _imageUrlCtrl.text.trim();
      final imageUrl = imageUrlText.isNotEmpty ? imageUrlText : defaultImageUrl;

      final firestore = FirebaseFirestore.instance;
      final kitchensRef = firestore.collection('kitchens');

      // 👉 si estamos editando, usamos el id existente; si no, generamos uno nuevo
      final docRef = widget.kitchen != null
          ? kitchensRef.doc(widget.kitchen!.id)
          : kitchensRef.doc();

      await docRef.set({
        'id': docRef.id,
        'name': name,
        'category': category,
        'minPrice': minPrice,
        'maxPrice': maxPrice,
        'deliveryTimeMinutes': deliveryTime,
        'distanceKm': distanceKm,
        'rating': rating,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // 👈 merge para no borrar campos extra

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing
                  ? 'Cocina actualizada ✅'
                  : 'Cocina creada correctamente 🎉',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar la cocina: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar cocina' : 'Nueva cocina'),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen
              Text('Foto de la cocina', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _isSaving ? null : _pickImage,
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _imageFile != null
                          ? Image.file(
                              _imageFile!,
                              height: 90,
                              width: 120,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              height: 90,
                              width: 120,
                              color: Colors.grey[200],
                              child: const Icon(Icons.photo_camera_outlined),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _imageFile == null
                          ? 'Toca para seleccionar una foto'
                          : 'Cambiar foto',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Nombre
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la cocina',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Categoría
              TextFormField(
                controller: _categoryCtrl,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  hintText: 'Mexicana, Comida corrida, etc.',
                ),
              ),
              const SizedBox(height: 12),

              const SizedBox(height: 16),
              Text(
                'URL de imagen (opcional)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[700],
                ),
              ),
              TextFormField(
                controller: _imageUrlCtrl,
                decoration: const InputDecoration(
                  hintText: 'https://ejemplo.com/mi-foto.jpg',
                ),
                keyboardType: TextInputType.url,
              ),

              // Fila precios
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minPriceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Precio mínimo por persona',
                        prefixText: '\$',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _maxPriceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Precio máximo por persona',
                        prefixText: '\$',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Entrega y distancia
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _deliveryTimeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Tiempo de entrega (min)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _distanceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Distancia (km)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Rating
              TextFormField(
                controller: _ratingCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Calificación inicial',
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveKitchen,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Guardar cocina'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
