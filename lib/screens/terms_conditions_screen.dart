import 'package:flutter/material.dart';
import 'package:demo_app/main.dart';

class TermsConditionsScreen extends StatelessWidget {
  final ThemeProvider themeProvider;

  const TermsConditionsScreen({super.key, required this.themeProvider});

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
          'Terms & Conditions',
          style: TextStyle(
            color: theme.primaryColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.description,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Terms & Conditions',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Last updated: October 25, 2025',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.subtextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // App Usage Agreement
              _buildSection(
                theme,
                'App Usage Agreement',
                Icons.check_circle_outline,
                'By using ChatPT, you agree to use this application solely for its intended purpose of physical therapy management. You must provide accurate information during registration and maintain the confidentiality of your account credentials. Any misuse of the application or violation of these terms may result in account termination.',
              ),
              const SizedBox(height: 24),
              
              // Privacy Policy Summary
              _buildSection(
                theme,
                'Privacy Policy Summary',
                Icons.privacy_tip_outlined,
                'We collect and store your personal information, health data, and exercise progress to provide personalized physical therapy services. Your data is encrypted and stored securely. We do not share your personal information with third parties without your explicit consent, except as required by law or to provide essential services.',
              ),
              const SizedBox(height: 24),
              
              // Liability Disclaimer
              _buildSection(
                theme,
                'Liability Disclaimer',
                Icons.warning_outlined,
                'ChatPT is designed to assist with physical therapy management and should not replace professional medical advice. Users are responsible for consulting with qualified healthcare professionals before making any health-related decisions. We are not liable for any injuries, damages, or health complications that may arise from the use of this application.',
              ),
              const SizedBox(height: 24),
              
              // Intellectual Property Notice
              _buildSection(
                theme,
                'Intellectual Property Notice',
                Icons.copyright_outlined,
                'All content, features, and functionality of ChatPT, including but not limited to text, graphics, logos, and software, are owned by ChatPT and are protected by copyright and other intellectual property laws. Users may not reproduce, distribute, or create derivative works without written permission.',
              ),
              const SizedBox(height: 24),
              
              // Contact Information
              _buildSection(
                theme,
                'Contact Information',
                Icons.contact_support_outlined,
                'For questions, concerns, or support regarding these Terms & Conditions or the ChatPT application, please contact us at:\n\nEmail: support@chatpt.com\n\nWe will respond to your inquiries within 2-3 business days.',
              ),
              const SizedBox(height: 32),
              
              // Footer
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'By continuing to use ChatPT, you acknowledge that you have read, understood, and agree to be bound by these Terms & Conditions.',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.subtextColor,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Copyright
              Center(
                child: Text(
                  '© 2025 ChatPT. All rights reserved.',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.subtextColor.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    ThemeProvider theme,
    String title,
    IconData icon,
    String content,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: theme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: theme.subtextColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
