import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
import '../models/appointment.dart';
import '../services/appointment_service.dart';

class CreateAppointmentScreen extends StatefulWidget {
  final ThemeProvider themeProvider;
  final String? patientId; // Optional: pre-select a patient

  const CreateAppointmentScreen({
    super.key,
    required this.themeProvider,
    this.patientId,
  });

  @override
  State<CreateAppointmentScreen> createState() => _CreateAppointmentScreenState();
}

class _CreateAppointmentScreenState extends State<CreateAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _purposeController = TextEditingController();
  
  String? _selectedPatientId;
  DateTime? _selectedDate;
  String? _selectedTime;
  bool _isLoading = false;
  List<Map<String, dynamic>> _patients = [];

  // Available time slots
  final List<String> _timeSlots = [
    '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
    '12:00', '12:30', '13:00', '13:30', '14:00', '14:30',
    '15:00', '15:30', '16:00', '16:30', '17:00', '17:30',
  ];

  @override
  void initState() {
    super.initState();
    _loadPatients();
    if (widget.patientId != null) {
      _selectedPatientId = widget.patientId;
    }
  }

  @override
  void dispose() {
    _purposeController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('Loading patients for doctor: ${user.uid}');
        final patients = await AppointmentService.getDoctorPatients(user.uid);
        print('Found ${patients.length} patients');
        for (var patient in patients) {
          print('Patient: ${patient['name']} (ID: ${patient['id']})');
        }
        setState(() {
          _patients = patients;
        });
      }
    } catch (e) {
      print('Error loading patients: $e');
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.themeProvider.primaryColor,
              onPrimary: Colors.white,
              surface: widget.themeProvider.cardColor,
              onSurface: widget.themeProvider.textColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null; // Reset time when date changes
      });
    }
  }

  Future<void> _createAppointment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPatientId == null) {
      _showSnackBar('Please select a patient', isError: true);
      return;
    }

    if (_selectedDate == null) {
      _showSnackBar('Please select a date', isError: true);
      return;
    }

    if (_selectedTime == null) {
      _showSnackBar('Please select a time', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar('User not authenticated', isError: true);
        return;
      }

      // Check for conflicts
      final hasConflict = await AppointmentService.hasConflict(
        user.uid,
        _selectedDate!,
        _selectedTime!,
      );

      if (hasConflict) {
        _showSnackBar('Time slot is already booked. Please choose another time.', isError: true);
        return;
      }

      // Create appointment
      final appointment = Appointment(
        doctorId: user.uid,
        patientId: _selectedPatientId!,
        date: _selectedDate!,
        time: _selectedTime!,
        purpose: _purposeController.text.trim(),
        status: 'confirmed',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await AppointmentService.createAppointment(appointment);

      _showSnackBar('Appointment created and confirmed successfully!');
      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      _showSnackBar('Failed to create appointment: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.themeProvider;

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
          'Create Appointment',
          style: TextStyle(color: theme.primaryColor),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: theme.primaryColor),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.primaryColor.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.calendar_today_rounded,
                                  size: 24,
                                  color: theme.primaryColor,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Schedule New Appointment',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: theme.textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Create a new appointment for your patient',
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Patient Selection
                    _buildSectionTitle('Select Patient', theme),
                    const SizedBox(height: 12),
                    _buildPatientDropdown(theme),
                    const SizedBox(height: 24),

                    // Date Selection
                    _buildSectionTitle('Select Date', theme),
                    const SizedBox(height: 12),
                    _buildDateSelector(theme),
                    const SizedBox(height: 24),

                    // Time Selection
                    _buildSectionTitle('Select Time', theme),
                    const SizedBox(height: 12),
                    _buildTimeSelector(theme),
                    const SizedBox(height: 24),

                    // Purpose
                    _buildSectionTitle('Purpose / Notes', theme),
                    const SizedBox(height: 12),
                    _buildPurposeField(theme),
                    const SizedBox(height: 32),

                    // Create Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _createAppointment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Create Appointment',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeProvider theme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: theme.textColor,
      ),
    );
  }

  Widget _buildPatientDropdown(ThemeProvider theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.primaryColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedPatientId,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          hintText: _patients.isEmpty ? 'No patients found' : 'Select a patient',
          hintStyle: TextStyle(
            color: theme.subtextColor.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        dropdownColor: theme.cardColor,
        style: TextStyle(
          color: theme.textColor,
          fontSize: 14,
        ),
        items: _patients.isEmpty 
            ? [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text(
                    'No patients available',
                    style: TextStyle(
                      color: theme.subtextColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ]
            : _patients.map((patient) {
                return DropdownMenuItem<String>(
                  value: patient['id'],
                  child: Text(patient['name']),
                );
              }).toList(),
        onChanged: _patients.isEmpty ? null : (value) {
          setState(() {
            _selectedPatientId = value;
          });
        },
        validator: (value) {
          if (_patients.isEmpty) {
            return 'No patients are assigned to you. Please assign patients first.';
          }
          if (value == null || value.isEmpty) {
            return 'Please select a patient';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDateSelector(ThemeProvider theme) {
    return InkWell(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.primaryColor.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              color: theme.primaryColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedDate != null
                    ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                    : 'Select appointment date',
                style: TextStyle(
                  color: _selectedDate != null ? theme.textColor : theme.subtextColor.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: theme.subtextColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector(ThemeProvider theme) {
    return InkWell(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: _selectedTime != null 
              ? TimeOfDay(
                  hour: int.parse(_selectedTime!.split(':')[0]),
                  minute: int.parse(_selectedTime!.split(':')[1]),
                )
              : TimeOfDay.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: theme.primaryColor,
                ),
              ),
              child: child!,
            );
          },
        );
        if (time != null) {
          setState(() {
            _selectedTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: theme.primaryColor),
            const SizedBox(width: 12),
            Text(
              _selectedTime == null ? 'Select Time' : _selectedTime!,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurposeField(ThemeProvider theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.primaryColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: _purposeController,
        maxLines: 3,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          hintText: 'Enter appointment purpose or notes...',
          hintStyle: TextStyle(
            color: theme.subtextColor.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        style: TextStyle(
          color: theme.textColor,
          fontSize: 14,
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter appointment purpose';
          }
          return null;
        },
      ),
    );
  }
}
