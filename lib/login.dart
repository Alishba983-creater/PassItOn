import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:passiton/forgot.dart';
import 'package:passiton/homepage.dart';

import 'package:passiton/signup.dart';
import 'package:flutter/foundation.dart';

class Login extends StatefulWidget {
  const Login({super.key});
  @override
  State createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool isLoading = false;


  signInWithGoogle() async {
    try {
      UserCredential userCredential;
      if (kIsWeb) {
        GoogleAuthProvider authProvider = GoogleAuthProvider();
        userCredential =
            await FirebaseAuth.instance.signInWithPopup(authProvider);
      } else {
        final googleSignIn = GoogleSignIn();
        await googleSignIn.signInSilently();
        final account = await googleSignIn.signIn();
        if (account == null) return;
        final auth = await account.authentication;
        final credential =
            GoogleAuthProvider.credential(idToken: auth.idToken);
        userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
      }
      if (userCredential.user != null) Get.offAll(() => const HomePage());
    } catch (e) {
      Get.snackbar("Error", "Google Sign-In failed. Please try again.");
    }
  }

  signin() async {
    setState(() => isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.text.trim(), password: password.text.trim());

      Get.offAll(() => const HomePage());
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffe8f5e9), // 🌿 Eco-friendly background
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline,
                  size: 90, color: Color(0xff325832)), // deep forest green
              const SizedBox(height: 20),
              const Text(
                "Welcome Back",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff1e3d1e), // darker green text
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Login to continue",
                style: TextStyle(color: Color(0xff486f48), fontSize: 16),
              ),
              const SizedBox(height: 40),

              // Email Field
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  prefixIcon:
                      const Icon(Icons.email_outlined, color: Color(0xff325832)),
                  hintText: 'Email Address',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 18, horizontal: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Password Field
              TextField(
                controller: password,
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon:
                      const Icon(Icons.lock_outline, color: Color(0xff325832)),
                  hintText: 'Password',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 18, horizontal: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Get.to(const Forgot()),
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(color: Color(0xff94c273)),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => signin(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xff325832), // primary eco green
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                    shadowColor: Colors.greenAccent.withOpacity(0.4),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Login",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 25),

              // Divider
              Row(
                children: const [
                  Expanded(child: Divider(thickness: 1.2)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text("or", style: TextStyle(color: Colors.black54)),
                  ),
                  Expanded(child: Divider(thickness: 1.2)),
                ],
              ),
              const SizedBox(height: 25),

              // Google Sign-In
              OutlinedButton.icon(
                onPressed: () => signInWithGoogle(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 20),
                  side: const BorderSide(color: Color(0xff325832), width: 1.4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: Image.asset('assets/google-logo.png', height: 22),
                label: const Text(
                  "Sign in with Google",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff325832),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Sign Up Link
              TextButton(
                onPressed: () => Get.to(const Signup()),
                child: const Text(
                  "Don’t have an account? Register",
                  style: TextStyle(
                    color: Color(0xff94c273),
                    fontWeight: FontWeight.w600,
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
