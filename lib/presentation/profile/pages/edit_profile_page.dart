import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../auth/widgets/custom_text_field.dart';
import '../../auth/widgets/primary_button.dart';
import '../controllers/profile_controller.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with current profile data
    final profile = ref.read(profileControllerProvider).valueOrNull;
    if (profile != null) {
      _nameController.text = profile.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(profileRepositoryImplProvider).updateProfile(
            fullName: _nameController.text.trim(),
          );

      // Refresh the profile controller so UI updates everywhere
      await ref.read(profileControllerProvider.notifier).refresh();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully.'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1626),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1626),
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(context.responsive.sp(8)),
            decoration: const BoxDecoration(
              color: Color(0xFF1E233D),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: context.responsive.sp(18),
            ),
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: context.responsive.sp(16),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator.adaptive(
              valueColor: AlwaysStoppedAnimation(Color(0xFFB062FF)),
            ),
          ),
          error: (e, _) => Center(
            child: Text(
              'Failed to load profile.',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: context.responsive.sp(14),
              ),
            ),
          ),
          data: (profile) => SingleChildScrollView(
            padding: EdgeInsets.all(context.responsive.wp(24)),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  SizedBox(height: context.responsive.sp(16)),

                  // Avatar
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFFB062FF),
                                Color(0xFF3861FB),
                              ],
                            ),
                          ),
                          child: CircleAvatar(
                            radius: context.responsive.sp(44),
                            backgroundImage:
                                NetworkImage(profile.avatarUrl),
                            backgroundColor: Colors.transparent,
                          ),
                        ),
                        // Avatar edit button (placeholder for now)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(
                              context.responsive.sp(6),
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFB062FF),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF0F1626),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.camera_alt_outlined,
                              color: Colors.white,
                              size: context.responsive.sp(14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: context.responsive.sp(32)),

                  // Full Name
                  CustomTextField(
                    label: 'Full Name',
                    hintText: 'Enter your full name',
                    prefixIcon: Icons.person_outline,
                    controller: _nameController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name cannot be empty';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: context.responsive.sp(20)),

                  // Email (read-only)
                  CustomTextField(
                    label: 'Email',
                    hintText: profile.email,
                    prefixIcon: Icons.email_outlined,
                    controller:
                        TextEditingController(text: profile.email),
                  ),

                  SizedBox(height: context.responsive.sp(40)),

                  PrimaryButton(
                    text: 'Save Changes',
                    isLoading: _isLoading,
                    onPressed: _handleSave,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}