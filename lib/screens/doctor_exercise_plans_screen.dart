import 'package:flutter/material.dart';
import 'package:demo_app/main.dart';

class DoctorExercisePlansScreen extends StatefulWidget {
  final ThemeProvider themeProvider;

  const DoctorExercisePlansScreen({super.key, required this.themeProvider});

  @override
  State<DoctorExercisePlansScreen> createState() => _DoctorExercisePlansScreenState();
}

class _DoctorExercisePlansScreenState extends State<DoctorExercisePlansScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _exercisePlans = [];
  List<Map<String, dynamic>> _filteredPlans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExercisePlans();
  }

  Future<void> _loadExercisePlans() async {
    // Mock exercise plans data
    setState(() {
      _exercisePlans = [
        {
          'id': 'EP001',
          'patientName': 'John Smith',
          'patientId': 'P001',
          'planName': 'Knee Rehabilitation Program',
          'diagnosis': 'Post-surgical knee recovery',
          'exercises': [
            {
              'name': 'Lateral Pendulum',
              'sets': 3,
              'reps': 10,
              'duration': '5 minutes',
              'difficulty': 'Easy',
            },
            {
              'name': 'Basic Hamstring Stretch',
              'sets': 2,
              'reps': 15,
              'duration': '3 minutes',
              'difficulty': 'Easy',
            },
            {
              'name': 'Quad Strengthening',
              'sets': 3,
              'reps': 12,
              'duration': '8 minutes',
              'difficulty': 'Medium',
            },
          ],
          'frequency': 'Daily',
          'duration': '6 weeks',
          'status': 'Active',
          'lastModified': '2024-01-15',
        },
        {
          'id': 'EP002',
          'patientName': 'Sarah Johnson',
          'patientId': 'P002',
          'planName': 'Shoulder Recovery Plan',
          'diagnosis': 'Rotator cuff injury',
          'exercises': [
            {
              'name': 'Shoulder Rolls',
              'sets': 2,
              'reps': 10,
              'duration': '3 minutes',
              'difficulty': 'Easy',
            },
            {
              'name': 'Pendulum Exercises',
              'sets': 3,
              'reps': 8,
              'duration': '5 minutes',
              'difficulty': 'Easy',
            },
            {
              'name': 'Wall Slides',
              'sets': 2,
              'reps': 12,
              'duration': '6 minutes',
              'difficulty': 'Medium',
            },
          ],
          'frequency': 'Twice daily',
          'duration': '8 weeks',
          'status': 'Active',
          'lastModified': '2024-01-14',
        },
        {
          'id': 'EP003',
          'patientName': 'Mike Wilson',
          'patientId': 'P003',
          'planName': 'Back Pain Management',
          'diagnosis': 'Chronic lower back pain',
          'exercises': [
            {
              'name': 'Cat-Cow Stretch',
              'sets': 2,
              'reps': 10,
              'duration': '4 minutes',
              'difficulty': 'Easy',
            },
            {
              'name': 'Pelvic Tilts',
              'sets': 3,
              'reps': 15,
              'duration': '5 minutes',
              'difficulty': 'Easy',
            },
            {
              'name': 'Core Strengthening',
              'sets': 2,
              'reps': 8,
              'duration': '6 minutes',
              'difficulty': 'Medium',
            },
          ],
          'frequency': 'Daily',
          'duration': '12 weeks',
          'status': 'Active',
          'lastModified': '2024-01-12',
        },
        {
          'id': 'EP004',
          'patientName': 'Emily Davis',
          'patientId': 'P004',
          'planName': 'Ankle Rehabilitation',
          'diagnosis': 'Ankle sprain recovery',
          'exercises': [
            {
              'name': 'Ankle Circles',
              'sets': 2,
              'reps': 15,
              'duration': '3 minutes',
              'difficulty': 'Easy',
            },
            {
              'name': 'Calf Raises',
              'sets': 3,
              'reps': 12,
              'duration': '4 minutes',
              'difficulty': 'Easy',
            },
            {
              'name': 'Balance Exercises',
              'sets': 2,
              'reps': 10,
              'duration': '5 minutes',
              'difficulty': 'Medium',
            },
          ],
          'frequency': 'Daily',
          'duration': '4 weeks',
          'status': 'Completed',
          'lastModified': '2024-01-13',
        },
      ];
      _filteredPlans = List.from(_exercisePlans);
      _isLoading = false;
    });
  }

  void _filterPlans(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPlans = List.from(_exercisePlans);
      } else {
        _filteredPlans = _exercisePlans.where((plan) {
          return plan['patientName'].toLowerCase().contains(query.toLowerCase()) ||
                 plan['planName'].toLowerCase().contains(query.toLowerCase()) ||
                 plan['diagnosis'].toLowerCase().contains(query.toLowerCase());
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
          'Exercise Plans',
          style: TextStyle(color: widget.themeProvider.primaryColor),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: widget.themeProvider.primaryColor),
            onPressed: _addNewPlan,
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
                      onChanged: _filterPlans,
                      decoration: InputDecoration(
                        hintText: 'Search exercise plans...',
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
                  // Plans List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredPlans.length,
                      itemBuilder: (context, index) {
                        final plan = _filteredPlans[index];
                        return _buildPlanCard(plan);
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.themeProvider.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(plan['status']).withOpacity(0.3),
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
                    plan['patientName'],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.themeProvider.textColor,
                    ),
                  ),
                  Text(
                    'ID: ${plan['patientId']}',
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
                  color: _getStatusColor(plan['status']).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  plan['status'],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(plan['status']),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            plan['planName'],
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: widget.themeProvider.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Diagnosis: ${plan['diagnosis']}',
            style: TextStyle(
              fontSize: 14,
              color: widget.themeProvider.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: widget.themeProvider.subtextColor),
              const SizedBox(width: 4),
              Text(
                '${plan['frequency']} • ${plan['duration']}',
                style: TextStyle(
                  fontSize: 14,
                  color: widget.themeProvider.subtextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Exercises (${(plan['exercises'] as List).length}):',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: widget.themeProvider.textColor,
            ),
          ),
          const SizedBox(height: 8),
          ...(plan['exercises'] as List).take(2).map((exercise) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Text(
                  '• ${exercise['name']}',
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.themeProvider.textColor,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(exercise['difficulty']).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    exercise['difficulty'],
                    style: TextStyle(
                      fontSize: 10,
                      color: _getDifficultyColor(exercise['difficulty']),
                    ),
                  ),
                ),
              ],
            ),
          )),
          if ((plan['exercises'] as List).length > 2)
            Text(
              '... and ${(plan['exercises'] as List).length - 2} more',
              style: TextStyle(
                fontSize: 12,
                color: widget.themeProvider.subtextColor,
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _editPlan(plan),
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
                  onPressed: () => _viewFullPlan(plan),
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'paused':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _addNewPlan() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Exercise Plan'),
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
                labelText: 'Plan Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Diagnosis',
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
                  content: Text('Exercise plan created successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _editPlan(Map<String, dynamic> plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Plan - ${plan['patientName']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Plan Name',
                border: const OutlineInputBorder(),
                hintText: plan['planName'],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Frequency',
                border: const OutlineInputBorder(),
                hintText: plan['frequency'],
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
                  content: Text('Plan updated for ${plan['patientName']}'),
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

  void _viewFullPlan(Map<String, dynamic> plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${plan['patientName']} - Exercise Plan'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Patient ID: ${plan['patientId']}'),
              Text('Plan: ${plan['planName']}'),
              Text('Diagnosis: ${plan['diagnosis']}'),
              Text('Frequency: ${plan['frequency']}'),
              Text('Duration: ${plan['duration']}'),
              Text('Status: ${plan['status']}'),
              Text('Last Modified: ${plan['lastModified']}'),
              const SizedBox(height: 16),
              const Text('Exercises:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...(plan['exercises'] as List).map((exercise) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.themeProvider.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.themeProvider.primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Sets: ${exercise['sets']} | Reps: ${exercise['reps']}'),
                    Text('Duration: ${exercise['duration']}'),
                    Text('Difficulty: ${exercise['difficulty']}'),
                  ],
                ),
              )),
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
