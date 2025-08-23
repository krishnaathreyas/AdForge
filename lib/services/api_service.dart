import 'dart:math';
import '../models/product.dart';

class ApiService {
  static const String baseUrl = 'https://api.example.com';

  // Mock data for demonstration
  static final List<Product> _mockProducts = [
    Product(
      id: '1',
      name: 'Samsung Galaxy A16',
      description: 'Premium smartphone with advanced features',
      imageUrl: 'https://via.placeholder.com/300x200',
      specifications: {
        'RAM': '6GB',
        'Storage': '128GB',
        'Display': '120Hz AMOLED',
        'Processor': 'Snapdragon 695',
        'Camera': '50MP Triple Camera',
        'Battery': '5000mAh',
      },
    ),
    Product(
      id: '2',
      name: 'iPhone 15',
      description: 'Latest iPhone with cutting-edge technology',
      imageUrl: 'https://via.placeholder.com/300x200',
      specifications: {
        'RAM': '8GB',
        'Storage': '256GB',
        'Display': 'Super Retina XDR',
        'Processor': 'A17 Pro',
        'Camera': '48MP Main Camera',
        'Battery': 'All-day battery life',
      },
    ),
    Product(
      id: '3',
      name: 'Google Pixel 8',
      description: 'AI-powered smartphone with pure Android',
      imageUrl: 'https://via.placeholder.com/300x200',
      specifications: {
        'RAM': '8GB',
        'Storage': '128GB',
        'Display': '120Hz OLED',
        'Processor': 'Google Tensor G3',
        'Camera': '50MP Dual Camera',
        'Battery': '4575mAh',
      },
    ),
  ];

  static Future<Product?> fetchProductByBarcode(String barcode) async {
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 2));

      // Mock response based on barcode
      final random = Random();
      final productIndex = random.nextInt(_mockProducts.length);
      return _mockProducts[productIndex];

      /* Real API implementation would be:
      final response = await http.get(
        Uri.parse('$baseUrl/products/barcode/$barcode'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Product.fromJson(data);
      }
      return null;
      */
    } catch (e) {
      print('Error fetching product: $e');
      return null;
    }
  }

  static Future<String?> generateContextualVideo({
    required Product product,
    required String context,
  }) async {
    try {
      // Simulate API call delay for video generation
      await Future.delayed(const Duration(seconds: 5));

      // Mock video URLs
      final videoUrls = [
        'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
      ];

      final random = Random();
      return videoUrls[random.nextInt(videoUrls.length)];

      /* Real API implementation would be:
      final response = await http.post(
        Uri.parse('$baseUrl/generate-video'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'productId': product.id,
          'context': context,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['videoUrl'];
      }
      return null;
      */
    } catch (e) {
      print('Error generating video: $e');
      return null;
    }
  }
}
