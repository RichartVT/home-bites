import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/services/storage_service.dart';
import '../domain/kitchen.dart';
import '../domain/dish.dart';
import 'package:image_picker/image_picker.dart';

class DishFormScreen extends StatefulWidget {
  final Kitchen kitchen;

  const DishFormScreen({super.key, required this.kitchen});

  @override
  State<DishFormScreen> createState() => _DishFormScreenState();
}

class _DishFormScreenState extends State<DishFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _prepTimeCtrl = TextEditingController();

  bool _isPopular = false;
  bool _isSaving = false;

  File? _imageFile;

  final _picker = ImagePicker();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _prepTimeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );

    if (picked == null) return;

    setState(() {
      _imageFile = File(picked.path);
    });
  }

  Future<void> _saveDish() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      String imageUrl = widget.kitchen.imageUrl;

      // Si el usuario eligió foto nueva, la subimos
      if (_imageFile != null) {
        imageUrl = await StorageService.instance.uploadImageFile(
          _imageFile!,
          pathPrefix: 'dishes/${widget.kitchen.id}',
        );
      }

      final price = double.tryParse(_priceCtrl.text.trim()) ?? 0;
      final prepTime = int.tryParse(_prepTimeCtrl.text.trim()) ?? 0;

      final firestore = FirebaseFirestore.instance;

      final dishesRef = firestore.collection('dishes');

      final dishDoc = dishesRef.doc();

      final dish = Dish(
        id: dishDoc.id,
        kitchenId: widget.kitchen.id,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        imageUrl: imageUrl,
        price: price,
        prepTimeMinutes: prepTime,
        isPopular: _isPopular,
      );

      await dishDoc.set({
        'id': dish.id,
        'kitchenId': dish.kitchenId,
        'name': dish.name,
        'description': dish.description,
        'imageUrl': dish.imageUrl,
        'price': dish.price,
        'prepTimeMinutes': dish.prepTimeMinutes,
        'isPopular': dish.isPopular,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.of(context).pop(dish);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Platillo guardado ✅')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar platillo: $e')),
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

    return Scaffold(
      appBar: AppBar(title: Text('Nuevo platillo – ${widget.kitchen.name}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AbsorbPointer(
          absorbing: _isSaving,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Imagen
                GestureDetector(
                  onTap: _pickImage,
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.grey[200],
                        image: _imageFile != null
                            ? DecorationImage(
                                image: FileImage(_imageFile!),
                                fit: BoxFit.cover,
                              )
                            : (widget.kitchen.imageUrl.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(
                                        widget.kitchen.imageUrl,
                                      ),
                                      fit: BoxFit.cover,
                                      colorFilter: ColorFilter.mode(
                                        Colors.black.withOpacity(0.2),
                                        BlendMode.darken,
                                      ),
                                    )
                                  : null),
                      ),
                      child:
                          _imageFile == null && widget.kitchen.imageUrl.isEmpty
                          ? const Center(
                              child: Icon(
                                Icons.add_a_photo_outlined,
                                size: 40,
                                color: Colors.grey,
                              ),
                            )
                          : Align(
                              alignment: Alignment.bottomRight,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Text(
                                    'Cambiar foto',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del platillo',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Ingresa un nombre'
                      : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _priceCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Precio',
                    prefixText: '\$',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Ingresa un precio';
                    }
                    if (double.tryParse(v) == null) {
                      return 'Precio inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _prepTimeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tiempo de preparación (minutos)',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: false,
                  ),
                ),
                const SizedBox(height: 12),

                SwitchListTile(
                  value: _isPopular,
                  onChanged: (v) => setState(() => _isPopular = v),
                  title: const Text('Marcar como platillo popular'),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _saveDish,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text('Guardar platillo'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
