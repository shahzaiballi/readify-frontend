import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../domain/entities/book_entity.dart';

class CompletedBooksWidget extends StatelessWidget {
  final List<BookEntity> books;

  const CompletedBooksWidget({
    super.key,
    required this.books,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.responsive.wp(20)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(
            books.length,
            (index) {
              final book = books[index];
              return Padding(
                padding: EdgeInsets.only(right: context.responsive.sp(12)),
                child: Container(
                  width: context.responsive.sp(120),
                  height: context.responsive.sp(160),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(context.responsive.sp(12)),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Book cover
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(context.responsive.sp(12)),
                          image: DecorationImage(
                            image: NetworkImage(book.imageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // Overlay
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(context.responsive.sp(12)),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                      // Completed badge
                      Positioned(
                        top: context.responsive.sp(8),
                        right: context.responsive.sp(8),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.responsive.sp(6),
                            vertical: context.responsive.sp(3),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(context.responsive.sp(4)),
                          ),
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: context.responsive.sp(16),
                          ),
                        ),
                      ),
                      // Book info
                      Positioned(
                        bottom: context.responsive.sp(8),
                        left: context.responsive.sp(8),
                        right: context.responsive.sp(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: context.responsive.sp(10),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
