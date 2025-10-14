import 'package:demo_app/main.dart';
import 'package:demo_app/screens/main_screen.dart';
import 'package:demo_app/services/ai/chatbot_service.dart';
import 'package:flutter/material.dart';

// CHATBOT SCREEN
class ChatBotScreen extends StatefulWidget {
  final ThemeProvider themeProvider;
  const ChatBotScreen({super.key, required this.themeProvider});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [
    {
      'text': ChatbotService.generateResponse('hello'),
      'isBot': true,
      'showButtons': true,
    },
  ];

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'text': text,
        'isBot': false,
        'showButtons': false,
      });
      _messageController.clear();
    });

    // Generate bot response using ChatbotService
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _messages.add({
          'text': ChatbotService.generateResponse(text),
          'isBot': true,
          'showButtons': false,
        });
      });
      _scrollToBottom();
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.themeProvider;
    return Scaffold(
      backgroundColor: theme.cardColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.primaryColor),
          onPressed: () {
            Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainScreen(themeProvider: widget.themeProvider,)),
            );
            setState(() {
              _messages.clear();
              _messages.add({
                'text': ChatbotService.generateResponse('hello'),
                'isBot': true,
                'showButtons': true,
              });
            });
          },
        ),
        title: Text(
          'Back',
          style: TextStyle(color: theme.primaryColor),
        ),
      ),
      body: Column(
        children: [
          // ChatPT Bot Header
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'ChatPT Bot',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Chat Messages
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _buildMessage(
                    message['text'],
                    message['isBot'],
                    message['showButtons'],
                  );
                },
              ),
            ),
          ),
          // Add spacing between chat and input
          const SizedBox(height: 15),
          // Message Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.primaryColor,
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                        onSubmitted: _sendMessage,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _sendMessage(_messageController.text),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Icon(
                        Icons.send,
                        color: theme.primaryColor,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(String text, bool isBot, bool showButtons) {
    final theme = widget.themeProvider;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isBot)
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.directions_run,
                color: theme.primaryColor,
                size: 20,
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isBot ? Colors.white : theme.tertiaryColor.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isBot ? Colors.black87 : Colors.white,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (showButtons) ...[
                  const SizedBox(height: 12),
                  _buildQuickButton('Frequently asked questions '),
                  const SizedBox(height: 8),
                  _buildQuickButton('Self-care & Wellness Tips '),
                ],
              ],
            ),
          ),
          if (!isBot) const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildQuickButton(String text) {
    final theme = widget.themeProvider;
    return GestureDetector(
      onTap: () {
        final response = ChatbotService.handleQuickButton(text);
        setState(() {
          _messages.add({
            'text': response,
            'isBot': true,
            'showButtons': false,
          });
        });
        _scrollToBottom();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: theme.primaryColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}