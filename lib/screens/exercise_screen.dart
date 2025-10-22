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
  final Map<String, bool> _expandedCategories = {};

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
                        const SizedBox(height: 12),
                        ..._buildCategorizedExerciseList(_todayExercises, true),
                      ],
                      if (_upcomingExercises.isNotEmpty) ...[
                        const SizedBox(height: 20),
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
                        const SizedBox(height: 12),
                        ..._buildCategorizedExerciseList(_upcomingExercises, false),
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

  String _getExerciseCategory(Map<String, dynamic> exercise) {
    // Try to get category from exercise data, fallback to intelligent categorization
    String? category = exercise['category']?.toString().toLowerCase();
    if (category != null && category.isNotEmpty) {
      return category;
    }
    
    // Intelligent categorization based on exercise name
    String name = (exercise['exerciseName'] ?? exercise['name'] ?? exercise['title'] ?? '').toString().toLowerCase();
    
    if (name.contains('core') || name.contains('ab') || name.contains('plank') || name.contains('crunch')) {
      return 'core';
    } else if (name.contains('leg') || name.contains('squat') || name.contains('calf') || name.contains('thigh')) {
      return 'lower body';
    } else if (name.contains('arm') || name.contains('bicep') || name.contains('tricep') || name.contains('shoulder') || name.contains('chest')) {
      return 'upper body';
    } else if (name.contains('cardio') || name.contains('walk') || name.contains('run') || name.contains('bike')) {
      return 'cardio';
    } else if (name.contains('stretch') || name.contains('flexibility') || name.contains('yoga')) {
      return 'flexibility';
    } else {
      return 'general';
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupExercisesByCategory(List<Map<String, dynamic>> exercises) {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    
    for (var exercise in exercises) {
      String category = _getExerciseCategory(exercise);
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
        // Initialize category as expanded by default
        _expandedCategories[category] ??= true;
      }
      grouped[category]!.add(exercise);
    }
    
    return grouped;
  }

  String _capitalizeCategory(String category) {
    return category.split(' ').map((word) => 
      word.isEmpty ? word : word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  List<Widget> _buildCategorizedExerciseList(List<Map<String, dynamic>> exercises, bool isToday) {
    final groupedExercises = _groupExercisesByCategory(exercises);
    List<Widget> widgets = [];
    
    // Sort categories for consistent display
    final sortedCategories = groupedExercises.keys.toList()..sort();
    
    for (String category in sortedCategories) {
      final categoryExercises = groupedExercises[category]!;
      final isExpanded = _expandedCategories[category] ?? true;
      
      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.themeProvider.subtextColor.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Category header
              InkWell(
                onTap: () {
                  setState(() {
                    _expandedCategories[category] = !isExpanded;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: widget.themeProvider.primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getCategoryIcon(category),
                        color: widget.themeProvider.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _capitalizeCategory(category),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: widget.themeProvider.textColor,
                          ),
                        ),
                      ),
                      Text(
                        '${categoryExercises.length}',
                        style: TextStyle(
                          fontSize: 14,
                          color: widget.themeProvider.subtextColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: widget.themeProvider.subtextColor,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Exercise list
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: isExpanded ? null : 0,
                child: isExpanded
                    ? Column(
                        children: categoryExercises.map((exercise) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: _buildCompactExerciseCard(
                              context,
                              exercise['exerciseName'] ?? exercise['name'] ?? exercise['title'] ?? 'Exercise',
                              exercise['completed'] == true 
                                  ? 'Completed' 
                                  : (isToday ? 'Not yet started' : (exercise['date'] as Timestamp?)?.toDate().toString().split(' ')[0] ?? 'Scheduled'),
                              isToday ? widget.themeProvider.secondaryColor : widget.themeProvider.secondaryColor.withOpacity(0.8),
                              exercise,
                            ),
                          );
                        }).toList(),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    
    return widgets;
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'core':
        return Icons.fitness_center;
      case 'lower body':
        return Icons.directions_walk;
      case 'upper body':
        return Icons.accessibility_new;
      case 'cardio':
        return Icons.favorite;
      case 'flexibility':
        return Icons.self_improvement;
      default:
        return Icons.sports_gymnastics;
    }
  }

  Widget _buildCompactExerciseCard(
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
              instructions: List<String>.from(exercise['instructions'] ?? []),
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
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isToday ? bgColor : bgColor.withOpacity(0.6),
          borderRadius: BorderRadius.circular(8),
          border: isToday ? null : Border.all(
            color: widget.themeProvider.subtextColor.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Exercise info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: widget.themeProvider.textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Compact status indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isCompleted 
                              ? Colors.green.withOpacity(0.1)
                              : widget.themeProvider.subtextColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isCompleted ? 'Done' : 'Pending',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isCompleted ? Colors.green : widget.themeProvider.subtextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Exercise details row
                  Row(
                    children: [
                      if (exercise['date'] != null) ...[
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: widget.themeProvider.subtextColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          (exercise['date'] as Timestamp).toDate().toString().split(' ')[0],
                          style: TextStyle(
                            fontSize: 11,
                            color: widget.themeProvider.subtextColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (exercise.containsKey('sets') || exercise.containsKey('repetitions') || exercise.containsKey('duration')) ...[
                        Icon(
                          Icons.timer,
                          size: 12,
                          color: widget.themeProvider.subtextColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${exercise['sets'] ?? ''}x${exercise['repetitions'] ?? ''} ${exercise['duration'] != null ? '${exercise['duration']}min' : ''}',
                          style: TextStyle(
                            fontSize: 11,
                            color: widget.themeProvider.subtextColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Action button
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isToday 
                    ? widget.themeProvider.primaryColor.withOpacity(0.1)
                    : widget.themeProvider.subtextColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                isToday
                    ? Icons.play_arrow
                    : Icons.lock_clock,
                color: isToday
                    ? widget.themeProvider.primaryColor
                    : widget.themeProvider.subtextColor.withOpacity(0.5),
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
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
              instructions: List<String>.from(exercise['instructions'] ?? []),
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