import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/responsive_utils.dart';
import '../controllers/library_controller.dart';
import '../widgets/library_segmented_control.dart';
import '../widgets/library_book_card.dart';

class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredBooksAsync = ref.watch(filteredLibraryProvider);

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: context.responsive.isLandscape ? 800 : double.infinity),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Bar / Header
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: context.responsive.wp(20), vertical: context.responsive.sp(16)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'My Library',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: context.responsive.sp(26),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Sliding Segmented Control Filters
                  const LibrarySegmentedControl(),
                  SizedBox(height: context.responsive.sp(16)),

                  // Filtered Main Content Body
                  Expanded(
                    child: filteredBooksAsync.when(
                      data: (books) {
                         if (books.isEmpty) {
                            return _buildEmptyState(context);
                         }

                         return ListView.builder(
                           padding: EdgeInsets.only(bottom: context.responsive.sp(32)),
                           itemCount: books.length,
                           itemBuilder: (context, index) {
                             return LibraryBookCard(book: books[index]);
                           },
                         );
                      },
                      loading: () => const Center(child: CircularProgressIndicator.adaptive(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB062FF)))),
                      error: (err, st) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent))),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
     return Center(
       child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
            Icon(Icons.library_books_outlined, color: Colors.white24, size: context.responsive.sp(64)),
            SizedBox(height: context.responsive.sp(16)),
            Text(
               "No books found here.",
               style: TextStyle(color: Colors.white54, fontSize: context.responsive.sp(16)),
            ),
         ],
       ),
     );
  }
}

