import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/responsive_utils.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_primary_button.dart';
import '../widgets/social_auth_button.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  late AnimationController _shakeController;
  late Animation<Offset> _shakeAnimation;

  String? _serverError;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = TweenSequence<Offset>([
      TweenSequenceItem(tween: Tween(begin: Offset.zero, end: const Offset(-0.03, 0)), weight: 1),
      TweenSequenceItem(tween: Tween(begin: const Offset(-0.03, 0), end: const Offset(0.03, 0)), weight: 2),
      TweenSequenceItem(tween: Tween(begin: const Offset(0.03, 0), end: const Offset(-0.02, 0)), weight: 2),
      TweenSequenceItem(tween: Tween(begin: const Offset(-0.02, 0), end: Offset.zero), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _shake() {
    _shakeController.forward(from: 0);
  }

  void _clearServerError() {
    if (_serverError != null) setState(() => _serverError = null);
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    _clearServerError();

    if (!(_formKey.currentState?.validate() ?? false)) {
      _shake();
      return;
    }

    await ref.read(authControllerProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );
    // Navigation is handled by the router via authControllerProvider listener
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    // Listen for errors from server
    ref.listen<AsyncValue<dynamic>>(authControllerProvider, (prev, next) {
      if (next is AsyncError) {
        setState(() {
          _serverError = next.error.toString().replaceAll('Exception: ', '');
        });
        _shake();
      }
      // Successful login → router handles navigation automatically
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0F1626),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: context.responsive.wp(24),
              vertical: context.responsive.sp(24),
            ),
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(minHeight: constraints.maxHeight - context.responsive.sp(48)),
              child: IntrinsicHeight(
                child: Form(
                  key: _formKey,
                  autovalidateMode: _submitted
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: context.responsive.sp(16)),

                      // ── Logo & Title ─────────────────────────────────
                      _Logo(sp: context.responsive.sp),
                      SizedBox(height: context.responsive.sp(20)),
                      Text(
                        'Welcome back',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: context.responsive.sp(28),
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: context.responsive.sp(6)),
                      Text(
                        'Log in to continue reading',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: context.responsive.sp(15),
                        ),
                      ),

                      SizedBox(height: context.responsive.sp(36)),

                      // ── Server Error Banner ──────────────────────────
                      if (_serverError != null)
                        SlideTransition(
                          position: _shakeAnimation,
                          child: _ErrorBanner(
                            message: _serverError!,
                            onDismiss: _clearServerError,
                          ),
                        ),

                      // ── Email ─────────────────────────────────────────
                      AuthTextField(
                        label: 'Email',
                        hint: 'you@example.com',
                        icon: Icons.email_outlined,
                        controller: _emailController,
                        focusNode: _emailFocus,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        enabled: !isLoading,
                        onChanged: (_) => _clearServerError(),
                        onSubmitted: (_) => _passwordFocus.requestFocus(),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Email is required';
                          if (!v.contains('@') || !v.contains('.')) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: context.responsive.sp(18)),

                      // ── Password ──────────────────────────────────────
                      AuthTextField(
                        label: 'Password',
                        hint: '••••••••',
                        icon: Icons.lock_outline,
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        isPassword: true,
                        textInputAction: TextInputAction.done,
                        enabled: !isLoading,
                        onChanged: (_) => _clearServerError(),
                        onSubmitted: (_) => _submit(),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Password is required';
                          return null;
                        },
                      ),

                      SizedBox(height: context.responsive.sp(10)),

                      // ── Forgot password ───────────────────────────────
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: isLoading
                              ? null
                              : () => context.push('/forgot_password'),
                          child: Text(
                            'Forgot password?',
                            style: TextStyle(
                              color: const Color(0xFFB062FF),
                              fontSize: context.responsive.sp(13),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: context.responsive.sp(28)),

                      // ── Login Button ──────────────────────────────────
                      AuthPrimaryButton(
                        label: 'Log In',
                        isLoading: isLoading,
                        onTap: _submit,
                      ),

                      SizedBox(height: context.responsive.sp(28)),

                      // ── Divider ───────────────────────────────────────
                      _OrDivider(),

                      SizedBox(height: context.responsive.sp(20)),

                      // ── Social ────────────────────────────────────────
                      SocialAuthButton(
                        text: 'Continue with Google',
                        icon: _GoogleIcon(),
                        onPressed: isLoading ? () {} : () {},
                      ),
                      SocialAuthButton(
                        text: 'Continue with Apple',
                        icon: const Icon(Icons.apple,
                            color: Colors.white, size: 20),
                        onPressed: () {},
                      ),

                      const Spacer(),
                      SizedBox(height: context.responsive.sp(24)),

                      // ── Sign up link ──────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account?",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: context.responsive.sp(14),
                            ),
                          ),
                          TextButton(
                            onPressed:
                                isLoading ? null : () => context.go('/signup'),
                            child: Text(
                              'Sign Up',
                              style: TextStyle(
                                color: const Color(0xFFB062FF),
                                fontWeight: FontWeight.w600,
                                fontSize: context.responsive.sp(14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Signup Page
// ────────────────────────────────────────────────────────────────────────────

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  late AnimationController _shakeController;
  late Animation<Offset> _shakeAnimation;

  String? _serverError;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = TweenSequence<Offset>([
      TweenSequenceItem(tween: Tween(begin: Offset.zero, end: const Offset(-0.03, 0)), weight: 1),
      TweenSequenceItem(tween: Tween(begin: const Offset(-0.03, 0), end: const Offset(0.03, 0)), weight: 2),
      TweenSequenceItem(tween: Tween(begin: const Offset(0.03, 0), end: const Offset(-0.02, 0)), weight: 2),
      TweenSequenceItem(tween: Tween(begin: const Offset(-0.02, 0), end: Offset.zero), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _shake() => _shakeController.forward(from: 0);
  void _clearError() {
    if (_serverError != null) setState(() => _serverError = null);
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    _clearError();

    if (!(_formKey.currentState?.validate() ?? false)) {
      _shake();
      return;
    }

    await ref.read(authControllerProvider.notifier).signUp(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    ref.listen<AsyncValue<dynamic>>(authControllerProvider, (prev, next) {
      if (next is AsyncError) {
        setState(() {
          _serverError = next.error.toString().replaceAll('Exception: ', '');
        });
        _shake();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0F1626),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: context.responsive.wp(24),
            vertical: context.responsive.sp(24),
          ),
          child: Form(
            key: _formKey,
            autovalidateMode: _submitted
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: context.responsive.sp(16)),

                _Logo(sp: context.responsive.sp),
                SizedBox(height: context.responsive.sp(20)),
                Text(
                  'Create account',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.responsive.sp(28),
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: context.responsive.sp(6)),
                Text(
                  'Start your reading journey today',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: context.responsive.sp(15),
                  ),
                ),

                SizedBox(height: context.responsive.sp(36)),

                if (_serverError != null)
                  SlideTransition(
                    position: _shakeAnimation,
                    child: _ErrorBanner(
                      message: _serverError!,
                      onDismiss: _clearError,
                    ),
                  ),

                AuthTextField(
                  label: 'Full Name',
                  hint: 'Ali Thompson',
                  icon: Icons.person_outline,
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                  onChanged: (_) => _clearError(),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Name is required';
                    if (v.trim().length < 2) return 'Name too short';
                    return null;
                  },
                ),

                SizedBox(height: context.responsive.sp(16)),

                AuthTextField(
                  label: 'Email',
                  hint: 'you@example.com',
                  icon: Icons.email_outlined,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                  onChanged: (_) => _clearError(),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!v.contains('@') || !v.contains('.')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),

                SizedBox(height: context.responsive.sp(16)),

                AuthTextField(
                  label: 'Password',
                  hint: 'Min. 8 characters',
                  icon: Icons.lock_outline,
                  controller: _passwordController,
                  isPassword: true,
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                  onChanged: (_) => _clearError(),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 8) return 'At least 8 characters';
                    return null;
                  },
                ),

                SizedBox(height: context.responsive.sp(16)),

                AuthTextField(
                  label: 'Confirm Password',
                  hint: 'Re-enter password',
                  icon: Icons.lock_outline,
                  controller: _confirmController,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  enabled: !isLoading,
                  onChanged: (_) => _clearError(),
                  onSubmitted: (_) => _submit(),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please confirm password';
                    if (v != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),

                SizedBox(height: context.responsive.sp(28)),

                AuthPrimaryButton(
                  label: 'Create Account',
                  isLoading: isLoading,
                  onTap: _submit,
                ),

                SizedBox(height: context.responsive.sp(28)),
                _OrDivider(),
                SizedBox(height: context.responsive.sp(20)),

                SocialAuthButton(
                  text: 'Continue with Google',
                  icon: _GoogleIcon(),
                  onPressed: () {},
                ),
                SocialAuthButton(
                  text: 'Continue with Apple',
                  icon: const Icon(Icons.apple, color: Colors.white, size: 20),
                  onPressed: () {},
                ),

                SizedBox(height: context.responsive.sp(32)),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: context.responsive.sp(14),
                      ),
                    ),
                    TextButton(
                      onPressed:
                          isLoading ? null : () => context.go('/login'),
                      child: Text(
                        'Log In',
                        style: TextStyle(
                          color: const Color(0xFFB062FF),
                          fontWeight: FontWeight.w600,
                          fontSize: context.responsive.sp(14),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: context.responsive.sp(16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ────────────────────────────────────────────────────────────────────────────

class _Logo extends StatelessWidget {
  final double Function(double) sp;
  const _Logo({required this.sp});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: sp(44),
      height: sp(44),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB062FF), Color(0xFF3861FB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(sp(12)),
      ),
      child: Icon(Icons.menu_book_rounded, color: Colors.white, size: sp(24)),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;
  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: context.responsive.sp(20)),
      padding: EdgeInsets.symmetric(
        horizontal: context.responsive.wp(14),
        vertical: context.responsive.sp(12),
      ),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close, color: Colors.redAccent, size: 16),
          ),
        ],
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.responsive.wp(14)),
          child: Text(
            'or continue with',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: context.responsive.sp(13),
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
      ],
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.redAccent),
      alignment: Alignment.center,
      child: const Text('G',
          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
