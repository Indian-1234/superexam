import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:superexam/config/api_config.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _mobileController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _subjectController;
  
  String studentId = '';
  bool isLoading = true;
  bool isUpdating = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _mobileController = TextEditingController();
    _emailController = TextEditingController();
    _addressController = TextEditingController();
    _subjectController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

Future<void> _loadUserData() async {
  try {
    print('Loading user data...');
    final prefs = await SharedPreferences.getInstance();

    // Handle subject name extraction from stored JSON list
    String subjectName = '';
    final subjectData = prefs.getString('student_subject') ?? '';
    print('Subject Data: $subjectData');

    if (subjectData.isNotEmpty) {
      try {
        // Parse the JSON string to a List of Map
        final List<dynamic> subjectList = json.decode(subjectData);
        print('Parsed Subject List: $subjectList');

        if (subjectList.isNotEmpty && subjectList.first is Map<String, dynamic>) {
          subjectName = subjectList.first['name']?.toString() ?? '';
        }
      } catch (e) {
        print('❌ Failed to parse subject JSON: $e');
        subjectName = subjectData; // fallback
      }
    }

    setState(() {
      studentId = prefs.getString('student_id') ?? '';
      _nameController.text = prefs.getString('student_name') ?? '';
      _emailController.text = prefs.getString('student_email') ?? '';
      _mobileController.text = prefs.getString('student_mobile') ?? '';
      _addressController.text = prefs.getString('student_address') ?? '';
      _subjectController.text = subjectName;
      isLoading = false;
    });
  } catch (e) {
    setState(() {
      isLoading = false;
    });
    _showSnackBar('Error loading user data: $e');
  }
}

  // Update student profile via API
  Future<void> _updateProfile() async {
    if (studentId.isEmpty) {
      _showSnackBar('Student ID not found');
      return;
    }

    setState(() {
      isUpdating = true;
    });

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}api/students/$studentId');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'mobileNo': _mobileController.text.trim(),
          'address': _addressController.text.trim(),
          // Note: Subject is not included in update as it's read-only
        }),
      );

      if (response.statusCode == 200) {
        // Update local storage with new data
        await _updateLocalStorage();
        _showSnackBar('Profile updated successfully');
      } else {
        final errorData = json.decode(response.body);
        _showSnackBar('Update failed: ${errorData['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      _showSnackBar('Network error: $e');
    } finally {
      setState(() {
        isUpdating = false;
      });
    }
  }

  // Update SharedPreferences with new data
  Future<void> _updateLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('student_name', _nameController.text.trim());
    await prefs.setString('student_email', _emailController.text.trim());
    await prefs.setString('student_mobile', _mobileController.text.trim());
    await prefs.setString('student_address', _addressController.text.trim());
    // Note: Subject is not updated as it's read-only
  }

  // Clear all SharedPreferences and logout
  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clear all stored data
      
      // Navigate to WelcomeScreen and remove all previous routes
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/welcome',
        (Route<dynamic> route) => false,
      );
      
      _showSnackBar('Logged out successfully');
    } catch (e) {
      _showSnackBar('Error during logout: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Profile',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300),
              ),
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.arrow_back, color: Colors.black87, size: 18),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              children: [
                // Profile Picture
                _buildProfilePicture(),
                
                const SizedBox(height: 24),

                // Form Fields
                _buildCompactField('Name/ID', _nameController),
                const SizedBox(height: 16),

                _buildCompactField('Mobile Number', _mobileController, TextInputType.phone),
                const SizedBox(height: 16),

                _buildCompactField('Email', _emailController, TextInputType.emailAddress),
                const SizedBox(height: 16),

                _buildCompactField('Address', _addressController),
                const SizedBox(height: 16),

                _buildCompactField('Subject', _subjectController, null, true), // Disabled field
                
                const SizedBox(height: 32),

                // Buttons
                _buildUpdateButton(),
                const SizedBox(height: 12),
                _buildLogoutButton(),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePicture() {
    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.green.shade100,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF4CAF50),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 28,
              ),
            ),
            Positioned(
              right: 5,
              bottom: 5,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Icon(
                  Icons.edit,
                  color: Colors.black54,
                  size: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactField(String label, TextEditingController controller, [TextInputType? keyboardType, bool disabled = false]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          enabled: !disabled,
          style: TextStyle(
            fontSize: 13,
            color: disabled ? Colors.grey.shade600 : Colors.black,
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: disabled,
            fillColor: disabled ? Colors.grey.shade100 : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(6)),
              borderSide: BorderSide(color: Color(0xFF4CAF50)),
            ),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateButton() {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: ElevatedButton(
        onPressed: isUpdating ? null : _updateProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1D8E3E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 2,
        ),
        child: isUpdating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Update',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: OutlinedButton(
        onPressed: () => _showLogoutDialog(),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: const Text(
          'Logout',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.red,
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout? This will clear all stored data.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}