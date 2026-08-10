import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/letters/presentation/screens/letters_screen.dart';
import '../../features/meditation/presentation/screens/meditation_screen.dart';

import '../../features/activities/presentation/screens/activities_screen.dart';
import '../../features/ai_questions/presentation/screens/ai_questions_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/name_entry_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/breathing/presentation/screens/breathing_screen.dart';
import '../../features/calendar/presentation/screens/calendar_screen.dart';
import '../../features/community/presentation/screens/community_screen.dart';
import '../../features/daily_question/presentation/screens/daily_question_screen.dart';
import '../../features/dreams/presentation/screens/dream_journal_screen.dart';
import '../../features/dreams/presentation/screens/dream_reflection_screen.dart';
import '../../features/dreams/presentation/screens/new_dream_screen.dart';
import '../../features/goals/presentation/screens/goals_screen.dart';
import '../../features/hobbies/presentation/screens/hobbies_screen.dart';
import '../../features/journal/presentation/screens/favorites_screen.dart';
import '../../features/journal/presentation/screens/journal_entry_screen.dart';
import '../../features/journal/presentation/screens/sealed_journals_screen.dart';
import '../../features/posts/presentation/screens/feed_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/reminders/presentation/screens/reminders_screen.dart';
import '../../features/rewards/presentation/screens/rewards_screen.dart';
import '../../features/shell/presentation/app_shell.dart';
import '../../features/stats/presentation/screens/stats_screen.dart';
import '../../features/shell/presentation/widgets/feature_coming_soon_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/theme_choice/presentation/screens/astra_landing_screen.dart';
import '../../features/wellbeing/presentation/screens/focus_timer_screen.dart';
import '../../features/wellbeing/presentation/screens/sos_calm_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const splash = '/splash';
  static const astraLanding = '/astra-landing';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const signup = '/signup';
  static const nameEntry = '/name-entry';
  static const welcome = '/welcome';
  static const home = '/home';
  static const reminders = '/reminders';
  static const goals = '/goals';
  static const breathing = '/breathing';
  static const dreams = '/dreams';
  static const newDream = '/dreams/new';
  static const dreamReflection = '/dreams/reflection';
  static const featureComingSoon = '/feature-coming-soon';
  static const dailyQuestion = '/daily-question';
  static const community = '/community';
  static const journalEntry = '/journal-entry';
  static const sealedJournals = '/sealed-journals';
  static const calendar = '/calendar';
  static const rewards = '/rewards';
  static const letters = '/letters';
  static const stats = '/stats';
  static const aiQuestions = '/ai-questions';
  static const meditation = '/meditation';
  static const hobbies = '/hobbies';
  static const hobbiesOnboarding = '/hobbies-onboarding';
  static const activities = '/activities';
  static const feed = '/feed';
  static const calm = '/calm';
  static const focusTimer = '/focus';
  static const favorites = '/favorites';
}

