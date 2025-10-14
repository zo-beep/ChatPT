import 'package:flutter/material.dart';
import 'package:demo_app/main.dart';

class DoctorSessionNotesScreen extends StatefulWidget {
  final ThemeProvider themeProvider;

  const DoctorSessionNotesScreen({super.key, required this.themeProvider});

  @override
  State<DoctorSessionNotesScreen> createState() => _DoctorSessionNotesScreenState();
}

class _DoctorSessionNotesScreenState extends State<DoctorSessionNotesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _sessionNotes = [];
  List<Map<String, dynamic>> _filteredNotes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessionNotes();
  }

  Future<void> _loadSessionNotes() async {
    // Mock session notes data
    setState(() {
      _sessionNotes = [
        {
          'id': 'N001',
          'patientName': 'John Smith',
          'patientId': 'P001',
          'date': '2024-01-15',
          'sessionType': 'Knee Rehabilitation',
          'notes': 'Patient showed significant improvement in range of motion. Completed all exercises without pain. Recommended to increase intensity for next session.',
          'exercises': ['Lateral Pendulum', 'Basic Hamstring Stretch', 'Quad Strengthening'],
          'duration': 45,
          'status': 'Completed',
        },
        {
          'id': 'N002',
          'patientName': 'Sarah Johnson',
          'patientId': 'P002',
          'date': '2024-01-14',
          'sessionType': 'Shoulder Recovery',
          'notes': 'Initial assessment completed. Patient experiencing moderate pain during certain movements. Started with gentle range of motion exercises.',
          'exercises': ['Shoulder Rolls', 'Pendulum Exercises'],
          'duration': 30,
          'status': 'Completed',
        },
        {
          'id': 'N003',
          'patientName': 'Mike Wilson',
          'patientId': 'P003',
          'date': '2024-01-12',
          'sessionType': 'Back Pain Management',
          'notes': 'Patient reported increased stiffness in lower back. Modified exercise plan to focus on core strengthening and flexibility.',
          'exercises': ['Cat-Cow Stretch', 'Pelvic Tilts', 'Core Strengthening'],
          'duration': 40,
          'status': 'Completed',
        },
        {
          'id': 'N004',
          'patientName': 'Emily Davis',
          'patientId': 'P004',
          'date': '2024-01-13',
          'sessionType': 'Ankle Rehabilitation',
          'notes': 'Excellent progress! Patient has regained full range of motion. Ready for discharge planning.',
          'exercises': ['Ankle Circles', 'Calf Raises', 'Balance Exercises'],
          'duration': 35,
          'status': 'Completed',
        },
      ];
      _filteredNotes = List.from(_sessionNotes);
      _isLoading = false;
    });
  }

  void _filterNotes(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredNotes = List.from(_sessionNotes);
      } else {
        _filteredNotes = _sessionNotes.where((note) {
          return note['patientName'].toLowerCase().contains(query.toLowerCase()) ||
                 note['sessionType'].toLowerCase().contains(query.toLowerCase()) ||
                 note['notes'].toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.themeProvider.backgroundColor,
      appBar: AppBar(
        backgroundColor: widget.themeProvider.cardColor,
        elevation: 0,
        title: Text(
          'Session Notes',
          style: TextStyle(color: widget.themeProvider.primaryColor),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: widget.themeProvider.primaryColor),
            onPressed: _addNewNote,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: widget.themeProvider.primaryColor,
                ),
              )
            : Column(
                children: [
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterNotes,
                      decoration: InputDecoration(
                        hintText: 'Search notes...',
                        hintStyle: TextStyle(color: widget.themeProvider.subtextColor),
                        prefixIcon: Icon(Icons.search, color: widget.themeProvider.primaryColor),
                        filled: true,
                        fillColor: widget.themeProvider.cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  // Notes List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredNotes.length,
                      itemBuilder: (context, index) {
                        final note = _filteredNotes[index];
                        return _buildNoteCard(note);
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildNoteCard(Map<String, dynamic> note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.themeProvider.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.themeProvider.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note['patientName'],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.themeProvider.textColor,
                    ),
                  ),
                  Text(
                    'ID: ${note['patientId']} | ${note['date']}',
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.themeProvider.subtextColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  note['status'],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: widget.themeProvider.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              note['sessionType'],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: widget.themeProvider.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Duration: ${note['duration']} minutes',
            style: TextStyle(
              fontSize: 14,
              color: widget.themeProvider.subtextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Notes:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: widget.themeProvider.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            note['notes'],
            style: TextStyle(
              fontSize: 14,
              color: widget.themeProvider.textColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Exercises Performed:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: widget.themeProvider.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: (note['exercises'] as List).map((exercise) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: widget.themeProvider.backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: widget.themeProvider.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Text(
                exercise,
                style: TextStyle(
                  fontSize: 12,
                  color: widget.themeProvider.textColor,
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _editNote(note),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: widget.themeProvider.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: BorderSide(color: widget.themeProvider.primaryColor),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _viewFullNote(note),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View Full'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.themeProvider.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _addNewNote() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Session Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Patient Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Session Type',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Session note added successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _editNote(Map<String, dynamic> note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Note - ${note['patientName']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Notes',
                border: const OutlineInputBorder(),
                hintText: note['notes'],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Note updated for ${note['patientName']}'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _viewFullNote(Map<String, dynamic> note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${note['patientName']} - Session Note'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Patient ID: ${note['patientId']}'),
              Text('Date: ${note['date']}'),
              Text('Session Type: ${note['sessionType']}'),
              Text('Duration: ${note['duration']} minutes'),
              const SizedBox(height: 16),
              const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(note['notes']),
              const SizedBox(height: 16),
              const Text('Exercises Performed:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...(note['exercises'] as List).map((exercise) => Text('• $exercise')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
