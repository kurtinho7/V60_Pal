import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:v60pal/Theme.dart';
import 'package:v60pal/main.dart';
import 'SignInScreen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snap.data;
        return user == null ? const SignInScreen() : ChooseIfSignedIn();
      },
    );
  }
}

class ChooseIfSignedIn extends StatelessWidget {
  const ChooseIfSignedIn({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Sign Out?', style: TextStyle(color: TEXT_COLOR),),
      content: Text(''),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            FirebaseAuth.instance.signOut();
            Navigator.pop(context);
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
