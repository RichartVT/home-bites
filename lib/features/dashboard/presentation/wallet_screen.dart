import 'package:flutter/material.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final List<CreditCard> _cards = [
    CreditCard(
      number: '**** **** **** 1234',
      holder: 'Richart Vázquez',
      expiry: '12/26',
      brand: 'Visa',
    ),
    // Puedes precargar una de prueba o dejar vacío
  ];

  void _addCard() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        final numberCtrl = TextEditingController();
        final nameCtrl = TextEditingController();
        final expiryCtrl = TextEditingController();

        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Agregar tarjeta',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: numberCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Número de tarjeta',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del titular',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: expiryCtrl,
                decoration: const InputDecoration(
                  labelText: 'Fecha de expiración (MM/AA)',
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                icon: const Icon(Icons.credit_card),
                label: const Text('Guardar tarjeta'),
                onPressed: () {
                  if (numberCtrl.text.length >= 4 &&
                      nameCtrl.text.isNotEmpty &&
                      expiryCtrl.text.isNotEmpty) {
                    setState(() {
                      _cards.add(
                        CreditCard(
                          number:
                              '**** **** **** ${numberCtrl.text.substring(numberCtrl.text.length - 4)}',
                          holder: nameCtrl.text,
                          expiry: expiryCtrl.text,
                          brand:
                              'Visa', // mejora futura: detectar marca automáticamente
                        ),
                      );
                    });
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Billetera')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _cards.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final card = _cards[index];
          return _CreditCardTile(card: card);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCard,
        icon: const Icon(Icons.add),
        label: const Text('Agregar tarjeta'),
      ),
    );
  }
}

class CreditCard {
  final String number;
  final String holder;
  final String expiry;
  final String brand;

  CreditCard({
    required this.number,
    required this.holder,
    required this.expiry,
    required this.brand,
  });
}

class _CreditCardTile extends StatelessWidget {
  final CreditCard card;

  const _CreditCardTile({required this.card});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Theme.of(context).colorScheme.primary;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(Icons.credit_card, color: color),
        title: Text(card.number),
        subtitle: Text('${card.holder} • Expira ${card.expiry}'),
        trailing: Text(card.brand),
      ),
    );
  }
}
