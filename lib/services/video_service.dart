import 'package:video_player/video_player.dart';

class VideoService {
  static VideoPlayerController? _controller;
  static bool _isInitialized = false;

  static Future<VideoPlayerController?> initializeVideo(String videoPath) async {
    try {
      _controller = VideoPlayerController.asset(videoPath);
      await _controller!.initialize();
      _isInitialized = true;
      return _controller;
    } catch (e) {
      print('Error initializing video: $e');
      return null;
    }
  }

  static Future<void> disposeVideo() async {
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
      _isInitialized = false;
    }
  }

  static bool get isInitialized => _isInitialized;
  static VideoPlayerController? get controller => _controller;

  static Future<void> playVideo() async {
    if (_controller != null && _isInitialized) {
      await _controller!.play();
    }
  }

  static Future<void> pauseVideo() async {
    if (_controller != null && _isInitialized) {
      await _controller!.pause();
    }
  }

  static Future<void> stopVideo() async {
    if (_controller != null && _isInitialized) {
      await _controller!.pause();
      await _controller!.seekTo(Duration.zero);
    }
  }

  static Duration get position {
    if (_controller != null && _isInitialized) {
      return _controller!.value.position;
    }
    return Duration.zero;
  }

  static Duration get duration {
    if (_controller != null && _isInitialized) {
      return _controller!.value.duration;
    }
    return Duration.zero;
  }

  static bool get isPlaying {
    if (_controller != null && _isInitialized) {
      return _controller!.value.isPlaying;
    }
    return false;
  }

  static double get aspectRatio {
    if (_controller != null && _isInitialized) {
      return _controller!.value.aspectRatio;
    }
    return 16 / 9; // Default aspect ratio
  }
}
