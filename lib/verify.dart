import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:passiton/login.dart';
import 'package:passiton/signup.dart';

class Verify extends StatefulWidget {
  const Verify({super.key});

  @override
  State<Verify> createState() => _VerifyState();
}

class _VerifyState extends State<Verify> {
  @override
  void initState() {
    sendVerifyLink();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Get.offAll(() => Signup());
          },
        ),
        title: const Text("Verify Email"),
        centerTitle: true,
      ),
      body: const Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(
          child: Text("A verification link has been sent to your email."),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          reload();
        },
        child: const Icon(Icons.restart_alt_rounded),
      ),
    );
  }

  void sendVerifyLink() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
      Get.snackbar(
        "Link sent",
        "A verification link has been sent to ${user.email}",
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        "Error",
        "User not logged in or already verified",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void reload() async {
    await FirebaseAuth.instance.currentUser!.reload();

    final user = FirebaseAuth.instance.currentUser;

    if (user != null && user.emailVerified) {
      Get.offAll(() => const Login());
    } else {
      Get.snackbar(
        "Not verified",
        "Please verify your email before continuing.",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
