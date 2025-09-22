import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ContextScreen extends StatefulWidget {
  const ContextScreen({super.key});

  @override
  State<ContextScreen> createState() => _ContextScreenState();
}

class _ContextScreenState extends State<ContextScreen> {
  final TextEditingController _contextController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // CRITICAL: Keep this loading state from original
  bool _isButtonLoading = false;

  // NEW: Language dropdown state
  String? _selectedLanguage;

  final List<String> _suggestions = [
    'Student Discounts',
    'Eco-Friendly Features',
    'Smart Home Integration',
    'Gaming Performance',
    'Holiday Season Deal',
    'New Product Launch',
    'Local Community Event',
    'Trade-in Offer',
  ];

  // NEW: Language options
  final List<Map<String, String>> _languageOptions = [
    {'value': 'english', 'label': 'English'},
    {'value': 'hindi', 'label': 'Delhi-Hindi'},
    {'value': 'kannada', 'label': 'Bengaluru-Kannada'},
    {'value': 'marathi', 'label': 'Mumbai-Marathi'},
    {'value': 'tamil', 'label': 'Chennai-Tamil'},
    {'value': 'telugu', 'label': 'Hyderabad-Telugu'},
  ];

  @override
  void initState() {
    super.initState();
    _contextController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _contextController.dispose();
    super.dispose();
  }

  // NEW FEATURE: Image picker functionality
  Future<void> _pickImage() async {
    final provider = context.read<AppProvider>();
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        provider.setStoreImage(File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not pick image.'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  // CRITICAL: Keep this error dialog from original
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F3A),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 10),
            Text('Uh-Oh!', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          'An error occurred while trying to start the ad generation. Please try again.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'OK',
              style: TextStyle(
                  color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // CRITICAL: Keep this proper async error handling from original
  Future<void> _handleGenerateAd() async {
    FocusScope.of(context).unfocus();

    // Start the button's loading spinner
    setState(() => _isButtonLoading = true);

    final provider = context.read<AppProvider>();
    provider.setMarketingContext(_contextController.text.trim());

    // Call the provider. The provider will handle navigation on success.
    final bool success = await provider.startVideoGeneration();

    // Stop the button's loading spinner
    if (mounted) {
      setState(() => _isButtonLoading = false);
    }

    // If it failed to start, show our error pop-up
    if (!success && mounted) {
      _showErrorDialog(provider.error ?? "Failed to start job");
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final product = provider.scannedProduct;

    if (product == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0F23),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Text(
              'Please scan a product on the Scan tab first.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 18),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      appBar: AppBar(
        title: const Text('Enter Marketing Context'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Original product display
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 25),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F3A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF6366F1).withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SCANNED PRODUCT',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.description,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // NEW: Language Selection Dropdown
              const Text(
                'Language:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 15),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F3A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A2A4E)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedLanguage,
                    hint: Text(
                      'Language',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 16,
                      ),
                    ),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey.shade400,
                    ),
                    dropdownColor: const Color(0xFF1F1F3A),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    items: _languageOptions.map((language) {
                      return DropdownMenuItem<String>(
                        value: language['value'],
                        child: Text(
                          language['label']!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedLanguage = newValue;
                        // Pass the selected value to the AppProvider
                        context
                            .read<AppProvider>()
                            .setSelectedLanguage(newValue);
                      });
                    },
                  ),
                ),
              ),

              // Original context input
              const SizedBox(height: 30),
              Text(
                'Tell us about your local marketing needs:',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 15),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F3A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _contextController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'e.g., \'A festive holiday ad for families...\'',
                    hintStyle:
                        TextStyle(color: Colors.grey.shade500, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),

              // Store Image Upload (existing feature)
              const SizedBox(height: 30),
              const Text(
                'Store Image (Optional):',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 15),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F1F3A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2A2A4E)),
                  ),
                  child: provider.storeImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(provider.storeImage!,
                              fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined,
                                color: Colors.grey.shade400, size: 40),
                            const SizedBox(height: 8),
                            Text('Tap to upload store image',
                                style: TextStyle(color: Colors.grey.shade400)),
                          ],
                        ),
                ),
              ),

              // Original suggestions
              const SizedBox(height: 30),
              const Text(
                'Quick Suggestions:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 15),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _suggestions.map((suggestion) {
                  return ActionChip(
                    label: Text(suggestion),
                    onPressed: () => _contextController.text = suggestion,
                    backgroundColor: const Color(0xFF1F1F3A),
                    labelStyle: const TextStyle(color: Colors.white),
                    side: const BorderSide(color: Color(0xFF2A2A4E)),
                  );
                }).toList(),
              ),

              // CRITICAL: Keep original button with proper error handling
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  // IMPORTANT: Call the proper async method, not direct provider calls
                  onPressed: _contextController.text.trim().isEmpty ||
                          _isButtonLoading ||
                          provider.isGenerating
                      ? null
                      : _handleGenerateAd, // This handles errors properly
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    disabledBackgroundColor: Colors.grey.shade800,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: _isButtonLoading || provider.isGenerating
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Generate Ad',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
