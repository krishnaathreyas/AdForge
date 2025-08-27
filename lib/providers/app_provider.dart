import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class AppProvider with ChangeNotifier {
  // Navigation State
  final PageController pageController = PageController();
  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;

  // App Data State
  Product? _scannedProduct;
  Product? get scannedProduct => _scannedProduct;

  String _marketingContext = '';
  String get marketingContext => _marketingContext;

  String? _generatedVideoUrl;
  String? get generatedVideoUrl => _generatedVideoUrl;

  bool _isGeneratingVideo = false;
  bool get isGeneratingVideo => _isGeneratingVideo;

  List<ActivityItem> _recentActivities = [];
  List<ActivityItem> get recentActivities => _recentActivities;

  // --- METHODS ---

  void goToTab(int index) {
    _selectedIndex = index;
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeIn,
    );
    notifyListeners();
  }

  Future<void> setScannedProduct(Product product) async {
    // <-- Made this async
    _scannedProduct = product;
    addActivity(ActivityItem(
      icon: Icons.qr_code_2,
      iconColor: Colors.green,
      title: 'Product Scanned',
      subtitle: product.name,
      time: 'Just now',
    ));
    notifyListeners();
    // Simulate a small delay for a smoother transition before navigating
    await Future.delayed(
        const Duration(milliseconds: 500)); // <-- Added a small delay
    goToTab(2); // Automatically go to Context screen
  }

  void setMarketingContext(String context) {
    _marketingContext = context;
    notifyListeners();
  }

  // This is the main method that calls our real backend
  Future<bool> generateVideo() async {
    if (_scannedProduct == null) return false;

    _isGeneratingVideo = true;
    _generatedVideoUrl = null;
    notifyListeners();

    // Call the REAL ApiService method
    final url = await ApiService.generateRealVideo(
        product: _scannedProduct!, context: _marketingContext);

    _generatedVideoUrl = url;
    _isGeneratingVideo = false;

    if (url != null) {
      addActivity(ActivityItem(
        icon: Icons.play_circle_outline,
        iconColor: Colors.green,
        title: 'New Ad Generated',
        subtitle: _scannedProduct?.name ?? 'Custom Product',
        time: 'Just now',
      ));
      notifyListeners();
      return true;
    }
    return false;
  }

  void resetFlow() {
    _scannedProduct = null;
    _marketingContext = '';
    _generatedVideoUrl = null;
    goToTab(0);
    notifyListeners();
  }

  void addActivity(ActivityItem activity) {
    _recentActivities.insert(0, activity);
    if (_recentActivities.length > 5) {
      _recentActivities.removeLast();
    }
    notifyListeners();
  }
}

// Helper class for activity items
class ActivityItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;

  ActivityItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
  });
}
