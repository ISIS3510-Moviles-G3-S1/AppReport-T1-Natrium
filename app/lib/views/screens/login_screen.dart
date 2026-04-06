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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  ///DIALOGO DE ERROR CENTRAL
  Future<void> _showErrorDialog(String message) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  ///LOGIN
  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    /// 1. CAMPOS VACÍOS
    if (email.isEmpty || password.isEmpty) {
      await _showErrorDialog("Please fill all fields");
      return;
    }

    /// 2. EMAIL INVÁLIDO
    if (!_isValidEmail(email)) {
      await _showErrorDialog("Invalid email format");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await context.read<SessionViewModel>().signIn(
            email: email,
            password: password,
          );
    } on AuthFailure catch (failure) {
      /// 3. CREDENCIALES INCORRECTAS
      final errorMessage = _messageForFailure(failure);
      await _showErrorDialog(errorMessage);
    } catch (e) {
      await _showErrorDialog("Unexpected error. Please try again");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  
  String _messageForFailure(AuthFailure failure) {
    switch (failure.code) {
      case 'user-not-found':
        return 'User not found';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-credential':
        return 'Invalid credentials';
      case 'invalid-email':
        return 'Invalid email';
      default:
        return 'Login failed. Please try again';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                24 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(minHeight: constraints.maxHeight - 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 40),

                    /// LOGO
                    Column(
                      children: [
                        Image.asset(
                          'assets/images/uni_market_logo.png',
                          height: 60,
                          width: 60,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "UniMarket",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
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

                    /// LOGIN BUTTON
                    ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
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
            );
          },
        ),
      ),
    );
  }
}