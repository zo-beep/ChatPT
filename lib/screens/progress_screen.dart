import 'package:demo_app/main.dart';
import 'package:demo_app/screens/main_screen.dart';
import 'package:flutter/material.dart';

// PROGRESS SCREEN
class ProgressScreen extends StatefulWidget {
  final ThemeProvider themeProvider;
  const ProgressScreen({super.key, required this.themeProvider});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  Map<String, dynamic> _dashboardData = {};
  List<Map<String, dynamic>> _userProgress = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgressData();
  }

  Future<void> _loadProgressData() async {
    // Load mock progress data
    setState(() {
      _dashboardData = {
        'daysActive': 7,
        'progressPercentage': 25,
        'totalMinutes': 236,
      };
      _userProgress = [
        {
          'exerciseName': 'Lateral Pendulum',
          'duration': 5,
          'completedAt': DateTime.now().subtract(const Duration(hours: 2)),
          'status': 'completed',
        },
        {
          'exerciseName': 'Basic Hamstring Stretch',
          'duration': 5,
          'completedAt': DateTime.now().subtract(const Duration(hours: 2)),
          'status': 'completed',
        },
        {
          'exerciseName': 'Straight Leg Raises',
          'duration': 5,
          'completedAt': DateTime.now().subtract(const Duration(hours: 3)),
          'status': 'completed',
        },
      ];
      _isLoading = false;
    });
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Way to go! Check your progress here.',
                            style: TextStyle(
                              fontSize: 15,
                              color: widget.themeProvider.subtextColor,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: widget.themeProvider.primaryColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        '${_dashboardData['daysActive'] ?? 7}',
                                        style: const TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'days active',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: widget.themeProvider.primaryColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        '${_dashboardData['progressPercentage'] ?? 25}%',
                                        style: const TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Completion rate',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '1 Day',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: widget.themeProvider.subtextColor,
                                ),
                              ),
                              Text(
                                '1 Week',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: widget.themeProvider.textColor,
                                ),
                              ),
                              Text(
                                '1 Month',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: widget.themeProvider.subtextColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: widget.themeProvider.backgroundColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: widget.themeProvider.primaryColor,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                                const Expanded(
                                  flex: 7,
                                  child: SizedBox(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Text(
                                '${_dashboardData['totalMinutes'] ?? 236}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: widget.themeProvider.textColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'minutes',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: widget.themeProvider.subtextColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Simple Bar Chart
                          SizedBox(
                            height: 120,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _buildBar('M', 40, false),
                                _buildBar('T', 60, false),
                                _buildBar('W', 50, false),
                                _buildBar('T', 80, true),
                                _buildBar('F', 35, false),
                                _buildBar('S', 70, false),
                                _buildBar('S', 65, false),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: widget.themeProvider.textColor,
                      ),
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
                        children: _userProgress.isEmpty
                            ? [
                                _buildActivityItem('Lateral Pendulum - 5 minutes',
                                    '2 hours ago', widget.themeProvider.secondaryColor),
                                const SizedBox(height: 12),
                                _buildActivityItem('Basic Hamstring Stretch - 5 minutes',
                                    '2 hours ago', widget.themeProvider.secondaryColor),
                                const SizedBox(height: 12),
                                _buildActivityItem(
                                    'Straight Leg Raises - 5 minutes', '3 hours ago', widget.themeProvider.secondaryColor),
                              ]
                            : _userProgress.map((activity) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildActivityItem(
                                  '${activity['exerciseName']} - ${activity['duration']} minutes',
                                  _formatTimestamp(activity['completedAt']),
                                  widget.themeProvider.secondaryColor,
                                ),
                              )).toList(),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildBar(String label, double heightPercent, bool isActive) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 28,
          height: heightPercent,
          decoration: BoxDecoration(
            color: isActive ? widget.themeProvider.primaryColor : widget.themeProvider.primaryColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: widget.themeProvider.subtextColor,
          ),
        ),
      ],
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

  Widget _buildActivityItem(String title, String time, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: widget.themeProvider.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.themeProvider.subtextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}