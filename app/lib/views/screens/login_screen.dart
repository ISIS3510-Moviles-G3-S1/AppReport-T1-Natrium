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
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_clearError);
    _passwordController.addListener(_clearError);
  }

  @override
  void dispose() {
    _emailController.removeListener(_clearError);
    _passwordController.removeListener(_clearError);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_errorMessage != null) {
      debugPrint('[LoginScreen] Clearing error message: $_errorMessage');
      setState(() {
        _errorMessage = null;
      });
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }



  ///LOGIN
  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    debugPrint('[LoginScreen] _login() called with email: $email');

    setState(() {
      _errorMessage = null;
    });

    /// 1. CAMPOS VACÍOS
    if (email.isEmpty || password.isEmpty) {
      debugPrint('[LoginScreen] Empty fields detected');
      _setValidationError("Please fill all fields");
      return;
    }

    /// 2. EMAIL INVÁLIDO
    if (!_isValidEmail(email)) {
      debugPrint('[LoginScreen] Invalid email format');
      _setValidationError("Invalid email format");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('[LoginScreen] About to call signIn...');
      await context.read<SessionViewModel>().signIn(
            email: email,
            password: password,
          );
      debugPrint('[LoginScreen] Sign in succeeded!');
      // Success - no error message needed
    } on AuthFailure catch (failure) {
      debugPrint('[LoginScreen] CAUGHT AuthFailure: code=${failure.code}, message=${failure.message}');
      final errorMessage = _messageForFailure(failure);
      debugPrint('[LoginScreen] _messageForFailure returned: $errorMessage');
      _setAuthError(errorMessage);
    } catch (e) {
      debugPrint('[LoginScreen] CAUGHT other exception: $e');
      _setAuthError("Unexpected error. Please try again");
    } finally {
      debugPrint('[LoginScreen] Finally block - setting _isLoading to false');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _setValidationError(String message) {
    setState(() {
      _errorMessage = message;
    });
  }

  void _setAuthError(String message) {
    debugPrint('[LoginScreen] _setAuthError called with message: $message');
    setState(() {
      _errorMessage = message;
      debugPrint('[LoginScreen] _errorMessage set to: $_errorMessage');
    });
    // Show SnackBar for authentication errors
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
      debugPrint('[LoginScreen] SnackBar shown with message: $message');
    }
  }



  
  String _messageForFailure(AuthFailure failure) {
    debugPrint('[LoginScreen] _messageForFailure called with code: ${failure.code}, message: ${failure.message}');
    switch (failure.code) {
      case 'user-not-found':
        debugPrint('[LoginScreen] Returning: User not found');
        return 'User not found';
      case 'wrong-password':
        debugPrint('[LoginScreen] Returning: Incorrect password');
        return 'Incorrect password';
      case 'invalid-credential':
        debugPrint('[LoginScreen] Returning: Invalid credentials');
        return 'Invalid credentials';
      case 'invalid-email':
        debugPrint('[LoginScreen] Returning: Invalid email');
        return 'Invalid email';
      default:
        debugPrint('[LoginScreen] Returning default: Login failed. Please try again');
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

                    // Error banner
                    if (_errorMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    if (_errorMessage != null) const SizedBox(height: 16),

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