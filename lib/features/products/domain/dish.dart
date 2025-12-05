class Dish {
  final String id;
  final String kitchenId; // 👈 NUEVO
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final int prepTimeMinutes;
  final bool isPopular;

  Dish({
    required this.id,
    required this.kitchenId, // 👈 NUEVO
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.prepTimeMinutes,
    required this.isPopular,
  });

  factory Dish.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Dish(
      id: documentId,
      kitchenId: data['kitchenId'] as String? ?? '', // 👈 NUEVO
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      prepTimeMinutes: data['prepTimeMinutes'] as int? ?? 0,
      isPopular: data['isPopular'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kitchenId': kitchenId, // 👈 NUEVO
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'price': price,
      'prepTimeMinutes': prepTimeMinutes,
      'isPopular': isPopular,
    };
  }
}
