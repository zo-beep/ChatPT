import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static const String _apiKey = 'AIzaSyC6RPdr_zu6kmuKIm1mUlYjaDIY1UaLm44'; // Replace with your Gemini API key
  late final GenerativeModel _model;
  
  // System prompt to constrain responses to physical therapy topics
  static const String _systemPrompt = '''
You are a knowledgeable physical therapy assistant AI. Your role is to:
- Only answer questions related to physical therapy, exercise, rehabilitation, and injury recovery
- Provide evidence-based information and exercise recommendations
- Emphasize safety and proper form
- Refer complex medical issues to healthcare professionals
- Decline to answer questions outside of physical therapy scope
- Always include safety disclaimers when providing exercise advice

If a question is not related to physical therapy, respond with:
"I can only assist with physical therapy related questions. Please ask me about exercises, rehabilitation, or injury recovery."
''';

  GeminiService() {
    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
    );
    
    _model = model;
  }

  /// Checks if the question is related to physical therapy
  bool _isPhysicalTherapyRelated(String question) {
    // Keywords related to physical therapy
    final ptKeywords = [
      'exercise', 'therapy', 'rehabilitation', 'injury', 'recovery',
      'pain', 'movement', 'stretch', 'muscle', 'joint', 'strength',
      'flexibility', 'mobility', 'posture', 'ergonomic', 'spine',
      'back pain', 'physical therapy', 'pt', 'physiotherapy',
      'range of motion', 'workout', 'training', 'healing', 'treatment'
    ];

    question = question.toLowerCase();
    return ptKeywords.any((keyword) => question.contains(keyword.toLowerCase()));
  }

  /// Get response from Gemini API for physical therapy related questions
  Future<String> getResponse(String question) async {
    try {
      if (!_isPhysicalTherapyRelated(question)) {
        return "I can only assist with physical therapy related questions. Please ask me about exercises, rehabilitation, or injury recovery.";
      }

      final prompt = '$_systemPrompt\n\nQuestion: $question';
      final response = await _model.generateContent([
        Content.text(prompt),
      ]);
      
      final responseText = response.text;
      if (responseText == null) {
        return "I apologize, but I couldn't generate a response. Please try rephrasing your question about physical therapy.";
      }

      return responseText;
    } catch (e) {
      return "I encountered an error while processing your physical therapy question. Please try again later.";
    }
  }

  /// Get exercise recommendations based on specific condition or goal
  Future<String> getExerciseRecommendations(String condition) async {
    final prompt = '''
Please provide safe, beginner-friendly exercises for $condition. Include:
- 3-4 basic exercises
- Clear form instructions
- Repetitions and sets
- Safety precautions
- When to stop or consult a professional
''';

    try {
      final response = await getResponse(prompt);
      return response;
    } catch (e) {
      return "I couldn't generate exercise recommendations at this time. Please consult a physical therapist for personalized advice.";
    }
  }

  /// Check if an exercise form description is safe and correct
  Future<String> validateExerciseForm(String exerciseDescription) async {
    final prompt = '''
Please analyze this exercise form and provide:
- Safety assessment
- Form corrections if needed
- Proper technique reminders
- Warning signs to watch for
Exercise: $exerciseDescription
''';

    try {
      final response = await getResponse(prompt);
      return response;
    } catch (e) {
      return "I couldn't analyze the exercise form at this time. Please consult a physical therapist for form checks.";
    }
  }
}
