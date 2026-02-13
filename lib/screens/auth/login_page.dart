import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:email_validator/email_validator.dart';
import '../../theme/tokens.dart';
import '../../providers/user_provider.dart';
import '../../utils/logger.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Login con Supabase Auth
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Carica il profilo utente nel provider
      if (mounted) {
        await ref.read(currentUserProvider.notifier).refresh();

        if (mounted) {
          context.go('/today');
        }
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = _translateError(e.message);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Errore di connessione. Riprova.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _googleInitialized = false;

  Future<void> _initGoogleSignIn() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: dotenv.env['GOOGLE_CLIENT_ID'] ?? '',
    );
    _googleInitialized = true;
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      await _initGoogleSignIn();

      final googleUser = await GoogleSignIn.instance.authenticate();

      final idToken = googleUser.authentication.idToken;
      if (idToken == null) {
        throw Exception('Impossibile ottenere il token Google');
      }

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      if (mounted) {
        await ref.read(currentUserProvider.notifier).refresh();
        if (mounted) {
          context.go('/today');
        }
      }
    } on GoogleSignInException catch (e) {
      dlog('GoogleSignInException: code=${e.code}, details=$e');
      if (e.code == GoogleSignInExceptionCode.canceled) {
        // User cancelled — do nothing
      } else {
        setState(() {
          _errorMessage = 'Errore Google: ${e.code}';
        });
      }
    } on AuthException catch (e) {
      dlog('AuthException on Google Sign-In: ${e.message}');
      setState(() {
        _errorMessage = _translateError(e.message);
      });
    } catch (e, st) {
      dlog('Google Sign-In error: $e');
      dlog('Stack: $st');
      setState(() {
        _errorMessage = 'Errore Google: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  String _translateError(String error) {
    if (error.contains('Invalid login credentials')) {
      return 'Email o password non corretti';
    }
    if (error.contains('Email not confirmed')) {
      return 'Conferma la tua email prima di accedere';
    }
    return 'Errore: $error';
  }

  DateTime? _lastResetRequestTime;

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(text: _emailController.text);
    bool isResetting = false;
    String? resetError;
    bool emailSent = false;
    int cooldownSeconds = 0;
    Timer? cooldownTimer;

    // Check if we're still in cooldown from a previous request
    if (_lastResetRequestTime != null) {
      final elapsed = DateTime.now().difference(_lastResetRequestTime!).inSeconds;
      if (elapsed < 60) {
        cooldownSeconds = 60 - elapsed;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          void startCooldown() {
            cooldownSeconds = 60;
            _lastResetRequestTime = DateTime.now();
            cooldownTimer?.cancel();
            cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
              if (cooldownSeconds <= 0) {
                timer.cancel();
                setModalState(() => cooldownSeconds = 0);
              } else {
                setModalState(() => cooldownSeconds--);
              }
            });
          }

          return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Icon
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: emailSent
                          ? AppColors.earningsGreen.withOpacity(0.15)
                          : AppColors.turboOrange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      emailSent ? Icons.mark_email_read : Icons.lock_reset,
                      size: 32,
                      color: emailSent ? AppColors.earningsGreen : AppColors.turboOrange,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  emailSent ? 'Richiesta inviata' : 'Recupera password',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  emailSent
                      ? 'Se l\'account esiste, riceverai un\'email con il link per reimpostare la password.'
                      : 'Inserisci l\'email del tuo account.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 24),

                if (!emailSent) ...[
                  // Error message
                  if (resetError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.urgentRed.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.urgentRed.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.urgentRed,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              resetError!,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.urgentRed,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Email field
                  TextFormField(
                    controller: resetEmailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: 'nome@esempio.com',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 15,
                        color: Colors.grey[600],
                      ),
                      prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[500], size: 20),
                      filled: true,
                      fillColor: const Color(0xFF0D0D0F),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[800]!, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.turboOrange, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Send button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: (isResetting || cooldownSeconds > 0)
                          ? null
                          : () async {
                              final email = resetEmailController.text.trim();
                              if (email.isEmpty || !EmailValidator.validate(email)) {
                                setModalState(() {
                                  resetError = 'Inserisci un\'email valida';
                                });
                                return;
                              }

                              setModalState(() {
                                isResetting = true;
                                resetError = null;
                              });

                              try {
                                await Supabase.instance.client.auth.resetPasswordForEmail(email);
                                startCooldown();
                                setModalState(() {
                                  emailSent = true;
                                  isResetting = false;
                                });
                              } catch (_) {
                                // Anti-enumeration: always show success message
                                startCooldown();
                                setModalState(() {
                                  emailSent = true;
                                  isResetting = false;
                                });
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.turboOrange,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.turboOrange.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: isResetting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : Text(
                              cooldownSeconds > 0
                                  ? 'Riprova tra ${cooldownSeconds}s'
                                  : 'INVIA LINK',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),
                ] else ...[
                  // Success - close button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.earningsGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'HO CAPITO',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header gradient section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 40),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF1A1A1E),
                      Color(0xFF0D0D0F),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    // Logo
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.turboOrange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.bolt,
                        size: 40,
                        color: AppColors.turboOrange,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Bentornato!',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Accedi per iniziare a consegnare',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),

              // Form section
              Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Error message
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.urgentRed.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.urgentRed.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: AppColors.urgentRed,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.urgentRed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Email field
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'nome@esempio.com',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Inserisci la tua email';
                          }
                          if (!EmailValidator.validate(value)) {
                            return 'Email non valida';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password field
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: '••••••••',
                        icon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Inserisci la password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Forgot password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showForgotPasswordDialog,
                          child: Text(
                            'Password dimenticata?',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.turboOrange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Login button
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.turboOrange,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppColors.turboOrange.withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : Text(
                                  'ACCEDI',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey[800])),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'oppure',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey[800])),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Google Sign-In button
                      SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: (_isLoading || _isGoogleLoading) ? null : _handleGoogleSignIn,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey[700]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isGoogleLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(Colors.white70),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/images/google_logo.png',
                                      height: 22,
                                      width: 22,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Accedi con Google',
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Sign up link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Non hai un account? ',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey[400],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.go('/signup'),
                            child: Text(
                              'Registrati',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.earningsGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[300],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 15,
              color: Colors.grey[600],
            ),
            prefixIcon: Icon(icon, color: Colors.grey[500], size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFF1A1A1E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[800]!, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.turboOrange, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.urgentRed, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.urgentRed, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
