import 'dart:math';
import '../models/product.dart';

class ApiService {
  // This method simulates fetching a product by its barcode
  static Future<Product?> fetchProductByBarcode(String barcode) async {
    // Simulate a network delay
    await Future.delayed(const Duration(seconds: 2));

    // In a real app, you would look up the barcode. Here, we just pick a random sample.
    final products = Product.sampleProducts;
    return products[Random().nextInt(products.length)];
  }

  // This method simulates the AI video generation process
  static Future<String?> generateContextualVideo({
    required Product product,
    required String context,
  }) async {
    // Simulate a long video generation delay
    await Future.delayed(const Duration(seconds: 5));

    // In a real app, you would call your ElevenLabs, GPT-4, etc. APIs here.
    // For now, we return a random sample video URL.
    final videoUrls = [
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
    ];

    return videoUrls[Random().nextInt(videoUrls.length)];
  }
}
