import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:superexam/config/api_config.dart';
import 'dart:convert';
import 'package:superexam/screens/exam/exam_screen.dart';
import 'package:superexam/screens/exam/exam_storage_service.dart';
import 'package:superexam/screens/home/profile_screen.dart';
import 'package:superexam/screens/home/attempt_details_screen.dart';
import 'package:superexam/widgets/test_records_grid.dart';

class HomeDashboardScreen extends StatefulWidget {
  final String username;
  final String studentId;

  const HomeDashboardScreen(
      {Key? key, required this.username, required this.studentId})
      : super(key: key);

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen>
    with TickerProviderStateMixin {
  List<dynamic> unattemptedQuestions = [];
  List<dynamic> completedQuestions = [];
  bool isLoadingAvailable = true;
  bool isLoadingCompleted = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late TabController _tabController;
  String selectedFilter = 'All';
  List<String> availableSubjects = ['All'];
  List<String> completedSubjects = ['All'];

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {
          selectedFilter = 'All'; // Reset filter when switching tabs
        });
      }
    });

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    fetchUnattemptedQuestions();
    fetchCompletedQuestions();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshAllData() async {
    try {
      await Future.wait([
        fetchUnattemptedQuestions(showLoading: false),
        fetchCompletedQuestions(showLoading: false),
      ]);
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
        isLoadingAvailable = true;
      });
    }

    try {
      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}api/attempt/unattempted/${widget.studentId}'),
      );
      print('Fetching unattempted questions for studentId: ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            unattemptedQuestions = data['data'];
            if (showLoading) {
              isLoadingAvailable = false;
            }
            availableSubjects = [
              'All',
              ...unattemptedQuestions
                  .map<String>((q) => q['subject']['name'])
                  .toSet()
                  .toList()
            ];
          });

          if (showLoading) {
            _fadeController.forward();
          }
        }
      }
    } catch (e) {
      if (showLoading) {
        setState(() {
          isLoadingAvailable = false;
        });
      }
      print('Error fetching unattempted questions: $e');
    }
  }

  Future<void> fetchCompletedQuestions({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        isLoadingCompleted = true;
      });
    }

    try {
      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}api/attempt/completed/${widget.studentId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            completedQuestions = data['data'];
            if (showLoading) {
              isLoadingCompleted = false;
            }
            completedSubjects = [
              'All',
              ...completedQuestions
                  .where((q) =>
                      q['subject'] != null && q['subject']['name'] != null)
                  .map<String>((q) => q['subject']['name'])
                  .toSet()
                  .toList()
            ];
          });
        }
      }
    } catch (e) {
      if (showLoading) {
        setState(() {
          isLoadingCompleted = false;
        });
      }
      print('Error fetching completed questions: $e');
    }
  }

  List<dynamic> get currentFilteredQuestions {
    final currentTab = _tabController.index;
    final questions =
        currentTab == 0 ? unattemptedQuestions : completedQuestions;
    if (selectedFilter == 'All') return questions;
    return questions
        .where((q) => q['subject']['name'] == selectedFilter)
        .toList();
  }

  List<String> get currentSubjects {
    return _tabController.index == 0 ? availableSubjects : completedSubjects;
  }

  // Replace the existing navigateToExam method with this one
  void navigateToExam(Map<String, dynamic> question) async {
    final questionId =
        question['questionId'] ?? question['questionSetId'] ?? '';
    final isInProgress = await _isExamInProgress(questionId);

    // Extract duration from the question data
    final int durationInMinutes = question['duration']?['minutes'] ??
        60; // Default to 60 if not specified

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            question['title'] ?? 'Test',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isInProgress
                    ? 'Would you like to continue your exam?'
                    : 'Are you ready to start this test?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Subject: ${question['subject']?['name'] ?? 'Unknown'}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                'Unit: ${question['unit']?['name'] ?? 'Unknown'}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        ExamScreen(
                      examTitle: question['title'] ?? 'Test',
                      questionSetId: questionId,
                      studentId: widget.studentId,
                      durationInMinutes:
                          durationInMinutes, // Pass the duration from API
                    ),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
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
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                isInProgress ? 'Continue' : 'Start Test',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void navigateToAttemptDetails(Map<String, dynamic> attempt) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            AttemptDetailsScreen(
          attemptId: attempt['attemptId'],
          title: attempt['title'],
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
    final currentTab = _tabController.index;
    final count = currentTab == 0
        ? unattemptedQuestions.length
        : completedQuestions.length;
    final label =
        currentTab == 0 ? 'Available Questions' : 'Completed Questions';

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
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '$count',
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
        itemCount: currentSubjects.length,
        itemBuilder: (context, index) {
          final subject = currentSubjects[index];
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

  // Add this method to check if exam is in progress
  Future<bool> _isExamInProgress(String questionId) async {
    return await ExamStorageService.hasInProgressExam(
      questionSetId: questionId,
      studentId: widget.studentId,
    );
  }

  // Update the _buildAvailableQuestionCard method
  Widget _buildAvailableQuestionCard(Map<String, dynamic> question, int index) {
    // Fix: Use the correct field name and add null check
    final questionId =
        question['questionId'] ?? question['questionSetId'] ?? '';

    return FutureBuilder<bool>(
      future: questionId.isNotEmpty
          ? _isExamInProgress(questionId)
          : Future.value(false),
      builder: (context, snapshot) {
        final isInProgress = snapshot.data ?? false;
        final subjectName = question['subject']?['name'] ?? 'Unknown';
        final subjectColor = _getSubjectColor(subjectName);
        final unitName = question['unit']?['name'] ?? 'Unknown';

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
                            question['title'] ?? 'Untitled',
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
                                  subjectName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: subjectColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '• $unitName',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (isInProgress) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.timer_outlined,
                                        size: 12,
                                        color: Colors.orange[700],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Continue',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
      },
    );
  }

  Widget _buildCompletedQuestionCard(Map<String, dynamic> attempt, int index) {
    final subjectName = attempt['subject']?['name'] ?? 'Unknown';
    final subjectColor = _getSubjectColor(subjectName);
    final percentage = attempt['percentage'] ?? 0;
    final unitName = attempt['unit']?['name'] ?? 'Unknown';

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () => navigateToAttemptDetails(attempt),
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
                  height: 50,
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
                        attempt['title'] ?? 'Untitled',
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
                              subjectName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: subjectColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• $unitName',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: percentage >= 60
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$percentage%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: percentage >= 60
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${attempt['correctAnswers'] ?? 0}/${attempt['totalQuestions'] ?? 0}',
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
      extendBodyBehindAppBar: true,
      body: Container(
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
          top: true,
          child: RefreshIndicator(
            onRefresh: _refreshAllData,
            color: const Color(0xFF4CAF50),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
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
                      _buildCompactStatsCard(),
                      const SizedBox(height: 24),

                      // Tab Bar
                      // Replace your existing Tab Bar section with this improved version

                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(25),
                          border:
                              Border.all(color: Colors.grey[300]!, width: 0.5),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4CAF50).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicatorPadding: const EdgeInsets.all(4),
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.grey[600],
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                          splashFactory: NoSplash.splashFactory,
                          overlayColor:
                              MaterialStateProperty.all(Colors.transparent),
                          dividerColor: Colors.transparent,
                          tabs: const [
                            Tab(
                              child: Text(
                                'Available',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Tab(
                              child: Text(
                                'Completed',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Available Questions Tab
                      _buildQuestionsTab(
                        isLoading: isLoadingAvailable,
                        questions: currentFilteredQuestions,
                        emptyMessage: 'No available questions',
                        emptySubMessage: selectedFilter == 'All'
                            ? 'Check back later for new questions'
                            : 'No questions found for $selectedFilter',
                        buildCard: _buildAvailableQuestionCard,
                      ),

                      // Completed Questions Tab
                      _buildQuestionsTab(
                        isLoading: isLoadingCompleted,
                        questions: currentFilteredQuestions,
                        emptyMessage: 'No completed questions',
                        emptySubMessage: selectedFilter == 'All'
                            ? 'Start taking some quizzes!'
                            : 'No completed questions for $selectedFilter',
                        buildCard: _buildCompletedQuestionCard,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionsTab({
    required bool isLoading,
    required List<dynamic> questions,
    required String emptyMessage,
    required String emptySubMessage,
    required Widget Function(Map<String, dynamic>, int) buildCard,
  }) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Chips
            if (currentSubjects.length > 2) ...[
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
                : questions.isEmpty
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
                            Text(
                              emptyMessage,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              emptySubMessage,
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
                        itemCount: questions.length,
                        itemBuilder: (context, index) {
                          return buildCard(questions[index], index);
                        },
                      ),
          ],
        ),
      ),
    );
  }
}
