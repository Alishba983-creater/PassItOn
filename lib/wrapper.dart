import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:passiton/homepage.dart';
import 'package:passiton/login.dart';
//import 'package:passiton/verify.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Something went wrong.')),
          );
        }

        
        if (!snapshot.hasData) {
          return const Login();
        }

       // final user = snapshot.data!;
       
        // if (!user.emailVerified) {
        //   return const Verify();
        // }

        // 🏠 If verified → go to Home
        return const HomePage();
      },
    );
  }
}
