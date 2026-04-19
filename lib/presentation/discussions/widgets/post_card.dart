import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../domain/entities/post_entity.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../controllers/discussion_controller.dart';

class PostCard extends ConsumerWidget {
  final PostEntity post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/discussions/${post.id}'),
      child: Container(
        margin: EdgeInsets.only(bottom: context.responsive.sp(16)),
        padding: EdgeInsets.all(context.responsive.sp(20)),
        decoration: BoxDecoration(
          color: const Color(0xFF1E233D),
          borderRadius: BorderRadius.circular(context.responsive.sp(16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Avatar, Name, Timestamp
            Row(
              children: [
                CircleAvatar(
                  radius: context.responsive.sp(16),
                  backgroundImage: NetworkImage(post.userAvatarUrl),
                  backgroundColor: Colors.white12,
                ),
                SizedBox(width: context.responsive.wp(12)),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          post.userName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: context.responsive.sp(14),
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.responsive.wp(8),
                        ),
                        child: Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: Colors.white54,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Text(
                        post.timeAgo,
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: context.responsive.sp(12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: context.responsive.sp(12)),

            // Chapter Tag
            if (post.chapterTag != null)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.responsive.wp(8),
                  vertical: context.responsive.sp(4),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF381A5D),
                  borderRadius:
                      BorderRadius.circular(context.responsive.sp(12)),
                ),
                child: Text(
                  post.chapterTag!,
                  style: TextStyle(
                    color: const Color(0xFFB062FF),
                    fontSize: context.responsive.sp(10),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            SizedBox(height: context.responsive.sp(12)),

            // Title & Content
            Text(
              post.title,
              style: TextStyle(
                color: Colors.white,
                fontSize: context.responsive.sp(16),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: context.responsive.sp(8)),
            Text(
              post.contentSnippet,
              style: TextStyle(
                color: Colors.white70,
                fontSize: context.responsive.sp(13),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            SizedBox(height: context.responsive.sp(16)),

            // Footer: Comments + Likes (likes are tappable)
            Row(
              children: [
                // Comments count (not tappable — opens detail page)
                _buildInteractionIcon(
                  Icons.chat_bubble_outline,
                  post.commentsCount.toString(),
                  context,
                  onTap: null,
                ),
                SizedBox(width: context.responsive.wp(20)),

                // Like button — tappable, calls toggleLike
                _buildInteractionIcon(
                  Icons.favorite_border,
                  post.likesCount.toString(),
                  context,
                  onTap: () => ref
                      .read(discussionControllerProvider.notifier)
                      .toggleLike(post.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionIcon(
    IconData icon,
    String count,
    BuildContext context, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white54,
            size: context.responsive.sp(16),
          ),
          SizedBox(width: context.responsive.wp(6)),
          Text(
            count,
            style: TextStyle(
              color: Colors.white54,
              fontSize: context.responsive.sp(12),
            ),
          ),
        ],
      ),
    );
  }
}