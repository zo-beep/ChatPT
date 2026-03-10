import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo_app/main.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
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
          .get();

      _patients = snapshot.docs.map((d) {
        final data = d.data();
        data['uid'] = d.id;
        return data;
      }).where((user) => user['role'] != 'doctor').toList();
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

  final regular = await PdfGoogleFonts.nunitoRegular();
  final bold = await PdfGoogleFonts.nunitoBold();
  final light = await PdfGoogleFonts.nunitoLight();

  const primaryColor = PdfColor.fromInt(0xFF4E80FF);
  const accentColor = PdfColor.fromInt(0xFF90CAF9);
  const darkGrey = PdfColor.fromInt(0xFF37474F);
  const lightGrey = PdfColor.fromInt(0xFFF5F5F5);
  const white = PdfColors.white;

  String formatField(dynamic val) =>
      (val != null && val.toString().isNotEmpty) ? val.toString() : '-';

  final fields = [
    {'label': 'Full Name',       'value': formatField(p['name'])},
    {'label': 'Email Address',   'value': formatField(p['email'])},
    {'label': 'Contact Number',  'value': formatField(p['contactNumber'])},
    {'label': 'Age',             'value': formatField(p['age'])},
    {'label': 'Gender',          'value': formatField(p['gender'])},
    {'label': 'Diagnosis',       'value': formatField(p['diagnosis'])},
    {'label': 'Medications',     'value': formatField(p['medications'])},
    {'label': 'Assigned Doctor', 'value': formatField(p['assignedDoctor'])},
  ];

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(0),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [

          // ── Header Banner ───────────────────────────────────────
          pw.Container(
            color: primaryColor,
            padding: const pw.EdgeInsets.fromLTRB(32, 24, 32, 0),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Top row: Logo left, CONFIDENTIAL badge right
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // ChatPT Logo block
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(
                          width: 42,
                          height: 42,
                          decoration: pw.BoxDecoration(
                            color: white,
                            borderRadius: pw.BorderRadius.circular(10),
                          ),
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            'PT',
                            style: pw.TextStyle(
                              font: bold,
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 10),
                        pw.Text(
                          'ChatPT',
                          style: pw.TextStyle(
                            font: bold,
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: white,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),

                    // CONFIDENTIAL badge
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: pw.BoxDecoration(
                        color: white,
                        borderRadius: pw.BorderRadius.circular(4),
                        border: pw.Border.all(
                          color: PdfColor.fromInt(0x66FFFFFF),
                          width: 0.8,
                        ),
                      ),
                      child: pw.Text(
                        'CONFIDENTIAL',
                        style: pw.TextStyle(
                          font: bold,
                          fontSize: 8,
                          color: primaryColor,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 20),

                // Divider
                pw.Container(height: 0.8, color: PdfColor.fromInt(0x66FFFFFF)),
                pw.SizedBox(height: 14),

                // Patient label + name + UID
                pw.Text(
                  'PATIENT RECORD',
                  style: pw.TextStyle(
                    font: regular,
                    fontSize: 9,
                    color: accentColor,
                    letterSpacing: 2,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  formatField(p['name']),
                  style: pw.TextStyle(
                    font: bold,
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: white,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'UID: ${formatField(p['uid'])}',
                  style: pw.TextStyle(
                    font: regular,
                    fontSize: 8,
                    color: PdfColor.fromInt(0xB3FFFFFF),
                  ),
                ),
                pw.SizedBox(height: 20),
              ],
            ),
          ),

          // ── Accent strip ───────────────────────────────────────
          pw.Container(
            height: 4,
            color: accentColor,
          ),

          // ── Body ───────────────────────────────────────────────
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Section label with left bar accent
                  pw.Row(
                    children: [
                      pw.Container(width: 4, height: 16, color: primaryColor),
                      pw.SizedBox(width: 8),
                      pw.Text(
                        'Patient Information',
                        style: pw.TextStyle(
                          font: bold,
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          color: darkGrey,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 12),

                  // ── Info Table ────────────────────────────────
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(1.3),
                      1: const pw.FlexColumnWidth(2.5),
                    },
                    children: fields.asMap().entries.map((entry) {
                      final isEven = entry.key.isEven;
                      final field = entry.value;
                      return pw.TableRow(
                        decoration: pw.BoxDecoration(
                          color: isEven ? lightGrey : PdfColors.white,
                        ),
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 12, vertical: 9),
                            child: pw.Text(
                              field['label']!,
                              style: pw.TextStyle(
                                font: bold,
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: darkGrey,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 12, vertical: 9),
                            child: pw.Text(
                              field['value']!,
                              style: pw.TextStyle(
                                font: regular,
                                fontSize: 10,
                                color: PdfColors.black,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          // ── Footer ─────────────────────────────────────────────
          pw.Container(
            color: darkGrey,
            padding: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    pw.Text(
                      'ChatPT',
                      style: pw.TextStyle(
                        font: bold,
                        fontSize: 9,
                        color: accentColor,
                      ),
                    ),
                    pw.Text(
                      '  |  For authorized personnel only',
                      style: pw.TextStyle(
                        font: light,
                        fontSize: 8,
                        color: PdfColor.fromInt(0xB3FFFFFF),
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  'Generated: ${DateTime.now().toString().substring(0, 16)}',
                  style: pw.TextStyle(
                    font: regular,
                    fontSize: 8,
                    color: PdfColor.fromInt(0xB3FFFFFF),
                  ),
                ),
              ],
            ),
          ),
        ],
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
