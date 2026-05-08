import 'dart:async';
import 'dart:isolate';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth_failure.dart';
import '../../view_models/session_view_model.dart';

// ── Isolate: validación de credenciales ───────────────────────────────────
// Función top-level requerida por Isolate.run() — no puede ser un método.
// Ejecuta validaciones de email/contraseña en un hilo separado para no
// bloquear el UI thread durante expresiones regulares intensivas.
Map<String, String?> _validateCredentialsIsolate(Map<String, String> input) {
  final email = input['email'] ?? '';
  final password = input['password'] ?? '';
  final errors = <String, String?>{};

  // Validación de formato de email con regex completo (RFC 5322 simplificado).
  final emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
  );
  if (!emailRegex.hasMatch(email)) {
    errors['email'] = 'Enter a valid email address';
  }

  // Validación de fortaleza de contraseña: mínimo 6 chars +
  // al menos una letra y un número para mayor seguridad.
  if (password.length < 6) {
    errors['password'] = 'Password must be at least 6 characters';
  } else if (!RegExp(r'[A-Za-z]').hasMatch(password) ||
      !RegExp(r'[0-9]').hasMatch(password)) {
    errors['password'] = 'Password must include letters and numbers';
  }

  return errors;
}

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
    if (_isOffline) {
      setState(() => _error = 'No internet connection. Please check your network.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    // Capturamos el ViewModel antes de cualquier await para no usar
    // BuildContext después de un async gap (lint: use_build_context_synchronously).
    final sessionVM = context.read<SessionViewModel>();

    // ── Isolate: validación de credenciales en hilo separado ─────────────
    // Usamos Isolate.run() para ejecutar el RegEx de email y el análisis
    // de fortaleza de contraseña fuera del UI thread. Esto evita jank
    // visible en dispositivos lentos y demuestra el patrón Isolate.
    final validationErrors = await Isolate.run(
      () => _validateCredentialsIsolate({'email': email, 'password': password}),
    );

    if (validationErrors.isNotEmpty) {
      if (mounted) {
        setState(() {
          _error = validationErrors.values.whereType<String>().join(' · ');
          _isLoading = false;
        });
      }
      return;
    }

    // ── Future con handler (.then / .catchError / .whenComplete) ─────────
    // Mismo patrón aplicado en LoginScreen: separamos lógica de éxito
    // de la de error de forma reactiva, sin depender de try/catch en UI.
    sessionVM
        .signUp(email: email, password: password)
        .then((_) {
          // Handler de éxito: GoRouter redirect toma control automáticamente.
          debugPrint('[RegisterScreen] signUp succeeded (then-handler)');
        })
        .catchError((error) {
          // Handler de error: captura AuthFailure o excepciones inesperadas.
          debugPrint('[RegisterScreen] catchError handler: $error');
          if (!mounted) return;
          final message = error is AuthFailure
              ? error.message
              : 'Unable to create account. Please try again';
          setState(() => _error = message);
        })
        .whenComplete(() {
          // whenComplete equivale al finally: siempre resetea el loading.
          if (mounted) setState(() => _isLoading = false);
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