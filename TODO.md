# TODO: Fix YouTube Video Playback Issue on Mobile

## Steps to Complete
- [x] Update pubspec.yaml to replace youtube_player_flutter with youtube_player_iframe for better cross-platform support
- [x] Run flutter pub get to update dependencies
- [x] Modify lib/screens/video_guide_screen.dart to use YoutubePlayerIFrame and add platform checks/error handling
- [ ] Test video playback on mobile to ensure the debug message is gone and videos play correctly