/// Bridges Supabase's auth-state stream to a [Listenable] so [GoRouter] can
/// re-run its `redirect` the moment a session is created or cleared —
/// otherwise `redirect` only fires on navigation, and a sign-out (say) would
/// leave a stale authenticated screen on-stack until the next manual nav.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier() {
    _subscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (_) => notifyListeners(),
    );
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Routes that require an authenticated Supabase session. Everything else
/// (splash/onboarding/login/signup) is reachable while logged out.
const _protectedRoutes = {
  AppRoutes.welcome,
  AppRoutes.home,
  AppRoutes.reminders,
  AppRoutes.goals,
  AppRoutes.breathing,
  AppRoutes.dreams,
  AppRoutes.newDream,
  AppRoutes.dreamReflection,
  AppRoutes.featureComingSoon,
  AppRoutes.dailyQuestion,
  AppRoutes.community,
  AppRoutes.journalEntry,
  AppRoutes.sealedJournals,
  AppRoutes.calendar,
  AppRoutes.rewards,
  AppRoutes.letters,
  AppRoutes.stats,
  AppRoutes.aiQuestions,
  AppRoutes.meditation,
  AppRoutes.hobbies,
  AppRoutes.hobbiesOnboarding,
  AppRoutes.activities,
  AppRoutes.feed,
  AppRoutes.calm,
  AppRoutes.focusTimer,
  AppRoutes.favorites,
};

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  refreshListenable: _AuthRefreshNotifier(),
  redirect: (context, state) {
    final isAuthenticated = Supabase.instance.client.auth.currentSession != null;
    final targetIsProtected = _protectedRoutes.contains(state.matchedLocation);
    if (targetIsProtected && !isAuthenticated) {
      return AppRoutes.login;
    }
    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.astraLanding,
      builder: (context, state) => const AstraLandingScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) =>
          OnboardingScreen(isNewSignup: (state.extra as bool?) ?? false),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.signup,
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: AppRoutes.nameEntry,
      builder: (context, state) => const NameEntryScreen(),
    ),
    GoRoute(
      path: AppRoutes.welcome,
      builder: (context, state) {
        final isNewSignup = (state.extra as bool?) ??
            ((state.extra as Map<String, dynamic>?)?['isNewSignup'] as bool?) ??
            false;
        return WelcomeScreen(isNewSignup: isNewSignup);
      },
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const AppShell(),
    ),
    GoRoute(
      path: AppRoutes.reminders,
      builder: (context, state) => const RemindersScreen(),
    ),
    GoRoute(
      path: AppRoutes.goals,
      builder: (context, state) => const GoalsScreen(),
    ),
    GoRoute(
      path: AppRoutes.breathing,
      builder: (context, state) => const BreathingScreen(),
    ),
    GoRoute(
      path: AppRoutes.dreams,
      builder: (context, state) => const DreamJournalScreen(),
    ),
    GoRoute(
      path: AppRoutes.newDream,
      builder: (context, state) => const NewDreamScreen(),
    ),
    GoRoute(
      path: AppRoutes.dreamReflection,
      builder: (context, state) => DreamReflectionScreen(dreamId: state.extra! as int),
    ),
    GoRoute(
      path: AppRoutes.featureComingSoon,
      builder: (context, state) =>
          FeatureComingSoonScreen(args: state.extra! as FeatureComingSoonArgs),
    ),
    GoRoute(
      path: AppRoutes.dailyQuestion,
      builder: (context, state) => const DailyQuestionScreen(),
    ),
    GoRoute(
      path: AppRoutes.community,
      builder: (context, state) => const CommunityScreen(),
    ),
    GoRoute(
      path: AppRoutes.journalEntry,
      builder: (context, state) => const JournalEntryScreen(),
    ),
    GoRoute(
      path: AppRoutes.sealedJournals,
      builder: (context, state) => const SealedJournalsScreen(),
    ),
    GoRoute(
      path: AppRoutes.calendar,
      builder: (context, state) => const CalendarScreen(),
    ),
    GoRoute(
      path: AppRoutes.rewards,
      builder: (context, state) => const RewardsScreen(),
    ),
    GoRoute(
      path: AppRoutes.letters,
      builder: (context, state) => const LettersScreen(),
    ),
    GoRoute(
      path: AppRoutes.stats,
      builder: (context, state) => const StatsScreen(),
    ),
    GoRoute(
      path: AppRoutes.aiQuestions,
      builder: (context, state) => const AiQuestionsScreen(),
    ),
    GoRoute(
      path: AppRoutes.meditation,
      builder: (context, state) => const MeditationScreen(),
    ),
    GoRoute(
      path: AppRoutes.hobbies,
      builder: (context, state) => const HobbiesScreen(),
    ),
    GoRoute(
      path: AppRoutes.hobbiesOnboarding,
      builder: (context, state) => const HobbiesScreen(onboarding: true),
    ),
    GoRoute(
      path: AppRoutes.activities,
      builder: (context, state) => const ActivitiesScreen(),
    ),
    GoRoute(
      path: AppRoutes.feed,
      builder: (context, state) => const FeedScreen(),
    ),
    GoRoute(
      path: AppRoutes.calm,
      builder: (context, state) => const SosCalmScreen(),
    ),
    GoRoute(
      path: AppRoutes.focusTimer,
      builder: (context, state) => const FocusTimerScreen(),
    ),
    GoRoute(
      path: AppRoutes.favorites,
      builder: (context, state) => const FavoritesScreen(),
    ),
  ],
);
