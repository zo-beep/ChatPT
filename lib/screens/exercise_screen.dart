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

  List<Map<String, dynamic>> _todayExercises = [];
  List<Map<String, dynamic>> _upcomingExercises = [];

  Future<void> _loadExercises() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      _userId = user?.uid;
      if (user != null) {
        // Get today's date at midnight for comparison
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        final snap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('assignedExercises')
            .orderBy('date')
            .get();

        _exercises = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
        
        // Split exercises into today and upcoming
        _todayExercises = _exercises.where((e) {
          final date = (e['date'] as Timestamp?)?.toDate();
          if (date == null) return false;
          return DateTime(date.year, date.month, date.day).isAtSameMomentAs(today);
        }).toList();

        _upcomingExercises = _exercises.where((e) {
          final date = (e['date'] as Timestamp?)?.toDate();
          if (date == null) return false;
          return DateTime(date.year, date.month, date.day).isAfter(today);
        }).toList();
      } else {
        _exercises = [];
        _todayExercises = [];
        _upcomingExercises = [];
      }
    } catch (e) {
      print('Failed to load assigned exercises: $e');
      _exercises = [];
      _todayExercises = [];
      _upcomingExercises = [];
    }

    setState(() {
      _isLoading = false;
    });
  }

  // No helper methods needed - completion logic moved to VideoGuideScreen

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
                    if (_todayExercises.isEmpty && _upcomingExercises.isEmpty) ...[
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 48,
                              color: widget.themeProvider.subtextColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No exercises assigned yet',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: widget.themeProvider.textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Please consult with your doctor to get your personalized exercise plan',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: widget.themeProvider.subtextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      if (_todayExercises.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(Icons.today, color: widget.themeProvider.primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Today\'s Exercises',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: widget.themeProvider.textColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ..._todayExercises.map(
                          (exercise) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildExerciseCard(
                              context,
                              exercise['exerciseName'] ?? exercise['name'] ?? exercise['title'] ?? 'Exercise',
                              exercise['completed'] == true ? 'Completed' : 'Not yet started',
                              widget.themeProvider.secondaryColor,
                              exercise,
                            ),
                          ),
                        ),
                      ],
                      if (_upcomingExercises.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Icon(Icons.event, color: widget.themeProvider.primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Upcoming Exercises',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: widget.themeProvider.textColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ..._upcomingExercises.map(
                          (exercise) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildExerciseCard(
                              context,
                              exercise['exerciseName'] ?? exercise['name'] ?? exercise['title'] ?? 'Exercise',
                              exercise['completed'] == true ? 'Completed' : (exercise['date'] as Timestamp?)?.toDate().toString().split(' ')[0] ?? 'Scheduled',
                              widget.themeProvider.secondaryColor.withOpacity(0.8),
                              exercise,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  bool _isExerciseForToday(Map<String, dynamic> exercise) {
    final date = (exercise['date'] as Timestamp?)?.toDate();
    if (date == null) return false;

    final now = DateTime.now();
    final exerciseDate = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);

    return exerciseDate.isAtSameMomentAs(today);
  }

  Widget _buildExerciseCard(
      BuildContext context, String title, String status, Color bgColor, Map<String, dynamic> exercise) {
    final isToday = _isExerciseForToday(exercise);
    final isCompleted = exercise['completed'] == true;

    return GestureDetector(
      onTap: isToday ? () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoGuideScreen(
              exerciseName: title,
              instructions: List<String>.from(exercise['instructions'] ?? [
                '1. Follow the exercise instructions carefully.',
                '2. Start slowly and increase intensity gradually.',
                '3. Stop if you feel any pain.',
                '4. Breathe normally throughout the exercise.',
                '5. Repeat as recommended by your physical therapist.',
              ]),
              themeProvider: widget.themeProvider,
              exerciseData: exercise,
              canComplete: !isCompleted,
            ),
          ),
        );
        if (result == true && mounted) {
          await _loadExercises(); // Reload to update all lists
        }
      } : null,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isToday ? bgColor : bgColor.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
          border: isToday ? null : Border.all(
            color: widget.themeProvider.subtextColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            if (exercise['date'] != null) ...[
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 14,
                                    color: widget.themeProvider.subtextColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    (exercise['date'] as Timestamp).toDate().toString().split(' ')[0],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: widget.themeProvider.subtextColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                            ],
                            Row(
                              children: [
                                Icon(
                                  exercise['completed'] == true ? Icons.check_circle : Icons.pending,
                                  size: 14,
                                  color: exercise['completed'] == true ? Colors.green : widget.themeProvider.subtextColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: exercise['completed'] == true ? Colors.green : widget.themeProvider.subtextColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (exercise.containsKey('sets') || exercise.containsKey('repetitions') || exercise.containsKey('duration'))
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: widget.themeProvider.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${exercise['sets'] ?? ''}x${exercise['repetitions'] ?? ''} ${exercise['duration'] != null ? '${exercise['duration']}min' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: widget.themeProvider.primaryColor,
                            ),
                          ),
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isCompleted)
                  const Icon(Icons.check_circle, color: Colors.green, size: 24)
                else if (isToday)
                  Icon(
                    Icons.arrow_forward_ios,
                    color: widget.themeProvider.primaryColor,
                    size: 20,
                  )
                else
                  Icon(
                    Icons.lock_clock,
                    color: widget.themeProvider.subtextColor.withOpacity(0.5),
                    size: 24,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }


}