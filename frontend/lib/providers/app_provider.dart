import 'dart:async';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import 'dart:io';

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

  bool _isGenerating = false;
  bool get isGenerating => _isGenerating;
  String _generationStatus = '';
  String get generationStatus => _generationStatus;

  File? _storeImage;
  File? get storeImage => _storeImage;
  String? _selectedCity;
  String? get selectedCity => _selectedCity;

  // NEW: Language state
  String? _selectedLanguage;
  String? get selectedLanguage => _selectedLanguage;

  String? _error;
  String? get error => _error;

  Timer? _pollingTimer;

  final List<ActivityItem> _recentActivities = [];
  List<ActivityItem> get recentActivities => _recentActivities;

  @override
  void dispose() {
    _pollingTimer?.cancel();
    pageController.dispose();
    super.dispose();
  }

  void goToTab(int index) {
    _selectedIndex = index;
    pageController.animateToPage(index,
        duration: const Duration(milliseconds: 200), curve: Curves.easeIn);
    notifyListeners();
  }

  void setPageIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  Future<void> setScannedProduct(Product product) async {
    _scannedProduct = product;
    addActivity(ActivityItem(
        icon: Icons.qr_code_2,
        iconColor: Colors.green,
        title: 'Product Scanned',
        subtitle: product.name,
        time: 'Just now'));
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));
    goToTab(2);
  }

  void setMarketingContext(String context) {
    _marketingContext = context;
    notifyListeners();
  }

  // Methods for existing features (keeping store image for UI purposes)
  void setStoreImage(File? image) {
    _storeImage = image;
    notifyListeners();
  }

  void setSelectedCity(String? city) {
    _selectedCity = city;
    notifyListeners();
  }

  // NEW: Language setter
  void setSelectedLanguage(String? language) {
    _selectedLanguage = language;
    notifyListeners();
  }

  // UPDATED: Now passes language to backend
  Future<bool> startVideoGeneration() async {
    if (_scannedProduct == null) return false;
    _isGenerating = true;
    _generatedVideoUrl = null;
    _generationStatus = "Kicking off the ad-forge engine...";
    notifyListeners();

    // UPDATED: Now includes language parameter
    final jobId = await ApiService.startVideoGenerationJob(
        product: _scannedProduct!,
        context: _marketingContext,
        language: _selectedLanguage // NEW: Passing language to backend
        );

    if (jobId != null) {
      goToTab(3); // Immediately go to the results screen to show progress
      _generationStatus = "Blueprint created, generating video clips...";
      notifyListeners();
      _startPolling(jobId);
      return true;
    } else {
      _generationStatus = "Failed to start generation job.";
      _isGenerating = false;
      _error = "Could not start the job. Check backend connection.";
      notifyListeners();
      return false;
    }
  }

  void _startPolling(String jobId) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      // Timeout after 5 minutes
      if (timer.tick > 20) {
        _generationStatus =
            "Generation is taking too long. Please try again later.";
        _isGenerating = false;
        timer.cancel();
        notifyListeners();
        return;
      }

      final statusResult = await ApiService.checkJobStatus(jobId: jobId);

      if (statusResult != null) {
        final status = statusResult['status'];
        if (status == 'COMPLETE') {
          _generatedVideoUrl = statusResult['finalVideoUrl'];
          _isGenerating = false;
          _generationStatus = "Complete!";
          timer.cancel();
          addActivity(ActivityItem(
              icon: Icons.play_circle_outline,
              iconColor: Colors.green,
              title: 'New Ad Generated',
              subtitle: _scannedProduct?.name ?? 'Custom Product',
              time: 'Just now'));
        } else if (status == 'FAILED') {
          _generationStatus = "Video generation failed.";
          _error = "The backend process failed during generation.";
          _isGenerating = false;
          timer.cancel();
        } else {
          _generationStatus = "Status: ${status ?? 'Processing...'}";
        }
      } else {
        _generationStatus = "Error checking status. Retrying...";
      }
      notifyListeners();
    });
  }

  // UPDATED: Reset now includes language
  void resetFlow() {
    _pollingTimer?.cancel();
    _scannedProduct = null;
    _marketingContext = '';
    _generatedVideoUrl = null;
    _isGenerating = false;
    _generationStatus = '';
    _error = null;
    _storeImage = null;
    _selectedCity = null;
    _selectedLanguage = null; // NEW: Reset language selection
    goToTab(0);
    notifyListeners();
  }

  void addActivity(ActivityItem activity) {
    _recentActivities.insert(0, activity);
    if (_recentActivities.length > 5) _recentActivities.removeLast();
    notifyListeners();
  }
}

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
