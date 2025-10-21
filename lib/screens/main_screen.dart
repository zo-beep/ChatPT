import 'package:demo_app/screens/exercise_screen.dart';
import 'package:demo_app/main.dart';
import 'package:demo_app/screens/more_screen.dart';
import 'package:demo_app/screens/progress_screen.dart';
import 'package:demo_app/screens/chatbot_screen.dart';
import 'package:demo_app/screens/patient_dashboard_screen.dart';
import 'package:demo_app/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 

// MAIN SCREEN WITH BOTTOM NAVIGATION
class MainScreen extends StatefulWidget {
  final ThemeProvider themeProvider;

  const MainScreen({super.key, required this.themeProvider});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final String patientId;

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    patientId = currentUser?.uid ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.themeProvider,
      builder: (context, child) {
        final List<Widget> screens = [
          HomeScreen(themeProvider: widget.themeProvider),
          ChatBotScreen(themeProvider: widget.themeProvider),
          ExerciseScreen(themeProvider: widget.themeProvider),
          ProgressScreen(
              themeProvider: widget.themeProvider, patientId: patientId),
          MoreScreen(themeProvider: widget.themeProvider),
        ];

        return Scaffold(
          body: screens[_selectedIndex],
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: widget.themeProvider.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(Icons.home_outlined, 'Home', 0),
                    _buildNavItem(Icons.chat_bubble_outline, 'ChatPT', 1),
                    _buildNavItem(Icons.directions_run, 'Exercise', 2),
                    _buildNavItem(Icons.bar_chart, 'Progress', 3),
                    _buildNavItem(Icons.add_circle_outline, 'More', 4),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: widget.themeProvider.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color:
                        widget.themeProvider.primaryColor.withOpacity(0.5),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.001),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? widget.themeProvider.primaryColor
                  : widget.themeProvider.subtextColor,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected
                    ? widget.themeProvider.primaryColor
                    : widget.themeProvider.subtextColor,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// HOME SCREEN
class HomeScreen extends StatefulWidget {
  final ThemeProvider themeProvider;

  const HomeScreen({super.key, required this.themeProvider});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic> _dashboardData = {};
  List<Map<String, dynamic>> _recentActivities = [];
  bool _isLoading = true;
  late final String patientId; 

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    patientId = currentUser?.uid ?? '';
    _loadDashboardData();
  }

  int _durationToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? 0;
    }
    return 0;
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      // Get assigned exercises
      final assignedSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(patientId)
          .collection('assignedExercises')
          .get();

      final allAssigned = assignedSnap.docs
          .map((d) => d.data())
          .toList();

      final int totalExercises = allAssigned.length;
      final int completedAssignedCount =
          allAssigned.where((a) => a['completed'] == true).length;
      final int progressPercentage = totalExercises > 0
          ? ((completedAssignedCount / totalExercises) * 100).round()
          : 0;

      // Get exercise history
      final historySnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(patientId)
          .collection('exerciseHistory')
          .orderBy('completedAt', descending: true)
          .limit(3) // Only get the 3 most recent activities
          .get();

      final historyList = historySnap.docs.map((d) {
        final data = d.data();
        final ca = data['completedAt'];
        final completedAt =
            (ca is Timestamp) ? ca.toDate() : (ca is DateTime ? ca : null);
        return {
          ...data,
          'completedAt': completedAt,
          'duration': _durationToInt(data['duration']),
        };
      }).toList();

      final totalMinutes = historyList.fold<int>(
          0, (sum, h) => sum + _durationToInt(h['duration']));

      setState(() {
        _dashboardData = {
          'daysActive': historyList.isNotEmpty ? 1 : 0,
          'progressPercentage': progressPercentage,
          'totalMinutes': totalMinutes,
        };
        _recentActivities = historyList;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.themeProvider,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: widget.themeProvider.backgroundColor,
          body: SafeArea(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: widget.themeProvider.primaryColor,
                    ),
                  )
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: widget.themeProvider.primaryColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'ChatPT',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            PatientDashboardScreen(
                                          themeProvider:
                                              widget.themeProvider,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _getUserInitial(),
                                        style: TextStyle(
                                          color:
                                              widget.themeProvider.primaryColor,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Quick Overview
                          Text(
                            'Quick Overview',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: widget.themeProvider.textColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: widget.themeProvider.cardColor,
                                    borderRadius:
                                        BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        '${_dashboardData['daysActive'] ?? 7}',
                                        style: TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                          color: widget
                                              .themeProvider.primaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'days active',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: widget
                                              .themeProvider.subtextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: widget.themeProvider.cardColor,
                                    borderRadius:
                                        BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        '${_dashboardData['progressPercentage'] ?? 25}%',
                                        style: TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                          color: widget
                                              .themeProvider.primaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'progress',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: widget
                                              .themeProvider.subtextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Buttons
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ExerciseScreen(
                                            themeProvider:
                                                widget.themeProvider),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    widget.themeProvider.primaryColor,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                "Start today's session",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // View Plan
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ExerciseScreen(
                                        themeProvider:
                                            widget.themeProvider),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor:
                                    widget.themeProvider.primaryColor,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(
                                  color: widget.themeProvider.primaryColor,
                                  width: 1.5,
                                ),
                              ),
                              child: const Text(
                                'View Exercise Plan',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Recent Activity
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Recent Activity',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      widget.themeProvider.textColor,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProgressScreen(
                                          themeProvider:
                                              widget.themeProvider,
                                          patientId: patientId),
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    Text(
                                      'See progress',
                                      style: TextStyle(
                                        color: widget
                                            .themeProvider.primaryColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward,
                                      size: 16,
                                      color: widget
                                          .themeProvider.primaryColor,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: widget.themeProvider.cardColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _recentActivities.isEmpty
                                  ? [
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Center(
                                          child: Text(
                                            'No completed exercises yet.',
                                            style: TextStyle(
                                              color: widget.themeProvider.subtextColor,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                      )
                                    ]
                                  : _recentActivities.map((activity) {
                                      return Card(
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 6,
                                          horizontal: 4,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        elevation: 2,
                                        color: widget.themeProvider.backgroundColor,
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: widget.themeProvider.primaryColor,
                                            child: const Icon(
                                              Icons.fitness_center,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                          title: Text(
                                            activity['exerciseName'] ?? 'Unknown Exercise',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: widget.themeProvider.textColor,
                                            ),
                                          ),
                                          subtitle: Text(
                                            '${activity['duration']} minutes • ${_formatTimestamp(activity['completedAt'])}',
                                            style: TextStyle(
                                              color: widget.themeProvider.subtextColor,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown time';
    if (timestamp is DateTime) {
      final now = DateTime.now();
      final difference = now.difference(timestamp);
      if (difference.inHours < 1) {
        return '${difference.inMinutes} minutes ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours} hours ago';
      } else {
        return '${difference.inDays} days ago';
      }
    }
    return 'Unknown time';
  }

  String _getUserInitial() {
    return UserService.getUserInitial();
  }
}
