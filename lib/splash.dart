import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:passiton/wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      
      Get.offAll(() => const Wrapper());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff325832),
      body: FadeTransition(
        opacity: _fadeIn,
        child: Center(
          child: ClipOval(
            child: Image.asset(
              'assets/logo.png',
              width: 150,
              height: 150,
            ),
          ),
        ),
      ),
    );
  }
}
