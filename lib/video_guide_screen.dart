import 'package:flutter/material.dart';


// VIDEO GUIDE SCREEN
import 'package:demo_app/main.dart';

class VideoGuideScreen extends StatelessWidget {
  final String exerciseName;
  final List<String> instructions;
  final ThemeProvider? themeProvider;

  const VideoGuideScreen({
    super.key,
    required this.exerciseName,
    required this.instructions,
    this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = themeProvider;
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
                    exerciseName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: theme?.secondaryColor ?? Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
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
                        ...instructions.map((instruction) => _buildInstruction(instruction, theme)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {},
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
                child: const Text(
                  'Next Exercise',
                  style: TextStyle(
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