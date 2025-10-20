import 'package:demo_app/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    setState(() {
      _isLoading = true;
    });

    // Try to load assigned exercises for logged-in user
    try {
      final user = FirebaseAuth.instance.currentUser;
      _userId = user?.uid;
      if (user != null) {
        final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('assignedExercises').orderBy('date').get();
        if (snap.docs.isNotEmpty) {
          _exercises = snap.docs.map((d) {
            return {'id': d.id, ...d.data()};
          }).toList();
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      print('Failed to load assigned exercises: $e');
    }

    // Fallback to mock exercises
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
                        exercise['exerciseName'] ?? exercise['name'] ?? exercise['title'] ?? 'Exercise',
                        exercise['completed'] == true ? 'Completed' : 'Not yet started',
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
      onTap: () async {
        final result = await Navigator.push(
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
        if (result == true) {
          setState(() {
            exercise['completed'] = true;
          });
        }
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 14,
                            color: widget.themeProvider.subtextColor,
                          ),
                        ),
                      ),
                      if (exercise.containsKey('sets') || exercise.containsKey('repetitions') || exercise.containsKey('duration'))
                        Text(
                          '${exercise['sets'] ?? ''}x${exercise['repetitions'] ?? ''} ${exercise['duration'] != null ? '${exercise['duration']}min' : ''}',
                          style: TextStyle(fontSize: 12, color: widget.themeProvider.subtextColor),
                        ),
                    ],
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
            Column(
              children: [
                if (exercise.containsKey('completed') && exercise['completed'] != true)
                  Checkbox(
                    value: exercise['completed'] == true,
                    onChanged: (val) async {
                      // Toggle completion in Firestore if this is an assigned exercise
                      if (_userId != null && exercise.containsKey('id')) {
                        final docRef = FirebaseFirestore.instance.collection('users').doc(_userId).collection('assignedExercises').doc(exercise['id']);
                        if (val == true) {
                          await FirebaseFirestore.instance.runTransaction((tx) async {
                            final snap = await tx.get(docRef);
                            if (!snap.exists) return;
                            final data = snap.data() ?? {};
                            if ((data['completed'] == true) || (data['completedAt'] != null)) return;
                            tx.update(docRef, {'completed': true, 'completedAt': FieldValue.serverTimestamp()});
                            final histRef = FirebaseFirestore.instance.collection('users').doc(_userId).collection('exerciseHistory').doc();
                            tx.set(histRef, {
                              'assignmentId': exercise['id'],
                              'exerciseId': data['exerciseId'] ?? null,
                              'exerciseName': data['exerciseName'] ?? exercise['name'] ?? exercise['title'] ?? '',
                              'sets': data['sets'] ?? exercise['sets'] ?? 0,
                              'repetitions': data['repetitions'] ?? exercise['repetitions'] ?? 0,
                              'duration': data['duration'] ?? exercise['duration'] ?? 0,
                              'assignedBy': data['assignedBy'] ?? null,
                              'assignedAt': data['assignedAt'] ?? null,
                              'completedAt': FieldValue.serverTimestamp(),
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                          });
                          setState(() {
                            exercise['completed'] = true;
                          });
                        } else {
                          await docRef.update({'completed': false, 'completedAt': FieldValue.delete()});
                          setState(() {
                            exercise['completed'] = false;
                          });
                        }
                      } else {
                        setState(() {
                          exercise['completed'] = val == true;
                        });
                      }
                    },
                  ),
                if (exercise.containsKey('completed') && exercise['completed'] == true)
                  Column(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(height: 4),
                      if (exercise['completedAt'] is Timestamp)
                        Text((exercise['completedAt'] as Timestamp).toDate().toLocal().toString().split(' ')[0], style: TextStyle(color: widget.themeProvider.subtextColor, fontSize: 12)),
                    ],
                  ),
                const SizedBox(height: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  color: widget.themeProvider.primaryColor,
                  size: 20,
                ),
                const SizedBox(height: 8),
                if (!(exercise.containsKey('completed') && exercise['completed'] == true))
                  ElevatedButton(
                    onPressed: () async {
                      if (_userId != null && exercise.containsKey('id')) {
                        final docRef = FirebaseFirestore.instance.collection('users').doc(_userId).collection('assignedExercises').doc(exercise['id']);
                        await FirebaseFirestore.instance.runTransaction((tx) async {
                          final snap = await tx.get(docRef);
                          if (!snap.exists) return;
                          final data = snap.data() ?? {};
                          if ((data['completed'] == true) || (data['completedAt'] != null)) return;
                          tx.update(docRef, {'completed': true, 'completedAt': FieldValue.serverTimestamp()});
                          final histRef = FirebaseFirestore.instance.collection('users').doc(_userId).collection('exerciseHistory').doc();
                          tx.set(histRef, {
                            'assignmentId': exercise['id'],
                            'exerciseId': data['exerciseId'] ?? null,
                            'exerciseName': data['exerciseName'] ?? exercise['name'] ?? exercise['title'] ?? '',
                            'sets': data['sets'] ?? exercise['sets'] ?? 0,
                            'repetitions': data['repetitions'] ?? exercise['repetitions'] ?? 0,
                            'duration': data['duration'] ?? exercise['duration'] ?? 0,
                            'assignedBy': data['assignedBy'] ?? null,
                            'assignedAt': data['assignedAt'] ?? null,
                            'completedAt': FieldValue.serverTimestamp(),
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                        });
                        setState(() {
                          exercise['completed'] = true;
                        });
                      }
                      showDialog(
                        context: context,
                        builder: (c) => AlertDialog(
                          content: const Text('Exercise marked as complete!'),
                          actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
                        ),
                      );
                    },
                    child: const Text('Complete'),
                  ),
              ],
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