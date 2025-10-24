import 'package:flutter/material.dart';
import 'package:demo_app/main.dart';
import 'package:demo_app/screens/more_screen.dart';
import 'package:demo_app/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo_app/screens/admin_patient_records_screen.dart';

// ADMIN DASHBOARD SCREEN (User Management)
class AdminDashboardScreen extends StatefulWidget {
  final ThemeProvider themeProvider;

  const AdminDashboardScreen({super.key, required this.themeProvider});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selectedUser;
  bool _isSearching = false;
  bool _isLoadingUser = false;

  @override
  void initState() {
    super.initState();
    _enforceRole();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ensure UI is mounted before potential navigation
    });
  }

  Future<void> _enforceRole() async {
    try {
      String role = UserService.getUserRole().toString().trim();

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final remoteRole = (data['role']?.toString() ?? '').trim();
          if (remoteRole.isNotEmpty) {
            role = remoteRole;
            await UserService.setUserRole(role);
          }
        }
      }

      if (role != 'admin') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Access denied — admin account required.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pushReplacementNamed(context, '/main');
        }
      }
    } catch (e) {
      print('Role enforcement error on admin dashboard: $e');
      if (mounted) Navigator.pushReplacementNamed(context, '/main');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.themeProvider,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: widget.themeProvider.backgroundColor,
          appBar: AppBar(
            backgroundColor: widget.themeProvider.cardColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back,
                  color: widget.themeProvider.primaryColor),
              onPressed: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MoreScreen(themeProvider: widget.themeProvider,)));
              }
            ),
            title: Text(
              'Back',
              style: TextStyle(color: widget.themeProvider.primaryColor),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Management Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: widget.themeProvider.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: widget.themeProvider.primaryColor.withOpacity(0.15),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.themeProvider.primaryColor.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'User Management',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: widget.themeProvider.textColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Search Bar
                        TextField(
                          controller: _searchController,
                          onChanged: _performSearch,
                          decoration: InputDecoration(
                            hintText: 'Search User',
                            hintStyle: TextStyle(
                              color: widget.themeProvider.subtextColor,
                            ),
                            prefixIcon: IconButton(
                              icon: Icon(
                                Icons.menu,
                                color: widget.themeProvider.primaryColor,
                              ),
                              onPressed: _showAllUsers,
                            ),
                            suffixIcon: _isSearching
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Icon(
                                    Icons.search,
                                    color: widget.themeProvider.primaryColor,
                                  ),
                            filled: true,
                            fillColor: widget.themeProvider.backgroundColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: widget.themeProvider.primaryColor.withOpacity(0.15),
                                width: 1,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Search Results
                        if (_searchResults.isNotEmpty)
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: widget.themeProvider.backgroundColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: widget.themeProvider.primaryColor.withOpacity(0.15),
                                width: 1,
                              ),
                            ),
                            child: ListView.builder(
                              itemCount: _searchResults.length,
                              itemBuilder: (context, index) {
                                final user = _searchResults[index];
                                return ListTile(
                                  title: Text(
                                    user['name'] ?? 'Unknown',
                                    style: TextStyle(color: widget.themeProvider.textColor),
                                  ),
                                  subtitle: Text(
                                    user['email'] ?? '',
                                    style: TextStyle(color: widget.themeProvider.subtextColor),
                                  ),
                                  onTap: () => _selectUser(user['uid']),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // User Information Card
                  Expanded(
                    child: SingleChildScrollView(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: widget.themeProvider.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: widget.themeProvider.primaryColor.withOpacity(0.15),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: widget.themeProvider.primaryColor.withOpacity(0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'User Information',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: widget.themeProvider.textColor,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: _selectedUser != null ? _showEditDialog : null,
                                  icon: Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: _selectedUser != null ? widget.themeProvider.primaryColor : widget.themeProvider.subtextColor,
                                  ),
                                  label: Text(
                                    'Edit Information',
                                    style: TextStyle(
                                      color: _selectedUser != null ? widget.themeProvider.primaryColor : widget.themeProvider.subtextColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildUserInfoTable(widget.themeProvider),
                            const SizedBox(height: 24),
                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => AdminPatientRecordsScreen(themeProvider: widget.themeProvider),
                                          ),
                                        );
                                      },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          widget.themeProvider.primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Column(
                                      children: [
                                        Text(
                                          'View Patient',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          'Records',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Active Records: 10',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          widget.themeProvider.primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Column(
                                      children: [
                                        Icon(Icons.backup, size: 32),
                                        SizedBox(height: 4),
                                        Text(
                                          'Back up & Restore',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Last back up:\n04/09/05',
                                          style: TextStyle(fontSize: 11),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserInfoTable(ThemeProvider theme) {
    if (_selectedUser == null) {
      return Center(
        child: Text(
          'Select a user to view information',
          style: TextStyle(color: theme.subtextColor),
        ),
      );
    }

    if (_isLoadingUser) {
      return const Center(child: CircularProgressIndicator());
    }

    final data = [
      ['UID#', _selectedUser!['uid'] ?? 'N/A'],
      ['Name', _selectedUser!['name'] ?? 'N/A'],
      ['Email', _selectedUser!['email'] ?? 'N/A'],
      ['Status', _selectedUser!['status'] ?? 'Active'],
      ['Role', _selectedUser!['role'] ?? 'patient'],
    ];

    return Column(
      children: [
        for (int i = 0; i < data.length; i++) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    data[i][0],
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.subtextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    data[i][1],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          if (i < data.length - 1)
            Divider(
              height: 1,
              color: theme.subtextColor.withOpacity(0.2),
            ),
        ],
      ],
    );
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await UserService.fetchUsers(searchQuery: query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      print('Search error: $e');
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  Future<void> _showAllUsers() async {
    setState(() {
      _isSearching = true;
    });

    try {
      final results = await UserService.fetchUsers(searchQuery: ''); // Empty query to fetch all users
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      print('Error fetching all users: $e');
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading users')),
      );
    }
  }

  Future<void> _selectUser(String uid) async {
    setState(() {
      _isLoadingUser = true;
      _selectedUser = null;
    });

    try {
      final user = await UserService.getUserProfileByUid(uid);
      setState(() {
        _selectedUser = user;
        _isLoadingUser = false;
        _searchResults = []; // Clear search results after selection
        _searchController.clear(); // Clear search text
      });
    } catch (e) {
      print('Error selecting user: $e');
      setState(() {
        _isLoadingUser = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading user information')),
      );
    }
  }

  void _showEditDialog() {
    if (_selectedUser == null) return;

    final nameController = TextEditingController(text: _selectedUser!['name'] ?? '');
    final emailController = TextEditingController(text: _selectedUser!['email'] ?? '');
    final statusController = TextEditingController(text: _selectedUser!['status'] ?? 'Active');
    final roleController = TextEditingController(text: _selectedUser!['role'] ?? 'patient');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.themeProvider.cardColor,
        title: Text(
          'Edit User Information',
          style: TextStyle(color: widget.themeProvider.textColor),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: widget.themeProvider.subtextColor),
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(color: widget.themeProvider.textColor),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: widget.themeProvider.subtextColor),
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(color: widget.themeProvider.textColor),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: statusController,
                decoration: InputDecoration(
                  labelText: 'Status',
                  labelStyle: TextStyle(color: widget.themeProvider.subtextColor),
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(color: widget.themeProvider.textColor),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: roleController,
                decoration: InputDecoration(
                  labelText: 'Role',
                  labelStyle: TextStyle(color: widget.themeProvider.subtextColor),
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(color: widget.themeProvider.textColor),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: widget.themeProvider.primaryColor),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final updates = {
                'name': nameController.text.trim(),
                'email': emailController.text.trim(),
                'status': statusController.text.trim(),
                'role': roleController.text.trim(),
              };

              // Basic validation
              if (updates['name']!.isEmpty || updates['email']!.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Name and Email are required')),
                );
                return;
              }

              // Prevent changing role to admin (basic permission check)
              if (updates['role'] == 'admin' && _selectedUser!['role'] != 'admin') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cannot assign admin role')),
                );
                return;
              }

              Navigator.of(context).pop(); // Close dialog

              try {
                final success = await UserService.updateUserProfileInFirestore(_selectedUser!['uid'], updates);
                if (success) {
                  // Refresh the selected user data
                  final updatedUser = await UserService.getUserProfileByUid(_selectedUser!['uid']);
                  setState(() {
                    _selectedUser = updatedUser;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User information updated successfully')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to update user information')),
                  );
                }
              } catch (e) {
                print('Error updating user: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error updating user information')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.themeProvider.primaryColor,
              foregroundColor: Colors.white,
            ),
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
