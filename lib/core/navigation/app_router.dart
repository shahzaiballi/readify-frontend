import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';
import '../../presentation/auth/controllers/auth_controller.dart';

// Auth & onboarding
import '../../presentation/onboarding/pages/onboarding_page.dart';
import '../../presentation/auth/pages/login_page.dart';
import '../../presentation/auth/pages/signup_page.dart';
import '../../presentation/auth/pages/forgot_password_page.dart';
import '../../presentation/auth/pages/otp_verification_page.dart';

// Core pages
import '../../presentation/home/pages/home_page.dart';
import '../../presentation/home/pages/all_books_page.dart';
import '../../presentation/book_detail/pages/book_detail_page.dart';
import '../../presentation/chapters/pages/chapter_list_page.dart';
import '../../presentation/book_summary/pages/chapter_summary_page.dart';

// Profile
import '../../presentation/profile/pages/profile_page.dart';
import '../../presentation/profile/pages/edit_profile_page.dart';
import '../../presentation/profile/pages/change_password_page.dart';
import '../../presentation/profile/pages/reading_plan_page.dart';

// Reading
import '../../presentation/chunked_reading/pages/chunked_reading_screen.dart';

// Features
import '../../presentation/search/pages/search_page.dart';
import '../../presentation/flashcards/pages/flashcard_page.dart';
import '../../presentation/progress/pages/progress_page.dart';

// ✅ NEW COMMUNITY IMPORTS (you must have these)
import '../../presentation/community/pages/community_page.dart';
import '../../presentation/community/pages/community_detail_page.dart';
import '../../presentation/community/pages/community_chat_page.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

// Refresh listener for auth changes
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
    refreshListenable: AuthRefreshListenable(ref),

    redirect: (context, state) {
      final bool loggedIn = authState is AsyncData && authState.value != null;
      final String location = state.matchedLocation;

      final prefs = ref.read(sharedPreferencesProvider);
      final isFirstTime = prefs.getBool('isFirstTime') ?? true;

      if (loggedIn) {
        if (location == '/onboarding' || location == '/login' || location == '/signup') {
          return '/home';
        }
      } else {
        if (location == '/onboarding' && !isFirstTime) {
          return '/login';
        }
      }

      // Deep linking
      if (loggedIn && deepLinkPayload != null) {
        try {
          final payloadData = jsonDecode(deepLinkPayload);
          final targetRoute = payloadData['route'] as String?;

          if (targetRoute != null && targetRoute.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(deepLinkPayloadProvider.notifier).state = null;
            });
            return targetRoute;
          }
        } catch (_) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(deepLinkPayloadProvider.notifier).state = null;
          });
        }
      }

      return null;
    },

    routes: [
      // Auth & onboarding
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (_, __) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (_, __) => const SignUpPage(),
      ),
      GoRoute(
        path: '/forgot_password',
        name: 'forgot_password',
        builder: (_, __) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/verify_otp',
        name: 'verify_otp',
        builder: (_, __) => const OtpVerificationPage(),
      ),

      // Home
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (_, __) => const HomePage(),
      ),

      // Profile
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (_, __) => const ProfilePage(),
      ),
      GoRoute(
        path: '/profile/edit',
        name: 'edit_profile',
        builder: (_, __) => const EditProfilePage(),
      ),
      GoRoute(
        path: '/profile/change_password',
        name: 'change_password',
        builder: (_, __) => const ChangePasswordPage(),
      ),

      // Books
      GoRoute(
        path: '/all_books/:category',
        name: 'all_books',
        builder: (_, state) {
          final category = state.pathParameters['category']!;
          return AllBooksPage(category: category);
        },
      ),
      GoRoute(
        path: '/book_detail/:id',
        name: 'book_detail',
        builder: (_, state) {
          final id = state.pathParameters['id']!;
          return BookDetailPage(bookId: id);
        },
      ),
      GoRoute(
        path: '/chapters/:id',
        name: 'chapters',
        builder: (_, state) {
          final id = state.pathParameters['id']!;
          return ChapterListPage(bookId: id);
        },
      ),
      GoRoute(
        path: '/book_summary/:id',
        name: 'book_summary',
        builder: (_, state) {
          final id = state.pathParameters['id']!;
          return ChapterSummaryPage(bookId: id);
        },
      ),

      // ✅ COMMUNITY (NEW)
      GoRoute(
        path: '/community',
        name: 'community',
        builder: (_, __) => const CommunityPage(),
      ),
      GoRoute(
        path: '/community/:id',
        name: 'community_detail',
        builder: (_, state) {
          final id = state.pathParameters['id']!;
          return CommunityDetailPage(communityId: id);
        },
      ),
      GoRoute(
        path: '/community/:id/chat',
        name: 'community_chat',
        builder: (_, state) {
          final id = state.pathParameters['id']!;
          return CommunityChatPage(communityId: id);
        },
      ),

      // Reading
      GoRoute(
        path: '/reading_plan',
        name: 'reading_plan',
        builder: (_, __) => const ReadingPlanPage(),
      ),
      GoRoute(
        path: '/read/:bookId/:chapterId',
        name: 'chunked_reading',
        builder: (_, state) {
          final bookId = state.pathParameters['bookId']!;
          final chapterId = state.pathParameters['chapterId']!;

          int index = 0;
          if (state.extra != null) {
            index = (state.extra as Map)['initialChunkIndex'] ?? 0;
          } else if (state.uri.queryParameters.containsKey('index')) {
            index = int.tryParse(state.uri.queryParameters['index']!) ?? 0;
          }

          return ChunkedReadingScreen(
            bookId: bookId,
            chapterId: chapterId,
            initialChunkIndex: index,
          );
        },
      ),

      // Other
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (_, __) => const SearchPage(),
      ),
      GoRoute(
        path: '/flashcards/:id',
        name: 'flashcards',
        builder: (_, state) {
          final id = state.pathParameters['id']!;
          return FlashcardPage(bookId: id);
        },
      ),
    ],
  );
});