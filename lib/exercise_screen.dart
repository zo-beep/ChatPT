import 'package:demo_app/main.dart';
import 'package:demo_app/main_screen.dart';
import 'package:demo_app/video_guide_screen.dart';
import 'package:flutter/material.dart';


// EXERCISE SCREEN (Exercise Plan)
class ExerciseScreen extends StatelessWidget {
  final ThemeProvider themeProvider;
  const ExerciseScreen({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      appBar: AppBar(
        backgroundColor: themeProvider.cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: themeProvider.primaryColor),
          onPressed: () {
            Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainScreen(themeProvider: themeProvider,)),
            );
          },
        ),
        title: Text(
          'Back',
          style: TextStyle(color: themeProvider.primaryColor),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: themeProvider.cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Ready for today\'s exercises?',
                      style: TextStyle(
                        fontSize: 16,
                        color: themeProvider.subtextColor,
                      ),
                    ),
                    const SizedBox(height: 8,),
                    Text(
                      'Let\'s work together to reach your recovery goals!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: themeProvider.textColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Today\'s Exercise: Lower Body',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.textColor,
                ),
              ),
              const SizedBox(height: 16),
              _buildExerciseCard(
                context,
                'Heel Slides',
                'Not yet started',
                themeProvider.secondaryColor,
              ),
              const SizedBox(height: 12),
              _buildExerciseCard(
                context,
                'Knee Bends',
                'Not yet started',
                themeProvider.secondaryColor,
              ),
              const SizedBox(height: 12),
              _buildExerciseCard(
                context,
                'Straight Leg Raises',
                'Not yet started',
                themeProvider.secondaryColor,
              ),
              const SizedBox(height: 12),
              _buildExerciseCard(
                context,
                'Ankle pumps & Circles',
                'Not yet started',
                themeProvider.secondaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseCard(
      BuildContext context, String title, String status, Color bgColor) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoGuideScreen(
              exerciseName: title,
              instructions: _getInstructions(title),
              themeProvider: themeProvider,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: themeProvider.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 14,
                      color: themeProvider.subtextColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: themeProvider.primaryColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getInstructions(String exerciseName) {
    switch (exerciseName) {
      case 'Heel Slides':
        return [
          '1. Lie on your back, legs straight.',
          '2. Bend one knee, sliding your heel toward your buttocks.',
          '3. Straighten your leg.',
          '4. Slide back to start.',
          '5. Repeat 10-15 times per leg, 2-3 sets daily.',
        ];
      case 'Knee Bends':
        return [
          '1. Sit on a chair with feet flat on the floor.',
          '2. Slowly bend your knee to lift your foot off the ground.',
          '3. Hold for 3-5 seconds.',
          '4. Lower your foot back down.',
          '5. Repeat 10-15 times per leg, 2-3 sets daily.',
        ];
      case 'Straight Leg Raises':
        return [
          '1. Lie on your back with one leg bent and foot flat.',
          '2. Keep the other leg straight.',
          '3. Lift the straight leg up to the height of the bent knee.',
          '4. Hold for 2-3 seconds.',
          '5. Lower slowly. Repeat 10-15 times per leg, 2-3 sets daily.',
        ];
      case 'Ankle pumps & Circles':
        return [
          '1. Sit or lie down comfortably.',
          '2. Point your toes away from you, then pull them toward you.',
          '3. Rotate your ankle in circles, clockwise then counterclockwise.',
          '4. Do 10 pumps and 10 circles in each direction.',
          '5. Repeat 2-3 times daily for each ankle.',
        ];
      default:
        return [
          '1. Follow the exercise instructions carefully.',
          '2. Start slowly and increase intensity gradually.',
          '3. Stop if you feel any pain.',
          '4. Breathe normally throughout the exercise.',
          '5. Repeat as recommended by your physical therapist.',
        ];
    }
  }
}