import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:superexam/config/api_config.dart';
import 'package:superexam/message/firebase_messaging_service.dart';
import 'package:superexam/screens/auth/login_screen.dart';
import 'dart:convert';
import 'verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  String _selectedSubject = 'Choose Subject';
  String _selectedSubjectId = '';
  List<Map<String, dynamic>> _subjects = [];
  bool _isLoading = false;
  bool _isLoadingSubjects = false;

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _fetchSubjects() async {
    setState(() {
      _isLoadingSubjects = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/subjects/getAll'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _subjects =
                List<Map<String, dynamic>>.from(data['data'].map((subject) => {
                      'id': subject['_id'],
                      'name': subject['name'],
                      'code': subject['code'],
                      'description': subject['description'],
                    }));
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to load subjects'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading subjects: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSubjects = false;
        });
      }
    }
  }

  bool _validateForm() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return false;
    }

    if (_mobileController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your mobile number')),
      );
      return false;
    }

    // Validate mobile number format (10 digits)
    if (!RegExp(r'^[0-9]{10}$').hasMatch(_mobileController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid 10-digit mobile number')),
      );
      return false;
    }

    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return false;
    }

    // Validate email format
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(_emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return false;
    }

    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your address')),
      );
      return false;
    }

    if (_selectedSubject == 'Choose Subject') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a subject')),
      );
      return false;
    }

    return true;
  }

  void _clearForm() {
    _nameController.clear();
    _mobileController.clear();
    _emailController.clear();
    _addressController.clear();
    setState(() {
      _selectedSubject = 'Choose Subject';
      _selectedSubjectId = '';
    });
  }

// Update the _submitForm method in your RegisterScreen

// Updated _submitForm method in RegisterScreen
  Future<void> _submitForm() async {
    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get FCM token
      String? fcmToken = await FirebaseMessagingService.getToken();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}api/students/initiate'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': _nameController.text.trim(),
          'mobileNo': _mobileController.text.trim(),
          'email': _emailController.text.trim(),
          'address': _addressController.text.trim(),
          'subject': [_selectedSubjectId],
          'date': DateTime.now().toIso8601String().split('T')[0],
          'fcmToken': fcmToken, // Add FCM token
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP sent to your device!'),
              backgroundColor: Colors.green,
            ),
          );

          final mobileNumber = _mobileController.text.trim();

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => VerificationScreen(
                phoneNumber: mobileNumber,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          final errorData = json.decode(response.body);
          final errorMessage = errorData['message'] ?? 'Failed to send OTP';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          image: DecorationImage(
            image: const AssetImage('assets/images/background_pattern.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.white.withOpacity(0.1),
              BlendMode.dstATop,
            ),
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // Top section with logo
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/images/academy_logo.png',
                            height: 60,
                            width: 60,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.school,
                                size: 40,
                                color: Colors.green,
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    // Form container - takes remaining space
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, -5),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(25.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 20),

                              // Header text
                              const Text(
                                'Let\'s start!',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),

                              const SizedBox(height: 8),

                              const Text(
                                'Enter your details to register and continue',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),

                              const SizedBox(height: 30),

                              // Form fields
                              Expanded(
                                child: Column(
                                  children: [
                                    // Name input field
                                    _buildInputField(
                                      controller: _nameController,
                                      hintText: 'Name...',
                                      keyboardType: TextInputType.name,
                                    ),

                                    const SizedBox(height: 16),

                                    // Mobile number input field
                                    Container(
                                      height: 50,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(25),
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.05),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 20, vertical: 15),
                                            child: const Text(
                                              '+91',
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black),
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Expanded(
                                            child: TextField(
                                              controller: _mobileController,
                                              keyboardType: TextInputType.phone,
                                              maxLength: 10,
                                              decoration: const InputDecoration(
                                                hintText: '00000 00000',
                                                hintStyle: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 14),
                                                border: InputBorder.none,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                        vertical: 15),
                                                counterText:
                                                    '', // Hide character counter
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    // Email input field
                                    _buildInputField(
                                      controller: _emailController,
                                      hintText: 'Email...',
                                      keyboardType: TextInputType.emailAddress,
                                    ),

                                    const SizedBox(height: 16),

                                    // Address input field
                                    _buildInputField(
                                      controller: _addressController,
                                      hintText: 'Address...',
                                      keyboardType: TextInputType.multiline,
                                    ),

                                    const SizedBox(height: 16),

                                    // Subject dropdown
                                    Container(
                                      height: 50,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(25),
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.05),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      child: _isLoadingSubjects
                                          ? Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 20),
                                              child: const Row(
                                                children: [
                                                  SizedBox(
                                                    height: 20,
                                                    width: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                            strokeWidth: 2),
                                                  ),
                                                  SizedBox(width: 10),
                                                  Text(
                                                    'Loading subjects...',
                                                    style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : DropdownButtonFormField<String>(
                                              value: _selectedSubject,
                                              decoration: const InputDecoration(
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                        horizontal: 20,
                                                        vertical: 10),
                                                border: InputBorder.none,
                                              ),
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black),
                                              icon: const Icon(
                                                  Icons.keyboard_arrow_down,
                                                  size: 20),
                                              items: [
                                                const DropdownMenuItem<String>(
                                                  value: 'Choose Subject',
                                                  child: Text('Choose Subject',
                                                      style: TextStyle(
                                                          color: Colors.grey)),
                                                ),
                                                ..._subjects.map<
                                                    DropdownMenuItem<
                                                        String>>((subject) {
                                                  return DropdownMenuItem<
                                                      String>(
                                                    value: subject['name'],
                                                    child:
                                                        Text(subject['name']),
                                                  );
                                                }).toList(),
                                              ],
                                              onChanged: (String? newValue) {
                                                setState(() {
                                                  _selectedSubject = newValue!;
                                                  if (newValue !=
                                                      'Choose Subject') {
                                                    // Find the subject ID for the selected name
                                                    final selectedSubjectData =
                                                        _subjects.firstWhere(
                                                      (subject) =>
                                                          subject['name'] ==
                                                          newValue,
                                                      orElse: () => {'id': ''},
                                                    );
                                                    _selectedSubjectId =
                                                        selectedSubjectData[
                                                                'id'] ??
                                                            '';
                                                  } else {
                                                    _selectedSubjectId = '';
                                                  }
                                                });
                                              },
                                            ),
                                    ),

                                    const Spacer(),

                                    // Continue button
                                    Container(
                                      width: double.infinity,
                                      height: 50,
                                      margin: const EdgeInsets.only(bottom: 20),
                                      child: ElevatedButton(
                                        onPressed:
                                            _isLoading ? null : _submitForm,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF0B7C25),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(25),
                                          ),
                                          elevation: 5,
                                          disabledBackgroundColor: Colors.grey,
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Text(
                                                'Register',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                    ),
                                      const Spacer(),

                              // Footer text
                              Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Already have an account? ',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    GestureDetector(
                                       onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                StudentLoginScreen(),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        'Login here',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF0B7C25),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                   
                                  ],
                                ),
                              ),
                            
                                  ],
                                ),
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
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
