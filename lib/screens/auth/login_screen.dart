import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:superexam/message/firebase_messaging_service.dart';
import 'dart:convert';

import 'package:superexam/screens/auth/loginerification.dart';
import 'package:superexam/screens/auth/register_screen.dart';


class StudentLoginScreen extends StatefulWidget {
  const StudentLoginScreen({Key? key}) : super(key: key);

  @override
  _StudentLoginScreenState createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<StudentLoginScreen> {
  final TextEditingController _mobileController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    if (_mobileController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your mobile number')),
      );
      return false;
    }
    
    // Validate mobile number format (10 digits)
    if (!RegExp(r'^[0-9]{10}$').hasMatch(_mobileController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit mobile number')),
      );
      return false;
    }
    
    return true;
  }

  void _clearForm() {
    _mobileController.clear();
  }

  Future<void> _initiateLogin() async {
    if (!_validateForm()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get FCM token
      String? fcmToken = await FirebaseMessagingService.getToken();
      
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/students/login/initiate'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'mobileNo': _mobileController.text.trim(),
          'fcmToken': fcmToken,
        }),
      );
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? 'Login OTP sent successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          final mobileNumber = _mobileController.text.trim();
          
          // Navigate to verification screen for login
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => LoginVerificationScreen(
                phoneNumber: mobileNumber,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          final errorData = json.decode(response.body);
          final errorMessage = errorData['message'] ?? 'Failed to send login OTP';
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
                      padding: const EdgeInsets.symmetric(vertical: 50),
                      child: Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/images/academy_logo.png',
                            height: 70,
                            width: 70,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.school,
                                size: 50,
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
                              const SizedBox(height: 30),

                              // Header text
                              const Text(
                                'Welcome Back!',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),

                              const SizedBox(height: 10),

                              const Text(
                                'Enter your mobile number to login',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),

                              const SizedBox(height: 50),

                              // Mobile number input field
                              Container(
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                                      child: const Text(
                                        '+91',
                                        style: TextStyle(
                                          fontSize: 16, 
                                          color: Colors.black,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      height: 30,
                                      width: 1,
                                      color: Colors.grey.withOpacity(0.3),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: TextField(
                                        controller: _mobileController,
                                        keyboardType: TextInputType.phone,
                                        maxLength: 10,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        decoration: const InputDecoration(
                                          hintText: '00000 00000',
                                          hintStyle: TextStyle(
                                            color: Colors.grey, 
                                            fontSize: 16,
                                            fontWeight: FontWeight.normal,
                                          ),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(vertical: 20),
                                          counterText: '', // Hide character counter
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 40),

                              // Login button
                              Container(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _initiateLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0B7C25),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    elevation: 8,
                                    shadowColor: const Color(0xFF0B7C25).withOpacity(0.3),
                                    disabledBackgroundColor: Colors.grey,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : const Text(
                                          'Send Login OTP',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 30),

                              // Additional login info
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: Colors.blue.withOpacity(0.1),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.blue.shade600,
                                      size: 24,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'We\'ll send a 4-digit OTP to verify your mobile number',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.blue.shade700,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
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
                                      'Don\'t have an account? ',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    GestureDetector(
                                        onTap: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RegisterScreen(),
      ),
    );
  },
                                      child: const Text(
                                        'Register here',
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
}