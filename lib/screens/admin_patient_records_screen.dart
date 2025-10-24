import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo_app/main.dart';

class AdminPatientRecordsScreen extends StatefulWidget {
  final ThemeProvider themeProvider;
  const AdminPatientRecordsScreen({super.key, required this.themeProvider});

  @override
  State<AdminPatientRecordsScreen> createState() => _AdminPatientRecordsScreenState();
}

class _AdminPatientRecordsScreenState extends State<AdminPatientRecordsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _patients = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'patient')
          .get();

      _patients = snapshot.docs.map((d) {
        final data = d.data();
        data['uid'] = d.id;
        return data;
      }).toList();
    } catch (e) {
      _error = 'Failed to load patient records: $e';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.themeProvider;
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        elevation: 0,
        title: Text('Patient Records', style: TextStyle(color: theme.primaryColor)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
              : _error != null
                  ? Center(child: Text(_error!, style: TextStyle(color: Colors.red)))
                  : _patients.isEmpty
                      ? Center(child: Text('No patient records found', style: TextStyle(color: theme.subtextColor)))
                      : RefreshIndicator(
                          onRefresh: _loadPatients,
                          child: ListView.builder(
                            itemCount: _patients.length,
                            itemBuilder: (context, index) {
                              final p = _patients[index];
                              final name = p['name'] ?? '—';
                              final email = p['email'] ?? '—';
                              final contact = p['contactNumber'] ?? '—';
                              final age = p['age']?.toString() ?? '—';
                              final diagnosis = p['diagnosis'] ?? '—';

                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              name,
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textColor),
                                            ),
                                          ),
                                          Text(email, style: TextStyle(color: theme.subtextColor)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Text('Age: $age', style: TextStyle(color: theme.subtextColor)),
                                          const SizedBox(width: 12),
                                          Text('Contact: $contact', style: TextStyle(color: theme.subtextColor)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text('Diagnosis: $diagnosis', style: TextStyle(color: theme.subtextColor)),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton(
                                            onPressed: () {
                                              _showPatientDetails(p);
                                            },
                                            child: Text('View', style: TextStyle(color: theme.primaryColor)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
        ),
      ),
    );
  }

  void _showPatientDetails(Map<String, dynamic> p) {
    final theme = widget.themeProvider;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.cardColor,
          title: Text(p['name'] ?? 'Patient Details', style: TextStyle(color: theme.textColor)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('UID', p['uid'] ?? '—', theme),
                _detailRow('Email', p['email'] ?? '—', theme),
                _detailRow('Contact', p['contactNumber'] ?? '—', theme),
                _detailRow('Age', p['age']?.toString() ?? '—', theme),
                _detailRow('Gender', p['gender'] ?? '—', theme),
                _detailRow('Diagnosis', p['diagnosis'] ?? '—', theme),
                _detailRow('Medications', p['medications'] ?? '—', theme),
                _detailRow('Assigned Doctor', p['assignedDoctor'] ?? '—', theme),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', style: TextStyle(color: theme.primaryColor)),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value, ThemeProvider theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text('$label:', style: TextStyle(color: theme.subtextColor))),
          Expanded(child: Text(value, style: TextStyle(color: theme.textColor))),
        ],
      ),
    );
  }
}
