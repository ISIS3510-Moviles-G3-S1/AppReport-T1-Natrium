import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    } catch (e) {
      setState(() {
        _error = "Login failed. Check your credentials";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                children: const [
                  Icon(Icons.checkroom, size: 60),
                  SizedBox(height: 10),
                  Text(
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

              /// ERROR
              if (_error != null)
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),

              const SizedBox(height: 12),

              /// LOGIN BUTTON
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Log in"),
              ),

              const SizedBox(height: 16),

              /// REGISTER
              TextButton(
                onPressed: () {
                  // luego conectamos register
                },
                child: const Text("Create an account"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}