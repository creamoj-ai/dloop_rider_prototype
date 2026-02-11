import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/tokens.dart';
import '../../services/biometric_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  bool _biometricFailed = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );

    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack)),
    );

    _controller.forward();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      // User has active session — require biometric unlock
      final biometricAvailable = await BiometricService.isAvailable();

      if (biometricAvailable) {
        final authenticated = await BiometricService.authenticate();
        if (!mounted) return;

        if (authenticated) {
          context.go('/today');
        } else {
          // Auth failed — show retry or go to login
          setState(() => _biometricFailed = true);
        }
      } else {
        // No biometrics available — proceed directly
        context.go('/today');
      }
    } else {
      context.go('/login');
    }
  }

  void _retryBiometric() async {
    setState(() => _biometricFailed = false);
    final authenticated = await BiometricService.authenticate();
    if (!mounted) return;

    if (authenticated) {
      context.go('/today');
    } else {
      setState(() => _biometricFailed = true);
    }
  }

  void _goToLogin() {
    Supabase.instance.client.auth.signOut();
    context.go('/login');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnim.value,
              child: Transform.scale(
                scale: _scaleAnim.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.turboOrange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.bolt,
                        size: 56,
                        color: AppColors.turboOrange,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Brand name
                    Text(
                      'dloop',
                      style: GoogleFonts.inter(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'rider',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.turboOrange,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Loading indicator or biometric retry
                    if (_biometricFailed) ...[
                      const Icon(
                        Icons.fingerprint,
                        size: 48,
                        color: AppColors.turboOrange,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Autenticazione fallita',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _retryBiometric,
                        icon: const Icon(Icons.fingerprint, size: 20),
                        label: Text(
                          'Riprova',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.turboOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _goToLogin,
                        child: Text(
                          'Accedi con email',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white38,
                          ),
                        ),
                      ),
                    ] else
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                            AppColors.turboOrange.withOpacity(0.6),
                          ),
                        ),
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
