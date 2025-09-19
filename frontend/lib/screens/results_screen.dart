import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../providers/app_provider.dart';
import '../widgets/loading_animation.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  VideoPlayerController? _controller;
  Future<void>? _initializeVideoPlayerFuture;

  // New state variables for loading indicators
  bool _isDownloading = false;
  bool _isSharing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.watch<AppProvider>();
    final videoUrl = provider.generatedVideoUrl;

    if (videoUrl != null &&
        (_controller == null || _controller!.dataSource != videoUrl)) {
      _controller?.dispose();
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

  // --- UPDATED DOWNLOAD HELPER ---
  Future<File?> _downloadVideo(String url) async {
    print("🔄 Starting video download from: $url");
    try {
      final dio = Dio();
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/ad_forge_video.mp4';

      // We removed the onReceiveProgress callback for a cleaner log
      await dio.download(url, tempPath);

      final file = File(tempPath);
      if (await file.exists() && await file.length() > 0) {
        print("✅ Download completed successfully to: $tempPath");
        return file;
      } else {
        throw Exception('Downloaded file is empty or does not exist.');
      }
    } catch (e) {
      print("❌ Error during video download: $e");
      return null;
    }
  }

  // --- UPDATED DOWNLOAD HANDLER ---
  Future<void> _handleDownloadAd() async {
    final provider = context.read<AppProvider>();
    if (provider.generatedVideoUrl == null) return;

    setState(() => _isDownloading = true);

    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) await Gal.requestAccess();

      final videoFile = await _downloadVideo(provider.generatedVideoUrl!);

      if (videoFile != null) {
        await Gal.putVideo(videoFile.path, album: 'Ad-Forge');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Video saved to gallery!'),
                backgroundColor: Colors.green),
          );
        }
        await videoFile.delete(); // Clean up
      } else {
        throw Exception('Download failed, file not available.');
      }
    } catch (e) {
      print("❌ Error saving to gallery: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to save video.'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      // This 'finally' block GUARANTEES the spinner stops
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  // --- UPDATED SHARE HANDLER ---
  Future<void> _handleShareAd() async {
    final provider = context.read<AppProvider>();
    if (provider.generatedVideoUrl == null) return;

    setState(() => _isSharing = true);

    try {
      final videoFile = await _downloadVideo(provider.generatedVideoUrl!);
      if (videoFile != null) {
        await Share.shareXFiles(
          [XFile(videoFile.path)],
          text: 'Check out this ad I made with Ad-Forge!',
        );
        await videoFile.delete(); // Clean up
      } else {
        throw Exception('Download failed, file not available for sharing.');
      }
    } catch (e) {
      print("❌ Error preparing for share: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to prepare video for sharing.'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      // This 'finally' block GUARANTEES the spinner stops
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(provider),
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _buildBody(provider),
        ),
      ),
    );
  }

  String _getAppBarTitle(AppProvider provider) {
    if (provider.isGenerating) return 'Generating Your Ad...';
    if (provider.error != null) return 'Generation Failed';
    if (provider.generatedVideoUrl != null) return 'Ad Ready!';
    return 'Results';
  }

  Widget _buildBody(AppProvider provider) {
    if (provider.isGenerating) {
      return _buildProcessingUI(provider);
    }
    if (provider.error != null) {
      return _buildErrorUI(provider);
    }
    if (provider.generatedVideoUrl != null) {
      return _buildVideoPlayerUI();
    }
    // Default state if user navigates here directly
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Text(
          'Your generated ad will appear here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade400, fontSize: 18),
        ),
      ),
    );
  }

  Widget _buildProcessingUI(AppProvider provider) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),

        // Option 1: Interactive circular loading with progress bar (recommended)
        InteractiveLoadingWidget(progress: 0.5),

        // Option 2: Flying character with progress bar (comment out the one above and uncomment this)
        // FlyingCharacterWidget(progress: provider.generationProgress),

        const SizedBox(height: 40),
        const Text(
          "Forging your masterpiece...",
          style: TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 15),
        Text(
          provider.generationStatus,
          style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 15),
        Text(
          "This may take a few moments. Please keep the app open.",
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorUI(AppProvider provider) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        const Icon(Icons.error_outline, color: Colors.red, size: 60),
        const SizedBox(height: 20),
        const Text(
          "Uh-Oh! Something went wrong.",
          style: TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 15),
        Text(
          provider.error!,
          style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => context.read<AppProvider>().resetFlow(),
            icon: const Icon(Icons.refresh, color: Colors.white),
            label:
                const Text('Start Over', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildVideoPlayerUI() {
    return Column(
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
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      VideoPlayer(_controller!),
                      // Play/Pause Button Overlay
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _controller!.value.isPlaying
                                ? _controller!.pause()
                                : _controller!.play();
                          });
                        },
                        child: Container(
                          color: Colors
                              .transparent, // Makes the whole area tappable
                          child: Center(
                            child: AnimatedOpacity(
                              opacity: _controller!.value.isPlaying ? 0.0 : 1.0,
                              duration: const Duration(milliseconds: 300),
                              child: const Icon(Icons.play_circle_fill,
                                  color: Colors.white70, size: 60),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12)),
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
              Text('Ad Generation Complete!',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ],
          ),
        ),
        const SizedBox(height: 30),
        // Save and Share Buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isDownloading ? null : _handleDownloadAd,
                icon: _isDownloading
                    ? Container(
                        width: 24,
                        height: 24,
                        padding: const EdgeInsets.all(2.0),
                        child: const CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 3))
                    : const Icon(Icons.download, color: Colors.white),
                label: const Text('Download Ad',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isSharing ? null : _handleShareAd,
                icon: _isSharing
                    ? Container(
                        width: 24,
                        height: 24,
                        padding: const EdgeInsets.all(2.0),
                        child: const CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 3))
                    : const Icon(Icons.share, color: Colors.white),
                label: const Text('Share Ad',
                    style: TextStyle(color: Colors.white)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
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
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            label: const Text('Start New Ad',
                style: TextStyle(color: Colors.white)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF2A2A4E)),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}
