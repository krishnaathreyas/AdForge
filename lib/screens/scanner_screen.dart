import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/product.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _handleBarcodeScan(String barcodeValue) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    // For our demo, we'll just pick a random sample product
    final product = Product.sampleProducts.first;

    // Use the provider to set the product and navigate
    await context.read<AppProvider>().setScannedProduct(product);

    // Reset state if we come back to this screen
    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      appBar: AppBar(
        title: const Text(
          'Scan Product QR Code',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    MobileScanner(
                      controller: controller,
                      onDetect: (capture) {
                        if (capture.barcodes.isNotEmpty &&
                            capture.barcodes.first.rawValue != null) {
                          _handleBarcodeScan(capture.barcodes.first.rawValue!);
                        }
                      },
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF6366F1).withOpacity(0.7),
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    if (_isProcessing)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                            child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text("Processing...",
                                style: TextStyle(color: Colors.white))
                          ],
                        )),
                      )
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () {
                  context.read<AppProvider>().goToTab(2);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Enter Code Manually',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
