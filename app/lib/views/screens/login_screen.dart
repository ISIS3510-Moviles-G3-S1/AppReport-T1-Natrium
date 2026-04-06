import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/auth_failure.dart';
import '../../view_models/session_view_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _error = "Please fill all fields";
        _isLoading = false;
      });
      return;
    }

    try {
      await context.read<SessionViewModel>().signIn(
            email: email,
            password: password,
          );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      final errorMessage = _messageForFailure(failure);
      setState(() {
        _error = errorMessage;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Unable to sign in. Please try again";
        _isLoading = false;
      });
    }
  }

  String _messageForFailure(AuthFailure failure) {
    switch (failure.code) {
      case 'user-not-found':
        return 'User not found';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid email';
      default:
        return failure.message;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionViewModel>(
      builder: (context, sessionViewModel, child) {
        final errorMessage = _error ?? sessionViewModel.errorMessage;

        return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              /// LOGO
              Column(
                children: [
                  Image.asset(
                    'assets/images/uni_market_logo.png',
                    height: 80,
                    width: 80,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "UniMarket",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              /// TITLE
              const Text(
                "Welcome back",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Log in to continue buying and selling on UniMarket.",
              ),

              const SizedBox(height: 30),

              /// EMAIL
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "University Email",
                  hintText: "username@uniandes.edu.co",
                ),
              ),

              const SizedBox(height: 16),

              /// PASSWORD
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                ),
              ),

              const SizedBox(height: 24),

              /// ERROR
              if (errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorMessage,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),

              /// LOGIN BUTTON
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Log in"),
              ),

              const SizedBox(height: 16),

              /// REGISTER
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        context.go('/register');
                      },
                child: const Text("Create an account"),
              ),
            ],
          ),
        ),
      ),
    );
      },
    );
  }
}
