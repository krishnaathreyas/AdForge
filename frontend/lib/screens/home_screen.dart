import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class AdResult {
  final String status;
  final String message;
  final String? videoUrl;

  AdResult({required this.status, required this.message, this.videoUrl});
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      appBar: AppBar(
        title: const Text(
          'Ad-Forge',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 180,
                width: double.infinity,
                child: ClipRRect(
                  // This makes your image have the same rounded corners
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/stock1.png',
                    fit: BoxFit
                        .cover, // This makes the image fill the space nicely
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Forge Your Local Ads',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Use the provider to navigate
                    context.read<AppProvider>().goToTab(1);
                  },
                  icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                  label: const Text(
                    'Scan QR Code',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Recent Activities',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showAdGenerationDialog(context, provider);
                  },
                  icon: const Icon(Icons.video_call, color: Colors.white),
                  label: const Text(
                    'Generate Ad',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Build the list of recent activities from the provider
              ListView.separated(
                itemCount: provider.recentActivities.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final activity = provider.recentActivities[index];
                  return _buildActivityItem(activity);
                },
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 15),
              ),
              if (provider.adResult != null)
                _buildAdResult(provider.adResult! as AdResult),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(ActivityItem activity) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F3A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: activity.iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(activity.icon, color: activity.iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity.subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
          Text(
            activity.time,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

// Add this method after your _buildActivityItem method
void _showAdGenerationDialog(BuildContext context, AppProvider provider) {
  String productName = '';
  String userContext = 'General';

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1F1F3A),
      title: const Text(
        'Generate Ad',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            onChanged: (value) => productName = value,
            decoration: const InputDecoration(
              labelText: 'Product Name',
              labelStyle: TextStyle(color: Colors.white),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          DropdownButton<String>(
            value: userContext,
            onChanged: (value) => userContext = value!,
            items: ['General', 'Sale', 'Electronics', 'Clothing', 'Grocery']
                .map((context) => DropdownMenuItem(
                      value: context,
                      child: Text(
                        context,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            provider.generateAd(
              productName: productName,
              userContext: userContext,
            );
          },
          child: const Text('Generate'),
        ),
      ],
    ),
  );
}

// Add this method after _showAdGenerationDialog
Widget _buildAdResult(AdResult result) {
  return Container(
    margin: const EdgeInsets.only(top: 20),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF1F1F3A),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ad Generation Result',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Status: ${result.status}',
          style: TextStyle(
            fontSize: 14,
            color: result.status == 'Success' ? Colors.green : Colors.orange,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Message: ${result.message}',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        if (result.videoUrl != null) ...[
          const SizedBox(height: 8),
          Text(
            'Video URL: ${result.videoUrl}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.blue,
            ),
          ),
        ],
      ],
    ),
  );
}
