import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo_app/main.dart';
import 'package:demo_app/screens/main_screen.dart';
import 'package:flutter/material.dart';

class ProgressScreen extends StatefulWidget {
  final ThemeProvider themeProvider;
  final String patientId;

  const ProgressScreen({
    super.key,
    required this.themeProvider,
    required this.patientId,
  });

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with TickerProviderStateMixin {
  String _selectedTimeRange = 'Weekly';
  final List<String> _timeRanges = ['Daily', 'Weekly', 'Monthly', 'Yearly'];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
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

  List<Map<String, dynamic>> _buildChartDataFromHistory(
      List<Map<String, dynamic>> history) {
    final Map<String, int> dayTotals = {
      'M': 0,
      'T': 0,
      'W': 0,
      'Th': 0,
      'F': 0,
      'S': 0,
      'Su': 0
    };

    for (var ex in history) {
      final completedAt = ex['completedAt'];
      if (completedAt == null || completedAt is! DateTime) continue;
      final day = completedAt.weekday;
      final dayKey = ['M', 'T', 'W', 'Th', 'F', 'S', 'Su'][day - 1];
      dayTotals[dayKey] =
          (dayTotals[dayKey] ?? 0) + _durationToInt(ex['duration']);
    }

    return dayTotals.entries
        .map((e) => {'label': e.key, 'value': e.value, 'isActive': e.value > 0})
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final assignedStream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.patientId)
        .collection('assignedExercises')
        .snapshots();

    final historyStream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.patientId)
        .collection('exerciseHistory')
        .orderBy('completedAt', descending: true)
        .snapshots();

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
              MaterialPageRoute(
                builder: (context) =>
                    MainScreen(themeProvider: widget.themeProvider),
              ),
            );
          },
        ),
        title:
            Text('Back', style: TextStyle(color: widget.themeProvider.primaryColor)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: assignedStream,
        builder: (context, assignedSnapshot) {
          if (assignedSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (assignedSnapshot.hasError) {
            return Center(child: Text('Error: ${assignedSnapshot.error}'));
          }

          final allAssigned = assignedSnapshot.data?.docs
                  .map((d) => d.data() as Map<String, dynamic>)
                  .toList() ??
              [];

          final int totalExercises = allAssigned.length;
          final int completedAssignedCount =
              allAssigned.where((a) => a['completed'] == true).length;
          final int progressPercentage = totalExercises > 0
              ? ((completedAssignedCount / totalExercises) * 100).round()
              : 0;

          final int totalMinutesFromAssigned = allAssigned.fold<int>(
              0, (sum, a) => sum + _durationToInt(a['duration']));

          _fadeController.forward();

          return StreamBuilder<QuerySnapshot>(
            stream: historyStream,
            builder: (context, historySnapshot) {
              if (historySnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (historySnapshot.hasError) {
                return Center(child: Text('Error: ${historySnapshot.error}'));
              }

              final historyDocs = historySnapshot.data?.docs ?? [];
              final List<Map<String, dynamic>> historyList = historyDocs.map((d) {
                final data = d.data() as Map<String, dynamic>;
                final ca = data['completedAt'];
                final completedAt =
                    (ca is Timestamp) ? ca.toDate() : (ca is DateTime ? ca : null);
                return {
                  ...data,
                  'completedAt': completedAt,
                  'duration': _durationToInt(data['duration']),
                };
              }).toList();

              final int totalMinutesFromHistory = historyList.fold<int>(
                  0, (sum, h) => sum + _durationToInt(h['duration']));

              final int displayedTotalMinutes =
                  totalMinutesFromHistory > 0 ? totalMinutesFromHistory : totalMinutesFromAssigned;

              final chartData = _buildChartDataFromHistory(historyList);
              final daysActive = historyList.isNotEmpty ? 1 : 0;
              final safeProgress = progressPercentage.clamp(0, 100);

              return LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTimeRangeTabs(),
                          const SizedBox(height: 20),
                          _buildProgressCard(
                            daysActive: daysActive,
                            progressPercentage: safeProgress,
                            totalMinutes: displayedTotalMinutes,
                            chartData: chartData,
                            availableWidth: constraints.maxWidth,
                          ),
                          const SizedBox(height: 24),
                          _buildRecentActivity(historyList),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTimeRangeTabs() {
    return Container(
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
              onTap: () {
                setState(() => _selectedTimeRange = range);
                _fadeController.reset();
                _fadeController.forward();
              },
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
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
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
    );
  }

  Widget _buildProgressCard({
    required int daysActive,
    required int progressPercentage,
    required int totalMinutes,
    required List<Map<String, dynamic>> chartData,
    required double availableWidth,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.themeProvider.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Way to go! Check your progress here.',
              style: TextStyle(
                  fontSize: 15, color: widget.themeProvider.subtextColor)),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildStatBox('$daysActive', 'days active'),
              const SizedBox(width: 16),
              _buildStatBox('$progressPercentage%', 'Completion rate'),
            ],
          ),
          const SizedBox(height: 20),
          _buildProgressBar(progressPercentage),
          const SizedBox(height: 20),
          Row(
            children: [
              Text('$totalMinutes',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.themeProvider.textColor)),
              const SizedBox(width: 4),
              Text('minutes total',
                  style: TextStyle(
                      fontSize: 14,
                      color: widget.themeProvider.subtextColor)),
            ],
          ),
          const SizedBox(height: 16),
          _buildChart(chartData, availableWidth),
        ],
      ),
    );
  }

  Widget _buildChart(List<Map<String, dynamic>> chartData, double availableWidth) {
    const chartHeight = 200.0;
    final barWidth = 32.0;
    final spacing = 18.0;

    final totalWidth = (chartData.length * (barWidth + spacing)) + 50;
    final chartWidth = totalWidth < availableWidth ? availableWidth : totalWidth;

    final maxValue = chartData.fold<int>(
        0, (max, item) => item['value'] > max ? item['value'] as int : max);

    return SizedBox(
      height: chartHeight + 60, // extra padding to prevent vertical overflow
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: chartWidth,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: chartData.map((item) {
              final heightPercent = maxValue > 0
                  ? (item['value'] as int) / maxValue * chartHeight
                  : 0.0;
              return _buildBar(
                  item['label'], heightPercent, item['isActive'] ?? false, item['value']);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: widget.themeProvider.primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: Colors.white.withOpacity(0.9))),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(int progressPercentage) {
    final safeProgress = progressPercentage.clamp(0, 100);
    return Container(
      height: 8,
      decoration: BoxDecoration(
          color: widget.themeProvider.backgroundColor,
          borderRadius: BorderRadius.circular(4)),
      child: Row(
        children: [
          Expanded(
            flex: safeProgress,
            child: Container(
              decoration: BoxDecoration(
                color: widget.themeProvider.primaryColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Expanded(flex: 100 - safeProgress, child: const SizedBox()),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(List<Map<String, dynamic>> userProgress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Activity',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: widget.themeProvider.textColor)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: widget.themeProvider.cardColor,
              borderRadius: BorderRadius.circular(12)),
          child: userProgress.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text('No completed exercises yet.',
                        style: TextStyle(
                            color: widget.themeProvider.subtextColor,
                            fontStyle: FontStyle.italic)),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: userProgress.length,
                  itemBuilder: (context, index) {
                    final activity = userProgress[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                      color: widget.themeProvider.backgroundColor,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: widget.themeProvider.primaryColor,
                          child: const Icon(Icons.fitness_center,
                              color: Colors.white, size: 20),
                        ),
                        title: Text(
                          activity['exerciseName'] ?? 'Unknown Exercise',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: widget.themeProvider.textColor),
                        ),
                        subtitle: Text(
                          '${activity['duration']} minutes • ${_formatTimestamp(activity['completedAt'])}',
                          style:
                              TextStyle(color: widget.themeProvider.subtextColor),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildBar(String label, double heightPercent, bool isActive, int value) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (value > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: widget.themeProvider.primaryColor,
                  borderRadius: BorderRadius.circular(4)),
              child: Text('$value',
                  style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 24,
          height: heightPercent,
          decoration: BoxDecoration(
            color: isActive
                ? widget.themeProvider.primaryColor
                : widget.themeProvider.primaryColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: widget.themeProvider.subtextColor,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return 'Unknown time';
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inHours < 1) return '${difference.inMinutes} min ago';
    if (difference.inDays < 1) return '${difference.inHours} hr ago';
    return '${difference.inDays} days ago';
  }
}
