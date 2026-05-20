import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/responsive_utils.dart';
import '../controllers/auth_controller.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/social_auth_button.dart';

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onSignUpPressed() {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    ref.read(authControllerProvider.notifier).signUp(fullName, email, password);
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
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.symmetric(
                   horizontal: context.responsive.wp(24), 
                   vertical: context.responsive.sp(32)
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      SizedBox(height: context.responsive.sp(16)),
                      Text(
                        'Create Account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: context.responsive.sp(28),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: context.responsive.sp(8)),
                      Text(
                        'Join Readify and start your reading journey',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: context.responsive.sp(15),
                        ),
                      ),
                      SizedBox(height: context.responsive.sp(40)),

                      CustomTextField(
                        label: 'Full Name',
                        hintText: 'John Doe',
                        prefixIcon: Icons.person_outline,
                        controller: _fullNameController,
                      ),
                      SizedBox(height: context.responsive.sp(20)),

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
                      SizedBox(height: context.responsive.sp(20)),

                      CustomTextField(
                        label: 'Confirm Password',
                        hintText: '••••••••',
                        prefixIcon: Icons.lock_outline,
                        isPassword: true,
                        controller: _confirmPasswordController,
                      ),
                      SizedBox(height: context.responsive.sp(32)),

                      PrimaryButton(
                        text: 'Sign Up',
                        isLoading: isLoading,
                        onPressed: _onSignUpPressed,
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
                        onPressed: () {
                          context.go('/home');
                        },
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

                      SizedBox(height: context.responsive.sp(32)),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                           Container(
                             constraints: BoxConstraints(maxWidth: context.responsive.wp(120)),
                             child: Text(
                               "Already have an account?",
                               textAlign: TextAlign.center,
                               style: TextStyle(color: Colors.white70, fontSize: context.responsive.sp(14)),
                             ),
                           ),
                          SizedBox(width: context.responsive.wp(8)),
                          TextButton(
                            onPressed: () {
                              context.go('/login');
                            },
                            child: Text(
                              'Log In',
                              style: TextStyle(
                                color: const Color(0xFFB062FF), 
                                fontWeight: FontWeight.w600,
                                fontSize: context.responsive.sp(14)
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
          ],
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

