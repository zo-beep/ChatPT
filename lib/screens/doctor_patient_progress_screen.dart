import 'package:flutter/material.dart';
import 'package:demo_app/main.dart';

class DoctorPatientProgressScreen extends StatefulWidget {
  final ThemeProvider themeProvider;

  const DoctorPatientProgressScreen({super.key, required this.themeProvider});

  @override
  State<DoctorPatientProgressScreen> createState() => _DoctorPatientProgressScreenState();
}

class _DoctorPatientProgressScreenState extends State<DoctorPatientProgressScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _filteredPatients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    // Mock patient data
    setState(() {
      _patients = [
        {
          'id': 'P001',
          'name': 'John Smith',
          'age': 45,
          'diagnosis': 'Knee Rehabilitation',
          'progress': 75,
          'lastSession': '2024-01-15',
          'nextAppointment': '2024-01-20',
          'status': 'Active',
        },
        {
          'id': 'P002',
          'name': 'Sarah Johnson',
          'age': 38,
          'diagnosis': 'Shoulder Recovery',
          'progress': 60,
          'lastSession': '2024-01-14',
          'nextAppointment': '2024-01-18',
          'status': 'Active',
        },
        {
          'id': 'P003',
          'name': 'Mike Wilson',
          'age': 52,
          'diagnosis': 'Back Pain Management',
          'progress': 40,
          'lastSession': '2024-01-12',
          'nextAppointment': '2024-01-19',
          'status': 'Active',
        },
        {
          'id': 'P004',
          'name': 'Emily Davis',
          'age': 29,
          'diagnosis': 'Ankle Rehabilitation',
          'progress': 90,
          'lastSession': '2024-01-13',
          'nextAppointment': '2024-01-22',
          'status': 'Active',
        },
      ];
      _filteredPatients = List.from(_patients);
      _isLoading = false;
    });
  }

  void _filterPatients(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPatients = List.from(_patients);
      } else {
        _filteredPatients = _patients.where((patient) {
          return patient['name'].toLowerCase().contains(query.toLowerCase()) ||
                 patient['diagnosis'].toLowerCase().contains(query.toLowerCase()) ||
                 patient['id'].toLowerCase().contains(query.toLowerCase());
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
          'Patient Progress',
          style: TextStyle(color: widget.themeProvider.primaryColor),
        ),
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
                      onChanged: _filterPatients,
                      decoration: InputDecoration(
                        hintText: 'Search patients...',
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
                  // Patient List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredPatients.length,
                      itemBuilder: (context, index) {
                        final patient = _filteredPatients[index];
                        return _buildPatientCard(patient);
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
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
                    patient['name'],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.themeProvider.textColor,
                    ),
                  ),
                  Text(
                    'ID: ${patient['id']} | Age: ${patient['age']}',
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
                  color: _getStatusColor(patient['status']).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  patient['status'],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(patient['status']),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Diagnosis: ${patient['diagnosis']}',
            style: TextStyle(
              fontSize: 14,
              color: widget.themeProvider.textColor,
            ),
          ),
          const SizedBox(height: 8),
          // Progress Bar
          Row(
            children: [
              Text(
                'Progress: ',
                style: TextStyle(
                  fontSize: 14,
                  color: widget.themeProvider.subtextColor,
                ),
              ),
              Expanded(
                child: LinearProgressIndicator(
                  value: patient['progress'] / 100,
                  backgroundColor: widget.themeProvider.backgroundColor,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.themeProvider.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${patient['progress']}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: widget.themeProvider.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last Session',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.themeProvider.subtextColor,
                    ),
                  ),
                  Text(
                    patient['lastSession'],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: widget.themeProvider.textColor,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Next Appointment',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.themeProvider.subtextColor,
                    ),
                  ),
                  Text(
                    patient['nextAppointment'],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: widget.themeProvider.textColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _viewDetailedProgress(patient),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View Details'),
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
                  onPressed: () => _addSessionNote(patient),
                  icon: const Icon(Icons.note_add, size: 16),
                  label: const Text('Add Note'),
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _viewDetailedProgress(Map<String, dynamic> patient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${patient['name']} - Detailed Progress'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Patient ID: ${patient['id']}'),
            Text('Age: ${patient['age']}'),
            Text('Diagnosis: ${patient['diagnosis']}'),
            Text('Progress: ${patient['progress']}%'),
            Text('Last Session: ${patient['lastSession']}'),
            Text('Next Appointment: ${patient['nextAppointment']}'),
          ],
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

  void _addSessionNote(Map<String, dynamic> patient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Session Note - ${patient['name']}'),
        content: const TextField(
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Enter session notes...',
            border: OutlineInputBorder(),
          ),
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
                  content: Text('Note added for ${patient['name']}'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Save'),
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
