import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../domain/dish.dart';
import '../domain/kitchen.dart';

class DishFormScreen extends StatefulWidget {
  final Kitchen kitchen;
  final Dish? dish; // 👉 null = nuevo, no null = editar

  const DishFormScreen({super.key, required this.kitchen, this.dish});

  @override
  State<DishFormScreen> createState() => _DishFormScreenState();
}

class _DishFormScreenState extends State<DishFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _prepTimeCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();

  bool _isPopular = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final dish = widget.dish;
    if (dish != null) {
      // 👉 Modo edición: prellenar campos
      _nameCtrl.text = dish.name;
      _descCtrl.text = dish.description;
      _priceCtrl.text = dish.price == dish.price.roundToDouble()
          ? dish.price.toInt().toString()
          : dish.price.toString();
      _prepTimeCtrl.text = dish.prepTimeMinutes.toString();
      _imageUrlCtrl.text = dish.imageUrl;
      _isPopular = dish.isPopular;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _prepTimeCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveDish() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final name = _nameCtrl.text.trim();
      final desc = _descCtrl.text.trim();
      final price = double.tryParse(_priceCtrl.text.trim()) ?? 0;
      final prepTime = int.tryParse(_prepTimeCtrl.text.trim()) ?? 0;
      final imageUrl = _imageUrlCtrl.text.trim();

      final firestore = FirebaseFirestore.instance;
      final dishesRef = firestore.collection('dishes');

      if (widget.dish == null) {
        // 👉 Crear nuevo platillo
        final newDishRef = await dishesRef.add({
          'kitchenId': widget.kitchen.id,
          'name': name,
          'description': desc,
          'imageUrl': imageUrl,
          'price': price,
          'prepTimeMinutes': prepTime,
          'isPopular': _isPopular,
        });

        final created = Dish(
          id: newDishRef.id,
          kitchenId: widget.kitchen.id,
          name: name,
          description: desc,
          imageUrl: imageUrl,
          price: price,
          prepTimeMinutes: prepTime,
          isPopular: _isPopular,
        );

        Navigator.of(context).pop(created);
      } else {
        // 👉 Actualizar platillo existente
        await dishesRef.doc(widget.dish!.id).update({
          'name': name,
          'description': desc,
          'imageUrl': imageUrl,
          'price': price,
          'prepTimeMinutes': prepTime,
          'isPopular': _isPopular,
        });

        // No necesitamos regresar nada especial
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar platillo: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.dish == null ? 'Nuevo platillo' : 'Editar platillo'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(widget.kitchen.name, style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del platillo',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Escribe un nombre'
                    : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _priceCtrl,
                decoration: const InputDecoration(
                  labelText: 'Precio',
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Escribe un precio';
                  }
                  final value = double.tryParse(v.trim());
                  if (value == null || value <= 0) {
                    return 'Precio inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _prepTimeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tiempo de preparación (min)',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _imageUrlCtrl,
                decoration: const InputDecoration(
                  labelText: 'URL de imagen (opcional)',
                  helperText: 'Debe ser una URL accesible (https://...)',
                ),
              ),
              const SizedBox(height: 12),

              SwitchListTile(
                title: const Text('Marcar como popular'),
                value: _isPopular,
                onChanged: (v) => setState(() => _isPopular = v),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveDish,
                  child: _isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          widget.dish == null
                              ? 'Guardar platillo'
                              : 'Guardar cambios',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
