import 'package:demo_app/exercise_screen.dart';
import 'package:demo_app/main.dart';
import 'package:demo_app/more_screen.dart';
import 'package:demo_app/progress_screen.dart';
import 'package:flutter/material.dart';
import 'chatbot_screen.dart';

// MAIN SCREEN WITH BOTTOM NAVIGATION
class MainScreen extends StatefulWidget {
  final ThemeProvider themeProvider;

  const MainScreen({super.key, required this.themeProvider});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.themeProvider,
      builder: (context, child) {
        final List<Widget> screens = [
          HomeScreen(themeProvider: widget.themeProvider),
          ChatBotScreen(themeProvider: widget.themeProvider),
          ExerciseScreen(themeProvider: widget.themeProvider),
          ProgressScreen(themeProvider: widget.themeProvider),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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

// HOME SCREEN
class HomeScreen extends StatelessWidget {
  final ThemeProvider themeProvider;

  const HomeScreen({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeProvider,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: themeProvider.backgroundColor,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: themeProvider.primaryColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'ChatPT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'J',
                                style: TextStyle(
                                  color: themeProvider.primaryColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
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
                        color: themeProvider.textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: themeProvider.cardColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '7',
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: themeProvider.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'days active',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: themeProvider.subtextColor,
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
                              color: themeProvider.cardColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '25%',
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: themeProvider.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'progress',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: themeProvider.subtextColor,
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
                          //Navigator.pushReplacement(
                          //context,
                          //MaterialPageRoute(builder: (context) => ReminderScreen(themeProvider: themeProvider,)),
                          //);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeProvider.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => ExerciseScreen(themeProvider: themeProvider,)),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: themeProvider.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: themeProvider.primaryColor,
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Activity',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: themeProvider.textColor,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => ProgressScreen(themeProvider: themeProvider,)),
                            );
                          },
                          child: Row(
                            children: [
                              Text(
                                'See progress',
                                style: TextStyle(
                                  color: themeProvider.primaryColor,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward,
                                size: 16,
                                color: themeProvider.primaryColor,
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
                        color: themeProvider.cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lateral Pendulum - 5 minutes',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: themeProvider.textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '2 hours ago',
                            style: TextStyle(
                              fontSize: 13,
                              color: themeProvider.subtextColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Basic Hamstring Stretch - 5 minutes',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: themeProvider.textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '2 hours ago',
                            style: TextStyle(
                              fontSize: 13,
                              color: themeProvider.subtextColor,
                            ),
                          ),
                        ],
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
}