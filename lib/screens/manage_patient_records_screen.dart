import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo_app/main.dart';

class ManagePatientRecordsScreen extends StatefulWidget {
  final ThemeProvider themeProvider;
  final Map<String, dynamic>? specificPatient;
  
  const ManagePatientRecordsScreen({
    super.key, 
    required this.themeProvider,
    this.specificPatient,
  });

  @override
  State<ManagePatientRecordsScreen> createState() => _ManagePatientRecordsScreenState();
}

class _ManagePatientRecordsScreenState extends State<ManagePatientRecordsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  bool _loadingUsers = true;
  
  // Sorting and filtering state
  String _sortBy = 'name'; // 'name' or 'recent'
  String _filterDoctor = 'all';
  String _filterStatus = 'all'; // 'all', 'active', 'completed'
  bool _showSortFilter = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _loadingUsers = true);
    try {
      // Query users and order by name by default for consistent initial load
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('name')
          .limit(200)
          .get();
      
      _users = snap.docs.map((d) {
        final data = d.data();
        return {
          'id': d.id,
          'name': data['name'] ?? '',
          'email': data['email'] ?? '',
          'patientId': data['patientId'] ?? '',
          'assignedDoctor': data['assignedDoctor'] ?? '',
          'therapyStartDate': data['therapyStartDate'] ?? '',
          // Include other fields needed for filtering/display
          ...data,
        };
      }).where((user) => user['role'] != 'doctor').toList();
      
      // Initial sort by name
      _users.sort((a, b) => (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));
      
    } catch (e) {
      print('Failed to load users for records: $e');
      _users = [];
    }
    setState(() => _loadingUsers = false);
  }

  List<Map<String, dynamic>> get _filteredUsers {
    var filtered = _users;
    
    // Apply search filter
    final q = _searchController.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      filtered = filtered.where((u) {
        final name = (u['name'] ?? '').toString().toLowerCase();
        final email = (u['email'] ?? '').toString().toLowerCase();
        final id = (u['patientId'] ?? u['id'] ?? '').toString().toLowerCase();
        return name.contains(q) || email.contains(q) || id.contains(q);
      }).toList();
    }
    
    // Apply doctor filter
    if (_filterDoctor != 'all') {
      filtered = filtered.where((u) => 
        (u['assignedDoctor'] ?? '').toString().toLowerCase() == _filterDoctor.toLowerCase()
      ).toList();
    }
    
    // Apply status filter
    if (_filterStatus != 'all') {
      final isActive = _filterStatus == 'active';
      filtered = filtered.where((u) {
        final hasTherapyDate = (u['therapyStartDate'] ?? '').toString().isNotEmpty;
        return isActive ? hasTherapyDate : !hasTherapyDate;
      }).toList();
    }
    
    // Apply sorting
    filtered.sort((a, b) {
      if (_sortBy == 'recent') {
        final dateA = (a['therapyStartDate'] ?? '').toString();
        final dateB = (b['therapyStartDate'] ?? '').toString();
        return dateB.compareTo(dateA); // Most recent first
      } else {
        // Sort by name
        final nameA = (a['name'] ?? '').toString().toLowerCase();
        final nameB = (b['name'] ?? '').toString().toLowerCase();
        return nameA.compareTo(nameB);
      }
    });
    
    return filtered;
  }

  void _openRecordEditor(Map<String, dynamic> user) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => _PatientRecordEditor(user: user, themeProvider: widget.themeProvider)),
    );
    await _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.themeProvider;
    
    // If a specific patient is provided, navigate directly to their record editor
    if (widget.specificPatient != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => _PatientRecordEditor(
              user: widget.specificPatient!,
              themeProvider: widget.themeProvider,
            ),
          ),
        );
      });
      return Scaffold(
        backgroundColor: theme.backgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Patient Records'),
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
                    'Search patients and edit their medical records',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.subtextColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
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
                              hintText: 'Search patients... (name, email, id)',
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
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          _showSortFilter ? Icons.filter_list_off : Icons.filter_list,
                          color: theme.primaryColor,
                        ),
                        onPressed: () => setState(() => _showSortFilter = !_showSortFilter),
                        tooltip: 'Show/Hide Filters',
                      ),
                    ],
                  ),
                  if (_showSortFilter) ...[
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Sort options
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: theme.backgroundColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: theme.primaryColor.withOpacity(0.1)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _sortBy,
                                icon: Icon(Icons.sort, color: theme.primaryColor, size: 16),
                                style: TextStyle(color: theme.textColor, fontSize: 14),
                                dropdownColor: theme.backgroundColor,
                                items: [
                                  DropdownMenuItem(value: 'name', child: Text('Sort by Name')),
                                  DropdownMenuItem(value: 'recent', child: Text('Sort by Recent')),
                                ],
                                onChanged: (value) => setState(() => _sortBy = value!),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Doctor filter
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: theme.backgroundColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: theme.primaryColor.withOpacity(0.1)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _filterDoctor,
                                icon: Icon(Icons.person, color: theme.primaryColor, size: 16),
                                style: TextStyle(color: theme.textColor, fontSize: 14),
                                dropdownColor: theme.backgroundColor,
                                items: [
                                  DropdownMenuItem(value: 'all', child: Text('All Doctors')),
                                  ...Set.from(_users.map((u) => u['assignedDoctor'] ?? ''))
                                      .where((d) => d.isNotEmpty)
                                      .map((d) => DropdownMenuItem(value: d, child: Text(d))),
                                ],
                                onChanged: (value) => setState(() => _filterDoctor = value!),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Status filter
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: theme.backgroundColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: theme.primaryColor.withOpacity(0.1)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _filterStatus,
                                icon: Icon(Icons.event_note, color: theme.primaryColor, size: 16),
                                style: TextStyle(color: theme.textColor, fontSize: 14),
                                dropdownColor: theme.backgroundColor,
                                items: [
                                  DropdownMenuItem(value: 'all', child: Text('All Status')),
                                  DropdownMenuItem(value: 'active', child: Text('Active Therapy')),
                                  DropdownMenuItem(value: 'completed', child: Text('No Therapy')),
                                ],
                                onChanged: (value) => setState(() => _filterStatus = value!),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: _loadingUsers
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                      ),
                    )
                  : _filteredUsers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 64, color: theme.subtextColor),
                              const SizedBox(height: 16),
                              Text('No patients found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: theme.textColor)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, i) {
                            final u = _filteredUsers[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: theme.primaryColor.withOpacity(0.1)),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _openRecordEditor(u),
                                  borderRadius: BorderRadius.circular(12),
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
                                            child: Text((u['name'] ?? u['email'] ?? 'U')[0].toString().toUpperCase(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.primaryColor)),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(u['name'] ?? u['email'] ?? 'Unknown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textColor)),
                                              const SizedBox(height: 4),
                                              Text(u['email'] ?? '', style: TextStyle(fontSize: 14, color: theme.subtextColor)),
                                            ],
                                          ),
                                        ),
                                        Icon(Icons.arrow_forward_ios, size: 14, color: theme.primaryColor),
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

