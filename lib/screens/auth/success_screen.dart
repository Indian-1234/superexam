import 'package:flutter/material.dart';
import 'dart:math' show pi, cos, sin;
import 'dart:async'; // Import for Timer

class SuccessScreen extends StatefulWidget {
  const SuccessScreen({Key? key}) : super(key: key);

  @override
  _SuccessScreenState createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> {
  int _secondsRemaining = 5;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // Start the timer when the screen initializes
    startTimer();
  }

  void startTimer() {
    // Create a timer that ticks every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          // When timer reaches 0, cancel timer and navigate to home
          _timer.cancel();
          navigateToHome();
        }
      });
    });
  }

  void navigateToHome() {
    // Navigate to the home dashboard using the named route
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  void dispose() {
    // Cancel the timer when the widget is disposed to prevent memory leaks
    _timer.cancel();
    super.dispose();
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Success icon with flower shape
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Flower shape
                      CustomPaint(
                        size: const Size(120, 120),
                        painter: FlowerShapePainter(),
                      ),

                      // Inner circle
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF5AC15E),
                        ),
                      ),

                      // Checkmark icon
                      const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 50,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Successfully text
                const Text(
                  'Successfully',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 10),

                // Description text
                const Text(
                  'Your account has been created.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 10),

                // Timer text
                Text(
                  'Redirecting in $_secondsRemaining seconds...',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF0B7C25),
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),

                // Information box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: const [
                      Text(
                        'Dear Student your account open after verify',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Please open the app after some time',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'For more details +91 81481 53414',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
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
}

// Custom painter for the flower shape behind the checkmark
class FlowerShapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFF0B7C25)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final path = Path();

    // Create a flower shape with 8 petals
    for (int i = 0; i < 8; i++) {
      final startAngle = (i * pi / 4);
      final petalCenter = Offset(
        center.dx + cos(startAngle) * radius * 0.7,
        center.dy + sin(startAngle) * radius * 0.7,
      );

      path.addOval(Rect.fromCircle(
        center: petalCenter,
        radius: radius * 0.5,
      ));
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}