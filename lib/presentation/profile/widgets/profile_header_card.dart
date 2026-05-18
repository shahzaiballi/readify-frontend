import 'package:flutter/material.dart';
import '../../../../domain/entities/user_profile_entity.dart';
import '../../../../core/utils/responsive_utils.dart';

class ProfileHeaderCard extends StatelessWidget {
  final UserProfileEntity userProfile;

  const ProfileHeaderCard({super.key, required this.userProfile});

  @override
  Widget build(BuildContext context) {
    return Container(
       width: double.infinity,
       padding: EdgeInsets.symmetric(vertical: context.responsive.sp(24)),
       decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.responsive.sp(16)),
          gradient: const LinearGradient(
             colors: [Color(0xFF381A5D), Color(0xFF1E233D)],
             begin: Alignment.topLeft,
             end: Alignment.bottomRight,
          )
       ),
       child: Column(
          children: [
             Container(
               padding: const EdgeInsets.all(3), // Border thickness
               decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                     colors: [Color(0xFFB062FF), Color(0xFF3861FB)],
                     begin: Alignment.topLeft,
                     end: Alignment.bottomRight,
                  ),
               ),
               child: userProfile.avatarUrl.isNotEmpty
                   ? ClipRRect(
                       borderRadius: BorderRadius.circular(context.responsive.sp(36)),
                       child: Image.network(
                         userProfile.avatarUrl,
                         width: context.responsive.sp(72),
                         height: context.responsive.sp(72),
                         fit: BoxFit.cover,
                         errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(context),
                       ),
                     )
                   : _buildDefaultAvatar(context),
             ),
             SizedBox(height: context.responsive.sp(12)),
             Text(
                userProfile.name,
                style: TextStyle(color: Colors.white, fontSize: context.responsive.sp(18), fontWeight: FontWeight.bold),
             ),
             SizedBox(height: context.responsive.sp(4)),
             Text(
                userProfile.email,
                style: TextStyle(color: Colors.white54, fontSize: context.responsive.sp(12)),
             ),
             SizedBox(height: context.responsive.sp(16)),
             Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   if (userProfile.isAvidReader)
                      _buildGradientChip('📚 Avid Reader', const [Color(0xFF7A34B2), Color(0xFF3B1E6D)], context),
                   if (userProfile.currentStreak > 0) ...[
                      SizedBox(width: context.responsive.wp(8)),
                      _buildGradientChip('🔥 ${userProfile.currentStreak} day streak', const [Color(0xFF264DB5), Color(0xFF13255C)], context),
                   ]
                ],
             )
          ],
       ),
    );
  }

  Widget _buildGradientChip(String text, List<Color> colors, BuildContext context) {
    return Container(
       padding: EdgeInsets.symmetric(horizontal: context.responsive.wp(12), vertical: context.responsive.sp(6)),
       decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors, begin: Alignment.centerLeft, end: Alignment.centerRight),
          borderRadius: BorderRadius.circular(context.responsive.sp(16)),
       ),
       child: Text(
          text,
          style: TextStyle(color: Colors.white, fontSize: context.responsive.sp(11), fontWeight: FontWeight.w600),
       ),
    );
  }

  Widget _buildDefaultAvatar(BuildContext context) {
    return Container(
      width: context.responsive.sp(72),
      height: context.responsive.sp(72),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFB062FF),
      ),
      child: Icon(
        Icons.person_rounded,
        color: Colors.white,
        size: context.responsive.sp(36),
      ),
    );
  }
}

