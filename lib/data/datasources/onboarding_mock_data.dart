import '../../domain/entities/onboarding_entity.dart';

class OnboardingMockData {
  static const List<OnboardingEntity> items = [
    OnboardingEntity(
      title: 'Smart Summaries\n& Flashcards',
      subtitle: 'Master any book with AI-generated\nsummaries and personalized\nflashcards',
      icon: 'Icons.menu_book_rounded', // In a real app, this would be an SVG asset path
    ),
    OnboardingEntity(
      title: 'Personalized\nReading Plans',
      subtitle: 'Achieve your reading goals with custom-\ntailored daily schedules',
      icon: 'Icons.track_changes_rounded',
    ),
    OnboardingEntity(
      title: 'Connect with the\nCommunity',
      subtitle: 'Join vibrant communities and connect\nwith fellow book lovers',
      icon: 'Icons.groups_rounded',
    ),
  ];
}

