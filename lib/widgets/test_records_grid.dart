import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TestRecordsGrid extends StatefulWidget {
  final String studentId;
  
  const TestRecordsGrid({
    Key? key, 
    required this.studentId,
  }) : super(key: key);

  @override
  State<TestRecordsGrid> createState() => _TestRecordsGridState();
}

class _TestRecordsGridState extends State<TestRecordsGrid> {
  Map<String, dynamic>? studentData;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchStudentStatus();
  }

  Future<void> fetchStudentStatus() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/students/${widget.studentId}/status'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            studentData = data['data'];
            isLoading = false;
          });
        } else {
          setState(() {
            error = data['message'] ?? 'Failed to load data';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          error = 'Server error: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Network error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Test Records',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          if (isLoading)
            Container(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.green),
                    SizedBox(height: 16),
                    Text('Loading your progress...', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            )
          else if (error != null)
            Container(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 48),
                    SizedBox(height: 16),
                    Text('Failed to load data', style: TextStyle(color: Colors.red)),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isLoading = true;
                          error = null;
                        });
                        fetchStudentStatus();
                      },
                      child: Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else
            _buildGridView(),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    final performance = studentData!['overallPerformance'];
    final completedUnits = studentData!['completedUnits'].length;
    final completedTopics = studentData!['completedTopics'].length;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.8,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildRecordItem(
          icon: Icons.book,
          title: 'Completed Units',
          value: completedUnits.toString().padLeft(2, '0'),
          color: Colors.green,
          onTap: () => _showUnitsModal(),
        ),
        _buildRecordItem(
          icon: Icons.library_books,
          title: 'Completed Topics',
          value: completedTopics.toString().padLeft(2, '0'),
          color: Colors.blue,
          onTap: () => _showTopicsModal(),
        ),
        _buildRecordItem(
          icon: Icons.assignment,
          title: 'Total Attempts',
          value: performance['totalAttempts'].toString().padLeft(2, '0'),
          color: Colors.orange,
          onTap: () => _showAttemptsModal(),
        ),
        _buildRecordItem(
          icon: Icons.bar_chart,
          title: 'Accuracy',
          value: '${performance['accuracyPercentage'].toStringAsFixed(0)}%',
          color: _getAccuracyColor(performance['accuracyPercentage']),
          onTap: () => _showPerformanceModal(),
        ),
      ],
    );
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 80) return Colors.green;
    if (accuracy >= 60) return Colors.orange;
    return Colors.red;
  }

  Widget _buildRecordItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
             child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisAlignment: MainAxisAlignment.center,
  mainAxisSize: MainAxisSize.min,
  children: [
    Flexible(
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey[600],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
    const SizedBox(height: 2),
    Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 2),
          Icon(
            Icons.touch_app,
            size: 10,
            color: Colors.grey[400],
          ),
        ],
      ),
    ),
  ],
),
            
            ),
          ],
        ),
      ),
    );
  }

  void _showUnitsModal() {
    final units = studentData!['completedUnits'] as List;
    _showCustomModal(
      title: 'Completed Units',
      icon: Icons.book,
      color: Colors.green,
      content: units.isEmpty 
        ? [_buildEmptyState('No units completed yet')]
        : units.map((unit) => _buildListItem(
            title: unit['unitName'],
            subtitle: 'Subject: ${unit['subjectName']}',
            trailing: 'Code: ${unit['unitCode']}',
          )).toList(),
    );
  }

  void _showTopicsModal() {
    final topics = studentData!['completedTopics'] as List;
    _showCustomModal(
      title: 'Completed Topics',
      icon: Icons.library_books,
      color: Colors.blue,
      content: topics.isEmpty 
        ? [_buildEmptyState('No topics completed yet')]
        : topics.map((topic) => _buildListItem(
            title: topic['topicName'],
            subtitle: 'Unit: ${topic['unitName']}',
            trailing: topic['subjectName'],
          )).toList(),
    );
  }

  void _showAttemptsModal() {
    final attempts = studentData!['detailedStats']['attemptsSummary'] as List;
    _showCustomModal(
      title: 'Recent Attempts',
      icon: Icons.assignment,
      color: Colors.orange,
      content: attempts.map((attempt) => _buildAttemptItem(attempt)).toList(),
    );
  }

  void _showPerformanceModal() {
    final performance = studentData!['overallPerformance'];
    _showCustomModal(
      title: 'Performance Overview',
      icon: Icons.bar_chart,
      color: _getAccuracyColor(performance['accuracyPercentage']),
      content: [
        _buildPerformanceItem('Total Questions', performance['totalQuestions'].toString()),
        _buildPerformanceItem('Correct Answers', performance['correctAnswers'].toString()),
        _buildPerformanceItem('Wrong Answers', performance['wrongAnswers'].toString()),
        _buildPerformanceItem('Missed Answers', performance['missedAnswers'].toString()),
        _buildPerformanceItem('Accuracy', '${performance['accuracyPercentage'].toStringAsFixed(1)}%'),
        _buildPerformanceItem('Average Score', performance['averageScore'].toStringAsFixed(2)),
      ],
    );
  }

  void _showCustomModal({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> content,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  SizedBox(width: 16),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: content.length,
                  itemBuilder: (context, index) => content[index],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListItem({required String title, required String subtitle, required String trailing}) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(trailing, style: TextStyle(color: Colors.green, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildAttemptItem(Map<String, dynamic> attempt) {
    final accuracy = attempt['accuracyPercentage'] ?? 0.0;
    final accuracyColor = _getAccuracyColor(accuracy.toDouble());
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  attempt['unitName'] != 'Unknown Unit' 
                    ? attempt['unitName'] 
                    : 'Practice Test',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accuracyColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${accuracy.toStringAsFixed(0)}%',
                  style: TextStyle(color: accuracyColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              _buildStatChip('Score: ${attempt['score']}', Colors.blue),
              SizedBox(width: 8),
              _buildStatChip('Time: ${attempt['timeTaken']}', Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceItem(String label, String value) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}