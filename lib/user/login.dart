import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xF9FCFDFF),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo S
              Container(
                margin: const EdgeInsets.only(bottom: 32),
                child: CustomPaint(
                  size: const Size(120, 90),
                  painter: SLogoPainter(),
                ),
              ),
              // Nút SALESPRO
              Container(
                margin: const EdgeInsets.only(bottom: 32),
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
                      fontSize: 28,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              // Ô nhập email
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Nhập email',
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
              // Ô nhập mật khẩu
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: TextField(
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Mật khẩu',
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
              ),
              // Quên mật khẩu
              Container(
                alignment: Alignment.centerLeft,
                margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
                child: TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: const Text(
                    'Quên mật khẩu?',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              // Nút Đăng nhập
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3DD54A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    minimumSize: const Size(220, 50),
                    elevation: 0,
                  ),
                  onPressed: () {},
                  child: const Text(
                    'Đăng nhập',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
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

class SLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3DD54A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
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
