import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'SignInScreen.dart';

class AuthGate extends StatelessWidget {
  final bool showSignOutWhenSignedIn;

  const AuthGate({super.key, this.showSignOutWhenSignedIn = false});

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
        if (user == null) return const SignInScreen();
        return showSignOutWhenSignedIn
            ? const ChooseIfSignedIn()
            : const _CloseAfterSignIn();
      },
    );
  }
}

class _CloseAfterSignIn extends StatefulWidget {
  const _CloseAfterSignIn();

  @override
  State<_CloseAfterSignIn> createState() => _CloseAfterSignInState();
}

class _CloseAfterSignInState extends State<_CloseAfterSignIn> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class ChooseIfSignedIn extends StatelessWidget {
  const ChooseIfSignedIn({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sign out?'),
      content: const Text('You can sign back in any time.'),
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
