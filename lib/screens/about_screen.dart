import 'package:flutter/material.dart';
import 'package:demo_app/main.dart';

class AboutScreen extends StatelessWidget {
  final ThemeProvider themeProvider;

  const AboutScreen({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    final theme = themeProvider;
    
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: theme.primaryColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'About',
          style: TextStyle(
            color: theme.primaryColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                 // App Icon/Logo Placeholder
                 Container(
                   width: 120,
                   height: 120,
                   decoration: BoxDecoration(
                     color: theme.primaryColor,
                     borderRadius: BorderRadius.circular(20),
                   ),
                   child: Icon(
                     Icons.directions_run,
                     size: 60,
                     color: Colors.white,
                   ),
                 ),
                const SizedBox(height: 32),
                
                // App Name
                Text(
                  'ChatPT',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                
                // App Description
                Text(
                  'Mobile App for Physical Therapy',
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.subtextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 48),
                
                // Information Cards
                _buildInfoCard(
                  theme,
                  'App Version',
                  '1.0.0',
                  Icons.info_outline,
                ),
                const SizedBox(height: 16),
                
                _buildInfoCard(
                  theme,
                  'Developer Credits',
                  'ITS120L_BM4-Group10',
                  Icons.code,
                ),
                const SizedBox(height: 16),
                
                _buildInfoCard(
                  theme,
                  'Last Updated',
                  'October 25, 2025',
                  Icons.update,
                ),
                 const SizedBox(height: 48),
                 
                 // Copyright
                Text(
                  '© 2025 ChatPT. All rights reserved.',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.subtextColor.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    ThemeProvider theme,
    String title,
    String content,
    IconData icon,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: theme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.subtextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: theme.textColor,
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