class _PatientRecordEditor extends StatefulWidget {
  final Map<String, dynamic> user;
  final ThemeProvider themeProvider;
  const _PatientRecordEditor({required this.user, required this.themeProvider});

  @override
  State<_PatientRecordEditor> createState() => _PatientRecordEditorState();
}

class _PatientRecordEditorState extends State<_PatientRecordEditor> {
  late TextEditingController _diagnosisC;
  late TextEditingController _medicationsC;
  late TextEditingController _assignedDoctorC;
  late TextEditingController _therapyStartDateC;
  late TextEditingController _heightC;
  late TextEditingController _weightC;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _diagnosisC = TextEditingController(text: u['diagnosis'] ?? '');
    _medicationsC = TextEditingController(text: u['medications'] ?? '');
    _assignedDoctorC = TextEditingController(text: u['assignedDoctor'] ?? '');
    _therapyStartDateC = TextEditingController(text: u['therapyStartDate'] ?? '');
    _heightC = TextEditingController(text: u['height'] ?? '');
    _weightC = TextEditingController(text: u['weight'] ?? '');
  }

  @override
  void dispose() {
    _diagnosisC.dispose();
    _medicationsC.dispose();
    _assignedDoctorC.dispose();
    _therapyStartDateC.dispose();
    _heightC.dispose();
    _weightC.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final userId = widget.user['id'] ?? widget.user['patientId'];
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Missing user id')));
      setState(() => _isSaving = false);
      return;
    }

    final data = {
      'diagnosis': _diagnosisC.text.trim(),
      'medications': _medicationsC.text.trim(),
      'assignedDoctor': _assignedDoctorC.text.trim(),
      'therapyStartDate': _therapyStartDateC.text.trim(),
      'height': _heightC.text.trim(),
      'weight': _weightC.text.trim(),
    };

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set(data, SetOptions(merge: true));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Patient record saved'), backgroundColor: Colors.green));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.themeProvider;
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.user['name'] ?? 'Patient Record',
          style: TextStyle(
            color: theme.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: theme.cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: TextButton.icon(
            onPressed: _isSaving ? null : _save,
              icon: _isSaving 
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.subtextColor,
                      ),
                    )
                  : Icon(
                      Icons.save_rounded,
                      color: theme.primaryColor,
                      size: 20,
                    ),
              label: Text(
                'Save',
                style: TextStyle(
                  color: _isSaving ? theme.subtextColor : theme.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: theme.primaryColor.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.cardColor,
                      theme.cardColor.withOpacity(0.95),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.primaryColor.withOpacity(0.15),
                            theme.primaryColor.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.primaryColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.medical_services_rounded,
                        size: 24,
                        color: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Medical Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Update patient medical details',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.subtextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Form fields
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildEditableInfoRow(
                      'Diagnosis / Disability',
                      _diagnosisC,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter diagnosis';
                        return null;
                      },
                    ),
                    _buildDivider(theme),
                    
                    _buildEditableInfoRow(
                      'Medications',
                      _medicationsC,
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter medications';
                        return null;
                      },
                    ),
                    _buildDivider(theme),
                    
                    _buildEditableInfoRow(
                      'Assigned Doctor',
                      _assignedDoctorC,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter assigned doctor';
                        return null;
                      },
                    ),
                    _buildDivider(theme),
                    
                    _buildDatePickerRow(
                      'Therapy Start Date',
                      _therapyStartDateC,
                      theme: theme,
                    ),
                    _buildDivider(theme),
                    
                    // Height and Weight row
                    Row(
                      children: [
                        Expanded(
                          child: _buildEditableInfoRow(
                            'Height (cm)',
                            _heightC,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter height';
                              if (double.tryParse(value) == null) return 'Please enter a valid number';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildEditableInfoRow(
                            'Weight (kg)',
                            _weightC,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter weight';
                              if (double.tryParse(value) == null) return 'Please enter a valid number';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.subtextColor.withOpacity(0.1),
                            theme.subtextColor.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.subtextColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.close_rounded,
                                color: theme.subtextColor,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: theme.subtextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.primaryColor.withOpacity(0.1),
                            theme.primaryColor.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.primaryColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isSaving ? null : _save,
                          borderRadius: BorderRadius.circular(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _isSaving
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: theme.primaryColor,
                                      ),
                                    )
                                  : Icon(
                                      Icons.save_rounded,
                                      color: theme.primaryColor,
                                      size: 18,
                                    ),
                              const SizedBox(width: 8),
                              Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: theme.primaryColor,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditableInfoRow(String label, TextEditingController controller, {String? Function(String?)? validator, TextInputType? keyboardType, int maxLines = 1}) {
    final theme = widget.themeProvider;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              validator: validator,
              keyboardType: keyboardType,
              maxLines: maxLines,
              style: TextStyle(
                fontSize: 14,
                color: theme.textColor,
              ),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.primaryColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.primaryColor.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.primaryColor),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                errorStyle: const TextStyle(color: Colors.red),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerRow(String label, TextEditingController controller, {required ThemeProvider theme}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => _selectDate(),
              child: InputDecorator(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.primaryColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.primaryColor.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.primaryColor),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  suffixIcon: Icon(Icons.calendar_today, color: theme.primaryColor),
                ),
                child: Text(
                  controller.text.isEmpty ? 'Select Date' : controller.text,
                  style: TextStyle(
                    fontSize: 14,
                    color: controller.text.isEmpty ? theme.subtextColor : theme.textColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(ThemeProvider theme) {
    return Divider(
      color: theme.cardColor.withOpacity(0.2),
      height: 1,
    );
  }

  Future<void> _selectDate() async {
    final theme = widget.themeProvider;
    final initialDate = DateTime.tryParse(_therapyStartDateC.text) ?? DateTime.now();
    
    try {
      final picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: theme.primaryColor,
                onPrimary: Colors.white,
                surface: theme.cardColor,
                onSurface: theme.textColor,
              ),
            ),
            child: child!,
          );
        },
      );
      
      if (picked != null) {
        _therapyStartDateC.text = "${picked.day}/${picked.month}/${picked.year}";
      }
    } catch (e) {
      print('Error selecting date: $e');
    }
  }
}
