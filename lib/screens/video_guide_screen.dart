import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:demo_app/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VideoGuideScreen extends StatefulWidget {
  final String exerciseName;
  final List<String> instructions;
  final ThemeProvider? themeProvider;
  final Map<String, dynamic>? exerciseData;
  final bool canComplete;

  const VideoGuideScreen({
    super.key,
    required this.exerciseName,
    required this.instructions,
    this.themeProvider,
    this.exerciseData,
    this.canComplete = false,
  });

  @override
  State<VideoGuideScreen> createState() => _VideoGuideScreenState();
}

class _VideoGuideScreenState extends State<VideoGuideScreen> {
  VideoPlayerController? _controller;
  YoutubePlayerController? _youtubeController;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isYoutubeVideo = false;
  String? _videoError;

  @override
  void initState() {
    super.initState();
    _validateAndInitializeVideo();
  }

  void _handleError(String error) {
    _onVideoError(error);
  }
  
  // Custom Regex to extract YouTube ID accurately across cross-platform formats
  String? _extractYoutubeId(String url) {
    final RegExp regExp = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
      caseSensitive: false,
      multiLine: false,
    );
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  Future<void> _validateAndInitializeVideo() async {
    try {
      final videoUrl = widget.exerciseData?['videoUrl'];

      // Handle empty URL - show no video message
      if (videoUrl == null || videoUrl.isEmpty) {
        setState(() {
          _isInitialized = true;
          _isYoutubeVideo = false;
          _isPlaying = false;
          _videoError = 'No video available for this exercise';
        });
        return;
      }

      // Handle YouTube videos via iframe (Web/Mobile compatible)
      if (videoUrl.contains('youtube.com') || videoUrl.contains('youtu.be')) {
        final videoId = _extractYoutubeId(videoUrl);
        if (videoId != null) {
          _youtubeController = YoutubePlayerController.fromVideoId(
            videoId: videoId,
            autoPlay: false,
            params: const YoutubePlayerParams(
              showControls: true,
              showFullscreenButton: false,
            ),
          );
          setState(() {
            _isYoutubeVideo = true;
            _isInitialized = true;
          });
        } else {
          setState(() {
            _videoError = 'Invalid YouTube URL format';
          });
        }
        return;
      }

      // Handle regular direct URL video
      try {
        _controller = VideoPlayerController.network(videoUrl);
        await _controller!.initialize();
        setState(() {
          _isInitialized = true;
          _isYoutubeVideo = false;
        });
      } catch (e) {
        setState(() {
          _videoError = 'Error loading video: $e';
          _isYoutubeVideo = false;
        });
      }
    } catch (e) {
      setState(() {
        _videoError = 'Error initializing video: $e';
        _isYoutubeVideo = false;
      });
    }
  }

  void _onVideoError(String error) {
    if (!mounted) return;
    setState(() => _videoError = error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: Colors.redAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _youtubeController?.close();
    super.dispose();
  }

  @override
  void deactivate() {
    if (_isYoutubeVideo) {
      _youtubeController?.pauseVideo();
    } else {
      _controller?.pause();
    }
    super.deactivate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isYoutubeVideo && _youtubeController != null) {
      // This helps with initialization on web
      setState(() {});
    }
  }

  Future<void> _togglePlayPause() async {
    if (_controller != null && _isInitialized) {
      try {
        if (_controller!.value.isPlaying) {
          await _controller!.pause();
          setState(() => _isPlaying = false);
        } else {
          await _controller!.play();
          setState(() => _isPlaying = true);
        }
      } catch (e) {
        _onVideoError('Error controlling playback: ${e.toString()}');
      }
    }
  }

