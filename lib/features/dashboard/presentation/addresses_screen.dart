import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _detailsController = TextEditingController();

  DocumentReference? _editingRef; // 🔄 Para saber si estamos editando

  Future<void> _submitAddress() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final addressData = {
      'label': _labelController.text.trim(),
      'details': _detailsController.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (_editingRef != null) {
      // Editar dirección existente
      await _editingRef!.update(addressData);
    } else {
      // Agregar nueva
      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('addresses')
          .doc();

      await ref.set({
        ...addressData,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    _labelController.clear();
    _detailsController.clear();
    _editingRef = null;

    if (mounted) Navigator.of(context).pop();
  }

  void _openAddressForm({DocumentSnapshot? address}) {
    if (address != null) {
      _labelController.text = address['label'] ?? '';
      _detailsController.text = address['details'] ?? '';
      _editingRef = address.reference;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            top: 16,
          ),
          child: Form(
            key: _formKey,
            child: Wrap(
              children: [
                Text(
                  _editingRef == null
                      ? 'Agregar nueva dirección'
                      : 'Editar dirección',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _labelController,
                  decoration: const InputDecoration(
                    labelText: 'Etiqueta (Ej: Casa, Trabajo)',
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Ingresa una etiqueta'
                      : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _detailsController,
                  decoration: const InputDecoration(
                    labelText: 'Dirección completa',
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Ingresa la dirección'
                      : null,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _submitAddress,
                  child: Text(_editingRef == null ? 'Guardar' : 'Actualizar'),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      // Resetear después de cerrar
      _labelController.clear();
      _detailsController.clear();
      _editingRef = null;
    });
  }

  Future<void> _deleteAddress(DocumentReference ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar dirección'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar esta dirección?',
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('Eliminar'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Direcciones')),
        body: const Center(
          child: Text('Inicia sesión para ver tus direcciones'),
        ),
      );
    }

    final addressesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('addresses')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('Direcciones de entrega')),
      body: StreamBuilder(
        stream: addressesRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('No tienes direcciones guardadas'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final ref = docs[index].reference;

              return ListTile(
                leading: const Icon(Icons.location_on),
                title: Text(data['label'] ?? 'Sin título'),
                subtitle: Text(data['details'] ?? ''),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _openAddressForm(address: docs[index]);
                    } else if (value == 'delete') {
                      _deleteAddress(ref);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Editar')),
                    PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddressForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
