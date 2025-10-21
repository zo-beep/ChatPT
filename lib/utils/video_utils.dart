import 'package:url_launcher/url_launcher.dart';

class VideoUtils {
  static String? getYouTubeVideoId(String url) {
    // Handle multiple YouTube URL formats
    RegExp exp = RegExp(
      r"(?:youtube\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?)\/|\S*?[?&]v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})",
      caseSensitive: false,
    );

    final match = exp.firstMatch(url);
    return match?.group(1);
  }

  static Future<void> launchYouTubeVideo(String url) async {
    try {
      // For youtu.be links, convert to full youtube.com URL
      String? videoId = getYouTubeVideoId(url);
      if (videoId == null || videoId.isEmpty) {
        throw 'Invalid YouTube URL';
      }

      final Uri uri = Uri.parse('https://www.youtube.com/watch?v=$videoId');
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw 'Could not launch YouTube video';
      }
    } catch (e) {
      print('Error launching YouTube video: $e');
      rethrow;
    }
  }
}