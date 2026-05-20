// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/responsive_utils.dart';
import '../controllers/auth_controller.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/social_auth_button.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    ref.read(authControllerProvider.notifier).login(email, password);
  }

  void _handleGoogleSignIn() async {
    try {
      final googleSignInInstance = GoogleSignIn(scopes: ['email', 'profile']);
      final account = await googleSignInInstance.signIn();
      
      if (account != null && mounted) {
        // Since it's MVP, we'll mock the internal Google login session 
        // to sync with our Riverpod Authentication state which naturally triggers the router redirect.
        await ref.read(authControllerProvider.notifier).login(account.email, 'google_mock_password');
      } else {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                 content: Text('Google Sign-In cancelled or failed.', style: TextStyle(color: Colors.white)),
                 backgroundColor: Color(0xFF1E152A),
              ),
           );
        }
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
               content: Text('Google Sign-In cancelled or failed.', style: TextStyle(color: Colors.white)),
               backgroundColor: Color(0xFF1E152A),
            ),
         );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    ref.listen(authControllerProvider, (previous, next) {
      if (next is AsyncError && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      } else if (next is AsyncData && next.value != null && previous?.value == null) {
         context.go('/home');
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0F1626), 
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: context.responsive.wp(24), 
                vertical: context.responsive.sp(32)
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                   minHeight: constraints.maxHeight - (context.responsive.sp(64)), // Subtract vertical padding 
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: context.responsive.sp(32)),
                      Text(
                        'Welcome Back',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: context.responsive.sp(28),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: context.responsive.sp(8)),
                      Text(
                        'Continue your reading journey',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: context.responsive.sp(15),
                        ),
                      ),
                      SizedBox(height: context.responsive.sp(48)),

                      CustomTextField(
                        label: 'Email',
                        hintText: 'john@example.com',
                        prefixIcon: Icons.email_outlined,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: context.responsive.sp(20)),
                      
                      CustomTextField(
                        label: 'Password',
                        hintText: '••••••••',
                        prefixIcon: Icons.lock_outline,
                        isPassword: true,
                        controller: _passwordController,
                      ),
                      SizedBox(height: context.responsive.sp(12)),
                      
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                           onPressed: () {
                             context.push('/forgot_password');
                           },
                           style: TextButton.styleFrom(
                             padding: EdgeInsets.zero,
                             minimumSize: const Size(0, 0),
                             tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                           ),
                           child: Text(
                              'Forgot password?',
                              style: TextStyle(
                                 color: const Color(0xFFB062FF), 
                                 fontSize: context.responsive.sp(13),
                                 fontWeight: FontWeight.w500,
                              )
                           ),
                        ),
                      ),
                      SizedBox(height: context.responsive.sp(24)),

                      PrimaryButton(
                        text: 'Log In',
                        isLoading: isLoading,
                        onPressed: _onLoginPressed,
                      ),
                      SizedBox(height: context.responsive.sp(32)),

                      Row(
                        children: [
                           Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
                           Padding(
                             padding: EdgeInsets.symmetric(horizontal: context.responsive.wp(16)),
                             child: Text(
                               'or continue with',
                               style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: context.responsive.sp(13)),
                             ),
                           ),
                           Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
                        ],
                      ),
                      SizedBox(height: context.responsive.sp(32)),

                      SocialAuthButton(
                        text: 'Continue with Google',
                        icon: _buildIcon('G', Colors.redAccent, context), 
                        onPressed: _handleGoogleSignIn,
                      ),
                      SocialAuthButton(
                        text: 'Continue with Apple',
                        icon: Icon(Icons.apple, color: Colors.white, size: context.responsive.sp(20)),
                        onPressed: () {
                          context.go('/home');
                        },
                      ),
                      SocialAuthButton(
                        text: 'Continue with Phone',
                        icon: Icon(Icons.phone_outlined, color: Colors.white, size: context.responsive.sp(20)),
                        onPressed: () {
                          context.go('/home');
                        },
                      ),

                      // Push bottom section gracefully if screen is taller
                      const Spacer(),

                      SizedBox(height: context.responsive.sp(48)),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                             "Don't have an account?",
                             style: TextStyle(color: Colors.white70, fontSize: context.responsive.sp(14)),
                          ),
                          TextButton(
                            onPressed: () {
                              context.go('/signup');
                            },
                            child: Text(
                              'Sign Up',
                              style: TextStyle(
                                color: const Color(0xFFB062FF), 
                                fontWeight: FontWeight.w600,
                                fontSize: context.responsive.sp(14)
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            );
          }
        ),
      ),
    );
  }

  Widget _buildIcon(String letter, Color color, BuildContext context) {
    return Container(
      width: context.responsive.sp(20), 
      height: context.responsive.sp(20), 
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      alignment: Alignment.center,
      child: Text(letter, style: TextStyle(color: Colors.white, fontSize: context.responsive.sp(12), fontWeight: FontWeight.bold)),
    );
  }
}

