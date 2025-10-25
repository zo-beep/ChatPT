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
  
  // Expansion states for activity sections
  final Map<String, bool> _expandedSections = {
    'Today': true,
    'This Week': false,
    'Earlier': false,
  };

  // Animation controllers for sections
  final Map<String, AnimationController> _sectionControllers = {};
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Initialize section animation controllers
    for (final section in _expandedSections.keys) {
      _sectionControllers[section] = AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
        value: section == 'Today' ? 1.0 : 0.0, // Today section starts expanded
      );
    }
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    for (final controller in _sectionControllers.values) {
      controller.dispose();
    }
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
    switch (_selectedTimeRange) {
      case 'Daily':
        return _buildDailyChartData(history);
      case 'Weekly':
        return _buildWeeklyChartData(history);
      case 'Monthly':
        return _buildMonthlyChartData(history);
      case 'Yearly':
        return _buildYearlyChartData(history);
      default:
        return _buildWeeklyChartData(history);
    }
  }

  List<Map<String, dynamic>> _buildDailyChartData(List<Map<String, dynamic>> history) {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    // Find the earliest hour with activity today
    int earliestHour = 24;
    int latestHour = -1;
    
    for (var ex in history) {
      final completedAt = ex['completedAt'];
      if (completedAt == null || completedAt is! DateTime) continue;
      
      if (completedAt.isAfter(todayStart) && completedAt.isBefore(todayEnd)) {
        if (completedAt.hour < earliestHour) earliestHour = completedAt.hour;
        if (completedAt.hour > latestHour) latestHour = completedAt.hour;
      }
    }

    // If no activities today, show empty chart
    if (earliestHour == 24) {
      return [];
    }

    // Create chart data ensuring at least 5 slots
    final Map<String, int> hourTotals = {};
    
    // Calculate range to ensure at least 5 slots
    int startHour = earliestHour;
    int endHour = latestHour;
    
    // If we have less than 5 slots, expand the range
    if ((endHour - startHour + 1) < 5) {
      final neededSlots = 5;
      final currentSlots = endHour - startHour + 1;
      final extraSlots = neededSlots - currentSlots;
      
      // Distribute extra slots evenly before and after
      final beforeSlots = extraSlots ~/ 2;
      final afterSlots = extraSlots - beforeSlots;
      
      startHour = (startHour - beforeSlots).clamp(0, 23);
      endHour = (endHour + afterSlots).clamp(0, 23);
    }
    
    // Add padding around the range
    startHour = (startHour - 1).clamp(0, 23);
    endHour = (endHour + 1).clamp(0, 23);
    
    for (int hour = startHour; hour <= endHour; hour++) {
      hourTotals['${hour.toString().padLeft(2, '0')}:00'] = 0;
    }

    // Populate with actual data
    for (var ex in history) {
      final completedAt = ex['completedAt'];
      if (completedAt == null || completedAt is! DateTime) continue;
      
      if (completedAt.isAfter(todayStart) && completedAt.isBefore(todayEnd)) {
        final hourKey = '${completedAt.hour.toString().padLeft(2, '0')}:00';
        hourTotals[hourKey] = (hourTotals[hourKey] ?? 0) + _durationToInt(ex['duration']);
      }
    }

    return hourTotals.entries
        .map((e) => {'label': e.key, 'value': e.value, 'isActive': e.value > 0})
        .toList();
  }

  List<Map<String, dynamic>> _buildWeeklyChartData(List<Map<String, dynamic>> history) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    // Find days with activity
    final Set<int> activeDays = {};
    for (var ex in history) {
      final completedAt = ex['completedAt'];
      if (completedAt == null || completedAt is! DateTime) continue;
      
      if (completedAt.isAfter(weekStart) && completedAt.isBefore(weekEnd)) {
        activeDays.add(completedAt.weekday);
      }
    }

    // If no activities this week, show empty chart
    if (activeDays.isEmpty) {
      return [];
    }

    // Create chart data ensuring at least 5 slots
    final Map<String, int> dayTotals = {};
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    // Find range of active days
    final minDay = activeDays.reduce((a, b) => a < b ? a : b);
    final maxDay = activeDays.reduce((a, b) => a > b ? a : b);
    
    // Calculate range to ensure at least 5 slots
    int startDay = minDay;
    int endDay = maxDay;
    
    // If we have less than 5 slots, expand the range
    if ((endDay - startDay + 1) < 5) {
      final neededSlots = 5;
      final currentSlots = endDay - startDay + 1;
      final extraSlots = neededSlots - currentSlots;
      
      // Distribute extra slots evenly before and after
      final beforeSlots = extraSlots ~/ 2;
      final afterSlots = extraSlots - beforeSlots;
      
      startDay = (startDay - beforeSlots).clamp(1, 7);
      endDay = (endDay + afterSlots).clamp(1, 7);
    }
    
    // Add padding around the range
    startDay = (startDay - 1).clamp(1, 7);
    endDay = (endDay + 1).clamp(1, 7);
    
    for (int day = startDay; day <= endDay; day++) {
      dayTotals[dayNames[day - 1]] = 0;
    }

    // Populate with actual data
    for (var ex in history) {
      final completedAt = ex['completedAt'];
      if (completedAt == null || completedAt is! DateTime) continue;
      
      if (completedAt.isAfter(weekStart) && completedAt.isBefore(weekEnd)) {
        final dayKey = dayNames[completedAt.weekday - 1];
        dayTotals[dayKey] = (dayTotals[dayKey] ?? 0) + _durationToInt(ex['duration']);
      }
    }

    return dayTotals.entries
        .map((e) => {'label': e.key, 'value': e.value, 'isActive': e.value > 0})
        .toList();
  }

  List<Map<String, dynamic>> _buildMonthlyChartData(List<Map<String, dynamic>> history) {
    final now = DateTime.now();
    
    // Find months with activity
    final Set<int> activeMonths = {};
    for (var ex in history) {
      final completedAt = ex['completedAt'];
      if (completedAt == null || completedAt is! DateTime) continue;
      
      // Only include exercises from the last 12 months
      final twelveMonthsAgo = DateTime(now.year, now.month - 11, 1);
      if (completedAt.isAfter(twelveMonthsAgo)) {
        activeMonths.add(completedAt.month);
      }
    }

    // If no activities in last 12 months, show empty chart
    if (activeMonths.isEmpty) {
      return [];
    }

    // Create chart data ensuring at least 5 slots
    final Map<String, int> monthTotals = {};
    
    // Find range of active months
    final minMonth = activeMonths.reduce((a, b) => a < b ? a : b);
    final maxMonth = activeMonths.reduce((a, b) => a > b ? a : b);
    
    // Calculate range to ensure at least 5 slots
    int startMonth = minMonth;
    int endMonth = maxMonth;
    
    // If we have less than 5 slots, expand the range
    if ((endMonth - startMonth + 1) < 5) {
      final neededSlots = 5;
      final currentSlots = endMonth - startMonth + 1;
      final extraSlots = neededSlots - currentSlots;
      
      // Distribute extra slots evenly before and after
      final beforeSlots = extraSlots ~/ 2;
      final afterSlots = extraSlots - beforeSlots;
      
      startMonth = (startMonth - beforeSlots).clamp(1, 12);
      endMonth = (endMonth + afterSlots).clamp(1, 12);
    }
    
    // Add padding around the range
    startMonth = (startMonth - 1).clamp(1, 12);
    endMonth = (endMonth + 1).clamp(1, 12);
    
    for (int month = startMonth; month <= endMonth; month++) {
      monthTotals[_getMonthAbbreviation(month)] = 0;
    }

    // Populate with actual data
    for (var ex in history) {
      final completedAt = ex['completedAt'];
      if (completedAt == null || completedAt is! DateTime) continue;
      
      final twelveMonthsAgo = DateTime(now.year, now.month - 11, 1);
      if (completedAt.isAfter(twelveMonthsAgo)) {
        final monthKey = _getMonthAbbreviation(completedAt.month);
        monthTotals[monthKey] = (monthTotals[monthKey] ?? 0) + _durationToInt(ex['duration']);
      }
    }

    return monthTotals.entries
        .map((e) => {'label': e.key, 'value': e.value, 'isActive': e.value > 0})
        .toList();
  }

  List<Map<String, dynamic>> _buildYearlyChartData(List<Map<String, dynamic>> history) {
    final now = DateTime.now();
    
    // Find years with activity
    final Set<int> activeYears = {};
    for (var ex in history) {
      final completedAt = ex['completedAt'];
      if (completedAt == null || completedAt is! DateTime) continue;
      
      // Only include exercises from the last 5 years
      final fiveYearsAgo = DateTime(now.year - 4, 1, 1);
      if (completedAt.isAfter(fiveYearsAgo)) {
        activeYears.add(completedAt.year);
      }
    }

    // If no activities in last 5 years, show empty chart
    if (activeYears.isEmpty) {
      return [];
    }

    // Create chart data ensuring at least 5 slots
    final Map<String, int> yearTotals = {};
    
    // Find range of active years
    final minYear = activeYears.reduce((a, b) => a < b ? a : b);
    final maxYear = activeYears.reduce((a, b) => a > b ? a : b);
    
    // Calculate range to ensure at least 5 slots
    int startYear = minYear;
    int endYear = maxYear;
    
    // If we have less than 5 slots, expand the range
    if ((endYear - startYear + 1) < 5) {
      final neededSlots = 5;
      final currentSlots = endYear - startYear + 1;
      final extraSlots = neededSlots - currentSlots;
      
      // Distribute extra slots evenly before and after
      final beforeSlots = extraSlots ~/ 2;
      final afterSlots = extraSlots - beforeSlots;
      
      startYear = startYear - beforeSlots;
      endYear = endYear + afterSlots;
    }
    
    // Add padding around the range
    startYear = startYear - 1;
    endYear = endYear + 1;
    
    for (int year = startYear; year <= endYear; year++) {
      yearTotals[year.toString()] = 0;
    }

    // Populate with actual data
    for (var ex in history) {
      final completedAt = ex['completedAt'];
      if (completedAt == null || completedAt is! DateTime) continue;
      
      final fiveYearsAgo = DateTime(now.year - 4, 1, 1);
      if (completedAt.isAfter(fiveYearsAgo)) {
        final yearKey = completedAt.year.toString();
        yearTotals[yearKey] = (yearTotals[yearKey] ?? 0) + _durationToInt(ex['duration']);
      }
    }

    return yearTotals.entries
        .map((e) => {'label': e.key, 'value': e.value, 'isActive': e.value > 0})
        .toList();
  }

  String _getMonthAbbreviation(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Map<String, dynamic> _calculateTimeRangeStats(List<Map<String, dynamic>> history, String timeRange) {
    final now = DateTime.now();
    int daysActive = 0;
    int progressPercentage = 0;

    switch (timeRange) {
      case 'Daily':
        final today = DateTime(now.year, now.month, now.day);
        final todayEnd = today.add(const Duration(days: 1));
        final todayActivities = history.where((h) {
          final completedAt = h['completedAt'] as DateTime?;
          return completedAt != null && completedAt.isAfter(today) && completedAt.isBefore(todayEnd);
        }).toList();
        daysActive = todayActivities.isNotEmpty ? 1 : 0;
        progressPercentage = todayActivities.isNotEmpty ? 100 : 0;
        break;

      case 'Weekly':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 7));
        final weekActivities = history.where((h) {
          final completedAt = h['completedAt'] as DateTime?;
          return completedAt != null && completedAt.isAfter(weekStart) && completedAt.isBefore(weekEnd);
        }).toList();
        final uniqueDays = weekActivities.map((h) => (h['completedAt'] as DateTime).day).toSet();
        daysActive = uniqueDays.length;
        progressPercentage = daysActive > 0 ? ((daysActive / 7) * 100).round() : 0;
        break;

      case 'Monthly':
        final monthStart = DateTime(now.year, now.month, 1);
        final monthEnd = DateTime(now.year, now.month + 1, 1);
        final monthActivities = history.where((h) {
          final completedAt = h['completedAt'] as DateTime?;
          return completedAt != null && completedAt.isAfter(monthStart) && completedAt.isBefore(monthEnd);
        }).toList();
        final uniqueDays = monthActivities.map((h) => (h['completedAt'] as DateTime).day).toSet();
        daysActive = uniqueDays.length;
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        progressPercentage = daysActive > 0 ? ((daysActive / daysInMonth) * 100).round() : 0;
        break;

      case 'Yearly':
        final yearStart = DateTime(now.year, 1, 1);
        final yearEnd = DateTime(now.year + 1, 1, 1);
        final yearActivities = history.where((h) {
          final completedAt = h['completedAt'] as DateTime?;
          return completedAt != null && completedAt.isAfter(yearStart) && completedAt.isBefore(yearEnd);
        }).toList();
        final uniqueDays = yearActivities.map((h) => (h['completedAt'] as DateTime).day).toSet();
        daysActive = uniqueDays.length;
        final daysInYear = DateTime(now.year, 12, 31).difference(DateTime(now.year, 1, 1)).inDays + 1;
        progressPercentage = daysActive > 0 ? ((daysActive / daysInYear) * 100).round() : 0;
        break;
    }

    return {
      'daysActive': daysActive,
      'progressPercentage': progressPercentage.clamp(0, 100),
    };
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
              final timeRangeStats = _calculateTimeRangeStats(historyList, _selectedTimeRange);
              final daysActive = timeRangeStats['daysActive'] as int;
              final safeProgress = timeRangeStats['progressPercentage'] as int;

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

    // Check if chart is empty
    final hasData = chartData.any((item) => item['value'] > 0);

    if (!hasData) {
      return _buildEmptyChart();
    }

    final maxValue = chartData.fold<int>(
        0, (max, item) => item['value'] > max ? item['value'] as int : max);

    // Calculate dimensions for 5 visible slots
    final visibleSlots = 5;
    final slotWidth = (availableWidth - 40) / visibleSlots; // 40px for padding

    return SizedBox(
      height: chartHeight + 60,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: chartData.length * slotWidth,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: chartData.map((item) {
              final heightPercent = maxValue > 0
                  ? (item['value'] as int) / maxValue * chartHeight
                  : 0.0;
              return SizedBox(
                width: slotWidth,
                child: _buildBar(
                    item['label'], heightPercent, item['isActive'] ?? false, item['value']),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyChart() {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        color: widget.themeProvider.backgroundColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.themeProvider.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_outlined,
              size: 48,
              color: widget.themeProvider.subtextColor.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No data available for ${_selectedTimeRange.toLowerCase()} view',
              style: TextStyle(
                fontSize: 14,
                color: widget.themeProvider.subtextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Complete some exercises to see your progress',
              style: TextStyle(
                fontSize: 12,
                color: widget.themeProvider.subtextColor.withOpacity(0.7),
              ),
            ),
          ],
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
    if (userProgress.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            child: Center(
              child: Text(
                'No completed exercises yet.',
                style: TextStyle(
                  color: widget.themeProvider.subtextColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ],
      );
    }

    final groupedActivities = _groupActivitiesBySection(userProgress);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          decoration: BoxDecoration(
            color: widget.themeProvider.cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: groupedActivities.entries.map((entry) {
              final section = entry.key;
              final activities = entry.value;
              
              if (activities.isEmpty) return const SizedBox.shrink();

              return Column(
                children: [
                  // Section Header with Dropdown
                  InkWell(
                    onTap: () => _toggleSection(section),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Text(
                            section,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: widget.themeProvider.textColor,
                            ),
                          ),
                          const Spacer(),
                          AnimatedBuilder(
                            animation: _sectionControllers[section]!,
                            builder: (context, child) => Transform.rotate(
                              angle: _sectionControllers[section]!.value * 3.14159,
                              child: Icon(
                                Icons.keyboard_arrow_down,
                                color: widget.themeProvider.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Animated List Container
                  SizeTransition(
                    sizeFactor: _sectionControllers[section]!,
                    child: Column(
                      children: activities.map((activity) => Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
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
                      )).toList(),
                    ),
                  ),
                  if (section != 'Earlier') const Divider(height: 1),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBar(String label, double heightPercent, bool isActive, int value) {
    final fontSize = _selectedTimeRange == 'Daily' ? 10.0 : 12.0;
    final labelFontSize = _selectedTimeRange == 'Daily' ? 10.0 : 12.0;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (value > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 4, 
                vertical: 2
              ),
              decoration: BoxDecoration(
                  color: widget.themeProvider.primaryColor,
                  borderRadius: BorderRadius.circular(4)),
              child: Text('$value',
                  style: TextStyle(
                      fontSize: fontSize,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
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
                fontSize: labelFontSize,
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

  Map<String, List<Map<String, dynamic>>> _groupActivitiesBySection(List<Map<String, dynamic>> activities) {
    final now = DateTime.now();
    final Map<String, List<Map<String, dynamic>>> sections = {
      'Today': [],
      'This Week': [],
      'Earlier': [],
    };

    for (final activity in activities) {
      final completedAt = activity['completedAt'] as DateTime?;
      if (completedAt == null) continue;

      final difference = now.difference(completedAt);
      
      if (difference.inDays == 0) {
        sections['Today']!.add(activity);
      } else if (difference.inDays < 7) {
        sections['This Week']!.add(activity);
      } else {
        sections['Earlier']!.add(activity);
      }
    }

    return sections;
  }

  void _toggleSection(String section) {
    setState(() {
      _expandedSections[section] = !(_expandedSections[section] ?? false);
    });
    
    if (_expandedSections[section] ?? false) {
      _sectionControllers[section]?.forward();
    } else {
      _sectionControllers[section]?.reverse();
    }
  }
}
