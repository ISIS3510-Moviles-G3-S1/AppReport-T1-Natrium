import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
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

  // ── Connectivity ──────────────────────────────────────────────────────────
  bool _isOffline = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_clearError);
    _passwordController.addListener(_clearError);
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    // Snapshot the current connectivity state on screen open.
    final initial = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() => _isOffline = _isDisconnected(initial));
    }

    // Subscribe to changes for the lifetime of this screen.
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      if (mounted) {
        setState(() => _isOffline = _isDisconnected(results));
      }
    });
  }

  bool _isDisconnected(dynamic result) {
    if (result is List<ConnectivityResult>) {
      return result.every((r) => r == ConnectivityResult.none);
    }
    if (result is ConnectivityResult) {
      return result == ConnectivityResult.none;
    }
    return false;
  }

  @override
  void dispose() {
    _emailController.removeListener(_clearError);
    _passwordController.removeListener(_clearError);
    _emailController.dispose();
    _passwordController.dispose();
    _connectivitySub?.cancel();
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



  // Restores the last persisted session from SharedPreferences + LRU when offline.
  Future<void> _loginOffline() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await context.read<SessionViewModel>().signInOffline();
    } on AuthFailure catch (failure) {
      _setAuthError(failure.message);
    } catch (e) {
      _setAuthError('Could not restore offline session. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  ///LOGIN
  Future<void> _login() async {
    if (_isOffline) {
      _setValidationError('No internet connection. Please check your network.');
      return;
    }

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
    // Online login requires connectivity; offline login only requires no active request.
    final bool canSubmit = !_isLoading;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // ── Offline banner ─────────────────────────────────────────────
            // AnimatedContainer gives a smooth slide-in/out transition when
            // connectivity changes, making the state change obvious to the user.
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              height: _isOffline ? 48 : 0,
              color: const Color(0xFFF59E0B), // amber-500
              child: _isOffline
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.wifi_off_rounded,
                            size: 18, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'No internet connection',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),

            // ── Main content ───────────────────────────────────────────────
            Expanded(
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
                            enabled: !_isOffline,
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
                            enabled: !_isOffline,
                            decoration: const InputDecoration(
                              labelText: "Password",
                            ),
                          ),

                          const SizedBox(height: 24),

                          /// LOGIN BUTTON
                          ElevatedButton(
                            onPressed: canSubmit
                                ? (_isOffline ? _loginOffline : _login)
                                : null,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : Text(_isOffline ? 'Continue offline' : 'Log in'),
                          ),

                          // Hint shown below button when offline.
                          if (_isOffline)
                            const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Text(
                                'Your last saved session will be restored.',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            ),

                          const SizedBox(height: 16),

                          // Error banner
                          if (_errorMessage != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
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
          ],
        ),
      ),
    );
  }
}