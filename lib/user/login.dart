import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:cloud_firestore/cloud_firestore.dart'; // Không cần nếu chỉ dùng Auth
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLoggedIn();
    });
  }

  Future<void> _checkLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (isLoggedIn && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    }
  }

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
                  controller: _emailController,
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
                  controller: _passwordController,
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
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3DD54A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          minimumSize: const Size(220, 50),
                          elevation: 0,
                        ),
                        onPressed: _login,
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

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập email và mật khẩu')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Lưu trạng thái đăng nhập
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      // Đăng nhập thành công, chuyển sang HomeScreen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Đăng nhập thất bại';
      if (e.code == 'user-not-found') {
        message = 'Không tìm thấy tài khoản';
      } else if (e.code == 'wrong-password') {
        message = 'Sai mật khẩu';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
