class Kitchen {
  final String id;
  final String name;
  final String category;
  final double rating;
  final double distanceKm;
  final double minPrice;
  final double maxPrice;
  final int deliveryTimeMinutes;
  final String imageUrl;

  Kitchen({
    required this.id,
    required this.name,
    required this.category,
    required this.rating,
    required this.distanceKm,
    required this.minPrice,
    required this.maxPrice,
    required this.deliveryTimeMinutes,
    required this.imageUrl,
  });

  factory Kitchen.fromFirestore(String id, Map<String, dynamic> data) {
    return Kitchen(
      id: id,
      name: data['name'] as String? ?? 'Sin nombre',
      category: data['category'] as String? ?? 'Sin categoría',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      distanceKm: (data['distanceKm'] as num?)?.toDouble() ?? 0.0,
      minPrice: (data['minPrice'] as num?)?.toDouble() ?? 0.0,
      maxPrice: (data['maxPrice'] as num?)?.toDouble() ?? 0.0,
      deliveryTimeMinutes: (data['deliveryTimeMinutes'] as num?)?.toInt() ?? 0,
      imageUrl: data['imageUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category,
      'rating': rating,
      'distanceKm': distanceKm,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'deliveryTimeMinutes': deliveryTimeMinutes,
      'imageUrl': imageUrl,
    };
  }
}
