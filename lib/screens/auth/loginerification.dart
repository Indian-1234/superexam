import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:superexam/config/api_config.dart';
import 'package:superexam/main.dart';
import 'package:superexam/screens/home/home_dashboard_screen.dart';
import 'success_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const LoginVerificationScreen({
    Key? key,
    required this.phoneNumber,
  }) : super(key: key);

  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<LoginVerificationScreen> {
  // Controllers for each digit input
  final TextEditingController _digit1Controller = TextEditingController();
  final TextEditingController _digit2Controller = TextEditingController();
  final TextEditingController _digit3Controller = TextEditingController();
  final TextEditingController _digit4Controller = TextEditingController();

  // Focus nodes for each digit input
  final FocusNode _focusNode1 = FocusNode();
  final FocusNode _focusNode2 = FocusNode();
  final FocusNode _focusNode3 = FocusNode();
  final FocusNode _focusNode4 = FocusNode();

  @override
  void initState() {
    super.initState();
    // Set focus to first digit initially
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode1);
    });
  }

  @override
  void dispose() {
    // Dispose controllers and focus nodes
    _digit1Controller.dispose();
    _digit2Controller.dispose();
    _digit3Controller.dispose();
    _digit4Controller.dispose();
    _focusNode1.dispose();
    _focusNode2.dispose();
    _focusNode3.dispose();
    _focusNode4.dispose();
    super.dispose();
  }

  // Move focus to next input when digit is entered
  void _onDigitChanged(String value, FocusNode currentFocus, FocusNode? nextFocus) {
    if (value.isNotEmpty && nextFocus != null) {
      currentFocus.unfocus();
      FocusScope.of(context).requestFocus(nextFocus);
    }
  }

  // Get the full verification code
  String get _verificationCode {
    return '${_digit1Controller.text}${_digit2Controller.text}${_digit3Controller.text}${_digit4Controller.text}';
  }

// Inside the _VerificationScreenState class, update the _verifyCode method:
// Update your LoginVerificationScreen _verifyCode and _resendCode methods



// Replace the existing _verifyCode method
// Add this import at the top of your file

void _verifyCode() async {
  // Check if all digits are entered
  if (_verificationCode.length != 4) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter all 4 digits')),
    );
    return;
  }

  // Show loading indicator
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0B7C25)),
        ),
      );
    },
  );

  try {
    // Console log the 4-digit OTP
    print('Entered OTP: $_verificationCode');
    
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}api/students/login/verify-otp'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'mobileNo': widget.phoneNumber,
        'otp': _verificationCode,
      }),
    );

    // Close loading dialog
    Navigator.pop(context);

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      
      // Debug: Print the response to understand the structure
      print('API Response: $responseData');
      print('Student data type: ${responseData['student'].runtimeType}');
      
      // Store student data in SharedPreferences
      await _storeStudentData(responseData['student']);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to success screen
       final userName = await UserSession.getUserName() ?? 'Student';
final userId = await UserSession.getUserId() ?? '';

