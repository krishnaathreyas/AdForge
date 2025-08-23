class Product {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final Map<String, dynamic> specifications;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.specifications,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      specifications: json['specifications'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'specifications': specifications,
    };
  }
}
