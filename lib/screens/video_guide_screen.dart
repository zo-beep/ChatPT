import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
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
  bool _isInitialized = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      final videoPath = widget.exerciseData?['videoUrl'] ?? 'assets/videos/mockvid.mp4';
      _controller = VideoPlayerController.asset(videoPath);
      await _controller!.initialize();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller != null && _isInitialized) {
      setState(() {
        if (_controller!.value.isPlaying) {
          _controller!.pause();
          _isPlaying = false;
        } else {
          _controller!.play();
          _isPlaying = true;
        }
      });
    }
  }

  Future<void> _markAsComplete() async {
    try {
      // If this is an assigned exercise (has an assignment id), update Firestore
      final assignmentId = widget.exerciseData?['id'];
      final user = FirebaseAuth.instance.currentUser;
      if (assignmentId != null && user != null) {
        final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('assignedExercises').doc(assignmentId);
        await FirebaseFirestore.instance.runTransaction((tx) async {
          final snap = await tx.get(docRef);
          if (!snap.exists) return;
          final data = snap.data() ?? {};
          if ((data['completed'] == true) || (data['completedAt'] != null)) return;
          tx.update(docRef, {'completed': true, 'completedAt': FieldValue.serverTimestamp()});
          final histRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('exerciseHistory').doc();
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
            content: Text('Exercise marked as complete!'),
            backgroundColor: Colors.green,
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
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.themeProvider;
    return Scaffold(
      backgroundColor: theme?.backgroundColor ?? const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: theme?.cardColor ?? Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme?.primaryColor ?? const Color(0xFF5B8EFF)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Back',
          style: TextStyle(color: theme?.primaryColor ?? const Color(0xFF5B8EFF)),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: theme?.primaryColor ?? const Color(0xFF5B8EFF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    widget.exerciseName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final double width = constraints.maxWidth;
                  final double height = width > 0 ? (width * 9.0 / 16.0) : 200.0;
                  return Container(
                    height: height,
                    decoration: BoxDecoration(
                      color: theme?.secondaryColor ?? Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _isInitialized && _controller != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              children: [
                                SizedBox.expand(
                                  child: FittedBox(
                                    fit: BoxFit.cover,
                                    child: SizedBox(
                                      width: width,
                                      height: height,
                                      child: VideoPlayer(_controller!),
                                    ),
                                  ),
                                ),
                                Center(
                                  child: GestureDetector(
                                    onTap: _togglePlayPause,
                                    child: Container(
                                      width: 70,
                                      height: 70,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _isPlaying ? Icons.pause : Icons.play_arrow,
                                        size: 40,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Center(
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.play_arrow,
                                size: 40,
                                color: theme?.primaryColor ?? const Color(0xFF5B8EFF),
                              ),
                            ),
                             ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme?.cardColor ?? Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Instructions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme?.textColor ?? Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...widget.instructions.map((instruction) => _buildInstruction(instruction, theme)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (widget.canComplete) ...[
                ElevatedButton(
                  onPressed: _markAsComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme?.primaryColor ?? const Color(0xFF5B8EFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Mark as complete',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme?.primaryColor ?? const Color(0xFF5B8EFF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(
                    color: theme?.primaryColor ?? const Color(0xFF5B8EFF),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  widget.canComplete ? 'Next Exercise' : 'Close',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstruction(String text, ThemeProvider? theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: theme?.subtextColor ?? Colors.grey[700],
          height: 1.5,
        ),
      ),
    );
  }
}