import 'package:flutter/material.dart';
import 'package:demo_app/main.dart';
import 'package:demo_app/screens/manage_patient_exercise_screen.dart';
import 'package:demo_app/screens/manage_patient_records_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// VIEW PATIENTS SCREEN - Modern patient dashboard
class ViewPatientsScreen extends StatefulWidget {
  final ThemeProvider themeProvider;

  const ViewPatientsScreen({super.key, required this.themeProvider});

  @override
  State<ViewPatientsScreen> createState() => _ViewPatientsScreenState();
}

class _ViewPatientsScreenState extends State<ViewPatientsScreen> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _patients = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';
  String _selectedSort = 'progress';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadPatients();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    setState(() => _isLoading = true);
    try {
      // Get all users except doctors
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .limit(100)
          .get();
      
      List<Map<String, dynamic>> patients = [];
      
      for (var doc in snap.docs) {
        final userData = doc.data();
        // Skip users with doctor role
        if (userData['role'] == 'doctor') continue;
        
        userData['uid'] = doc.id;
        
        // Get patient progress data
        final progressData = await _getPatientProgress(doc.id);
        patients.add({
          ...userData,
          ...progressData,
        });
      }
      
      setState(() {
        _patients = patients;
        _isLoading = false;
      });
    } catch (e) {
      print('Failed to load patients: $e');
      setState(() {
        _patients = [];
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _getPatientProgress(String patientId) async {
    try {
      // Get assigned exercises
      final assignedSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(patientId)
          .collection('assignedExercises')
          .get();

      final assignedExercises = assignedSnap.docs.map((d) => d.data()).toList();
      final totalExercises = assignedExercises.length;
      final completedExercises = assignedExercises.where((e) => e['completed'] == true).length;
      final progressPercentage = totalExercises > 0 
          ? ((completedExercises / totalExercises) * 100).round() 
          : 0;

      // Get exercise history for recent activity
      final historySnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(patientId)
          .collection('exerciseHistory')
          .orderBy('completedAt', descending: true)
          .limit(5)
          .get();

      final recentActivities = historySnap.docs.map((d) {
        final data = d.data();
        final completedAt = data['completedAt'] as Timestamp?;
        return {
          ...data,
          'completedAt': completedAt?.toDate(),
        };
      }).toList();

      // Calculate total exercise time
      final totalMinutes = recentActivities.fold<int>(
        0, (total, activity) => total + ((activity['duration'] ?? 0) as int));

      // Get last activity date
      final lastActivity = recentActivities.isNotEmpty 
          ? recentActivities.first['completedAt'] as DateTime?
          : null;

      return {
        'totalExercises': totalExercises,
        'completedExercises': completedExercises,
        'progressPercentage': progressPercentage,
        'recentActivities': recentActivities,
        'totalMinutes': totalMinutes,
        'lastActivity': lastActivity,
        'isActive': lastActivity != null && 
            DateTime.now().difference(lastActivity).inDays <= 7,
      };
    } catch (e) {
      print('Error getting patient progress: $e');
      return {
        'totalExercises': 0,
        'completedExercises': 0,
        'progressPercentage': 0,
        'recentActivities': [],
        'totalMinutes': 0,
        'lastActivity': null,
        'isActive': false,
      };
    }
  }

  List<Map<String, dynamic>> get _filteredPatients {
    var filtered = _patients;
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((patient) {
        final name = (patient['name'] ?? '').toString().toLowerCase();
        final email = (patient['email'] ?? '').toString().toLowerCase();
        final patientId = (patient['patientId'] ?? '').toString().toLowerCase();
        return name.contains(_searchQuery.toLowerCase()) ||
               email.contains(_searchQuery.toLowerCase()) ||
               patientId.contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    // Apply status filter
    if (_selectedFilter != 'all') {
      filtered = filtered.where((patient) {
        switch (_selectedFilter) {
          case 'active':
            return patient['isActive'] == true;
          case 'inactive':
            return patient['isActive'] == false;
          case 'high_progress':
            return patient['progressPercentage'] >= 80;
          case 'low_progress':
            return patient['progressPercentage'] < 30;
          default:
            return true;
        }
      }).toList();
    }
    
    // Apply sorting
    filtered.sort((a, b) {
      switch (_selectedSort) {
        case 'progress':
          return (b['progressPercentage'] ?? 0).compareTo(a['progressPercentage'] ?? 0);
        case 'name':
          return (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString());
        case 'recent':
          final dateA = a['lastActivity'] as DateTime?;
          final dateB = b['lastActivity'] as DateTime?;
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          return dateB.compareTo(dateA);
        case 'exercises':
          return (b['totalExercises'] ?? 0).compareTo(a['totalExercises'] ?? 0);
        default:
          return 0;
      }
    });
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = widget.themeProvider;
    final filteredPatients = _filteredPatients;

    return AnimatedBuilder(
      animation: themeProvider,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: themeProvider.backgroundColor,
          appBar: AppBar(
            backgroundColor: themeProvider.cardColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: themeProvider.primaryColor),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Patient Dashboard',
              style: TextStyle(
                color: themeProvider.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, color: themeProvider.primaryColor),
                onPressed: _loadPatients,
              ),
            ],
          ),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SafeArea(
                child: Column(
                  children: [
                    // Header with stats
                    _buildHeaderSection(themeProvider),
                    
                    // Search and filter controls
                    _buildControlsSection(themeProvider),
                    
                    // Patient list
                    Expanded(
                      child: _isLoading
                          ? Center(child: CircularProgressIndicator(color: themeProvider.primaryColor))
                          : filteredPatients.isEmpty
                              ? _buildEmptyState(themeProvider)
                              : _buildPatientList(themeProvider, filteredPatients),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderSection(ThemeProvider theme) {
    final totalPatients = _patients.length;
    final activePatients = _patients.where((p) => p['isActive'] == true).length;
    final avgProgress = _patients.isNotEmpty 
        ? _patients.fold<double>(0.0, (total, p) => total + (p['progressPercentage'] ?? 0).toDouble()) / _patients.length
        : 0.0;

    return Container(
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
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header title section
          Row(
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
                  borderRadius: BorderRadius.circular(14),
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
                      'Patient Dashboard',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Monitor patient progress',
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
          const SizedBox(height: 20),
          
          // Enhanced stats cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  theme,
                  'Total',
                  totalPatients.toString(),
                  Icons.people_rounded,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  theme,
                  'Active',
                  activePatients.toString(),
                  Icons.trending_up_rounded,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  theme,
                  'Avg Progress',
                  '${avgProgress.round()}%',
                  Icons.analytics_rounded,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(ThemeProvider theme, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.12),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: theme.subtextColor,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildControlsSection(ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Enhanced search bar
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.primaryColor.withOpacity(0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: TextStyle(
                fontSize: 14,
                color: theme.textColor,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Search patients...',
                hintStyle: TextStyle(
                  color: theme.subtextColor.withOpacity(0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.search_rounded,
                    color: theme.primaryColor,
                    size: 16,
                  ),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: theme.subtextColor,
                          size: 16,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Enhanced filter and sort controls
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(theme),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSortDropdown(theme),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.primaryColor.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFilter,
          isExpanded: true,
          icon: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.filter_list_rounded,
              color: theme.primaryColor,
              size: 14,
            ),
          ),
          style: TextStyle(
            color: theme.textColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          items: const [
            DropdownMenuItem(
              value: 'all',
              child: Text('All'),
            ),
            DropdownMenuItem(
              value: 'active',
              child: Text('Active'),
            ),
            DropdownMenuItem(
              value: 'inactive',
              child: Text('Inactive'),
            ),
            DropdownMenuItem(
              value: 'high_progress',
              child: Text('High Progress'),
            ),
            DropdownMenuItem(
              value: 'low_progress',
              child: Text('Low Progress'),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedFilter = value!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildSortDropdown(ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.primaryColor.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSort,
          isExpanded: true,
          icon: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.sort_rounded,
              color: theme.primaryColor,
              size: 14,
            ),
          ),
          style: TextStyle(
            color: theme.textColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          items: const [
            DropdownMenuItem(
              value: 'progress',
              child: Text('Progress'),
            ),
            DropdownMenuItem(
              value: 'name',
              child: Text('Name'),
            ),
            DropdownMenuItem(
              value: 'recent',
              child: Text('Recent'),
            ),
            DropdownMenuItem(
              value: 'exercises',
              child: Text('Exercises'),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedSort = value!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeProvider theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.primaryColor.withOpacity(0.1),
                    theme.primaryColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: theme.primaryColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.people_outline_rounded,
                size: 60,
                color: theme.primaryColor.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No patients found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Try adjusting your search criteria or filters to find patients',
              style: TextStyle(
                fontSize: 16,
                color: theme.subtextColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.primaryColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: theme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Patients will appear here once they are added to the system',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientList(ThemeProvider theme, List<Map<String, dynamic>> patients) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: patients.length,
      itemBuilder: (context, index) {
        final patient = patients[index];
        return _buildPatientCard(theme, patient);
      },
    );
  }

  Widget _buildPatientCard(ThemeProvider theme, Map<String, dynamic> patient) {
    final name = patient['name'] ?? 'Unknown Patient';
    final progress = patient['progressPercentage'] ?? 0;
    final totalExercises = patient['totalExercises'] ?? 0;
    final completedExercises = patient['completedExercises'] ?? 0;
    final lastActivity = patient['lastActivity'] as DateTime?;
    final isActive = patient['isActive'] ?? false;
    final totalMinutes = patient['totalMinutes'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive 
              ? Colors.green.withOpacity(0.2)
              : theme.primaryColor.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openPatientDetails(patient),
          borderRadius: BorderRadius.circular(16),
          splashColor: theme.primaryColor.withOpacity(0.1),
          highlightColor: theme.primaryColor.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with enhanced design
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
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
                      child: Center(
                        child: Text(
                          name.substring(0, 1).toUpperCase(),
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
                            name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            patient['email'] ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.subtextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isActive 
                              ? [Colors.green.withOpacity(0.15), Colors.green.withOpacity(0.05)]
                              : [Colors.grey.withOpacity(0.15), Colors.grey.withOpacity(0.05)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive 
                              ? Colors.green.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.green.shade700 : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Progress section with enhanced design
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.backgroundColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.primaryColor.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                              letterSpacing: -0.2,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$completedExercises/$totalExercises',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: theme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress / 100,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: progress >= 80 
                                    ? [Colors.green.shade400, Colors.green.shade600]
                                    : progress >= 50 
                                        ? [Colors.orange.shade400, Colors.orange.shade600]
                                        : [Colors.red.shade400, Colors.red.shade600],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$progress% Complete',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.textColor,
                            ),
                          ),
                          Text(
                            '${totalMinutes}m',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.subtextColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Last activity with improved styling
                if (lastActivity != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.subtextColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: theme.subtextColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Last: ${_formatDate(lastActivity)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.subtextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Action buttons with enhanced design
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.primaryColor.withOpacity(0.1),
                              theme.primaryColor.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: theme.primaryColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _openPatientExercises(patient),
                            borderRadius: BorderRadius.circular(10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.fitness_center_rounded,
                                  size: 16,
                                  color: theme.primaryColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Exercises',
                                  style: TextStyle(
                                    fontSize: 12,
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
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.primaryColor.withOpacity(0.1),
                              theme.primaryColor.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: theme.primaryColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _openPatientRecords(patient),
                            borderRadius: BorderRadius.circular(10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.folder_open_rounded,
                                  size: 16,
                                  color: theme.primaryColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Records',
                                  style: TextStyle(
                                    fontSize: 12,
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
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '$difference days ago';
    if (difference < 30) return '${(difference / 7).round()} weeks ago';
    return '${(difference / 30).round()} months ago';
  }

  void _openPatientDetails(Map<String, dynamic> patient) {
    // Navigate to detailed patient view
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _PatientDetailScreen(
          patient: patient,
          themeProvider: widget.themeProvider,
        ),
      ),
    );
  }

  void _openPatientExercises(Map<String, dynamic> patient) {
    // Navigate to exercise management for specific patient
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManagePatientExerciseScreen(
          themeProvider: widget.themeProvider,
          specificPatient: patient,
        ),
      ),
    );
  }

  void _openPatientRecords(Map<String, dynamic> patient) async {
    // Navigate to record management for specific patient
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManagePatientRecordsScreen(
          themeProvider: widget.themeProvider,
          specificPatient: patient,
        ),
      ),
    );
    
    // Refresh patient data when returning from record editor
    if (result == true) {
      await _loadPatients();
    }
  }
}

// Patient Detail Screen for detailed patient view
class _PatientDetailScreen extends StatefulWidget {
  final Map<String, dynamic> patient;
  final ThemeProvider themeProvider;

  const _PatientDetailScreen({
    required this.patient,
    required this.themeProvider,
  });

  @override
  State<_PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<_PatientDetailScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  List<Map<String, dynamic>> _recentActivities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
    _loadPatientDetails();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadPatientDetails() async {
    setState(() => _isLoading = true);
    try {
      final patientId = widget.patient['uid'];
      if (patientId != null) {
        final historySnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(patientId)
            .collection('exerciseHistory')
            .orderBy('completedAt', descending: true)
            .limit(10)
            .get();

        _recentActivities = historySnap.docs.map((d) {
          final data = d.data();
          final completedAt = data['completedAt'] as Timestamp?;
          return {
            ...data,
            'completedAt': completedAt?.toDate(),
          };
        }).toList();
      }
    } catch (e) {
      print('Error loading patient details: $e');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.themeProvider;
    final patient = widget.patient;
    final name = patient['name'] ?? 'Unknown Patient';
    final progress = patient['progressPercentage'] ?? 0;
    final totalExercises = patient['totalExercises'] ?? 0;
    final completedExercises = patient['completedExercises'] ?? 0;
    final totalMinutes = patient['totalMinutes'] ?? 0;
    final isActive = patient['isActive'] ?? false;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Patient Details',
          style: TextStyle(
            color: theme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient header card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isActive 
                        ? Colors.green.withOpacity(0.3)
                        : theme.primaryColor.withOpacity(0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryColor.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person,
                            color: theme.primaryColor,
                            size: 40,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                patient['email'] ?? '',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: theme.subtextColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isActive ? Colors.green : Colors.grey,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  isActive ? 'Active Patient' : 'Inactive Patient',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Progress overview
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailStatCard(
                            theme, 
                            'Progress', 
                            '$progress%', 
                            Icons.trending_up, 
                            progress >= 80 ? Colors.green : progress >= 50 ? Colors.orange : Colors.red,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDetailStatCard(
                            theme, 
                            'Exercises', 
                            '$completedExercises/$totalExercises', 
                            Icons.fitness_center, 
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDetailStatCard(
                            theme, 
                            'Total Time', 
                            '${totalMinutes}m', 
                            Icons.timer, 
                            Colors.purple,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Progress bar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overall Progress',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progress / 100,
                          backgroundColor: theme.primaryColor.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progress >= 80 ? Colors.green 
                                : progress >= 50 ? Colors.orange 
                                : Colors.red,
                          ),
                          minHeight: 8,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Recent activities
              Text(
                'Recent Activities',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(height: 16),
              
              if (_isLoading)
                Center(child: CircularProgressIndicator(color: theme.primaryColor))
              else if (_recentActivities.isEmpty)
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.primaryColor.withOpacity(0.1)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.fitness_center_outlined,
                        size: 60,
                        color: theme.subtextColor.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No recent activities',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Patient hasn\'t completed any exercises yet',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.subtextColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ..._recentActivities.map((activity) => _buildActivityCard(theme, activity)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailStatCard(ThemeProvider theme, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: theme.subtextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(ThemeProvider theme, Map<String, dynamic> activity) {
    final exerciseName = activity['exerciseName'] ?? 'Unknown Exercise';
    final completedAt = activity['completedAt'] as DateTime?;
    final duration = activity['duration'] ?? 0;
    final sets = activity['sets'] ?? 0;
    final repetitions = activity['repetitions'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exerciseName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  completedAt != null 
                      ? 'Completed ${_formatDate(completedAt)}'
                      : 'Completed recently',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.subtextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${duration}m • $sets sets • $repetitions reps',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.subtextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) return 'today';
    if (difference == 1) return 'yesterday';
    if (difference < 7) return '$difference days ago';
    if (difference < 30) return '${(difference / 7).round()} weeks ago';
    return '${(difference / 30).round()} months ago';
  }
}
