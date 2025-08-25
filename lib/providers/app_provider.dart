import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class AppProvider with ChangeNotifier {
  // Navigation State
  final PageController pageController = PageController();
  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;

  // Scanned Product Data
  Product? _scannedProduct;
  Product? get scannedProduct => _scannedProduct;

  // Marketing Context
  String _marketingContext = '';
  String get marketingContext => _marketingContext;

  // Generated Video Data
  String? _generatedVideoUrl;
  String? get generatedVideoUrl => _generatedVideoUrl;
  bool _isGeneratingVideo = false;
  bool get isGeneratingVideo => _isGeneratingVideo;

  // Recent Activities
  List<ActivityItem> _recentActivities = [
    // Initial placeholder data
    ActivityItem(
      icon: Icons.play_circle_outline,
      iconColor: Colors.blue,
      title: 'Ad Generated',
      subtitle: 'Dining Ad for Samsung',
      time: '5 min ago',
    ),
    ActivityItem(
      icon: Icons.qr_code_2,
      iconColor: Colors.purple,
      title: 'Product Scanned',
      subtitle: 'Samsung Galaxy S24 Ultra',
      time: 'Yesterday',
    ),
  ];
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
    _scannedProduct = product;
    addActivity(ActivityItem(
      icon: Icons.qr_code_2,
      iconColor: Colors.green,
      title: 'Product Scanned',
      subtitle: product.name,
      time: 'Just now',
    ));
    notifyListeners();
    // Simulate a small delay before navigating
    await Future.delayed(const Duration(milliseconds: 500));
    goToTab(2); // Automatically go to Context screen
  }

  void setMarketingContext(String context) {
    _marketingContext = context;
    notifyListeners();
  }

  Future<bool> generateVideo() async {
    if (scannedProduct == null) return false;

    _isGeneratingVideo = true;
    notifyListeners();

    final url = await ApiService.generateContextualVideo(
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
    goToTab(0); // Go back to home
    notifyListeners();
  }

  void addActivity(ActivityItem activity) {
    _recentActivities.insert(0, activity);
    if (_recentActivities.length > 5) {
      // Keep list size manageable
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
