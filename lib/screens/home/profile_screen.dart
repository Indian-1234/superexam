import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  final String username;
  final String mobileNumber;
  final String email;
  final String address;

  const ProfileScreen({
    Key? key,
    this.username = 'Murugan',
    this.mobileNumber = '6385691235',
    this.email = 'Demo@gmail.com',
    this.address = 'Demo Address',
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _mobileController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.username);
    _mobileController = TextEditingController(text: widget.mobileNumber);
    _emailController = TextEditingController(text: widget.email);
    _addressController = TextEditingController(text: widget.address);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true, // Changed to true for better UX
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
                // Profile Picture - Smaller
                _buildProfilePicture(),
                
                const SizedBox(height: 24),

                // Form Fields - Compact
                _buildCompactField('Name/ID', _nameController),
                const SizedBox(height: 16),

                _buildCompactField('Mobile Number', _mobileController, TextInputType.phone),
                const SizedBox(height: 16),

                _buildCompactField('Email', _emailController, TextInputType.emailAddress),
                const SizedBox(height: 16),

                _buildCompactField('Address', _addressController),
                
                const SizedBox(height: 32),

                // Buttons - Compact
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

  Widget _buildCompactField(String label, TextEditingController controller, [TextInputType? keyboardType]) {
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
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey.shade300),
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
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile Updated')),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1D8E3E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 2,
        ),
        child: const Text(
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
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logged out successfully')),
                );
                // Navigate to login screen or handle logout
                // Navigator.pushReplacementNamed(context, '/login');
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