  Future<void> _markAsComplete() async {
    try {
      // If this is an assigned exercise (has an assignment id), update Firestore
      final assignmentId = widget.exerciseData?['id'];
      final user = FirebaseAuth.instance.currentUser;
      if (assignmentId != null && user != null) {
        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('assignedExercises')
            .doc(assignmentId);
            
        await FirebaseFirestore.instance.runTransaction((tx) async {
          final snap = await tx.get(docRef);
          if (!snap.exists) return;
          final data = snap.data() ?? {};
          if ((data['completed'] == true) || (data['completedAt'] != null)) return;
          
          tx.update(docRef, {
            'completed': true,
            'completedAt': FieldValue.serverTimestamp()
          });
          
          final histRef = FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('exerciseHistory')
              .doc();
              
          tx.set(histRef, {
            'assignmentId': assignmentId,
            'exerciseId': data['exerciseId'],
            'exerciseName': data['exerciseName'] ?? '',
            'sets': data['sets'] ?? 0,
            'repetitions': data['repetitions'] ?? 0,
            'duration': data['duration'] ?? 0,
            'assignedBy': data['assignedBy'],
            'assignedAt': data['assignedAt'],
            'completedAt': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          });
        });
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Exercise marked as complete!'),
            backgroundColor: Colors.green.shade600,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
      // Return true to caller so UI can update immediately
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      print('Failed to mark complete: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark complete: $e'),
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.themeProvider;
    final primaryColor = theme?.primaryColor ?? const Color(0xFF5B8EFF);
    final bgColor = theme?.backgroundColor ?? Colors.white;
    final textColor = theme?.textColor ?? const Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: primaryColor,
      body: Column(
        children: [
          // ─── Header Section ───────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Modern Back Button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Exercise Title
                    Text(
                      widget.exerciseName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Video Guide & Instructions',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          // ─── Content Section (Bottom Sheet Style) ─────────────────────────
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(36),
                  topRight: Radius.circular(36),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(36),
                  topRight: Radius.circular(36),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Video Player Container
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: _buildVideoPlayer(theme),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Instructions Title
                      Text(
                        'Step-by-Step Instructions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Instructions List
                      ...widget.instructions.asMap().entries.map((entry) {
                        return _buildInstructionStep(entry.value, entry.key + 1, theme);
                      }),
                      const SizedBox(height: 40),

                      // Action Buttons
                      if (widget.canComplete) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _markAsComplete,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              elevation: 2,
                              shadowColor: primaryColor.withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Mark as Complete',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            side: BorderSide(color: primaryColor, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            widget.canComplete ? 'Close Video' : 'Go Back',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24), // Extra bottom padding for safe area
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String text, int stepNumber, ThemeProvider? theme) {
    final primaryColor = theme?.primaryColor ?? const Color(0xFF5B8EFF);
    final textColor = theme?.textColor ?? const Color(0xFF1E293B);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$stepNumber',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  color: textColor.withOpacity(0.85),
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer(ThemeProvider? theme) {
    final primaryColor = theme?.primaryColor ?? const Color(0xFF5B8EFF);
    
    // Show error state if there's an error
    if (_videoError != null) {
      return Container(
        color: Colors.grey.shade100,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _videoError!,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    // Show loading state while video is initializing
    if (!_isInitialized) {
      return Container(
        color: Colors.grey.shade100,
        child: Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    // Show YouTube player if it's a YouTube video
    if (_isYoutubeVideo && _youtubeController != null) {
      return YoutubePlayer(
        controller: _youtubeController!,
      );
    }

    // Show video player for local or direct URL videos
    if (_controller != null && _controller!.value.isInitialized) {
      return Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            ),
          ),
          // Play/Pause Overlay
          GestureDetector(
            onTap: _togglePlayPause,
            child: AnimatedOpacity(
              opacity: _isPlaying ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // Invisible full-screen tap target to pause while playing
          if (_isPlaying)
            Positioned.fill(
              child: GestureDetector(
                onTap: _togglePlayPause,
                child: Container(color: Colors.transparent),
              ),
            ),
        ],
      );
    }

    // Fallback for no video
    return Container(
      color: Colors.grey.shade100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No video available',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}