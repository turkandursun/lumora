import 'dart:async';

import 'package:flutter/widgets.dart';
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
import '../../features/journal/presentation/screens/quote_gallery_screen.dart';
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
  static const quotes = '/quotes';
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
  AppRoutes.quotes,
};

/// Lets screens (e.g. [AppShell]) become [RouteAware] so they can replay their
/// entrance animation when a pushed screen is popped and they reappear.
final RouteObserver<ModalRoute<void>> astraRouteObserver = RouteObserver<ModalRoute<void>>();

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  observers: [astraRouteObserver],
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
      pageBuilder: (context, state) => _smoothPage(state, const SplashScreen()),
    ),
    GoRoute(
      path: AppRoutes.astraLanding,
      pageBuilder: (context, state) => _smoothPage(state, const AstraLandingScreen()),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      pageBuilder: (context, state) =>
          _smoothPage(state, OnboardingScreen(isNewSignup: (state.extra as bool?) ?? false)),
    ),
    GoRoute(
      path: AppRoutes.login,
      pageBuilder: (context, state) => _smoothPage(state, const LoginScreen()),
    ),
    GoRoute(
      path: AppRoutes.signup,
      pageBuilder: (context, state) => _smoothPage(state, const SignupScreen()),
    ),
    GoRoute(
      path: AppRoutes.nameEntry,
      pageBuilder: (context, state) => _smoothPage(state, const NameEntryScreen()),
    ),
    GoRoute(
      path: AppRoutes.welcome,
      pageBuilder: (context, state) {
        final isNewSignup = (state.extra as bool?) ??
            ((state.extra as Map<String, dynamic>?)?['isNewSignup'] as bool?) ??
            false;
        return _smoothPage(state, WelcomeScreen(isNewSignup: isNewSignup));
      },
    ),
    GoRoute(
      path: AppRoutes.home,
      pageBuilder: (context, state) => _smoothPage(state, const AppShell()),
    ),
    GoRoute(
      path: AppRoutes.reminders,
      pageBuilder: (context, state) => _smoothPage(state, const RemindersScreen()),
    ),
    GoRoute(
      path: AppRoutes.goals,
      pageBuilder: (context, state) => _smoothPage(state, const GoalsScreen()),
    ),
    GoRoute(
      path: AppRoutes.breathing,
      pageBuilder: (context, state) => _smoothPage(state, const BreathingScreen()),
    ),
    GoRoute(
      path: AppRoutes.dreams,
      pageBuilder: (context, state) => _smoothPage(state, const DreamJournalScreen()),
    ),
    GoRoute(
      path: AppRoutes.newDream,
      pageBuilder: (context, state) => _smoothPage(state, const NewDreamScreen()),
    ),
    GoRoute(
      path: AppRoutes.dreamReflection,
      pageBuilder: (context, state) => _smoothPage(state, DreamReflectionScreen(dreamId: state.extra! as int)),
    ),
    GoRoute(
      path: AppRoutes.featureComingSoon,
      pageBuilder: (context, state) =>
          _smoothPage(state, FeatureComingSoonScreen(args: state.extra! as FeatureComingSoonArgs)),
    ),
    GoRoute(
      path: AppRoutes.dailyQuestion,
      pageBuilder: (context, state) => _smoothPage(state, const DailyQuestionScreen()),
    ),
    GoRoute(
      path: AppRoutes.community,
      pageBuilder: (context, state) => _smoothPage(state, const CommunityScreen()),
    ),
    GoRoute(
      path: AppRoutes.journalEntry,
      pageBuilder: (context, state) => _smoothPage(state, const JournalEntryScreen()),
    ),
    GoRoute(
      path: AppRoutes.sealedJournals,
      pageBuilder: (context, state) => _smoothPage(state, const SealedJournalsScreen()),
    ),
    GoRoute(
      path: AppRoutes.calendar,
      pageBuilder: (context, state) => _smoothPage(state, const CalendarScreen()),
    ),
    GoRoute(
      path: AppRoutes.rewards,
      pageBuilder: (context, state) => _smoothPage(state, const RewardsScreen()),
    ),
    GoRoute(
      path: AppRoutes.letters,
      pageBuilder: (context, state) => _smoothPage(state, const LettersScreen()),
    ),
    GoRoute(
      path: AppRoutes.stats,
      pageBuilder: (context, state) => _smoothPage(state, const StatsScreen()),
    ),
    GoRoute(
      path: AppRoutes.aiQuestions,
      pageBuilder: (context, state) => _smoothPage(state, const AiQuestionsScreen()),
    ),
    GoRoute(
      path: AppRoutes.meditation,
      pageBuilder: (context, state) => _smoothPage(state, const MeditationScreen()),
    ),
    GoRoute(
      path: AppRoutes.hobbies,
      pageBuilder: (context, state) => _smoothPage(state, const HobbiesScreen()),
    ),
    GoRoute(
      path: AppRoutes.hobbiesOnboarding,
      pageBuilder: (context, state) => _smoothPage(state, const HobbiesScreen(onboarding: true)),
    ),
    GoRoute(
      path: AppRoutes.activities,
      pageBuilder: (context, state) => _smoothPage(state, const ActivitiesScreen()),
    ),
    GoRoute(
      path: AppRoutes.feed,
      pageBuilder: (context, state) => _smoothPage(state, const FeedScreen()),
    ),
    GoRoute(
      path: AppRoutes.calm,
      pageBuilder: (context, state) => _smoothPage(state, const SosCalmScreen()),
    ),
    GoRoute(
      path: AppRoutes.focusTimer,
      pageBuilder: (context, state) => _smoothPage(state, const FocusTimerScreen()),
    ),
    GoRoute(
      path: AppRoutes.favorites,
      pageBuilder: (context, state) => _smoothPage(state, const FavoritesScreen()),
    ),
    GoRoute(
      path: AppRoutes.quotes,
      pageBuilder: (context, state) => _smoothPage(state, QuoteGalleryScreen(initialIndex: (state.extra as int?) ?? 0)),
    ),
  ],
);

/// A soft, Reflectly-style page transition used app-wide: the incoming screen
/// fades in while gently rising, the outgoing one fades out — smooth on every
/// platform (the default web transition is an instant, "dead" cut). Keeping one
/// helper means every route shares the exact same feel.
CustomTransitionPage<void> _smoothPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 240),
    reverseTransitionDuration: const Duration(milliseconds: 210),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Shared-axis (Z) feel that animates BOTH directions:
      // • Entering (animation 0→1): fade in + scale 0.96→1.0 + slight rise.
      // • Being covered (secondaryAnimation 0→1): fade out + recede to 0.95.
      // • Revealed on pop (secondaryAnimation 1→0): the old screen grows
      //   0.95→1.0 and fades back in — no more static cut on back.
      final inCurve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
      final outCurve = CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);

      return FadeTransition(
        opacity: inCurve,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1.0).animate(inCurve),
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(inCurve),
            child: FadeTransition(
              opacity: Tween<double>(begin: 1.0, end: 0.0).animate(outCurve),
              child: ScaleTransition(
                scale: Tween<double>(begin: 1.0, end: 0.95).animate(outCurve),
                child: child,
              ),
            ),
          ),
        ),
      );
    },
    child: child,
  );
}
