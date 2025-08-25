import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../providers/app_provider.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  VideoPlayerController? _controller;
  Future<void>? _initializeVideoPlayerFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.watch<AppProvider>();
    final videoUrl = provider.generatedVideoUrl;

    if (videoUrl != null &&
        (_controller == null || _controller!.dataSource != videoUrl)) {
      _controller?.dispose(); // Dispose old controller if it exists
      _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      _initializeVideoPlayerFuture = _controller!.initialize().then((_) {
        setState(() {});
        _controller!.play();
        _controller!.setLooping(true);
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    if (provider.generatedVideoUrl == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0F23),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Text(
              'Your generated ad will appear here.',
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
          'Ad Ready!',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              FutureBuilder(
                future: _initializeVideoPlayerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      _controller != null &&
                      _controller!.value.isInitialized) {
                    return AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: VideoPlayer(_controller!),
                      ),
                    );
                  } else {
                    return AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F3A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Ad Generation Complete!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download, color: Colors.white),
                      label: const Text('Save Ad',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.share, color: Colors.white),
                      label: const Text('Share Ad',
                          style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.read<AppProvider>().resetFlow(),
                  icon:
                      const Icon(Icons.add_circle_outline, color: Colors.white),
                  label: const Text('Start New Ad',
                      style: TextStyle(color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2A2A4E)),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
