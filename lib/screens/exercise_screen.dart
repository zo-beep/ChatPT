import 'package:demo_app/main.dart';
import 'package:demo_app/screens/main_screen.dart';
import 'package:demo_app/screens/video_guide_screen.dart';
import 'package:flutter/material.dart';


// EXERCISE SCREEN (Exercise Plan)
class ExerciseScreen extends StatefulWidget {
  final ThemeProvider themeProvider;
  const ExerciseScreen({super.key, required this.themeProvider});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  List<Map<String, dynamic>> _exercises = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    // Load mock exercises directly
    setState(() {
      _exercises = _getMockExercises();
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> _getMockExercises() {
    return [
      {
        'name': 'Heel Slides',
        'description': 'Gentle knee movement exercise',
        'duration': 5,
        'instructions': [
          '1. Lie on your back, legs straight.',
          '2. Bend one knee, sliding your heel toward your buttocks.',
          '3. Straighten your leg.',
          '4. Slide back to start.',
          '5. Repeat 10-15 times per leg, 2-3 sets daily.',
        ],
        'videoUrl': 'assets/videos/mockvid.mp4',
        'category': 'Lower Body',
        'difficulty': 'Beginner',
      },
      {
        'name': 'Knee Bends',
        'description': 'Seated knee flexion exercise',
        'duration': 5,
        'instructions': [
          '1. Sit on a chair with feet flat on the floor.',
          '2. Slowly bend your knee to lift your foot off the ground.',
          '3. Hold for 3-5 seconds.',
          '4. Lower your foot back down.',
          '5. Repeat 10-15 times per leg, 2-3 sets daily.',
        ],
        'videoUrl': 'assets/videos/mockvid.mp4',
        'category': 'Lower Body',
        'difficulty': 'Beginner',
      },
      {
        'name': 'Straight Leg Raises',
        'description': 'Leg strengthening exercise',
        'duration': 5,
        'instructions': [
          '1. Lie on your back with one leg bent and foot flat.',
          '2. Keep the other leg straight.',
          '3. Lift the straight leg up to the height of the bent knee.',
          '4. Hold for 2-3 seconds.',
          '5. Lower slowly. Repeat 10-15 times per leg, 2-3 sets daily.',
        ],
        'videoUrl': 'assets/videos/mockvid.mp4',
        'category': 'Lower Body',
        'difficulty': 'Beginner',
      },
      {
        'name': 'Ankle pumps & Circles',
        'description': 'Ankle mobility exercise',
        'duration': 5,
        'instructions': [
          '1. Sit or lie down comfortably.',
          '2. Point your toes away from you, then pull them toward you.',
          '3. Rotate your ankle in circles, clockwise then counterclockwise.',
          '4. Do 10 pumps and 10 circles in each direction.',
          '5. Repeat 2-3 times daily for each ankle.',
        ],
        'videoUrl': 'assets/videos/mockvid.mp4',
        'category': 'Lower Body',
        'difficulty': 'Beginner',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.themeProvider.backgroundColor,
      appBar: AppBar(
        backgroundColor: widget.themeProvider.cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: widget.themeProvider.primaryColor),
          onPressed: () {
            Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainScreen(themeProvider: widget.themeProvider,)),
            );
          },
        ),
        title: Text(
          'Back',
          style: TextStyle(color: widget.themeProvider.primaryColor),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: widget.themeProvider.primaryColor,
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: widget.themeProvider.cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Ready for today\'s exercises?',
                            style: TextStyle(
                              fontSize: 16,
                              color: widget.themeProvider.subtextColor,
                            ),
                          ),
                          const SizedBox(height: 8,),
                          Text(
                            'Let\'s work together to reach your recovery goals!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: widget.themeProvider.textColor,
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
                        color: widget.themeProvider.textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._exercises.map((exercise) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildExerciseCard(
                        context,
                        exercise['name'] ?? 'Exercise',
                        'Not yet started',
                        widget.themeProvider.secondaryColor,
                        exercise,
                      ),
                    )),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildExerciseCard(
      BuildContext context, String title, String status, Color bgColor, Map<String, dynamic> exercise) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoGuideScreen(
              exerciseName: title,
              instructions: List<String>.from(exercise['instructions'] ?? _getInstructions(title)),
              themeProvider: widget.themeProvider,
              exerciseData: exercise,
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
                      color: widget.themeProvider.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.themeProvider.subtextColor,
                    ),
                  ),
                  if (exercise['duration'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${exercise['duration']} minutes',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.themeProvider.subtextColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: widget.themeProvider.primaryColor,
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