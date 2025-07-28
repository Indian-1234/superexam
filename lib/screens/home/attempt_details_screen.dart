import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:superexam/config/api_config.dart';
import 'dart:convert';

class AttemptDetailsScreen extends StatefulWidget {
  final String attemptId;
  final String title;

  const AttemptDetailsScreen({
    Key? key,
    required this.attemptId,
    required this.title,
  }) : super(key: key);

  @override
  State<AttemptDetailsScreen> createState() => _AttemptDetailsScreenState();
}

class _AttemptDetailsScreenState extends State<AttemptDetailsScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? attemptDetails;
  bool isLoading = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  String selectedFilter = 'All';
  List<String> filterOptions = ['All', 'Correct', 'Wrong'];

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
    
    fetchAttemptDetails();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> fetchAttemptDetails() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}api/attempt/details/${widget.attemptId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            attemptDetails = data['data'];
            isLoading = false;
          });
          _fadeController.forward();
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching attempt details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error loading attempt details'),
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

  List<Map<String, dynamic>> get filteredQuestions {
    if (attemptDetails == null) return [];
    
    final questions = List<Map<String, dynamic>>.from(attemptDetails!['questions']);
    
    switch (selectedFilter) {
      case 'Correct':
        return questions.where((q) => q['isCorrect'] == true).toList();
      case 'Wrong':
        return questions.where((q) => q['isCorrect'] == false).toList();
      default:
        return questions;
    }
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

  Widget _buildStatsCard() {
    if (attemptDetails == null) return const SizedBox();
    
    final percentage = attemptDetails!['percentage'];
    final correctAnswers = attemptDetails!['correctAnswers'];
    final wrongAnswers = attemptDetails!['wrongAnswers'];
    final totalQuestions = attemptDetails!['totalQuestions'];
    final timeTaken = attemptDetails!['timeTaken'];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4CAF50),
            const Color(0xFF66BB6A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Score',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '$percentage%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Time Taken',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${timeTaken}m',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Correct',
                  correctAnswers.toString(),
                  Colors.white,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white30,
              ),
              Expanded(
                child: _buildStatItem(
                  'Wrong',
                  wrongAnswers.toString(),
                  Colors.white,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white30,
              ),
              Expanded(
                child: _buildStatItem(
                  'Total',
                  totalQuestions.toString(),
                  Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filterOptions.length,
        itemBuilder: (context, index) {
          final option = filterOptions[index];
          final isSelected = selectedFilter == option;
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                option,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  selectedFilter = option;
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

Widget _buildQuestionCard(Map<String, dynamic> questionData, int index) {
  final isCorrect = questionData['isCorrect'] ?? false;
  
  // Extract question text
  final question = questionData['question']?.toString() ?? 'Question not available';
  
  // Extract options as list of strings
  final options = <String>[];
  if (questionData['options'] != null && questionData['options'] is List) {
    for (var option in questionData['options']) {
      if (option is String) {
        options.add(option);
      } else {
        // Fallback for any remaining object format
        options.add(option?.toString() ?? '');
      }
    }
  }
  
  // Extract indices with proper null checks
  final correctOptionIndex = questionData['correctOptionIndex'] is int 
      ? questionData['correctOptionIndex'] 
      : -1;
  final selectedOptionIndex = questionData['selectedOptionIndex'] is int 
      ? questionData['selectedOptionIndex'] 
      : -1;
  
  return FadeTransition(
    opacity: _fadeAnimation,
    child: Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          color: isCorrect ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isCorrect ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isCorrect ? Icons.check : Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Question ${index + 1}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Question Text
            Text(
              question,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Options
            if (options.isNotEmpty)
              ...options.asMap().entries.map((entry) {
                final optionIndex = entry.key;
                final optionText = entry.value;
                final isCorrectOption = optionIndex == correctOptionIndex;
                final isSelectedOption = optionIndex == selectedOptionIndex;
                
                Color backgroundColor = Colors.grey[50]!;
                Color borderColor = Colors.grey[200]!;
                Color textColor = Colors.black87;
                IconData? icon;
                
                if (isCorrectOption) {
                  backgroundColor = Colors.green.withOpacity(0.1);
                  borderColor = Colors.green.withOpacity(0.5);
                  textColor = Colors.green[700]!;
                  icon = Icons.check_circle;
                } else if (isSelectedOption && !isCorrect) {
                  backgroundColor = Colors.red.withOpacity(0.1);
                  borderColor = Colors.red.withOpacity(0.5);
                  textColor = Colors.red[700]!;
                  icon = Icons.cancel;
                }
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isCorrectOption 
                              ? Colors.green 
                              : (isSelectedOption && !isCorrect)
                                  ? Colors.red
                                  : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + optionIndex), // A, B, C, D
                            style: TextStyle(
                              color: (isCorrectOption || (isSelectedOption && !isCorrect))
                                  ? Colors.white
                                  : Colors.black54,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          optionText,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: (isCorrectOption || isSelectedOption) 
                                ? FontWeight.w600 
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (icon != null)
                        Icon(
                          icon,
                          color: isCorrectOption ? Colors.green : Colors.red,
                          size: 20,
                        ),
                    ],
                  ),
                );
              }).toList()
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'No options available for this question',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4CAF50),
              ),
            )
          : attemptDetails == null
              ? const Center(
                  child: Text('Failed to load attempt details'),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats Card
                        _buildStatsCard(),
                        
                        const SizedBox(height: 24),
                        
                        // Section Header
                        const Text(
                          'Question Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Filter Chips
                        _buildFilterChips(),
                        
                        const SizedBox(height: 16),
                        
                        // Questions List
                        filteredQuestions.isEmpty
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
                                      'No ${selectedFilter.toLowerCase()} questions found',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
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
    );
  }
}