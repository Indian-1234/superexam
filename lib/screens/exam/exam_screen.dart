import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:no_screenshot/no_screenshot.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:superexam/config/api_config.dart';

import '../../models/question_modal.dart';
import 'result_screen.dart';
import 'exam_timer_mixin.dart';

class ExamScreen extends StatefulWidget {
  final String examTitle;
  final String questionSetId;
  final String studentId;
  

  const ExamScreen({
    Key? key,
    required this.examTitle,
    required this.questionSetId,
    required this.studentId,
  }) : super(key: key);

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> with ExamTimerMixin {  
  int currentQuestionIndex = 0;
  List<QuestionModel> questions = [];
  List<int?> userAnswers = [];
  bool isLoading = true;
  String? examid='683b295032cd4b16ddb34e97';
  String? errorMessage;
  Map<String, int> correctOptionIndexMap = {}; // Added this property to track correct options
  String? subjectId;
  String? unitId;
  String? topicsId;
  
  final _noScreenshot = NoScreenshot.instance;
  bool _isScreenProtected = false;
  @override
void initState() {
  super.initState();
  initializeTimer(
    duration: Duration(hours: 1),
    onTimeUpCallback: _submitExam,
  );
  _enableScreenProtection();
  _fetchQuestions();
}


Future<void> _fetchQuestions() async {
  try {
    final response = await http.get(
  Uri.parse('${ApiConfig.baseUrl}api/questions/${widget.questionSetId}'),
    );
    print('Status: ${response.statusCode}, Body: ${response.body} ***********************************************************');
    
    if (response.statusCode == 200) {
      final questionData = json.decode(response.body);
      
      setState(() {
        // Reset correctOptionIndexMap
        correctOptionIndexMap = {};
        
        // Handle the API response structure with nested data
        if (questionData != null && 
            questionData.containsKey('data') && 
            questionData['data'].containsKey('questions') && 
            questionData['data']['questions'] is List) {
          
          // Extract subject, unit, and topics IDs from the response
          if (questionData['data'].containsKey('subject') && questionData['data']['subject']['_id'] != null) {
            subjectId = questionData['data']['subject']['_id'];
          }
          if (questionData['data'].containsKey('unit') && questionData['data']['unit']['_id'] != null) {
            unitId = questionData['data']['unit']['_id'];
          }
          
          if (questionData['data'].containsKey('topics') && questionData['data']['topics'] != null) {
  topicsId = questionData['data']['topics'].toString();
}
          
          final questionsList = questionData['data']['questions'] as List;
          
          questions = questionsList.map((item) {
            // Extract options as a list of strings
            List<String> optionTexts = [];
            int correctIndex = -1;

            if (item.containsKey('options') && item['options'] is List) {
              final options = item['options'] as List;
              optionTexts = options.map((option) => option['text'].toString()).toList();

              // Find the correct option index
              for (int i = 0; i < options.length; i++) {
                if (options[i]['isCorrect'] == true) {
                  correctIndex = i;
                  correctOptionIndexMap[item['_id']] = i;
                  break;
                }
              }
            }

            return QuestionModel(
              id: item['_id'] ?? '',
              question: item['questionText'] ?? '',
              options: optionTexts,
              correctOptionIndex: correctIndex,
            );
          }).toList();
        }
        // Check if it's a direct list of questions
        else if (questionData is List) {
          questions = questionData.map((item) {
            // Extract options as a list of strings
            List<String> optionTexts = [];
            int correctIndex = -1;
            
            if (item.containsKey('options') && item['options'] is List) {
              final options = item['options'] as List;
              optionTexts = options.map((option) => option['text'].toString()).toList();
              
              // Find the correct option index
              for (int i = 0; i < options.length; i++) {
                if (options[i]['isCorrect'] == true) {
                  correctIndex = i;
                  correctOptionIndexMap[item['_id']] = i;
                  break;
                }
              }
            }
            
            return QuestionModel(
              id: item['_id'] ?? item['questionId'] ?? '',
              question: item['questionText'] ?? '',
              options: optionTexts,
              correctOptionIndex: correctIndex,
            );
          }).toList();
        }
        // If it's wrapped in an object structure but not under 'data'
        else if (questionData != null && questionData.containsKey('questions') && questionData['questions'] is List) {
          questions = (questionData['questions'] as List).map((item) {
            // Extract options as a list of strings
            List<String> optionTexts = [];
            int correctIndex = -1;
            
            if (item.containsKey('options') && item['options'] is List) {
              final options = item['options'] as List;
              optionTexts = options.map((option) => option['text'].toString()).toList();
              
              // Find the correct option index
              for (int i = 0; i < options.length; i++) {
                if (options[i]['isCorrect'] == true) {
                  correctIndex = i;
                  correctOptionIndexMap[item['_id']] = i;
                  break;
                }
              }
            }
            
            return QuestionModel(
              id: item['_id'] ?? item['questionId'] ?? '',
              question: item['questionText'] ?? '',
              options: optionTexts,
              correctOptionIndex: correctIndex,
            );
          }).toList();
        }
        // Keep your existing recursive extraction as fallback
        else {
          Map<String, dynamic> mapData = questionData;
          _extractQuestionsRecursively(mapData);
        }
        
        userAnswers = List.filled(questions.length, null);
        isLoading = false;
      });
    } else {
      setState(() {
        errorMessage = 'Failed to load questions. Status: ${response.statusCode}';
        isLoading = false;
      });
    }
  } catch (e) {
    setState(() {
      errorMessage = 'Error: ${e.toString()}';
      isLoading = false;
    });
  }
}
  // Recursive function to extract questions from any JSON structure
  void _extractQuestionsRecursively(dynamic data) {
    if (data is Map<String, dynamic>) {
      // Check direct entries
      if (data.containsKey('questions') && data['questions'] is List) {
        _processQuestionsList(data['questions']);
        return;
      }

      // Process each entry recursively
      data.forEach((key, value) {
        if (value is Map<String, dynamic> || value is List) {
          _extractQuestionsRecursively(value);
        }
      });
    } else if (data is List) {
      // Check if this is a list of questions
      if (data.isNotEmpty && data[0] is Map<String, dynamic>) {
        if (data[0].containsKey('questionText') || data[0].containsKey('question')) {
          _processQuestionsList(data);
          return;
        }
      }

      // Process each item recursively
      for (var item in data) {
        _extractQuestionsRecursively(item);
      }
    }
  }

  // Process a list that contains questions
  void _processQuestionsList(List<dynamic> questionsList) {
    questions = questionsList.map((item) {
      String questionText = item['questionText'] ?? item['question'] ?? '';
      String id = item['_id'] ?? item['questionId'] ?? item['id'] ?? '';

      List<String> optionTexts = [];
      int correctIndex = -1;

      // Handle different option formats
      if (item.containsKey('options')) {
        var options = item['options'];
        if (options is List) {
          if (options.isNotEmpty) {
            // If options are objects with text field
            if (options[0] is Map) {
              optionTexts = options
                  .map<String>((option) => option['text']?.toString() ?? '')
                  .toList();

              // Find correct option
              for (int i = 0; i < options.length; i++) {
                if (options[i]['isCorrect'] == true) {
                  correctIndex = i;
                  correctOptionIndexMap[id] = i;
                  break;
                }
              }
            }
            // If options are directly strings
            else {
              optionTexts = options.map<String>((option) => option.toString()).toList();
            }
          }
        }
      }

      return QuestionModel(
        id: id,
        question: questionText,
        options: optionTexts,
        correctOptionIndex: correctIndex,
      );
    }).toList();
  }

  void _selectAnswer(int answerIndex) {
    setState(() {
      userAnswers[currentQuestionIndex] = answerIndex;
    });
  }

  void _navigateToQuestion(int index) {
    if (index >= 0 && index < questions.length) {
      setState(() {
        currentQuestionIndex = index;
      });
    }
  }

  void _nextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      _navigateToQuestion(currentQuestionIndex + 1);
    } else {
      // Check if the exam is complete (all questions answered)
      final allAnswered = !userAnswers.contains(null);
      if (allAnswered) {
        _submitExam();
      } else {
        // Show dialog to confirm submission with unanswered questions
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Incomplete Exam'),
            content: const Text('You have unanswered questions. Are you sure you want to submit?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _submitExam();
                },
                child: const Text('Submit Anyway'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _submitExam() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Prepare answers in the format expected by the API
      final List<Map<String, dynamic>> formattedAnswers = [];
      final List<Map<String, dynamic>> questionResults = [];

      for (int i = 0; i < questions.length; i++) {
        // Only include answered questions for submission
        if (userAnswers[i] != null) {
          formattedAnswers.add({
            'questionId': questions[i].id,
            'selectedOptionIndex': userAnswers[i],
          });
        }

        // Prepare question results for the result screen (include all questions)
        questionResults.add({
          'id': questions[i].id,
          'questionText': questions[i].question,
          'options': questions[i].options,
          'userAnswerIndex': userAnswers[i],
          'correctOptionIndex': correctOptionIndexMap[questions[i].id] ?? 0,
        });
      }

      int correctCount = 0;
int wrongCount = 0;
int missedCount = 0;

for (int i = 0; i < questions.length; i++) {
  if (userAnswers[i] == null) {
    missedCount++;
  } else if (userAnswers[i] == correctOptionIndexMap[questions[i].id]) {
    correctCount++;
  } else {
    wrongCount++;
  }
}

final response = await http.post(
  Uri.parse('${ApiConfig.baseUrl}api/attempt/submit'),
  headers: {'Content-Type': 'application/json'},
 body: json.encode({
  'studentId': widget.studentId,
  'questionSetId': widget.questionSetId,
  'subjectId': subjectId,
  'unitId': unitId,
  'topicsId': topicsId,
  'answers': formattedAnswers,
  'correctAnswersCount': correctCount,
  'wrongAnswersCount': wrongCount,
  'missedAnswersCount': missedCount,
  'totalQuestionsCount': questions.length,
  ...getTimeData(), // This adds startTime and endTime
}),
);
      print('Status: ${formattedAnswers}, Body: ${response.body} ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^');

      if (response.statusCode == 201) {
        final result = json.decode(response.body);
        
        // Disable screen protection before navigating
        await _disableScreenProtection();

        // Navigate to result screen with the submission result
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              examTitle: widget.examTitle,
              totalScore: result['totalScore'],
              totalQuestions: questions.length,
              attemptId: result['attemptId'],
              pointValue: questions.isNotEmpty ? result['totalScore'] / questions.length : 0,
              questionResults: questionResults, // New parameter passing question results
            ),
          ),
        );
      } else {
        setState(() {
          errorMessage = 'Failed to submit answers. Status: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error submitting exam: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  void _skipQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      _navigateToQuestion(currentQuestionIndex + 1);
    }
  }

  Future<void> _enableScreenProtection() async {
    try {
      // Enable screenshot blocking
      await _noScreenshot.screenshotOff();
      
      // Enable screen recording protection
      await ScreenProtector.protectDataLeakageOn();
      
      // Prevent screenshots in app switcher
      await ScreenProtector.preventScreenshotOn();
      
      setState(() {
        _isScreenProtected = true;
      });
      
      print('Screen protection enabled successfully');
    } catch (e) {
      print('Failed to enable screen protection: $e');
    }
  }

  Future<void> _disableScreenProtection() async {
    try {
      // Disable screenshot blocking
      await _noScreenshot.screenshotOn();
      
      // Disable screen recording protection
      await ScreenProtector.protectDataLeakageOff();
      
      // Allow screenshots
      await ScreenProtector.preventScreenshotOff();
      
      setState(() {
        _isScreenProtected = false;
      });
      
      print('Screen protection disabled successfully');
    } catch (e) {
      print('Failed to disable screen protection: $e');
    }
  }

  @override
  void dispose() {
    _disableScreenProtection(); // Clean up protection when leaving screen
    disposeTimer(); // Your existing timer disposal
    super.dispose();
  }

  // Add this method to properly dispose the timer
  void disposeTimer() {
    stopTimer(); // Call the timer cancellation method from ExamTimerMixin
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
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage != null
              ? Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        errorMessage = null;
                        isLoading = true;
                      });
                      _fetchQuestions();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          )
              : questions.isEmpty
              ? Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No questions found for this exam.',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isLoading = true;
                      });
                      _fetchQuestions();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          )
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with back button and title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Exit Exam?'),
                            content: const Text('Your progress will be lost if you exit now.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(context); // Close dialog
                                  await _disableScreenProtection(); // Disable protection before exit
                                  Navigator.pop(context); // Exit exam
                                },
                                child: const Text('Exit Anyway'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
      Expanded(
        child: Text(
          widget.examTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      buildTimerWidget(),
                 
                  
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Question navigation dots
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _navigateToQuestion(index),
                      child: Container(
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: currentQuestionIndex == index
                              ? Colors.green
                              : userAnswers[index] != null
                              ? Colors.grey.shade300
                              : Colors.grey.shade200,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: currentQuestionIndex == index
                                  ? Colors.white
                                  : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Question content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Que ${currentQuestionIndex + 1}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        questions[currentQuestionIndex].question,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Options
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: List.generate(
                              questions[currentQuestionIndex].options.length,
                                  (index) {
                                final optionLabels = ['A', 'B', 'C', 'D', 'E', 'F'];
                                final optionLabel = index < optionLabels.length ? optionLabels[index] : (index + 1).toString();

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: GestureDetector(
                                    onTap: () => _selectAnswer(index),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                        horizontal: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: userAnswers[currentQuestionIndex] == index
                                            ? const Color(0xFFE5F7E6)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: userAnswers[currentQuestionIndex] == index
                                              ? Colors.green
                                              : Colors.grey.shade300,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            '$optionLabel) ',
                                            style: TextStyle(
                                              color: userAnswers[currentQuestionIndex] == index
                                                  ? Colors.green
                                                  : Colors.black,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              questions[currentQuestionIndex].options[index],
                                              style: TextStyle(
                                                color: userAnswers[currentQuestionIndex] == index
                                                    ? Colors.green
                                                    : Colors.black,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    
                    ],
                  ),
                ),
              ),

              // Bottom buttons
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _skipQuestion,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: const Text(
                          'Skip',
                          style: TextStyle(color: Colors.black87),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _nextQuestion,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          currentQuestionIndex == questions.length - 1
                              ? 'Complete Exam'
                              : 'Save & Next',
                          style: const TextStyle(color: Colors.white),
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
    );
  }
}