import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'auth_controller.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    await ref.read(authControllerProvider.notifier).signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final error = authState.hasError
        ? ref.read(authControllerProvider.notifier).errorMessage(authState.error!)
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFF0C0E0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white70),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              }
            },
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: const Icon(Icons.lens_blur, color: Colors.white70),
              onPressed: () {},
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Orb Image
              Center(
                child: Image.asset(
                  'assets/images/auth_bg.png',
                  height: 120,
                  width: 120,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4FF2A).withValues(alpha: 0.2),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.public, size: 80, color: Color(0xFFD4FF2A)),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Headings
              Text(
                'Welcome Back!',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Sign in to access smart, personalized financial\nplans made for you.',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white54,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // Form
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      error,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Email Field
                    Text(
                      'Email address*',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration('example@gmail.com'),
                      validator: (value) {
                        if (value == null || !value.contains('@')) return 'Invalid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Password Field
                    Text(
                      'Password*',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      style: const TextStyle(color: Colors.white),
                      obscureText: true,
                      decoration: _inputDecoration('@Sn123hsn#').copyWith(
                        suffixIcon: const Icon(Icons.visibility_off, color: Colors.white38),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Password required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Remember Me & Forgot Password
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _rememberMe,
                                onChanged: (v) => setState(() => _rememberMe = v ?? false),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                side: const BorderSide(color: Colors.white38),
                                activeColor: const Color(0xFFD4FF2A),
                                checkColor: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Remember me',
                              style: GoogleFonts.spaceGrotesk(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            'Forgot Password?',
                            style: GoogleFonts.spaceGrotesk(color: Colors.white70, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Sign In Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: isLoading ? null : _submit,
                        icon: isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                          : const Icon(Icons.auto_awesome, color: Colors.black, size: 20),
                        label: Text(
                          isLoading ? 'Signing in...' : 'Sign in',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4FF2A),
                          disabledBackgroundColor: const Color(0xFFD4FF2A).withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Or continue with
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Or continue with',
                      style: GoogleFonts.spaceGrotesk(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
                ],
              ),

              const SizedBox(height: 24),

              // Social Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.g_mobiledata, color: Colors.white, size: 28),
                      label: Text('Google', style: GoogleFonts.spaceGrotesk(color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.apple, color: Colors.white, size: 24),
                      label: Text('Apple', style: GoogleFonts.spaceGrotesk(color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Sign Up Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: GoogleFonts.spaceGrotesk(color: Colors.white54, fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/sign-up'),
                    child: Text(
                      'Sign up',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white24),
      filled: true,
      fillColor: const Color(0xFF131511),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD4FF2A)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}
