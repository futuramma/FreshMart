/// Product model representing a grocery item in FreshMart
class Product {
  final int? id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String imageEmoji; // Emoji placeholder for product image
  final String unit; // e.g., "kg", "piece", "litre"
  final bool isAvailable;
  final double rating;
  final int reviewCount;

  Product({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.imageEmoji,
    required this.unit,
    this.isAvailable = true,
    this.rating = 4.5,
    this.reviewCount = 0,
  });

  /// Convert Product to a Map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'image_emoji': imageEmoji,
      'unit': unit,
      'is_available': isAvailable ? 1 : 0,
      'rating': rating,
      'review_count': reviewCount,
    };
  }

  /// Create a Product from a database Map
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String,
      price: (map['price'] as num).toDouble(),
      category: map['category'] as String,
      imageEmoji: map['image_emoji'] as String,
      unit: map['unit'] as String,
      isAvailable: (map['is_available'] as int) == 1,
      rating: (map['rating'] as num).toDouble(),
      reviewCount: map['review_count'] as int,
    );
  }

  @override
  String toString() => 'Product{id: $id, name: $name, price: $price}';
}

/// Static list of sample grocery products for the app
class SampleProducts {
  static List<Product> get all => [
        // Fruits & Vegetables
        Product(
          id: 1,
          name: 'Fresh Bananas',
          description: 'Sweet ripe bananas sourced locally. Perfect for breakfast or snacking.',
          price: 50.0,
          category: 'Fruits & Vegetables',
          imageEmoji: '🍌',
          unit: 'bunch',
          rating: 4.8,
          reviewCount: 124,
        ),
        Product(
          id: 2,
          name: 'Tomatoes',
          description: 'Fresh red tomatoes, perfect for cooking or salads.',
          price: 80.0,
          category: 'Fruits & Vegetables',
          imageEmoji: '🍅',
          unit: 'kg',
          rating: 4.6,
          reviewCount: 89,
        ),
        Product(
          id: 3,
          name: 'Avocados',
          description: 'Creamy ripe avocados, ideal for guacamole or toast.',
          price: 30.0,
          category: 'Fruits & Vegetables',
          imageEmoji: '🥑',
          unit: 'piece',
          rating: 4.9,
          reviewCount: 201,
        ),
        Product(
          id: 4,
          name: 'Spinach',
          description: 'Fresh green spinach, rich in iron and vitamins.',
          price: 40.0,
          category: 'Fruits & Vegetables',
          imageEmoji: '🥬',
          unit: 'bunch',
          rating: 4.5,
          reviewCount: 67,
        ),
        // Dairy & Eggs
        Product(
          id: 5,
          name: 'Fresh Milk',
          description: 'Farm-fresh whole milk, pasteurized and ready to drink.',
          price: 65.0,
          category: 'Dairy & Eggs',
          imageEmoji: '🥛',
          unit: 'litre',
          rating: 4.7,
          reviewCount: 312,
        ),
        Product(
          id: 6,
          name: 'Free Range Eggs',
          description: 'Farm-fresh free-range eggs, 12 per tray.',
          price: 180.0,
          category: 'Dairy & Eggs',
          imageEmoji: '🥚',
          unit: 'tray',
          rating: 4.8,
          reviewCount: 156,
        ),
        Product(
          id: 7,
          name: 'Yoghurt',
          description: 'Creamy natural yoghurt with live cultures. 500ml.',
          price: 120.0,
          category: 'Dairy & Eggs',
          imageEmoji: '🍦',
          unit: '500ml',
          rating: 4.6,
          reviewCount: 98,
        ),
        // Bakery
        Product(
          id: 8,
          name: 'Whole Wheat Bread',
          description: 'Freshly baked whole wheat bread loaf.',
          price: 65.0,
          category: 'Bakery',
          imageEmoji: '🍞',
          unit: 'loaf',
          rating: 4.7,
          reviewCount: 245,
        ),
        Product(
          id: 9,
          name: 'Mandazi',
          description: 'Freshly made East African fried dough, lightly sweetened.',
          price: 20.0,
          category: 'Bakery',
          imageEmoji: '🍩',
          unit: 'piece',
          rating: 4.9,
          reviewCount: 432,
        ),
        // Beverages
        Product(
          id: 10,
          name: 'Mineral Water',
          description: 'Pure mineral water. Refreshing and hydrating. 1.5 litres.',
          price: 80.0,
          category: 'Beverages',
          imageEmoji: '💧',
          unit: '1.5L bottle',
          rating: 4.5,
          reviewCount: 78,
        ),
        Product(
          id: 11,
          name: 'Orange Juice',
          description: 'Freshly squeezed orange juice, no added sugar. 1 litre.',
          price: 250.0,
          category: 'Beverages',
          imageEmoji: '🍊',
          unit: '1L bottle',
          rating: 4.8,
          reviewCount: 134,
        ),
        // Grains & Staples
        Product(
          id: 12,
          name: 'Basmati Rice',
          description: 'Premium long-grain basmati rice. Light and fluffy when cooked.',
          price: 300.0,
          category: 'Grains & Staples',
          imageEmoji: '🍚',
          unit: '2kg bag',
          rating: 4.7,
          reviewCount: 189,
        ),
        Product(
          id: 13,
          name: 'Unga wa Ugali',
          description: 'Finest maize flour for making ugali. 2kg pack.',
          price: 180.0,
          category: 'Grains & Staples',
          imageEmoji: '🌽',
          unit: '2kg bag',
          rating: 4.6,
          reviewCount: 267,
        ),
        // Meat & Seafood
        Product(
          id: 14,
          name: 'Chicken Breast',
          description: 'Fresh boneless chicken breast, trimmed and ready to cook.',
          price: 450.0,
          category: 'Meat & Seafood',
          imageEmoji: '🍗',
          unit: 'kg',
          rating: 4.8,
          reviewCount: 301,
        ),
        Product(
          id: 15,
          name: 'Tilapia Fish',
          description: 'Fresh tilapia fish, cleaned and ready to cook.',
          price: 350.0,
          category: 'Meat & Seafood',
          imageEmoji: '🐟',
          unit: 'kg',
          rating: 4.7,
          reviewCount: 145,
        ),
      ];

  /// Get unique categories from product list
  static List<String> get categories {
    final cats = all.map((p) => p.category).toSet().toList();
    return ['All', ...cats];
  }
}
