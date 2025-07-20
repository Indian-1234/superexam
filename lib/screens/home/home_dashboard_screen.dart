import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:superexam/screens/exam/exam_screen.dart';
import 'package:superexam/screens/home/profile_screen.dart';
import 'package:superexam/widgets/test_records_grid.dart';

class HomeDashboardScreen extends StatefulWidget {
  final String username;
  final String studentId;
  
  const HomeDashboardScreen({
    Key? key,
    required this.username,
    required this.studentId
  }) : super(key: key);

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen>
    with TickerProviderStateMixin {
  List<dynamic> unattemptedQuestions = [];
  bool isLoading = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  String selectedFilter = 'All';
  List<String> subjects = ['All'];
  
  @override
  void initState() {
    super.initState();
    
    // Set status bar to transparent
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    fetchUnattemptedQuestions();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _refreshAllData() async {
    try {
      await fetchUnattemptedQuestions(showLoading: false);
      _fadeController.reset();
      await Future.delayed(const Duration(milliseconds: 200));
      _fadeController.forward();
    } catch (e) {
      print('Error refreshing data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('Failed to refresh data'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> fetchUnattemptedQuestions({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/attempt/unattempted/${widget.studentId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            unattemptedQuestions = data['data'];
            if (showLoading) {
              isLoading = false;
            }
            subjects = ['All', ...unattemptedQuestions
                .map<String>((q) => q['subject']['name'])
                .toSet()
                .toList()];
          });
          
          if (showLoading) {
            _fadeController.forward();
          }
        }
      }
    } catch (e) {
      if (showLoading) {
        setState(() {
          isLoading = false;
        });
      }
      print('Error fetching unattempted questions: $e');
    }
  }

  List<dynamic> get filteredQuestions {
    if (selectedFilter == 'All') return unattemptedQuestions;
    return unattemptedQuestions
        .where((q) => q['subject']['name'] == selectedFilter)
        .toList();
  }

  void navigateToExam(Map<String, dynamic> question) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ExamScreen(
          examTitle: question['title'],
          questionSetId: question['questionId'],
          studentId: widget.studentId,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Color _getSubjectColor(String subject) {
    switch (subject.toLowerCase()) {
      case 'social':
        return const Color(0xFF4CAF50);
      case 'math':
      case 'mathematics':
        return const Color(0xFF66BB6A);
      case 'science':
        return const Color(0xFF388E3C);
      case 'english':
        return const Color(0xFF81C784);
      default:
        return const Color(0xFF4CAF50);
    }
  }

  Widget _buildCompactStatsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Total Questions: ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '${unattemptedQuestions.length}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: subjects.length,
        itemBuilder: (context, index) {
          final subject = subjects[index];
          final isSelected = selectedFilter == subject;
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                subject,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  selectedFilter = subject;
                });
              },
              backgroundColor: Colors.grey[100],
              selectedColor: const Color(0xFF4CAF50),
              checkmarkColor: Colors.white,
              elevation: isSelected ? 2 : 0,
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question, int index) {
    final subjectColor = _getSubjectColor(question['subject']['name']);
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () => navigateToExam(question),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: Colors.grey.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 40,
                  decoration: BoxDecoration(
                    color: subjectColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: subjectColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              question['subject']['name'],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: subjectColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• ${question['unit']['name']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: subjectColor,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      // Remove the default app bar and let content go to the top
      extendBodyBehindAppBar: true,
      body: Container(
        // Add gradient background that starts from the very top
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey[50]!,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          // Don't maintain top padding for status bar
          top: true,
          child: RefreshIndicator(
            onRefresh: _refreshAllData,
            color: const Color(0xFF4CAF50),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Add some top padding to account for status bar
                    const SizedBox(height: 8),
                    
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back,',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.username,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfileScreen(),
                              ),
                            );
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    TestRecordsGrid(studentId: widget.studentId),
                    
                    const SizedBox(height: 24),
                    
                    // Compact Stats Card
                    _buildCompactStatsCard(),
                    
                    const SizedBox(height: 24),
                    
                    // Questions Section Header
                    const Text(
                      'Available Questions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Filter Chips
                    if (subjects.length > 2) ...[
                      _buildFilterChips(),
                      const SizedBox(height: 16),
                    ],
                    
                    // Questions List
                    isLoading
                        ? Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                          )
                        : filteredQuestions.isEmpty
                            ? Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.quiz_outlined,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No questions available',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      selectedFilter == 'All' 
                                          ? 'Check back later for new questions'
                                          : 'No questions found for $selectedFilter',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filteredQuestions.length,
                                itemBuilder: (context, index) {
                                  return _buildQuestionCard(filteredQuestions[index], index);
                                },
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