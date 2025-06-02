import 'package:flutter/material.dart';
import '../../models/test_model.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';
import '../../widgets/test_card.dart';
import 'exam_screen.dart';

class TestListScreen extends StatefulWidget {
  final ApiService apiService;

  const TestListScreen({
    Key? key,
    required this.apiService,
  }) : super(key: key);

  @override
  _TestListScreenState createState() => _TestListScreenState();
}

class _TestListScreenState extends State<TestListScreen> {
  List<Test> _tests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTests();
  }

  Future<void> _fetchTests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tests = await widget.apiService.getAvailableTests();
      setState(() {
        _tests = tests;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching tests: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Tests'),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchTests,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _tests.isEmpty
            ? const Center(
          child: Text(
            'No tests available',
            style: TextStyle(color: AppTheme.secondaryTextColor),
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _tests.length,
          itemBuilder: (context, index) {
            return TestCard(
              test: _tests[index],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExamScreen(
                      test: _tests[index],
                      apiService: widget.apiService,
                    ),
                  ),
                ).then((_) => _fetchTests());
              },
            );
          },
        ),
      ),
    );
  }
}
