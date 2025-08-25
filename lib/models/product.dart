class Product {
  final String id;
  final String name;
  final String brand;
  final String category;
  final String description;
  final List<String> features;
  final String imageUrl;
  final double price;

  Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.description,
    required this.features,
    required this.imageUrl,
    required this.price,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      brand: json['brand'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      features: List<String>.from(json['features'] ?? []),
      imageUrl: json['imageUrl'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'category': category,
      'description': description,
      'features': features,
      'imageUrl': imageUrl,
      'price': price,
    };
  }

  // Sample products for demo
  static List<Product> get sampleProducts => [
        Product(
          id: '1',
          name: 'Galaxy S24 Ultra',
          brand: 'Samsung',
          category: 'Smartphone',
          description: 'Premium smartphone with AI-powered camera and S Pen',
          features: [
            'AI-Enhanced Camera',
            'S Pen Integration',
            '5G Connectivity',
            'Long Battery Life',
          ],
          imageUrl: 'https://example.com/galaxy-s24-ultra.jpg',
          price: 1199.99,
        ),
        Product(
          id: '2',
          name: 'Galaxy Z Fold5',
          brand: 'Samsung',
          category: 'Foldable Phone',
          description: 'Innovative foldable smartphone for multitasking',
          features: [
            'Foldable Display',
            'Multitasking Capabilities',
            'Durability Enhanced',
            'Premium Design',
          ],
          imageUrl: 'https://example.com/galaxy-fold5.jpg',
          price: 1799.99,
        ),
      ];
}
