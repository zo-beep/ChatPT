import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:demo_app/main.dart';
import 'package:demo_app/screens/doctor_dashboard_screen.dart';
import 'package:demo_app/screens/doctor_patient_progress_screen.dart';
import 'package:demo_app/screens/doctor_appointments_screen.dart';
import 'package:demo_app/screens/doctor_session_notes_screen.dart';
import 'package:demo_app/screens/doctor_exercise_plans_screen.dart';
import 'package:demo_app/services/user_service.dart';

// DOCTOR MAIN SCREEN WITH BOTTOM NAVIGATION
class DoctorMainScreen extends StatefulWidget {
  final ThemeProvider themeProvider;

  const DoctorMainScreen({super.key, required this.themeProvider});

  @override
  State<DoctorMainScreen> createState() => _DoctorMainScreenState();
}

class _DoctorMainScreenState extends State<DoctorMainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.themeProvider,
      builder: (context, child) {
        final List<Widget> screens = [
          DoctorHomeScreen(themeProvider: widget.themeProvider),
          DoctorPatientProgressScreen(themeProvider: widget.themeProvider),
          DoctorAppointmentsScreen(themeProvider: widget.themeProvider),
          DoctorSessionNotesScreen(themeProvider: widget.themeProvider),
          DoctorExercisePlansScreen(themeProvider: widget.themeProvider),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(Icons.home_outlined, 'Home', 0),
                    _buildNavItem(Icons.people_outline, 'Patients', 1),
                    _buildNavItem(Icons.calendar_today, 'Schedule', 2),
                    _buildNavItem(Icons.note_outlined, 'Notes', 3),
                    _buildNavItem(Icons.fitness_center, 'Plans', 4),
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
                    color: widget.themeProvider.primaryColor.withOpacity(0.5),
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
              color: isSelected ? widget.themeProvider.primaryColor : widget.themeProvider.subtextColor,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? widget.themeProvider.primaryColor : widget.themeProvider.subtextColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// DOCTOR HOME SCREEN
class DoctorHomeScreen extends StatefulWidget {
  final ThemeProvider themeProvider;

  const DoctorHomeScreen({super.key, required this.themeProvider});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  Map<String, dynamic> _dashboardData = {};
  List<Map<String, dynamic>> _recentActivities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    // Load mock dashboard data for doctor
    setState(() {
      _dashboardData = {
        'totalPatients': 15,
        'todayAppointments': 4,
        'pendingNotes': 3,
        'activePlans': 12,
      };
      _recentActivities = [
        {
          'patientName': 'John Smith',
          'activity': 'Completed knee exercises',
          'time': DateTime.now().subtract(const Duration(hours: 1)),
          'type': 'progress',
        },
        {
          'patientName': 'Sarah Johnson',
          'activity': 'Appointment scheduled',
          'time': DateTime.now().subtract(const Duration(hours: 2)),
          'type': 'appointment',
        },
        {
          'patientName': 'Mike Wilson',
          'activity': 'Exercise plan updated',
          'time': DateTime.now().subtract(const Duration(hours: 3)),
          'type': 'plan',
        },
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.themeProvider,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: widget.themeProvider.backgroundColor,
          appBar: AppBar(
            backgroundColor: widget.themeProvider.primaryColor,
            elevation: 0,
            title: const Text(
              'Doctor Dashboard',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  if (value == 'logout') {
                    _handleLogout(context);
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Logout', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
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
                          // Welcome Message
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: widget.themeProvider.cardColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back, Dr. ${UserService.getCurrentUserName()}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: widget.themeProvider.textColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Here\'s your practice overview',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: widget.themeProvider.subtextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Quick Stats
                          Text(
                            'Practice Overview',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: widget.themeProvider.textColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: 1.5,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            children: [
                              _buildStatCard(
                                'Total Patients',
                                '${_dashboardData['totalPatients']}',
                                Icons.people,
                                widget.themeProvider.primaryColor,
                              ),
                              _buildStatCard(
                                'Today\'s Appointments',
                                '${_dashboardData['todayAppointments']}',
                                Icons.calendar_today,
                                Colors.orange,
                              ),
                              _buildStatCard(
                                'Pending Notes',
                                '${_dashboardData['pendingNotes']}',
                                Icons.note_add,
                                Colors.red,
                              ),
                              _buildStatCard(
                                'Active Plans',
                                '${_dashboardData['activePlans']}',
                                Icons.fitness_center,
                                Colors.green,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Recent Activity
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Recent Activity',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: widget.themeProvider.textColor,
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
                                      Text(
                                        'No recent activity',
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: widget.themeProvider.subtextColor,
                                        ),
                                      ),
                                    ]
                                  : _recentActivities.map((activity) => Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${activity['patientName']} - ${activity['activity']}',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: widget.themeProvider.textColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatTimestamp(activity['time']),
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: widget.themeProvider.subtextColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )).toList(),
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.themeProvider.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 32,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: widget.themeProvider.subtextColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/',
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
