import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:v60pal/Theme.dart';
import 'package:v60pal/models/BeansList.dart';
import 'package:v60pal/models/Journal.dart';
import 'package:v60pal/widgets/app_ui.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final emailC = TextEditingController();
  final passC = TextEditingController();
  bool busy = false;
  String? error;

  Future<void> _signIn() async {
    setState(() {
      busy = true;
      error = null;
    });
    var signedIn = false;
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailC.text.trim(),
        password: passC.text,
      );
      signedIn = true;
    } on FirebaseAuthException catch (e) {
      setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }

    if (!signedIn || !mounted) return;

    final journal = context.read<Journal>();
    final beans = context.read<BeansList>();

    journal.init();
    beans.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BACKGROUND_COLOR,
      appBar: AppBar(title: const Text('Sign in')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppPageTitle(
                title: 'Welcome back',
                subtitle: 'Sign in to sync your beans and journal.',
              ),
              const SizedBox(height: 18),
              TextField(
                controller: emailC,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passC,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              if (error != null)
                Text(error!, style: TextStyle(color: COLOR_SCHEME.error)),
              FilledButton(
                onPressed: busy ? null : _signIn,
                child: Text(busy ? 'Signing in...' : 'Sign in'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    await FirebaseAuth.instance.createUserWithEmailAndPassword(
                      email: emailC.text.trim(),
                      password: passC.text,
                    );
                  } on FirebaseAuthException catch (e) {
                    debugPrint(
                      'FirebaseAuthException code=${e.code} message=${e.message}',
                    );
                  } catch (e, st) {
                    debugPrint('Unknown sign-up error: $e\n$st');
                  }
                },
                child: const Text('Create account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
