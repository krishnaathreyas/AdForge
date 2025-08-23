import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class AppProvider extends ChangeNotifier {
  Product? _currentProduct;
  String _context = '';
  String? _videoUrl;
  bool _isLoading = false;
  String? _error;

  Product? get currentProduct => _currentProduct;
  String get context => _context;
  String? get videoUrl => _videoUrl;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setProduct(Product product) {
    _currentProduct = product;
    notifyListeners();
  }

  void setContext(String context) {
    _context = context;
    notifyListeners();
  }

  Future<bool> fetchProductByBarcode(String barcode) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final product = await ApiService.fetchProductByBarcode(barcode);
      if (product != null) {
        _currentProduct = product;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Product not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Failed to fetch product: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> generateVideo() async {
    if (_currentProduct == null) return false;

    _isLoading = true;
    _error = null;
    _videoUrl = null;
    notifyListeners();

    try {
      final videoUrl = await ApiService.generateContextualVideo(
        product: _currentProduct!,
        context: _context,
      );

      if (videoUrl != null) {
        _videoUrl = videoUrl;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to generate video';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Video generation failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearData() {
    _currentProduct = null;
    _context = '';
    _videoUrl = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
