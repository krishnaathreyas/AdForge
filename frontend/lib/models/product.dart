class Product {
  final String id; // This will be used as the SKU
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

  // This factory constructor remains the same, it's for parsing JSON if needed
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

  // --- THIS IS THE UPDATED PART ---
  // The sample products now use the exact SKUs from your backend database
  static List<Product> get sampleProducts => [
        Product(
          id: 'PROD-S24ULTRA', // Correct SKU from your DB
          name: 'Galaxy S24 Ultra',
          brand: 'Samsung',
          category: 'Smartphone',
          description: 'Premium smartphone with AI-powered camera and S Pen.',
          features: [
            'AI-Enhanced Camera',
            'S Pen Integration',
            '5G Connectivity',
          ],
          imageUrl: '',
          price: 1299.99,
        ),
        Product(
          id: 'PROD-WW12T504DAB', // Correct SKU from your DB
          name: 'Bespoke AI™ EcoBubble™ Washer',
          brand: 'Samsung',
          category: 'Home Appliance',
          description: 'Smart washing machine with AI-powered energy savings.',
          features: [
            'EcoBubble Technology',
            'AI Energy Mode',
            'SpaceMax Design',
          ],
          imageUrl: '',
          price: 899.99,
        ),
        Product(
          id: 'PROD-QN900D-TV', // Correct SKU from your DB
          name: 'Samsung Neo QLED 8K TV',
          brand: 'Samsung',
          category: 'Television',
          description:
              'Experience stunning detail with 8K resolution and AI upscaling.',
          features: [
            '8K Resolution',
            'Quantum Matrix Technology',
            'AI Upscaling',
          ],
          imageUrl: '',
          price: 4999.99,
        ),
      ];
}
