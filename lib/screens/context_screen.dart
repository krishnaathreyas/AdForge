import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class ContextScreen extends StatefulWidget {
  const ContextScreen({super.key});

  @override
  State<ContextScreen> createState() => _ContextScreenState();
}

class _ContextScreenState extends State<ContextScreen> {
  final TextEditingController _contextController = TextEditingController();

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

  Future<void> _generateAd() async {
    FocusScope.of(context).unfocus();
    final provider = context.read<AppProvider>();
    provider.setMarketingContext(_contextController.text);

    final success = await provider.generateVideo();

    if (mounted && success) {
      provider.goToTab(3); // Navigate to Results
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error generating video.'),
            backgroundColor: Colors.red),
      );
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
        title: const Text(
          'Enter Marketing Context',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    hintText: 'e.g., \'Targeting young families...\'',
                    hintStyle:
                        TextStyle(color: Colors.grey.shade500, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
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
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _contextController.text.trim().isEmpty ||
                          provider.isGeneratingVideo
                      ? null
                      : _generateAd,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    disabledBackgroundColor: Colors.grey.shade800,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: provider.isGeneratingVideo
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
