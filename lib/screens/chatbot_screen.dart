import 'dart:convert';
import 'package:demo_app/main.dart';
import 'package:demo_app/screens/main_screen.dart';
import 'package:demo_app/services/ai/chatbot_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';

// MODEL: A single chat session (topic)
class ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final List<Map<String, dynamic>> messages;

  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.messages,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'messages': messages,
      };

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
        id: json['id'],
        title: json['title'],
        createdAt: DateTime.parse(json['createdAt']),
        messages: List<Map<String, dynamic>>.from(json['messages']),
      );
}

// CHATBOT SCREEN
class ChatBotScreen extends StatefulWidget {
  final ThemeProvider themeProvider;
  const ChatBotScreen({super.key, required this.themeProvider});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];

  // Recent topics state
  List<ChatSession> _recentSessions = [];
  String? _currentSessionId;
  bool _isDrawerOpen = false;
  late AnimationController _drawerAnimController;
  late Animation<double> _drawerAnimation;

  static const String _storageKey = 'chat_sessions';

  @override
  void initState() {
    super.initState();
    _drawerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _drawerAnimation = CurvedAnimation(
      parent: _drawerAnimController,
      curve: Curves.easeInOut,
    );
    _loadSessions();
    _startNewChat();
  }

  @override
  void dispose() {
    _drawerAnimController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ─── Storage ──────────────────────────────────────────────────────────────

  Future<void> _loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? [];
    setState(() {
      _recentSessions = raw
          .map((s) => ChatSession.fromJson(jsonDecode(s)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  Future<void> _saveSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = _recentSessions.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_storageKey, raw);
  }

  void _saveCurrentSession() {
    if (_currentSessionId == null || _messages.isEmpty) return;
    // Pick title from first non-typing user message
    final userMsg = _messages.firstWhere(
      (m) => m['isBot'] == false && m['isTyping'] != true,
      orElse: () => {'text': 'New Chat'},
    );
    final title = (userMsg['text'] as String).length > 40
        ? '${(userMsg['text'] as String).substring(0, 40)}...'
        : userMsg['text'] as String;

    final idx = _recentSessions.indexWhere((s) => s.id == _currentSessionId);
    final session = ChatSession(
      id: _currentSessionId!,
      title: title,
      createdAt: DateTime.now(),
      messages: List.from(_messages.where((m) => m['isTyping'] != true)),
    );

    setState(() {
      if (idx >= 0) {
        _recentSessions[idx] = session;
      } else {
        _recentSessions.insert(0, session);
      }
    });
    _saveSessions();
  }

  // ─── Session management ───────────────────────────────────────────────────

  void _startNewChat() {
    setState(() {
      _messages.clear();
      _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    });
    _initializeChat();
    _closeDrawer();
  }

  void _loadSession(ChatSession session) {
    _saveCurrentSession(); // save current before switching
    setState(() {
      _messages.clear();
      _messages.addAll(session.messages);
      _currentSessionId = session.id;
    });
    _closeDrawer();
    _scrollToBottom();
  }

  Future<void> _deleteSession(String id) async {
    setState(() {
      _recentSessions.removeWhere((s) => s.id == id);
    });
    await _saveSessions();
    // If we deleted the active session, start fresh
    if (_currentSessionId == id) {
      _startNewChat();
    }
  }

  // ─── Drawer ───────────────────────────────────────────────────────────────

  void _toggleDrawer() {
    FocusScope.of(context).unfocus();
    setState(() => _isDrawerOpen = !_isDrawerOpen);
    if (_isDrawerOpen) {
      _drawerAnimController.forward();
    } else {
      _drawerAnimController.reverse();
    }
  }

  void _closeDrawer() {
    if (_isDrawerOpen) {
      setState(() => _isDrawerOpen = false);
      _drawerAnimController.reverse();
    }
  }

  // ─── Chat logic ───────────────────────────────────────────────────────────

  void _initializeChat() async {
    final response = await ChatbotService.generateResponse('hello');
    setState(() {
      _messages.add({
        'text': response,
        'isBot': true,
        'showButtons': true,
      });
    });
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'text': text.trim(),
        'isBot': false,
        'showButtons': false,
      });
      _messageController.clear();
    });

    setState(() {
      _messages.add({
        'text': 'Thinking...',
        'isBot': true,
        'showButtons': false,
        'isTyping': true,
      });
    });
    _scrollToBottom();

    try {
      final response = await ChatbotService.generateResponse(text);
      setState(() {
        _messages.removeLast();
        _messages.add({
          'text': response,
          'isBot': true,
          'showButtons': false,
        });
      });
    } catch (e) {
      setState(() {
        _messages.removeLast();
        _messages.add({
          'text': 'Sorry, I encountered an error. Please try again.',
          'isBot': true,
          'showButtons': false,
        });
      });
    }

    _saveCurrentSession();
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

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = widget.themeProvider;
    final bgColor = theme.backgroundColor ?? Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Main chat UI
          Column(
            children: [
              _buildAppBar(theme),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (_isDrawerOpen) _closeDrawer();
                    FocusScope.of(context).unfocus();
                  },
                  child: _buildMessageList(theme),
                ),
              ),
              _buildInputArea(theme),
            ],
          ),

          // Dimming overlay when drawer is open
          AnimatedBuilder(
            animation: _drawerAnimation,
            builder: (context, _) {
              if (_drawerAnimation.value == 0) return const SizedBox.shrink();
              return GestureDetector(
                onTap: _closeDrawer,
                child: Container(
                  color: Colors.black.withOpacity(0.3 * _drawerAnimation.value),
                ),
              );
            },
          ),

          // Recent Topics Drawer (slides in from left)
          AnimatedBuilder(
            animation: _drawerAnimation,
            builder: (context, _) {
              final screenWidth = MediaQuery.of(context).size.width;
              final drawerWidth = screenWidth * 0.8;
              final offset = -drawerWidth * (1 - _drawerAnimation.value);
              return Positioned(
                left: offset,
                top: 0,
                bottom: 0,
                width: drawerWidth,
                child: _buildRecentTopicsDrawer(theme),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(ThemeProvider theme) {
    final primaryColor = theme.primaryColor ?? const Color(0xFF5B8EFF);
    final textColor = theme.textColor ?? const Color(0xFF1E293B);

    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: theme.backgroundColor ?? Colors.white,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withOpacity(0.15),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Menu button
            IconButton(
              icon: Icon(Icons.menu_rounded, color: textColor.withOpacity(0.7)),
              onPressed: _toggleDrawer,
              tooltip: 'Recent topics',
            ),
            const SizedBox(width: 8),
            // Title
            Expanded(
              child: Text(
                'ChatPT',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            // New chat button
            IconButton(
              icon: Icon(Icons.edit_square, color: primaryColor, size: 22),
              onPressed: _startNewChat,
              tooltip: 'New Chat',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(ThemeProvider theme) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessage(
          message['text'],
          message['isBot'],
          message['showButtons'] ?? false,
          isTyping: message['isTyping'] ?? false,
          faqButtons: message['faqButtons'],
        );
      },
    );
  }

  Widget _buildInputArea(ThemeProvider theme) {
    final primaryColor = theme.primaryColor ?? const Color(0xFF5B8EFF);
    
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 24),
      decoration: BoxDecoration(
        color: theme.backgroundColor ?? Colors.white,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            (theme.backgroundColor ?? Colors.white).withOpacity(0.0),
            (theme.backgroundColor ?? Colors.white),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.08),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Message ChatPT...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 15),
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onSubmitted: _sendMessage,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: AnimatedBuilder(
                  animation: _messageController,
                  builder: (context, child) {
                    final hasText = _messageController.text.trim().isNotEmpty;
                    return GestureDetector(
                      onTap: hasText ? () => _sendMessage(_messageController.text) : null,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: hasText ? primaryColor : Colors.grey.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_upward_rounded,
                          color: hasText ? Colors.white : Colors.white70,
                          size: 20,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Recent Topics Drawer ─────────────────────────────────────────────────

  Widget _buildRecentTopicsDrawer(ThemeProvider theme) {
    final primaryColor = theme.primaryColor ?? const Color(0xFF5B8EFF);
    final textColor = theme.textColor ?? const Color(0xFF1E293B);

    return Material(
      elevation: 0,
      child: Container(
        color: Colors.grey.shade50, // slightly off-white drawer background
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drawer header
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                child: Row(
                  children: [
                    Text(
                      'Chat History',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, color: textColor.withOpacity(0.5)),
                      onPressed: _closeDrawer,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),

            // New Chat button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: InkWell(
                onTap: _startNewChat,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add_circle_outline, color: primaryColor, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'New Chat',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Session list
            Expanded(
              child: _recentSessions.isEmpty
                  ? _buildEmptyState(theme)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _recentSessions.length,
                      itemBuilder: (context, index) {
                        final session = _recentSessions[index];
                        final isActive = session.id == _currentSessionId;
                        return _buildSessionTile(session, isActive, theme);
                      },
                    ),
            ),
            
            // Bottom Action (Exit to Main)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: InkWell(
                  onTap: () {
                    _saveCurrentSession();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MainScreen(themeProvider: widget.themeProvider),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    child: Row(
                      children: [
                        Icon(Icons.home_outlined, color: textColor.withOpacity(0.7), size: 22),
                        const SizedBox(width: 12),
                        Text(
                          'Back to Dashboard',
                          style: TextStyle(
                            color: textColor.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionTile(
      ChatSession session, bool isActive, ThemeProvider theme) {
    final textColor = theme.textColor ?? const Color(0xFF1E293B);

    return Dismissible(
      key: Key(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.redAccent,
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 22),
      ),
      onDismissed: (_) => _deleteSession(session.id),
      child: InkWell(
        onTap: () => _loadSession(session),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Row(
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 18,
                color: isActive ? textColor : Colors.grey.shade400,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                        color: isActive ? textColor : textColor.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(session.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeProvider theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No recent chats',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Message Widgets (Modernized) ─────────────────────────────────────────

  Widget _buildMessage(String text, bool isBot, bool showButtons,
      {bool isTyping = false, List<String>? faqButtons}) {
    final theme = widget.themeProvider;
    final primaryColor = theme.primaryColor ?? const Color(0xFF5B8EFF);
    final textColor = theme.textColor ?? const Color(0xFF1E293B);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isBot) ...[
            // AI Avatar
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: primaryColor.withOpacity(0.2)),
              ),
              child: Icon(Icons.directions_run, color: primaryColor, size: 18),
            ),
          ],
          
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                // Message Bubble
                Container(
                  padding: isBot 
                      ? const EdgeInsets.only(top: 4) // No background for bot, just padding
                      : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: isBot
                      ? null
                      : BoxDecoration(
                          color: Colors.grey.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                  child: isTyping
                      ? _buildTypingIndicator(primaryColor)
                      : (isBot
                          ? MarkdownBody(
                              data: text,
                              selectable: true,
                              styleSheet: MarkdownStyleSheet(
                                p: TextStyle(color: textColor, fontSize: 16, height: 1.5),
                                strong: const TextStyle(fontWeight: FontWeight.w700),
                                code: TextStyle(
                                  backgroundColor: Colors.grey.shade100,
                                  fontFamily: 'monospace',
                                  fontSize: 14,
                                ),
                                codeblockDecoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                              ),
                            )
                          : Text(
                              text,
                              style: TextStyle(color: textColor, fontSize: 16, height: 1.4),
                            )),
                ),

                // Prompt Chips
                if (showButtons) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildQuickButton('Frequently asked questions'),
                      _buildQuickButton('Self-care & Wellness Tips'),
                    ],
                  ),
                ],
                if (faqButtons != null) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: faqButtons
                        .map((faq) => _buildFaqButton(faq))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          
          if (!isBot) const SizedBox(width: 8), // small padding on right for user message
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Thinking',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 15,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickButton(String text) {
    final theme = widget.themeProvider;
    final primaryColor = theme.primaryColor ?? const Color(0xFF5B8EFF);

    return InkWell(
      onTap: () async {
        setState(() {
          _messages.add({
            'text': 'Thinking...',
            'isBot': true,
            'showButtons': false,
            'isTyping': true,
          });
        });
        _scrollToBottom();

        try {
          final result = await ChatbotService.handleQuickButton(text);
          setState(() {
            _messages.removeLast();
            if (result['type'] == 'faq_list') {
              _messages.add({
                'text': 'Here are some common questions:',
                'isBot': true,
                'showButtons': false,
                'faqButtons': result['faqs'],
              });
            } else if (result['type'] == 'text') {
              _messages.add({
                'text': result['text'],
                'isBot': true,
                'showButtons': false,
              });
            }
          });
        } catch (e) {
          setState(() {
            _messages.removeLast();
            _messages.add({
              'text': 'Sorry, I encountered an error. Please try again.',
              'isBot': true,
              'showButtons': false,
            });
          });
        }
        _scrollToBottom();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lightbulb_outline, color: primaryColor, size: 16),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: theme.textColor ?? Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqButton(String faq) {
    final theme = widget.themeProvider;
    final primaryColor = theme.primaryColor ?? const Color(0xFF5B8EFF);

    return InkWell(
      onTap: () async {
        setState(() {
          _messages.add({
            'text': 'Thinking...',
            'isBot': true,
            'showButtons': false,
            'isTyping': true,
          });
        });
        _scrollToBottom();

        try {
          final result = await ChatbotService.handleFaqButton(faq);
          setState(() {
            _messages.removeLast();
            _messages.add({
              'text': result['text'],
              'isBot': true,
              'showButtons': false,
            });
          });
        } catch (e) {
          setState(() {
            _messages.removeLast();
            _messages.add({
              'text': 'Sorry, I encountered an error. Please try again.',
              'isBot': true,
              'showButtons': false,
            });
          });
        }
        _scrollToBottom();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: primaryColor.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(20),
          color: primaryColor.withOpacity(0.05),
        ),
        child: Text(
          faq,
          style: TextStyle(
            color: primaryColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}