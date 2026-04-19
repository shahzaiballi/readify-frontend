import 'dart:convert';
import 'package:flutter/material.dart';
import '../../presentation/profile/pages/edit_profile_page.dart';
import '../../presentation/profile/pages/change_password_page.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../../presentation/auth/controllers/auth_controller.dart';
import '../../presentation/onboarding/pages/onboarding_page.dart';
import '../../presentation/auth/pages/login_page.dart';
import '../../presentation/auth/pages/signup_page.dart';
import '../../presentation/auth/pages/forgot_password_page.dart';
import '../../presentation/auth/pages/otp_verification_page.dart';
import '../../presentation/home/pages/home_page.dart';
import '../../presentation/home/pages/all_books_page.dart';
import '../../presentation/book_detail/pages/book_detail_page.dart';
import '../../presentation/chapters/pages/chapter_list_page.dart';
import '../../presentation/discussions/pages/discussion_detail_page.dart';
import '../../presentation/discussions/pages/discussions_page.dart';
import '../../presentation/discussions/pages/new_discussion_page.dart';
import '../../presentation/profile/pages/reading_plan_page.dart';
import '../../presentation/book_summary/pages/chapter_summary_page.dart';
import '../../presentation/chunked_reading/pages/chunked_reading_screen.dart';
import '../../presentation/search/pages/search_page.dart';
import '../../presentation/flashcards/pages/flashcard_page.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(); // Overridden in main.dart
});

// Helper class to listen to Auth changes and refresh GoRouter
class AuthRefreshListenable extends ChangeNotifier {
  AuthRefreshListenable(Ref ref) {
    ref.listen(authControllerProvider, (_, __) => notifyListeners());
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  final deepLinkPayload = ref.watch(deepLinkPayloadProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/onboarding',

    // This connects Riverpod's Auth State to GoRouter's redirection engine
    refreshListenable: AuthRefreshListenable(ref),

    redirect: (context, state) {
      final bool loggedIn = authState is AsyncData && authState.value != null;
      final String location = state.matchedLocation;

      final prefs = ref.read(sharedPreferencesProvider);
      final isFirstTime = prefs.getBool('isFirstTime') ?? true;

      // FIX: If logged in, push user away from Onboarding/Login to Home
      if (loggedIn) {
        if (location == '/onboarding' || location == '/login' || location == '/signup') {
          return '/home';
        }
      } else {
        // If not logged in and they've already completed onboarding, skip directly to login
        if (location == '/onboarding' && !isFirstTime) {
          return '/login';
        }
      }

      // Handle Deep Linking (Existing Logic)
      if (loggedIn && deepLinkPayload != null) {
        try {
          final payloadData = jsonDecode(deepLinkPayload);
          final targetRoute = payloadData['route'] as String?;

          if (targetRoute != null && targetRoute.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (ref.read(deepLinkPayloadProvider) != null) {
                ref.read(deepLinkPayloadProvider.notifier).state = null;
              }
            });
            return targetRoute;
          }
        } catch (e) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(deepLinkPayloadProvider.notifier).state = null;
          });
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignUpPage(),
      ),
      GoRoute(
        path: '/forgot_password',
        name: 'forgot_password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/verify_otp',
        name: 'verify_otp',
        builder: (context, state) => const OtpVerificationPage(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
  path: '/profile/edit',
  name: 'edit_profile',
  builder: (context, state) => const EditProfilePage(),
),
GoRoute(
  path: '/profile/change_password',
  name: 'change_password',
  builder: (context, state) => const ChangePasswordPage(),
),
      GoRoute(
        path: '/all_books/:category',
        name: 'all_books',
        builder: (context, state) {
          final category = state.pathParameters['category']!;
          return AllBooksPage(category: category);
        },
      ),
      GoRoute(
        path: '/chapters/:id',
        name: 'chapters',
        builder: (context, state) {
          final bookId = state.pathParameters['id']!;
          return ChapterListPage(bookId: bookId);
        },
      ),
      GoRoute(
        path: '/book_detail/:id',
        name: 'book_detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return BookDetailPage(bookId: id);
        },
      ),
      GoRoute(
        path: '/book_summary/:id',
        name: 'book_summary',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ChapterSummaryPage(bookId: id);
        },
      ),
      GoRoute(
        path: '/discussions/:id',
        name: 'discussions',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return DiscussionDetailPage(postId: id);
        },
      ),
      GoRoute(
        path: '/new_discussion',
        name: 'new_discussion',
        builder: (context, state) {
          final initialText = state.extra as String?;
          return NewDiscussionPage(initialText: initialText);
        },
      ),
      GoRoute(
        path: '/all_discussions',
        name: 'all_discussions',
        builder: (context, state) {
          final bookId = state.uri.queryParameters['bookId'];
          return DiscussionsPage(bookId: bookId);
        },
      ),
      GoRoute(
        path: '/reading_plan',
        name: 'reading_plan',
        builder: (context, state) => const ReadingPlanPage(),
      ),
      GoRoute(
        path: '/read/:bookId/:chapterId',
        name: 'chunked_reading',
        builder: (context, state) {
          final bookId = state.pathParameters['bookId']!;
          final chapterId = state.pathParameters['chapterId']!;

          int initialChunkIndex = 0;
          if (state.extra != null) {
            initialChunkIndex = (state.extra as Map<String, dynamic>)['initialChunkIndex'] as int? ?? 0;
          } else if (state.uri.queryParameters.containsKey('index')) {
            initialChunkIndex = int.tryParse(state.uri.queryParameters['index']!) ?? 0;
          }

          return ChunkedReadingScreen(
            bookId: bookId,
            chapterId: chapterId,
            initialChunkIndex: initialChunkIndex,
          );
        },
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => const SearchPage(),
      ),
      GoRoute(
        path: '/flashcards/:id',
        name: 'flashcards',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return FlashcardPage(bookId: id);
        },
      ),
    ],
  );
});