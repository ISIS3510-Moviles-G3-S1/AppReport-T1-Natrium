import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth_failure.dart';
import '../../view_models/session_view_model.dart';
import '../../data/offline_signup_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLoading = false;
  String? _error;

  // ── Connectivity ─────────────────────────────────────────────────────────
  bool _isOffline = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    final initial = await Connectivity().checkConnectivity();
    if (mounted) setState(() => _isOffline = _isDisconnected(initial));
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      if (mounted) setState(() => _isOffline = _isDisconnected(results));
    });
  }

  bool _isDisconnected(dynamic result) {
    if (result is List<ConnectivityResult>) {
      return result.every((r) => r == ConnectivityResult.none);
    }
    if (result is ConnectivityResult) return result == ConnectivityResult.none;
    return false;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _connectivitySub?.cancel();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final displayName = _emailController.text.split('@').first; // default: username parte del email
    final sessionVM = context.read<SessionViewModel>();

    // ── Validación inline: email y contraseña ─────────────────────────────
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    );
    
    String? validationError;
    if (!emailRegex.hasMatch(email)) {
      validationError = 'Enter a valid email address';
    } else if (password.length < 6) {
      validationError = 'Password must be at least 6 characters';
    } else if (!RegExp(r'[A-Za-z]').hasMatch(password) ||
        !RegExp(r'[0-9]').hasMatch(password)) {
      validationError = 'Password must include letters and numbers';
    }

    if (validationError != null) {
      if (mounted) {
        setState(() {
          _error = validationError;
          _isLoading = false;
        });
      }
      return;
    }

    // ── EVENTUAL CONNECTIVITY: Offline Registration ────────────────────
    // Si está offline, guardar localmente para sincronizar después
    if (_isOffline) {
      try {
        await OfflineSignupService.savePendingSignUp(
          email: email,
          password: password,
          displayName: displayName,
        );
        if (mounted) {
          setState(() {
            _error = null;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Registration saved! Will complete when your connection is restored.',
              ),
              duration: Duration(seconds: 4),
              backgroundColor: Colors.green,
            ),
          );
          // Opcionalmente navegar atrás o esperar
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) context.go('/login');
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _error = 'Could not save registration offline.';
            _isLoading = false;
          });
        }
      }
      return;
    }

    // ── Online: Future con handler (5pts) ──────────────────────────────
    // Mismo patrón aplicado en LoginScreen
    sessionVM
        .signUp(email: email, password: password, displayName: displayName)
        .then((_) {
          debugPrint('[RegisterScreen] signUp succeeded (then-handler)');
          if (mounted) {
            setState(() => _isLoading = false);
            // Redirige a login en caso de éxito
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) context.go('/login');
            });
          }
        })
        .catchError((error) {
          debugPrint('[RegisterScreen] catchError handler: $error');
          if (!mounted) return;
          final message = error is AuthFailure
              ? error.message
              : 'Unable to create account. Please try again';
          setState(() {
            _error = message;
            _isLoading = false;
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create account'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Offline banner ──────────────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              height: _isOffline ? 48 : 0,
              color: const Color(0xFFF59E0B),
              child: _isOffline
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off_rounded, size: 18, color: Colors.white),
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
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 16),

              /// LOGO
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/uni_market_logo.png',
                      height: 60,
                      width: 60,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "UniMarket",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              /// EMAIL
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'University Email',
                  hintText: 'username@uniandes.edu.co',
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) {
                    return 'Email is required';
                  }
                  if (!text.contains('@')) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              /// PASSWORD
              TextFormField(
                controller: _passwordController,
                textInputAction: TextInputAction.next,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                ),
                validator: (value) {
                  final text = value ?? '';
                  if (text.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              /// CONFIRM PASSWORD
              TextFormField(
                controller: _confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                ),
                validator: (value) {
                  final text = value ?? '';
                  if (text != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              /// ERROR
              if (_error != null)
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
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              /// CREATE ACCOUNT BUTTON
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create account'),
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: () {
                  context.go('/login');
                },
                child: const Text('Already have an account? Log in'),
              ),
            ],
          ),     // ListView
        ),       // Form
      ),         // Expanded
          ],     // Column children
        ),       // Column
      ),         // SafeArea
    );
  }
}