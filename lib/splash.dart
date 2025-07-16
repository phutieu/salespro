import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xF9FCFDFF),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo S
            Container(
              margin: const EdgeInsets.only(bottom: 32),
              child: CustomPaint(
                size: const Size(160, 120),
                painter: SLogoPainter(),
              ),
            ),
            // Nút SALEZMAN
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3DD54A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  minimumSize: const Size(300, 56),
                  elevation: 0,
                ),
                onPressed: () {},
                child: const Text(
                  'SALESPRO',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 32,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3DD54A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.8, size.height * 0.25);
    path.cubicTo(
      size.width * 0.7,
      size.height * 0.05,
      size.width * 0.2,
      size.height * 0.05,
      size.width * 0.2,
      size.height * 0.35,
    );
    path.cubicTo(
      size.width * 0.2,
      size.height * 0.55,
      size.width * 0.8,
      size.height * 0.55,
      size.width * 0.8,
      size.height * 0.75,
    );
    path.cubicTo(
      size.width * 0.8,
      size.height * 0.95,
      size.width * 0.3,
      size.height * 0.95,
      size.width * 0.2,
      size.height * 0.75,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
