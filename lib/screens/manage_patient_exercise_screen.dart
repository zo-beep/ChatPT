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
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search users by name, email or id',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => setState(() {}),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            Expanded(
              child: _loadingUsers
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, i) {
                        final u = _filteredUsers[i];
                        return ListTile(
                          title: Text(u['name'] ?? u['email'] ?? 'Unknown'),
                          subtitle: Text(u['email'] ?? ''),
                          trailing: Text(u['patientId'] ?? u['id'] ?? ''),
                          onTap: () => _openUserManage(u),
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

  Future<void> _markAssignmentComplete(String docId, bool completed) async {
    final userId = widget.user['id'] ?? widget.user['patientId'] ?? widget.user['uid'];
    if (userId == null) return;
    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(userId).collection('assignedExercises').doc(docId);
      if (completed == true) {
        // Use a transaction to ensure we only create one history entry per assignment
        await FirebaseFirestore.instance.runTransaction((tx) async {
          final snap = await tx.get(docRef);
          if (!snap.exists) return;
          final data = snap.data() ?? {};
          // if already completed, nothing to do
          if ((data['completed'] == true) || (data['completedAt'] != null)) return;
          tx.update(docRef, {'completed': true, 'completedAt': FieldValue.serverTimestamp()});
          final histRef = FirebaseFirestore.instance.collection('users').doc(userId).collection('exerciseHistory').doc();
          tx.set(histRef, {
            'assignmentId': docId,
            'exerciseId': data['exerciseId'] ?? null,
            'exerciseName': data['exerciseName'] ?? '',
            'sets': data['sets'] ?? 0,
            'repetitions': data['repetitions'] ?? 0,
            'duration': data['duration'] ?? 0,
            'assignedBy': data['assignedBy'] ?? null,
            'assignedAt': data['assignedAt'] ?? null,
            'completedAt': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          });
        });
      } else {
        // un-marking: simply update assignment (do not remove history)
        await FirebaseFirestore.instance.collection('users').doc(userId).collection('assignedExercises').doc(docId).update({'completed': false, 'completedAt': FieldValue.delete()});
      }
      await _loadAssignedExercises();
    } catch (e) {
      print('Failed to update assignment completion: $e');
    }
  }

  Future<void> _showEditAssignmentDialog(Map<String, dynamic> assignment, String docId) async {
    final setsC = TextEditingController(text: (assignment['sets'] ?? '').toString());
    final repsC = TextEditingController(text: (assignment['repetitions'] ?? '').toString());
    final durationC = TextEditingController(text: (assignment['duration'] ?? '').toString());
    DateTime? scheduledDate = assignment['date'] is Timestamp ? (assignment['date'] as Timestamp).toDate() : null;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: const Text('Edit Assignment'),
          content: SingleChildScrollView(
            child: Column(children: [
              Text('Exercise: ${assignment['exerciseName'] ?? ''}'),
              TextField(controller: setsC, decoration: const InputDecoration(labelText: 'Sets')),
              TextField(controller: repsC, decoration: const InputDecoration(labelText: 'Repetitions')),
              TextField(controller: durationC, decoration: const InputDecoration(labelText: 'Duration (minutes)')),
              const SizedBox(height: 8),
              Row(children: [
                const Text('Date: '),
                Text(scheduledDate == null ? 'Not set' : scheduledDate.toString().split(' ')[0]),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: scheduledDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => scheduledDate = picked);
                  },
                  child: const Text('Pick'),
                ),
              ])
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final userId = widget.user['id'] ?? widget.user['patientId'] ?? widget.user['uid'];
                if (userId != null) {
                  final docRef = FirebaseFirestore.instance.collection('users').doc(userId).collection('assignedExercises').doc(docId);
                  await docRef.update({
                    'sets': int.tryParse(setsC.text.trim()) ?? 0,
                    'repetitions': int.tryParse(repsC.text.trim()) ?? 0,
                    'duration': int.tryParse(durationC.text.trim()) ?? 0,
                    'date': scheduledDate != null ? Timestamp.fromDate(scheduledDate!) : FieldValue.serverTimestamp(),
                  });
                }
                Navigator.pop(context);
                await _loadAssignedExercises();
              },
              child: const Text('Save'),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _showCreateExerciseDialog() async {
    final titleC = TextEditingController();
    final categoryC = TextEditingController();
    final notesC = TextEditingController();
    final videoC = TextEditingController();
    final instructionsC = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Exercise'),
        content: SingleChildScrollView(
          child: Column(children: [
            TextField(controller: titleC, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: categoryC, decoration: const InputDecoration(labelText: 'Category (e.g. Lower Body)')),
            TextField(controller: notesC, decoration: const InputDecoration(labelText: 'Description')),
            TextField(controller: videoC, decoration: const InputDecoration(labelText: 'Video URL or asset path')),
            TextField(controller: instructionsC, decoration: const InputDecoration(labelText: 'Instructions (newline-separated)')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final doc = await FirebaseFirestore.instance.collection('exercises').add({
                'title': titleC.text.trim(),
                'category': categoryC.text.trim(),
                'description': notesC.text.trim(),
                'videoUrl': videoC.text.trim(),
                'instructions': instructionsC.text.trim().split('\n'),
                'createdAt': FieldValue.serverTimestamp(),
              });
              print('Created exercise ${doc.id}');
              Navigator.pop(context);
              await _loadExercises();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditExerciseDialog(Map<String, dynamic> exercise) async {
    final titleC = TextEditingController(text: exercise['title'] ?? exercise['name'] ?? '');
    final categoryC = TextEditingController(text: exercise['category'] ?? '');
    final notesC = TextEditingController(text: exercise['description'] ?? '');
    final videoC = TextEditingController(text: exercise['videoUrl'] ?? '');
    final instructionsC = TextEditingController(text: (exercise['instructions'] ?? []).join('\n'));

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Exercise'),
        content: SingleChildScrollView(
          child: Column(children: [
            TextField(controller: titleC, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: categoryC, decoration: const InputDecoration(labelText: 'Category')),
            TextField(controller: notesC, decoration: const InputDecoration(labelText: 'Description')),
            TextField(controller: videoC, decoration: const InputDecoration(labelText: 'Video URL')),
            TextField(controller: instructionsC, decoration: const InputDecoration(labelText: 'Instructions (newline-separated)')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
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
            child: const Text('Save'),
          ),
        ],
      ),
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

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: const Text('Assign Exercise'),
          content: SingleChildScrollView(
            child: Column(children: [
              Text('To: ${widget.user['name'] ?? widget.user['email'] ?? widget.user['id']}'),
              Text('Exercise: ${exercise['title'] ?? exercise['name'] ?? 'Exercise'}'),
              TextField(controller: setsC, decoration: const InputDecoration(labelText: 'Sets')),
              TextField(controller: repsC, decoration: const InputDecoration(labelText: 'Repetitions')),
              TextField(controller: durationC, decoration: const InputDecoration(labelText: 'Duration (minutes)')),
              const SizedBox(height: 8),
              Row(children: [
                const Text('Date: '),
                Text(scheduledDate == null ? 'Not set' : scheduledDate.toString().split(' ')[0]),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => scheduledDate = picked);
                  },
                  child: const Text('Pick'),
                ),
              ])
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final assignment = {
                  'exerciseId': exercise['id'],
                  'exerciseName': exercise['title'] ?? exercise['name'],
                  'category': exercise['category'] ?? '',
                  'videoUrl': exercise['videoUrl'] ?? '',
                  'instructions': exercise['instructions'] ?? [],
                  'sets': int.tryParse(setsC.text.trim()) ?? 0,
                  'repetitions': int.tryParse(repsC.text.trim()) ?? 0,
                  'duration': int.tryParse(durationC.text.trim()) ?? 0,
                  'date': scheduledDate != null ? Timestamp.fromDate(scheduledDate!) : FieldValue.serverTimestamp(),
                  'completed': false,
                  'assignedBy': FirebaseAuth.instance.currentUser?.uid,
                  'createdAt': FieldValue.serverTimestamp(),
                  'assignedAt': FieldValue.serverTimestamp(),
                };

                final userId = widget.user['id'] ?? widget.user['patientId'] ?? widget.user['uid'];
                if (userId != null) {
                  await FirebaseFirestore.instance.collection('users').doc(userId).collection('assignedExercises').add(assignment);
                }
                Navigator.pop(context);
              },
              child: const Text('Assign'),
            ),
          ],
        );
      }),
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
                                        IconButton(icon: Icon(Icons.check, color: a['completed'] == true ? Colors.green : theme.primaryColor), onPressed: () => _markAssignmentComplete(a['id'], !(a['completed'] == true))),
                                        IconButton(icon: Icon(Icons.edit, color: theme.primaryColor), onPressed: () => _showEditAssignmentDialog(a, a['id'])),
                                        IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteAssignment(a['id'])),
                                      ]),
                                    );
                                  },
                                ))
                      : (_loading
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.builder(
                              itemCount: _exercises.length,
                              itemBuilder: (context, i) {
                                final ex = _exercises[i];
                                return ListTile(
                                  title: Text(ex['title'] ?? ex['name'] ?? 'Exercise'),
                                  subtitle: Text(ex['category'] ?? ''),
                                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                    IconButton(icon: Icon(Icons.edit, color: theme.primaryColor), onPressed: () => _showEditExerciseDialog(ex)),
                                    IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteExercise(ex['id'])),
                                    ElevatedButton(onPressed: () => _showAssignDialog(ex), child: const Text('Assign')),
                                  ]),
                                );
                              },
                            )),
                ),
              ],
            ),
    );
  }
}
