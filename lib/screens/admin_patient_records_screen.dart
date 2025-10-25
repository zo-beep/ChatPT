import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo_app/main.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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

  Future<void> _deletePatient(String uid) async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      await _loadPatients();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Patient deleted'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete patient: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
        setState(() => _isLoading = false);
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
                  ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
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
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: theme.textColor),
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
                                            onPressed: () => _showPatientDetails(p),
                                            child: Text('View', style: TextStyle(color: theme.primaryColor)),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: Icon(Icons.delete_forever, color: Colors.red.shade700),
                                            tooltip: 'Delete patient',
                                            onPressed: () async {
                                              final confirmed = await showDialog<bool>(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: const Text('Confirm delete'),
                                                  content: Text(
                                                      'Delete patient "${p['name'] ?? 'this patient'}"? This cannot be undone.'),
                                                  actions: [
                                                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                                                    ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
                                                  ],
                                                ),
                                              );
                                              if (confirmed == true) {
                                                final uid = p['uid'];
                                                if (uid != null) {
                                                  await _deletePatient(uid.toString());
                                                }
                                              }
                                            },
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
            ElevatedButton.icon(
              onPressed: () async => _printPatientRecord(p),
              icon: const Icon(Icons.print, size: 18),
              label: const Text('Print Record'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _printPatientRecord(Map<String, dynamic> p) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Padding(
          padding: const pw.EdgeInsets.all(20),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Patient Record',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text('Name: ${p['name'] ?? '—'}'),
              pw.Text('Email: ${p['email'] ?? '—'}'),
              pw.Text('Contact: ${p['contactNumber'] ?? '—'}'),
              pw.Text('Age: ${p['age']?.toString() ?? '—'}'),
              pw.Text('Gender: ${p['gender'] ?? '—'}'),
              pw.Text('Diagnosis: ${p['diagnosis'] ?? '—'}'),
              pw.Text('Medications: ${p['medications'] ?? '—'}'),
              pw.Text('Assigned Doctor: ${p['assignedDoctor'] ?? '—'}'),
              pw.SizedBox(height: 30),
              pw.Text('Generated on: ${DateTime.now()}',
                  style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
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
