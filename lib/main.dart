import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:salespro/admin/routes.dart';
import 'login.dart';

void main() {
  runApp(const SalezmanApp());
}

class SalezmanApp extends StatelessWidget {
  const SalezmanApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return MaterialApp.router(
        title: 'SalesPro Admin',
        routerConfig: adminRouter,
        debugShowCheckedModeBanner: false,
      );
    } else {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SplashScreen(),
      );
    }
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
  }

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
            // Nút SALESPRO
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF3DD54A),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
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
