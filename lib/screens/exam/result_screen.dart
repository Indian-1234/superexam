import 'package:flutter/material.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:superexam/main.dart';
import 'package:superexam/screens/home/home_dashboard_screen.dart';

class ResultScreen extends StatefulWidget {
  final String examTitle;
  final int totalScore;
  final int totalQuestions;
  final String attemptId;
  final double pointValue;
  final List<Map<String, dynamic>> questionResults;

  const ResultScreen({
    Key? key,
    required this.examTitle,
    required this.totalScore,
    required this.totalQuestions,
    required this.attemptId,
    required this.pointValue,
    required this.questionResults,
  }) : super(key: key);

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final _noScreenshot = NoScreenshot.instance;
  bool _isScreenProtected = false;

  @override
  void initState() {
    super.initState();
    _enableScreenProtection();
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

      print('Screen protection enabled for ResultScreen');
    } catch (e) {
      print('Failed to enable screen protection: $e');
    }
  }

  Future<void> _disableScreenProtection() async {
    try {
      await _noScreenshot.screenshotOn();
      await ScreenProtector.protectDataLeakageOff();
      await ScreenProtector.preventScreenshotOff();
      setState(() {
        _isScreenProtected = false;
      });
    } catch (e) {
      print('Failed to disable screen protection: $e');
    }
  }

  @override
  void dispose() {
    _disableScreenProtection();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate correct answers count
    int correctAnswers = 0;
    for (var question in widget.questionResults) {
      if (question['userAnswerIndex'] != null &&
          question['userAnswerIndex'] == question['correctOptionIndex']) {
        correctAnswers++;
      }
    }

    // Calculate total points based on pointValue and correct answers
    double totalPoints = correctAnswers * widget.pointValue;
    double maxPoints = widget.totalQuestions * widget.pointValue;

    // Calculate percentage for the circular indicator
    double percentage = widget.totalQuestions > 0 ? correctAnswers / widget.totalQuestions : 0;

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
                        Navigator.of(context).popUntil((route) => route.isFirst);
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
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Results card
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Result summary card
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              CircularPercentIndicator(
                                radius: 80.0,
                                lineWidth: 12.0,
                                animation: true,
                                percent: percentage.clamp(0.0, 1.0),
                                center: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '$correctAnswers/${widget.totalQuestions}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20.0,
                                      ),
                                    ),
                                    Text(
                                      '${(percentage * 100).toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16.0,
                                      ),
                                    ),
                                  ],
                                ),
                                circularStrokeCap: CircularStrokeCap.round,
                                progressColor: percentage >= 0.7
                                    ? Colors.green
                                    : percentage >= 0.4
                                    ? Colors.orange
                                    : Colors.red,
                              ),
                              const SizedBox(height: 24),
                              _buildInfoRow('Total Points:', '${totalPoints.toStringAsFixed(1)}/${maxPoints.toStringAsFixed(1)}'),
                              const SizedBox(height: 8),
                              _buildInfoRow('Points per Question:', widget.pointValue.toStringAsFixed(1)),
                              const SizedBox(height: 8),
                              _buildInfoRow('Correct Answers:', '$correctAnswers out of ${widget.totalQuestions}'),
                              // const SizedBox(height: 8),
                              // _buildInfoRow('Attempt ID:', attemptId),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      const Text(
                        'Question Review',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Question review
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.questionResults.length,
                        itemBuilder: (context, index) {
                          final question = widget.questionResults[index];
                          final userAnswerIndex = question['userAnswerIndex'];
                          final correctOptionIndex = question['correctOptionIndex'];
                          final isCorrect = userAnswerIndex != null && userAnswerIndex == correctOptionIndex;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isCorrect ? Colors.green.shade200 : Colors.red.shade200,
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isCorrect
                                              ? Colors.green.shade100
                                              : Colors.red.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          isCorrect ? 'Correct' : 'Incorrect',
                                          style: TextStyle(
                                            color: isCorrect ? Colors.green.shade800 : Colors.red.shade800,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Question ${index + 1}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        isCorrect ? '+${widget.pointValue.toStringAsFixed(1)} points' : '0 points',
                                        style: TextStyle(
                                          color: isCorrect ? Colors.green : Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    question['questionText'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Column(
                                    children: List.generate(
                                      (question['options'] as List).length,
                                          (idx) {
                                        final optionLabels = ['A', 'B', 'C', 'D', 'E', 'F'];
                                        final optionLabel = idx < optionLabels.length
                                            ? optionLabels[idx]
                                            : (idx + 1).toString();
                                        final isUserAnswer = userAnswerIndex == idx;
                                        final isCorrectOption = correctOptionIndex == idx;

                                        Color bgColor = Colors.white;
                                        Color borderColor = Colors.grey.shade300;
                                        Color textColor = Colors.black;

                                        if (isUserAnswer && isCorrectOption) {
                                          bgColor = Colors.green.shade50;
                                          borderColor = Colors.green;
                                          textColor = Colors.green.shade800;
                                        } else if (isUserAnswer) {
                                          bgColor = Colors.red.shade50;
                                          borderColor = Colors.red;
                                          textColor = Colors.red.shade800;
                                        } else if (isCorrectOption) {
                                          bgColor = Colors.green.shade50;
                                          borderColor = Colors.green.shade300;
                                          textColor = Colors.green.shade800;
                                        }

                                        return Container(
                                          width: double.infinity,
                                          margin: const EdgeInsets.only(bottom: 8),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                            horizontal: 16,
                                          ),
                                          decoration: BoxDecoration(
                                            color: bgColor,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: borderColor,
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Text(
                                                '$optionLabel) ',
                                                style: TextStyle(
                                                  color: textColor,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  question['options'][idx],
                                                  style: TextStyle(color: textColor),
                                                ),
                                              ),
                                              if (isUserAnswer)
                                                Icon(
                                                  Icons.check_circle,
                                                  color: isCorrectOption ? Colors.green : Colors.red,
                                                  size: 20,
                                                )
                                              else if (isCorrectOption)
                                                const Icon(
                                                  Icons.check_circle_outline,
                                                  color: Colors.green,
                                                  size: 20,
                                                ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Action buttons
                SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    onPressed: () async {
      // Get user session data
      final userName = await UserSession.getUserName() ?? 'Student';
      final userId = await UserSession.getUserId() ?? '';
      
      // Clear all routes and push HomeDashboardScreen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => HomeDashboardScreen(
            username: userName,
            studentId: userId,
          ),
        ),
        (route) => false, // Remove all previous routes
      );
    },
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 16),
      backgroundColor: Colors.green,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    child: const Text(
      'Back to Home',
      style: TextStyle(color: Colors.white),
    ),
  ),
),
          
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8), // Add spacing between the label and value
        Flexible(  // Wrap the value text in Flexible
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis, // Handle potential overflow
            textAlign: TextAlign.end, // Align text to the right
          ),
        ),
      ],
    );
  }

}