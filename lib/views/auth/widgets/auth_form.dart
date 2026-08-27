import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/auth_provider.dart';
import 'forgot_password_dialog.dart';

/// The authentication form widget that handles sign-in and sign-up.
class AuthForm extends ConsumerStatefulWidget {
  const AuthForm({super.key});

  @override
  ConsumerState<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends ConsumerState<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isSignUp = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final authNotifier = ref.read(authProvider.notifier);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (_isSignUp) {
      final name = _nameController.text.trim();
      await authNotifier.signUpWithEmail(
        email: email,
        password: password,
        displayName: name.isNotEmpty ? name : 'Planner Friend',
      );
    } else {
      await authNotifier.signInWithEmail(email, password);
    }
  }

  void _showForgotPasswordDialog() {
    ForgotPasswordDialog.show(context, _emailController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authProvider);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sign In vs Sign Up Segmented Switch
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isSignUp = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: !_isSignUp ? colorScheme.surface : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: !_isSignUp
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                    )
                                  ]
                                : [],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Sign In",
                            style: GoogleFonts.fredoka(
                              fontSize: 14,
                              fontWeight: !_isSignUp ? FontWeight.w600 : FontWeight.w500,
                              color: !_isSignUp
                                  ? colorScheme.primary
                                  : colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isSignUp = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _isSignUp ? colorScheme.surface : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _isSignUp
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                    )
                                  ]
                                : [],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Create Account",
                            style: GoogleFonts.fredoka(
                              fontSize: 14,
                              fontWeight: _isSignUp ? FontWeight.w600 : FontWeight.w500,
                              color: _isSignUp
                                  ? colorScheme.primary
                                  : colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Error Message Banner
              if (authState.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded,
                          color: colorScheme.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          authState.errorMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Name field (Only in Sign Up mode)
              if (_isSignUp) ...[
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: "Your Name / Nickname",
                    hintText: "e.g. Alex 🍕",
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (val) {
                    if (_isSignUp && (val == null || val.trim().isEmpty)) {
                      return "Please enter your name";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
              ],

              // Email field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email Address",
                  hintText: "you@example.com",
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty || !val.contains('@')) {
                    return "Please enter a valid email address";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Password field
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: "Password",
                  hintText: "••••••••",
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 6) {
                    return "Password must be at least 6 characters";
                  }
                  return null;
                },
              ),

              // Forgot Password Link (Only in Sign In mode)
              if (!_isSignUp) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgotPasswordDialog,
                    child: Text(
                      "Forgot password?",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ] else
                const SizedBox(height: 16),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: authState.isLoading ? null : _submit,
                  child: authState.isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : Text(
                          _isSignUp
                              ? "Create My Account 🗓️"
                              : "Sign In ✨",
                          style: const TextStyle(fontSize: 15),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
