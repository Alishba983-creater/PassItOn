import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:passiton/login.dart';

class Forgot extends StatefulWidget {
  const Forgot({super.key});

  @override
  State<Forgot> createState() => _ForgotState();
}

class _ForgotState extends State<Forgot> {
  final email = TextEditingController();

  resetPassword() async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email.text.trim(),
      );
      Get.snackbar(
        "Success",
        "Password reset link sent to your email.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xffc8e6c9),
        colorText: const Color(0xff1e3d1e),
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Invalid email or network issue.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withOpacity(0.1),
        colorText: const Color(0xff1e3d1e),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xffe8f5e9,
      ), // 🌿 Same background as Login & Signup
      appBar: AppBar(
        backgroundColor: const Color(0xffe9f3ea), // 🌿 Light mint tone
        elevation: 0.8,
        title: const Text(
          'Forgot Password',
          style: TextStyle(
            color: Color(0xff325832), // Deep eco-green
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xff325832)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 🔒 Circular icon container with soft shadow
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(22),
                child: const Icon(
                  Icons.lock_reset_rounded,
                  size: 80,
                  color: Color(0xff4CAF50), // Primary eco-green
                ),
              ),
              const SizedBox(height: 25),
              const Text(
                'Reset Your Password',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff325832),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Enter your registered email and we’ll send you a reset link.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),
              const SizedBox(height: 35),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: Color(0xff4CAF50),
                  ),
                  hintText: 'Email Address',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xff325832,
                    ), // Consistent green
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: const Text(
                    'Send Reset Link',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Get.to(const Login()),
                child: const Text(
                  'Back to Login',
                  style: TextStyle(
                    color: Color(0xff94c273), // Soft mint accent
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
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