Navigator.of(context).pushAndRemoveUntil(
  MaterialPageRoute(
    builder: (context) => HomeDashboardScreen(
      username: userName,
      studentId: userId,
    ),
  ),
  (route) => false, // Clears all routes
);

      }
    } else {
      if (mounted) {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'OTP verification failed';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
        
        // Clear the input fields on error
        _digit1Controller.clear();
        _digit2Controller.clear();
        _digit3Controller.clear();
        _digit4Controller.clear();
        
        // Set focus back to first digit
        FocusScope.of(context).requestFocus(_focusNode1);
      }
    }
  } catch (e) {
    // Close loading dialog
    Navigator.pop(context);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Helper method to store student data
Future<void> _storeStudentData(dynamic studentData) async {
  final prefs = await SharedPreferences.getInstance();
  
  try {
    Map<String, dynamic> student;
    
    // Handle different response formats
    if (studentData is List) {
      // If student data is an array, take the first element
      if (studentData.isNotEmpty) {
        student = studentData[0] as Map<String, dynamic>;
        print('Student data is a list, using first element');
      } else {
        throw Exception('Student data array is empty');
      }
    } else if (studentData is Map<String, dynamic>) {
      // If student data is already a map, use it directly
      student = studentData;
      print('Student data is a map');
    } else {
      throw Exception('Invalid student data format: ${studentData.runtimeType}');
    }
    
    // Store individual fields with null safety
    await prefs.setString('student_id', student['id']?.toString() ?? '');
    await prefs.setString('student_name', student['name']?.toString() ?? '');
    await prefs.setString('student_email', student['email']?.toString() ?? '');
    await prefs.setString('student_mobile', student['mobileNo']?.toString() ?? '');
    await prefs.setString('student_address', student['address']?.toString() ?? '');
await prefs.setString('student_subject', json.encode(student['subject'] ?? []));
    await prefs.setString('student_status', student['status']?.toString() ?? '');
    await prefs.setString('student_application_status', student['applicationStatus']?.toString() ?? '');
    await prefs.setString('student_created_at', student['createdAt']?.toString() ?? '');
    
    // Store the entire student object as JSON string for easy retrieval
    await prefs.setString('student_data', json.encode(student));
    
    // Set login status using the same keys as your UserSession class
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userName', student['name']?.toString() ?? 'Student');
    await prefs.setString('userId', student['id']?.toString() ?? '');
    
    // Also set the old key for backward compatibility
    await prefs.setBool('is_logged_in', true);
    
    print('Student data stored successfully');
    print('Stored student name: ${student['name']}');
    print('Stored student ID: ${student['id']}');
    
  } catch (e) {
    print('Error storing student data: $e');
    print('Student data received: $studentData');
    
    // Set basic login status even if detailed storage fails
    await prefs.setBool('isLoggedIn', true);
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('userName', 'Student');
    
    rethrow; // Re-throw to handle in calling method if needed
  }
}
// Helper method to retrieve student data
// Future<Map<String, dynamic>?> getStoredStudentData() async {
//   final prefs = await SharedPreferences.getInstance();
//   final studentDataString = prefs.getString('student_data');
  
//   if (studentDataString != null) {
//     return json.decode(studentDataString);
//   }
//   return null;
// }

// // Helper method to check if user is logged in
// Future<bool> isUserLoggedIn() async {
//   final prefs = await SharedPreferences.getInstance();
//   return prefs.getBool('is_logged_in') ?? false;
// }

// // Helper method to clear stored data (for logout)
// Future<void> clearStoredData() async {
//   final prefs = await SharedPreferences.getInstance();
//   await prefs.clear();
//   print('All stored data cleared');
// }
// Replace the existing _resendCode method
void _resendCode() async {
  try {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}api/students/resend-otp'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'mobileNo': widget.phoneNumber,
      }),
    );

    if (response.statusCode == 200) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP resent successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Clear existing input
        _digit1Controller.clear();
        _digit2Controller.clear();
        _digit3Controller.clear();
        _digit4Controller.clear();
        
        // Set focus to first digit
        FocusScope.of(context).requestFocus(_focusNode1);
      }
    } else {
      if (mounted) {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Failed to resend OTP';
        
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
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
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
          child: Column(
            children: [
              const SizedBox(height: 60),

              // Logo
              Image.asset(
                'assets/images/academy_logo.png',
                height: 120,
                width: 120,
              ),

              const SizedBox(height: 60),

              // Form container with background and top border radius
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
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 30),

                          // Verification Code title
                          const Text(
                            'Verification Code',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),

                          const SizedBox(height: 15),

                          // Description text
                          Text(
                            'Enter 4 digit number that send to phone number.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Verification code input fields
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // First digit
                              _buildDigitInput(
                                controller: _digit1Controller,
                                focusNode: _focusNode1,
                                onChanged: (value) => _onDigitChanged(value, _focusNode1, _focusNode2),
                              ),

                              // Second digit
                              _buildDigitInput(
                                controller: _digit2Controller,
                                focusNode: _focusNode2,
                                onChanged: (value) => _onDigitChanged(value, _focusNode2, _focusNode3),
                              ),

                              // Third digit
                              _buildDigitInput(
                                controller: _digit3Controller,
                                focusNode: _focusNode3,
                                onChanged: (value) => _onDigitChanged(value, _focusNode3, _focusNode4),
                              ),

                              // Fourth digit
                              _buildDigitInput(
                                controller: _digit4Controller,
                                focusNode: _focusNode4,
                                onChanged: (value) => _onDigitChanged(value, _focusNode4, null),
                              ),
                            ],
                          ),

                          const SizedBox(height: 50),

                          // Verify button
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _verifyCode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0B7C25),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 5,
                              ),
                              child: const Text(
                                'Login Account',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Resend code option
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Don't receive the code? ",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _resendCode,
                                  child: const Text(
                                    "Resend",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF0B7C25),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
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

  // Widget for each digit input
  Widget _buildDigitInput({
    required TextEditingController controller,
    required FocusNode focusNode,
    required Function(String) onChanged,
  }) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.black54,
            width: 2.0,
          ),
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        decoration: const InputDecoration(
          counterText: "",
          border: InputBorder.none,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        onChanged: onChanged,
      ),
    );
  }
}