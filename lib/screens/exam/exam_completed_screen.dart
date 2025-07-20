import 'package:flutter/material.dart';
import 'package:superexam/main.dart';
import 'package:superexam/screens/home/home_dashboard_screen.dart';

class ExamCompletedScreen extends StatelessWidget {
  final String examTitle;
  final int score;
  final int totalPoints;
  final int averageScore;
  final String duration;

  const ExamCompletedScreen({
    Key? key,
    required this.examTitle,
    required this.score,
    required this.totalPoints,
    required this.averageScore,
    required this.duration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final int percentage = ((score / totalPoints) * 100).round();
    final int wrongAnswers = totalPoints - score;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Back button and title
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 24),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 16),
                  Expanded( // <-- this makes the Text take available space only
                    child: Text(
                      examTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis, // <-- prevent overflow
                      maxLines: 1,
                    ),
                  ),
                ],
              )
,
              const SizedBox(height: 32),

              // Completion icon and text
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.edit,
                            color: Colors.blue,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.lightbulb,
                            color: Colors.amber,
                            size: 28,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                "Exam Completed",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),

              const Divider(height: 32),

              // Test Result Text
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Test Result",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Results grid
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Correct answers indicator
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.green.withOpacity(0.1),
                                ),
                                child: Center(
                                  child: Text(
                                    "$score",
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Correct Answer",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Wrong answers indicator
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.red.withOpacity(0.1),
                                ),
                                child: Center(
                                  child: Text(
                                    "$wrongAnswers",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Wrong Answer",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        // Average score indicator
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey.withOpacity(0.1),
                                ),
                                child: Center(
                                  child: Text(
                                    "$averageScore%",
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Average Score",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Duration indicator
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey.withOpacity(0.1),
                                ),
                                child: Icon(
                                  Icons.timer,
                                  color: Colors.grey[800],
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      duration,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    Text(
                                      "Solving Time",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
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
                  ],
                ),
              ),

              const Spacer(),

              // Back to Home button
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
}

// Example of how to use this screen:
/*
Navigator.of(context).pushReplacement(
  MaterialPageRoute(
    builder: (context) => ExamCompletedScreen(
      examTitle: 'Unit 1 Algae',
      score: 8,
      totalPoints: 10,
      averageScore: 80,
      duration: '00:30 Mins',
    ),
  ),
);
*/