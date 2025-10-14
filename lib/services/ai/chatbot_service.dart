import 'dart:math';

class ChatbotService {
  static final List<String> _greetings = [
    "Hi! Let's make today a step forward in your recovery. How can I support you?",
    "Hello! I'm here to help with your physical therapy journey. What would you like to know?",
    "Welcome! Ready to work on your recovery goals today?",
  ];

  static final List<String> _exerciseResponses = [
    "That's a great exercise! Remember to start slowly and listen to your body.",
    "Excellent choice! Make sure to follow the proper form for best results.",
    "Keep up the good work! Consistency is key to your recovery.",
  ];

  static final List<String> _painResponses = [
    "If you're experiencing pain, please stop the exercise and consult your physical therapist.",
    "Pain is your body's way of saying something isn't right. Take a break and rest.",
    "Remember: some discomfort is normal, but sharp pain is not. Please be careful.",
  ];

  static final List<String> _generalResponses = [
    "Thank you for your message. How else can I assist you?",
    "I'm here to help! Is there anything specific about your therapy you'd like to know?",
    "That's a great question! Let me know if you need more information.",
    "I understand. Is there anything else I can help you with today?",
  ];

  static final Map<String, List<String>> _faqResponses = {
    'pain': [
      "If you experience pain during exercises, stop immediately and rest. Contact your physical therapist if pain persists.",
      "Some muscle soreness is normal, but sharp or severe pain is not. Always listen to your body.",
    ],
    'schedule': [
      "It's recommended to do your exercises daily as prescribed by your physical therapist.",
      "Consistency is more important than intensity. Even 10-15 minutes daily can make a difference.",
    ],
    'progress': [
      "Progress in physical therapy can be gradual. Track your daily activities and celebrate small wins.",
      "Your progress is tracked in the app. Check the Progress tab to see your improvement over time.",
    ],
    'equipment': [
      "Most exercises can be done with minimal equipment. A chair and comfortable space are usually sufficient.",
      "If you need specific equipment, your physical therapist will provide guidance on what to use.",
    ],
  };

  static String generateResponse(String userMessage) {
    final message = userMessage.toLowerCase();
    
    // Handle greetings
    if (message.contains('hello') || message.contains('hi') || message.contains('hey')) {
      return _greetings[Random().nextInt(_greetings.length)];
    }
    
    // Handle pain-related messages
    if (message.contains('pain') || message.contains('hurt') || message.contains('ache')) {
      return _painResponses[Random().nextInt(_painResponses.length)];
    }
    
    // Handle exercise-related messages
    if (message.contains('exercise') || message.contains('workout') || message.contains('stretch')) {
      return _exerciseResponses[Random().nextInt(_exerciseResponses.length)];
    }
    
    // Handle FAQ topics
    for (String keyword in _faqResponses.keys) {
      if (message.contains(keyword)) {
        final responses = _faqResponses[keyword]!;
        return responses[Random().nextInt(responses.length)];
      }
    }
    
    // Handle specific questions
    if (message.contains('how often') || message.contains('schedule')) {
      return _faqResponses['schedule']![Random().nextInt(_faqResponses['schedule']!.length)];
    }
    
    if (message.contains('progress') || message.contains('improvement')) {
      return _faqResponses['progress']![Random().nextInt(_faqResponses['progress']!.length)];
    }
    
    if (message.contains('equipment') || message.contains('tools')) {
      return _faqResponses['equipment']![Random().nextInt(_faqResponses['equipment']!.length)];
    }
    
    // Default response
    return _generalResponses[Random().nextInt(_generalResponses.length)];
  }

  static List<String> getQuickButtons() {
    return [
      'Frequently asked questions',
      'Self-care & Wellness Tips',
    ];
  }

  static String handleQuickButton(String buttonText) {
    switch (buttonText) {
      case 'Frequently asked questions':
        return "Here are some common questions:\n\n• Pain during exercises\n• Exercise schedule\n• Tracking progress\n• Equipment needed\n\nWhat would you like to know more about?";
      case 'Self-care & Wellness Tips':
        return "Here are some wellness tips:\n\n• Stay hydrated throughout the day\n• Get 7-9 hours of quality sleep\n• Listen to your body's signals\n• Maintain consistency in your routine\n\nWould you like more specific advice?";
      default:
        return generateResponse(buttonText);
    }
  }
}
