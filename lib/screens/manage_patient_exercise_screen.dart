import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:demo_app/main.dart';

class ManagePatientExerciseScreen extends StatefulWidget {
  final ThemeProvider themeProvider;
  const ManagePatientExerciseScreen({super.key, required this.themeProvider});

  @override
  State<ManagePatientExerciseScreen> createState() => _ManagePatientExerciseScreenState();
}

class _ManagePatientExerciseScreenState extends State<ManagePatientExerciseScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  bool _loadingUsers = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _loadingUsers = true);
    try {
      final snap = await FirebaseFirestore.instance.collection('users').limit(100).get();
  _users = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (e) {
      print('Failed to load users: $e');
      _users = [];
    }
    setState(() => _loadingUsers = false);
  }

  List<Map<String, dynamic>> get _filteredUsers {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _users;
    return _users.where((u) {
      final name = (u['name'] ?? '').toString().toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      final id = (u['patientId'] ?? u['id'] ?? '').toString().toLowerCase();
      return name.contains(q) || email.contains(q) || id.contains(q);
    }).toList();
  }

  void _openUserManage(Map<String, dynamic> user) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => _UserExerciseManager(user: user, themeProvider: widget.themeProvider)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.themeProvider;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Patients'),
        backgroundColor: theme.cardColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Patient Directory',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage exercises and track patient progress',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.subtextColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.primaryColor.withOpacity(0.1),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: theme.textColor),
                      decoration: InputDecoration(
                        hintText: 'Search patients...',
                        hintStyle: TextStyle(color: theme.subtextColor),
                        prefixIcon: Icon(Icons.search, color: theme.primaryColor),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: theme.subtextColor),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loadingUsers
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.primaryColor,
                        ),
                      ),
                    )
                  : _filteredUsers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: theme.subtextColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No patients found',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try adjusting your search',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.subtextColor,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredUsers.length,
                          padding: const EdgeInsets.all(16),
                          itemBuilder: (context, i) {
                            final u = _filteredUsers[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.primaryColor.withOpacity(0.1),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.primaryColor.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => _openUserManage(u),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: theme.primaryColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Center(
                                            child: Text(
                                              (u['name'] ?? u['email'] ?? 'U')[0].toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: theme.primaryColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                u['name'] ?? u['email'] ?? 'Unknown',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: theme.textColor,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                u['email'] ?? '',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: theme.subtextColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme.primaryColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.arrow_forward_ios,
                                            size: 14,
                                            color: theme.primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserExerciseManager extends StatefulWidget {
  final Map<String, dynamic> user;
  final ThemeProvider themeProvider;
  const _UserExerciseManager({required this.user, required this.themeProvider});

  @override
  State<_UserExerciseManager> createState() => _UserExerciseManagerState();
}

class _UserExerciseManagerState extends State<_UserExerciseManager> {
  List<Map<String, dynamic>> _exercises = [];
  bool _loading = true;
  List<Map<String, dynamic>> _assignedExercises = [];
  bool _loadingAssigned = true;
  bool _showAssigned = true; // toggle between Assigned / Available
  final Map<String, bool> _expandedCategories = {};
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExercises();
    _loadAssignedExercises();
  }

  Future<void> _loadExercises() async {
    setState(() => _loading = true);
    try {
      final snap = await FirebaseFirestore.instance.collection('exercises').orderBy('title').get();
  _exercises = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (e) {
      print('Failed to load exercises: $e');
      _exercises = [];
    }
    setState(() => _loading = false);
  }

  Future<void> _loadAssignedExercises() async {
    setState(() => _loadingAssigned = true);
    try {
      final userId = widget.user['id'] ?? widget.user['patientId'] ?? widget.user['uid'];
      if (userId != null) {
        final snap = await FirebaseFirestore.instance.collection('users').doc(userId).collection('assignedExercises').orderBy('date').get();
        _assignedExercises = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      } else {
        _assignedExercises = [];
      }
    } catch (e) {
      print('Failed to load assigned exercises: $e');
      _assignedExercises = [];
    }
    setState(() => _loadingAssigned = false);
  }

  String _getExerciseCategory(Map<String, dynamic> exercise) {
    // Try to get category from exercise data, fallback to intelligent categorization
    String? category = exercise['category']?.toString().toLowerCase();
    if (category != null && category.isNotEmpty) {
      return category;
    }
    
    // Intelligent categorization based on exercise name
    String name = (exercise['title'] ?? exercise['name'] ?? '').toString().toLowerCase();
    
    if (name.contains('core') || name.contains('ab') || name.contains('plank') || name.contains('crunch')) {
      return 'core';
    } else if (name.contains('leg') || name.contains('squat') || name.contains('calf') || name.contains('thigh')) {
      return 'lower body';
    } else if (name.contains('arm') || name.contains('bicep') || name.contains('tricep') || name.contains('shoulder') || name.contains('chest')) {
      return 'upper body';
    } else if (name.contains('cardio') || name.contains('walk') || name.contains('run') || name.contains('bike')) {
      return 'cardio';
    } else if (name.contains('stretch') || name.contains('flexibility') || name.contains('yoga')) {
      return 'flexibility';
    } else {
      return 'general';
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupExercisesByCategory(List<Map<String, dynamic>> exercises) {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    
    for (var exercise in exercises) {
      String category = _getExerciseCategory(exercise);
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
        // Initialize category as expanded by default
        _expandedCategories[category] ??= true;
      }
      grouped[category]!.add(exercise);
    }
    
    return grouped;
  }

  String _capitalizeCategory(String category) {
    return category.split(' ').map((word) => 
      word.isEmpty ? word : word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'core':
        return Icons.fitness_center;
      case 'lower body':
        return Icons.directions_walk;
      case 'upper body':
        return Icons.accessibility_new;
      case 'cardio':
        return Icons.favorite;
      case 'flexibility':
        return Icons.self_improvement;
      default:
        return Icons.sports_gymnastics;
    }
  }

  List<Map<String, dynamic>> get _filteredExercises {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _exercises;
    
    return _exercises.where((exercise) {
      final title = (exercise['title'] ?? exercise['name'] ?? '').toString().toLowerCase();
      final category = (exercise['category'] ?? '').toString().toLowerCase();
      final description = (exercise['description'] ?? '').toString().toLowerCase();
      
      return title.contains(query) || 
             category.contains(query) || 
             description.contains(query);
    }).toList();
  }

  List<Widget> _buildCategorizedExerciseList(List<Map<String, dynamic>> exercises) {
    final groupedExercises = _groupExercisesByCategory(exercises);
    List<Widget> widgets = [];
    
    // Sort categories for consistent display
    final sortedCategories = groupedExercises.keys.toList()..sort();
    
    for (String category in sortedCategories) {
      final categoryExercises = groupedExercises[category]!;
      final isExpanded = _expandedCategories[category] ?? true;
      
      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.themeProvider.subtextColor.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Category header
              InkWell(
                onTap: () {
                  setState(() {
                    _expandedCategories[category] = !isExpanded;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: widget.themeProvider.primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getCategoryIcon(category),
                        color: widget.themeProvider.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _capitalizeCategory(category),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: widget.themeProvider.textColor,
                          ),
                        ),
                      ),
                      Text(
                        '${categoryExercises.length}',
                        style: TextStyle(
                          fontSize: 14,
                          color: widget.themeProvider.subtextColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: widget.themeProvider.subtextColor,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Exercise list
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: isExpanded ? null : 0,
                child: isExpanded
                    ? Column(
                        children: categoryExercises.map((exercise) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: _buildCompactExerciseCard(exercise),
                          );
                        }).toList(),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    
    return widgets;
  }

  Widget _buildCompactExerciseCard(Map<String, dynamic> exercise) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: widget.themeProvider.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.themeProvider.subtextColor.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Exercise icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: widget.themeProvider.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getCategoryIcon(_getExerciseCategory(exercise)),
              color: widget.themeProvider.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Exercise info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        exercise['title'] ?? exercise['name'] ?? 'Exercise',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: widget.themeProvider.textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: widget.themeProvider.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _capitalizeCategory(_getExerciseCategory(exercise)),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: widget.themeProvider.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (exercise['description'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    exercise['description'],
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.themeProvider.subtextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Edit button
              InkWell(
                onTap: () => _showEditExerciseDialog(exercise),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: widget.themeProvider.subtextColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    color: widget.themeProvider.subtextColor,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Delete button
              InkWell(
                onTap: () => _deleteExercise(exercise['id']),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Assign button
              InkWell(
                onTap: () => _showAssignDialog(exercise),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.themeProvider.primaryColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Assign',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAssignment(String docId) async {
    final userId = widget.user['id'] ?? widget.user['patientId'] ?? widget.user['uid'];
    if (userId == null) return;
    final confirm = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: const Text('Delete assignment'),
      content: const Text('Are you sure you want to delete this assignment?'),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete'))],
    ));
    if (confirm != true) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).collection('assignedExercises').doc(docId).delete();
      await _loadAssignedExercises();
    } catch (e) {
      print('Failed to delete assignment: $e');
    }
  }

  Future<void> _showEditAssignmentDialog(Map<String, dynamic> assignment, String docId) async {
    final setsC = TextEditingController(text: (assignment['sets'] ?? '').toString());
    final repsC = TextEditingController(text: (assignment['repetitions'] ?? '').toString());
    final durationC = TextEditingController(text: (assignment['duration'] ?? '').toString());
    DateTime? scheduledDate = assignment['date'] is Timestamp ? (assignment['date'] as Timestamp).toDate() : null;
    bool isLoading = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final theme = widget.themeProvider;
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.subtextColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit Assignment',
                            style: TextStyle(
                              color: theme.textColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Exercise Info Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: theme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.fitness_center,
                                    color: theme.primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        assignment['exerciseName'] ?? '',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: theme.textColor,
                                        ),
                                      ),
                                      if (assignment['category'] != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          assignment['category'],
                                          style: TextStyle(
                                            color: theme.subtextColor,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Exercise Parameters
                          Text(
                            'Exercise Parameters',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: theme.subtextColor,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Sets Input
                          TextField(
                            controller: setsC,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: theme.textColor),
                            decoration: InputDecoration(
                              labelText: 'Number of Sets',
                              labelStyle: TextStyle(color: theme.subtextColor),
                              prefixIcon: Icon(Icons.repeat, color: theme.primaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.primaryColor.withOpacity(0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.primaryColor.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.primaryColor),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Repetitions Input
                          TextField(
                            controller: repsC,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: theme.textColor),
                            decoration: InputDecoration(
                              labelText: 'Repetitions per Set',
                              labelStyle: TextStyle(color: theme.subtextColor),
                              prefixIcon: Icon(Icons.refresh, color: theme.primaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.primaryColor.withOpacity(0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.primaryColor.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.primaryColor),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Duration Input
                          TextField(
                            controller: durationC,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: theme.textColor),
                            decoration: InputDecoration(
                              labelText: 'Duration (minutes)',
                              labelStyle: TextStyle(color: theme.subtextColor),
                              prefixIcon: Icon(Icons.timer, color: theme.primaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.primaryColor.withOpacity(0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.primaryColor.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.primaryColor),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Schedule Date
                          Text(
                            'Schedule Date',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: theme.subtextColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: scheduledDate ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2100),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: theme.primaryColor,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setState(() => scheduledDate = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: theme.primaryColor.withOpacity(0.3),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today,
                                    color: theme.primaryColor,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    scheduledDate == null
                                        ? 'Select Date'
                                        : scheduledDate.toString().split(' ')[0],
                                    style: TextStyle(
                                      color: theme.textColor,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Action Buttons
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.subtextColor,
                              side: BorderSide(color: theme.subtextColor),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () async {
                                    if (scheduledDate == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please select a date'),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                      return;
                                    }

                                    setState(() => isLoading = true);

                                    try {
                                      final userId = widget.user['id'] ?? widget.user['patientId'] ?? widget.user['uid'];
                                      if (userId != null) {
                                        final docRef = FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(userId)
                                            .collection('assignedExercises')
                                            .doc(docId);
                                        
                                        await docRef.update({
                                          'sets': int.tryParse(setsC.text.trim()) ?? 0,
                                          'repetitions': int.tryParse(repsC.text.trim()) ?? 0,
                                          'duration': int.tryParse(durationC.text.trim()) ?? 0,
                                          'date': Timestamp.fromDate(scheduledDate!),
                                        });

                                        Navigator.pop(context);
                                        await _loadAssignedExercises();

                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Text('Assignment updated successfully'),
                                            backgroundColor: Colors.green,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      setState(() => isLoading = false);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error updating assignment: $e'),
                                          backgroundColor: Colors.red,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text('Save Changes'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showCreateExerciseDialog() async {
    final titleC = TextEditingController();
    final categoryC = TextEditingController();
    final notesC = TextEditingController();
    final videoC = TextEditingController();
    final instructionsC = TextEditingController();
    bool isLoading = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final theme = widget.themeProvider;
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.subtextColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create New Exercise',
                            style: TextStyle(
                              color: theme.textColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add a new exercise to assign to patients',
                            style: TextStyle(
                              color: theme.subtextColor,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Name Field
                          TextField(
                            controller: titleC,
                            style: TextStyle(color: theme.textColor),
                            decoration: InputDecoration(
                              labelText: 'Exercise Name',
                              labelStyle: TextStyle(color: theme.subtextColor),
                              prefixIcon: Icon(Icons.fitness_center, color: theme.primaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.primaryColor.withOpacity(0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.primaryColor.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.primaryColor),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Category Field
                          TextField(
                            controller: categoryC,
                            style: TextStyle(color: theme.textColor),
                            decoration: InputDecoration(
                              labelText: 'Category',
                              hintText: 'e.g. Lower Body, Upper Body, Core',
                              hintStyle: TextStyle(color: theme.subtextColor.withOpacity(0.7)),
                              labelStyle: TextStyle(color: theme.subtextColor),
                              prefixIcon: Icon(Icons.category, color: theme.primaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.primaryColor.withOpacity(0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.primaryColor.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.primaryColor),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Description Field
                          TextField(
                            controller: notesC,
                            style: TextStyle(color: theme.textColor),
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Description',
                              labelStyle: TextStyle(color: theme.subtextColor),
                              alignLabelWithHint: true,
                              hintText: 'Describe the exercise and its benefits',
                              hintStyle: TextStyle(color: theme.subtextColor.withOpacity(0.7)),
                              prefixIcon: Icon(Icons.description, color: theme.primaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.primaryColor.withOpacity(0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.primaryColor.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.primaryColor),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Video URL Field
                          TextField(
                            controller: videoC,
                            style: TextStyle(color: theme.textColor),
                            decoration: InputDecoration(
                              labelText: 'Video URL',
                              labelStyle: TextStyle(color: theme.subtextColor),
                              hintText: 'Add a video demonstration link',
                              hintStyle: TextStyle(color: theme.subtextColor.withOpacity(0.7)),
                              prefixIcon: Icon(Icons.video_library, color: theme.primaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.primaryColor.withOpacity(0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.primaryColor.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.primaryColor),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Instructions Field
                          TextField(
                            controller: instructionsC,
                            style: TextStyle(color: theme.textColor),
                            maxLines: 5,
                            decoration: InputDecoration(
                              labelText: 'Instructions',
                              labelStyle: TextStyle(color: theme.subtextColor),
                              alignLabelWithHint: true,
                              hintText: 'Enter each instruction on a new line\nExample:\n1. Stand with feet shoulder-width apart\n2. Bend knees slowly\n3. Return to starting position',
                              hintStyle: TextStyle(color: theme.subtextColor.withOpacity(0.7)),
                              prefixIcon: Icon(Icons.list_alt, color: theme.primaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.primaryColor.withOpacity(0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.primaryColor.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.primaryColor),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Bottom Action Buttons
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.subtextColor,
                              side: BorderSide(color: theme.subtextColor),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () async {
                                    if (titleC.text.trim().isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Exercise name is required'),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                      return;
                                    }

                                    setState(() => isLoading = true);

                                    try {
                                      final doc = await FirebaseFirestore.instance.collection('exercises').add({
                                        'title': titleC.text.trim(),
                                        'category': categoryC.text.trim(),
                                        'description': notesC.text.trim(),
                                        'videoUrl': videoC.text.trim(),
                                        'instructions': instructionsC.text.trim().split('\n'),
                                        'createdAt': FieldValue.serverTimestamp(),
                                      });
                                      
                                      Navigator.pop(context);
                                      await _loadExercises();

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Text('Exercise created successfully'),
                                          backgroundColor: Colors.green,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      );
                                    } catch (e) {
                                      setState(() => isLoading = false);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error creating exercise: $e'),
                                          backgroundColor: Colors.red,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text('Create Exercise'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showEditExerciseDialog(Map<String, dynamic> exercise) async {
    final titleC = TextEditingController(text: exercise['title'] ?? exercise['name'] ?? '');
    final categoryC = TextEditingController(text: exercise['category'] ?? '');
    final notesC = TextEditingController(text: exercise['description'] ?? '');
    final videoC = TextEditingController(text: exercise['videoUrl'] ?? '');
    final instructionsC = TextEditingController(text: (exercise['instructions'] ?? []).join('\n'));
    bool isLoading = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final theme = widget.themeProvider;
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.subtextColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit Exercise',
                            style: TextStyle(
                              color: theme.textColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Name Field
                          TextField(
                            controller: titleC,
                            style: TextStyle(color: theme.textColor),
                            decoration: InputDecoration(
                              labelText: 'Exercise Name',
                              labelStyle: TextStyle(color: theme.subtextColor),
                              prefixIcon: Icon(Icons.fitness_center, color: theme.primaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.primaryColor.withOpacity(0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.primaryColor.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.primaryColor),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Category Field
                          TextField(
                            controller: categoryC,
                            style: TextStyle(color: theme.textColor),
                            decoration: InputDecoration(
                              labelText: 'Category',
                              labelStyle: TextStyle(color: theme.subtextColor),
                              prefixIcon: Icon(Icons.category, color: theme.primaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.primaryColor.withOpacity(0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.primaryColor.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.primaryColor),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Description Field
                          TextField(
                            controller: notesC,
                            style: TextStyle(color: theme.textColor),
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Description',
                              labelStyle: TextStyle(color: theme.subtextColor),
                              alignLabelWithHint: true,
                              prefixIcon: Icon(Icons.description, color: theme.primaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.primaryColor.withOpacity(0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.primaryColor.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.primaryColor),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Video URL Field
                          TextField(
                            controller: videoC,
                            style: TextStyle(color: theme.textColor),
                            decoration: InputDecoration(
                              labelText: 'Video URL',
                              labelStyle: TextStyle(color: theme.subtextColor),
                              prefixIcon: Icon(Icons.video_library, color: theme.primaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.primaryColor.withOpacity(0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.primaryColor.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.primaryColor),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Instructions Field
                          TextField(
                            controller: instructionsC,
                            style: TextStyle(color: theme.textColor),
                            maxLines: 5,
                            decoration: InputDecoration(
                              labelText: 'Instructions',
                              labelStyle: TextStyle(color: theme.subtextColor),
                              alignLabelWithHint: true,
                              hintText: 'Enter each instruction on a new line',
                              hintStyle: TextStyle(color: theme.subtextColor.withOpacity(0.7)),
                              prefixIcon: Icon(Icons.list_alt, color: theme.primaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.primaryColor.withOpacity(0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.primaryColor.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.primaryColor),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Bottom Action Buttons
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.subtextColor,
                              side: BorderSide(color: theme.subtextColor),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () async {
                                    if (titleC.text.trim().isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Exercise name is required'),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                      return;
                                    }

                                    setState(() => isLoading = true);

                                    final id = exercise['id'];
                                    if (id != null) {
                                      await FirebaseFirestore.instance.collection('exercises').doc(id).update({
                                        'title': titleC.text.trim(),
                                        'category': categoryC.text.trim(),
                                        'description': notesC.text.trim(),
                                        'videoUrl': videoC.text.trim(),
                                        'instructions': instructionsC.text.trim().split('\n'),
                                      });
                                      Navigator.pop(context);
                                      await _loadExercises();
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text('Save Changes'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteExercise(String id) async {
    final confirm = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: const Text('Delete exercise'),
      content: const Text('Delete this master exercise? This will not delete assignments.'),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete'))],
    ));
    if (confirm != true) return;
    try {
      await FirebaseFirestore.instance.collection('exercises').doc(id).delete();
      await _loadExercises();
    } catch (e) {
      print('Failed to delete exercise: $e');
    }
  }

  Future<void> _showAssignDialog(Map<String, dynamic> exercise) async {
    final setsC = TextEditingController(text: '2');
    final repsC = TextEditingController(text: '10');
    final durationC = TextEditingController(text: '5');
    DateTime? scheduledDate;
    bool isLoading = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final theme = widget.themeProvider;
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.subtextColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assign Exercise',
                            style: TextStyle(
                              color: theme.textColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Exercise Info Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.fitness_center,
                                      color: theme.primaryColor,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        exercise['title'] ?? exercise['name'] ?? 'Exercise',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: theme.textColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Category: ${exercise['category'] ?? 'General'}',
                                  style: TextStyle(
                                    color: theme.subtextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Patient Info
                          Text(
                            'Patient',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: theme.subtextColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: theme.primaryColor.withOpacity(0.2),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: theme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      (widget.user['name'] ?? widget.user['email'] ?? '?')[0].toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: theme.primaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.user['name'] ?? widget.user['email'] ?? widget.user['id'] ?? 'Unknown',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: theme.textColor,
                                        ),
                                      ),
                                      if (widget.user['email'] != null)
                                        Text(
                                          widget.user['email'],
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: theme.subtextColor,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Exercise Parameters
                          Text(
                            'Exercise Parameters',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: theme.subtextColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Sets Input
                          TextField(
                            controller: setsC,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: theme.textColor),
                            decoration: InputDecoration(
                              labelText: 'Number of Sets',
                              labelStyle: TextStyle(color: theme.subtextColor),
                              prefixIcon: Icon(Icons.repeat, color: theme.primaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.primaryColor.withOpacity(0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.primaryColor.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.primaryColor),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Repetitions Input
                          TextField(
                            controller: repsC,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: theme.textColor),
                            decoration: InputDecoration(
                              labelText: 'Repetitions per Set',
                              labelStyle: TextStyle(color: theme.subtextColor),
                              prefixIcon: Icon(Icons.refresh, color: theme.primaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.primaryColor.withOpacity(0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.primaryColor.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.primaryColor),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Duration Input
                          TextField(
                            controller: durationC,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: theme.textColor),
                            decoration: InputDecoration(
                              labelText: 'Duration (minutes)',
                              labelStyle: TextStyle(color: theme.subtextColor),
                              prefixIcon: Icon(Icons.timer, color: theme.primaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.primaryColor.withOpacity(0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.primaryColor.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.primaryColor),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Date Picker
                          Text(
                            'Schedule Date',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: theme.subtextColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: scheduledDate ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2100),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: theme.primaryColor,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setState(() => scheduledDate = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: theme.primaryColor.withOpacity(0.3),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today,
                                    color: theme.primaryColor,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    scheduledDate == null
                                        ? 'Select Date'
                                        : scheduledDate.toString().split(' ')[0],
                                    style: TextStyle(
                                      color: theme.textColor,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Bottom Action Buttons
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.subtextColor,
                              side: BorderSide(color: theme.subtextColor),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () async {
                                    if (scheduledDate == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please select a date'),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                      return;
                                    }

                                    setState(() => isLoading = true);

                                    final assignment = {
                                      'exerciseId': exercise['id'],
                                      'exerciseName': exercise['title'] ?? exercise['name'],
                                      'category': exercise['category'] ?? '',
                                      'videoUrl': exercise['videoUrl'] ?? '',
                                      'instructions': exercise['instructions'] ?? [],
                                      'sets': int.tryParse(setsC.text.trim()) ?? 0,
                                      'repetitions': int.tryParse(repsC.text.trim()) ?? 0,
                                      'duration': int.tryParse(durationC.text.trim()) ?? 0,
                                      'date': Timestamp.fromDate(scheduledDate!),
                                      'completed': false,
                                      'assignedBy': FirebaseAuth.instance.currentUser?.uid,
                                      'createdAt': FieldValue.serverTimestamp(),
                                      'assignedAt': FieldValue.serverTimestamp(),
                                    };

                                    final userId = widget.user['id'] ?? widget.user['patientId'] ?? widget.user['uid'];
                                    if (userId != null) {
                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(userId)
                                          .collection('assignedExercises')
                                          .add(assignment);
                                    }
                                    Navigator.pop(context);
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text('Assign Exercise'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.themeProvider;
    final user = widget.user;
    return Scaffold(
      appBar: AppBar(
        title: Text(user['name'] ?? 'Manage'),
        backgroundColor: theme.cardColor,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: theme.primaryColor), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(icon: Icon(Icons.add, color: theme.primaryColor), onPressed: _showCreateExerciseDialog),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // User header with medical info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: theme.cardColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['name'] ?? '', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textColor)),
                      const SizedBox(height: 6),
                      Text('Age: ${user['age'] ?? '—'} • Email: ${user['email'] ?? '—'}', style: TextStyle(color: theme.subtextColor)),
                      const SizedBox(height: 6),
                      Text('Assigned Doctor: ${user['assignedDoctor'] ?? '—'} • Therapy start: ${user['therapyStartDate'] ?? '—'}', style: TextStyle(color: theme.subtextColor)),
                      const SizedBox(height: 8),
                      // Progress summary
                      Builder(builder: (context) {
                        final total = _assignedExercises.length;
                        final done = _assignedExercises.where((a) => a['completed'] == true).length;
                        final pct = total == 0 ? 0 : ((done / total) * 100).round();
                        return Row(
                          children: [
                            Expanded(child: Text('Progress: $done / $total completed', style: TextStyle(color: theme.subtextColor))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: theme.primaryColor, borderRadius: BorderRadius.circular(8)),
                              child: Text('$pct%', style: const TextStyle(color: Colors.white)),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                // Toggle
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: _showAssigned ? theme.primaryColor : theme.cardColor, foregroundColor: _showAssigned ? Colors.white : theme.textColor),
                          onPressed: () => setState(() => _showAssigned = true),
                          child: const Text('Assigned'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: !_showAssigned ? theme.primaryColor : theme.cardColor, foregroundColor: !_showAssigned ? Colors.white : theme.textColor),
                          onPressed: () => setState(() => _showAssigned = false),
                          child: const Text('Available'),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _showAssigned
                      ? (_loadingAssigned
                          ? const Center(child: CircularProgressIndicator())
                          : _assignedExercises.isEmpty
                              ? Center(child: Text('No assigned exercises', style: TextStyle(color: theme.subtextColor)))
                              : ListView.builder(
                                  itemCount: _assignedExercises.length,
                                  itemBuilder: (context, i) {
                                    final a = _assignedExercises[i];
                                    final dateText = a['date'] is Timestamp ? (a['date'] as Timestamp).toDate().toLocal().toString().split(' ')[0] : a['date']?.toString() ?? '';
                                    final completedAtText = a['completedAt'] is Timestamp ? (a['completedAt'] as Timestamp).toDate().toLocal().toString().split(' ')[0] : null;
                                    final subtitleParts = <String>[];
                                    subtitleParts.add('Sets: ${a['sets'] ?? ''}');
                                    subtitleParts.add('Reps: ${a['repetitions'] ?? ''}');
                                    if (dateText.isNotEmpty) subtitleParts.add(dateText);
                                    if (completedAtText != null) subtitleParts.add('Completed: $completedAtText');
                                    return ListTile(
                                      title: Text(a['exerciseName'] ?? ''),
                                      subtitle: Text(subtitleParts.join(' • ')),
                                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                        IconButton(icon: Icon(Icons.edit, color: theme.primaryColor), onPressed: () => _showEditAssignmentDialog(a, a['id'])),
                                        IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteAssignment(a['id'])),
                                      ]),
                                    );
                                  },
                                ))
                      : (_loading
                          ? const Center(child: CircularProgressIndicator())
                          : Column(
                              children: [
                                // Search bar
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: (value) => setState(() {}),
                                    decoration: InputDecoration(
                                      hintText: 'Search exercises...',
                                      prefixIcon: Icon(
                                        Icons.search,
                                        color: theme.subtextColor,
                                      ),
                                      suffixIcon: _searchController.text.isNotEmpty
                                          ? IconButton(
                                              icon: Icon(
                                                Icons.clear,
                                                color: theme.subtextColor,
                                              ),
                                              onPressed: () {
                                                _searchController.clear();
                                                setState(() {});
                                              },
                                            )
                                          : null,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: theme.subtextColor.withOpacity(0.2),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: theme.subtextColor.withOpacity(0.2),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: theme.primaryColor,
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                // Categorized exercise list
                                Expanded(
                                  child: ListView(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    children: _buildCategorizedExerciseList(_filteredExercises),
                                  ),
                                ),
                              ],
                            )),
                ),
              ],
            ),
    );
  }
}