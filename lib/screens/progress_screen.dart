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

class _ProgressScreenState extends State<ProgressScreen> with TickerProviderStateMixin {
  Map<String, dynamic> _dashboardData = {};
  List<Map<String, dynamic>> _userProgress = [];
  bool _isLoading = true;
  
  // Time range selection
  String _selectedTimeRange = 'Weekly';
  final List<String> _timeRanges = ['Daily', 'Weekly', 'Monthly', 'Yearly'];
  
  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  // Dynamic data for different time periods
  Map<String, Map<String, dynamic>> _timeRangeData = {};

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadProgressData();
  }
  
  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadProgressData() async {
    // Load mock progress data for different time ranges
    setState(() {
      _timeRangeData = {
        'Daily': {
          'daysActive': 1,
          'progressPercentage': 100,
          'totalMinutes': 45,
          'chartData': [
            {'label': '6AM', 'value': 15, 'isActive': true},
            {'label': '9AM', 'value': 20, 'isActive': true},
            {'label': '12PM', 'value': 10, 'isActive': false},
            {'label': '3PM', 'value': 0, 'isActive': false},
            {'label': '6PM', 'value': 0, 'isActive': false},
            {'label': '9PM', 'value': 0, 'isActive': false},
          ],
        },
        'Weekly': {
          'daysActive': 5,
          'progressPercentage': 71,
          'totalMinutes': 236,
          'chartData': [
            {'label': 'M', 'value': 40, 'isActive': true},
            {'label': 'T', 'value': 60, 'isActive': true},
            {'label': 'W', 'value': 50, 'isActive': true},
            {'label': 'T', 'value': 80, 'isActive': true},
            {'label': 'F', 'value': 35, 'isActive': true},
            {'label': 'S', 'value': 0, 'isActive': false},
            {'label': 'S', 'value': 0, 'isActive': false},
          ],
        },
        'Monthly': {
          'daysActive': 18,
          'progressPercentage': 58,
          'totalMinutes': 1240,
          'chartData': [
            {'label': 'W1', 'value': 180, 'isActive': true},
            {'label': 'W2', 'value': 220, 'isActive': true},
            {'label': 'W3', 'value': 195, 'isActive': true},
            {'label': 'W4', 'value': 165, 'isActive': true},
            {'label': 'W5', 'value': 0, 'isActive': false},
          ],
        },
        'Yearly': {
          'daysActive': 180,
          'progressPercentage': 49,
          'totalMinutes': 12400,
          'chartData': [
            {'label': 'Jan', 'value': 1200, 'isActive': true},
            {'label': 'Feb', 'value': 1100, 'isActive': true},
            {'label': 'Mar', 'value': 1300, 'isActive': true},
            {'label': 'Apr', 'value': 1000, 'isActive': true},
            {'label': 'May', 'value': 1400, 'isActive': true},
            {'label': 'Jun', 'value': 1250, 'isActive': true},
            {'label': 'Jul', 'value': 1100, 'isActive': true},
            {'label': 'Aug', 'value': 1350, 'isActive': true},
            {'label': 'Sep', 'value': 1200, 'isActive': true},
            {'label': 'Oct', 'value': 1000, 'isActive': true},
            {'label': 'Nov', 'value': 1150, 'isActive': true},
            {'label': 'Dec', 'value': 0, 'isActive': false},
          ],
        },
      };
      
      _dashboardData = _timeRangeData[_selectedTimeRange]!;
      
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
    _fadeController.forward();
  }
  
  void _onTimeRangeChanged(String timeRange) {
    if (timeRange != _selectedTimeRange) {
      setState(() {
        _selectedTimeRange = timeRange;
        _dashboardData = _timeRangeData[timeRange]!;
      });
      _fadeController.reset();
      _fadeController.forward();
    }
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
                    // Time Range Selection Tabs
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: widget.themeProvider.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.themeProvider.primaryColor.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: _timeRanges.map((range) {
                          final isSelected = range == _selectedTimeRange;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => _onTimeRangeChanged(range),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? widget.themeProvider.primaryColor 
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  range,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected 
                                        ? Colors.white 
                                        : widget.themeProvider.textColor,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Progress Card with Animation
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
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
                          // Progress Bar
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: widget.themeProvider.backgroundColor,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: (_dashboardData['progressPercentage'] ?? 25).toInt(),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: widget.themeProvider.primaryColor,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                                 Expanded(
                                   flex: (100 - ((_dashboardData['progressPercentage'] ?? 25).toInt())).toInt(),
                                   child: const SizedBox(),
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
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: widget.themeProvider.textColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'minutes total',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: widget.themeProvider.subtextColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Dynamic Bar Chart
                          SizedBox(
                            height: 140,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: _buildDynamicChart(),
                            ),
                          ),
                        ],
                      ),
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

  List<Widget> _buildDynamicChart() {
    final chartData = _dashboardData['chartData'] as List<Map<String, dynamic>>? ?? [];
    final maxValue = chartData.fold<double>(0, (max, item) => 
        item['value'] > max ? item['value'].toDouble() : max);
    
    return chartData.map((item) {
      final heightPercent = maxValue > 0 ? (item['value'] / maxValue) * 100 : 0.0;
      return _buildBar(
        item['label'], 
        heightPercent, 
        item['isActive'] ?? false,
        item['value'],
      );
    }).toList();
  }

  Widget _buildBar(String label, double heightPercent, bool isActive, int value) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Value tooltip
        if (value > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: widget.themeProvider.primaryColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$value',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        const SizedBox(height: 4),
        // Bar
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: _selectedTimeRange == 'Yearly' ? 20 : 28,
          height: heightPercent,
          decoration: BoxDecoration(
            color: isActive 
                ? widget.themeProvider.primaryColor 
                : widget.themeProvider.primaryColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
            boxShadow: isActive ? [
              BoxShadow(
                color: widget.themeProvider.primaryColor.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: _selectedTimeRange == 'Yearly' ? 10 : 12,
            color: widget.themeProvider.subtextColor,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
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