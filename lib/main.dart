import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flirtfix/l10n/gen/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/local_notification_service.dart';
import 'services/push_notification_service.dart';
import 'l10n/l10n.dart';
import 'state/app_state.dart';
import 'views/screens/community_post_route_screen.dart';
import 'views/screens/community_screen.dart';
import 'views/screens/conversations_screen.dart';
import 'views/screens/login_screen.dart';
import 'views/screens/pricing_screen.dart';
import 'views/screens/profile_screen.dart';
import 'views/screens/settings_screen.dart';
import 'views/screens/signup_screen.dart';

ThemeData buildPremiumDarkNeonTheme() {
  const baseDark = Color(0xFF0E0F12);
  const surface = Color(0xFF12141A);
  const surfaceLow = Color(0xFF16181F);
  const primary = Color(0xFFFF2D6D);
  const secondary = Color(0xFFD4AF37);
  const tertiary = Color(0xFFB95A7B);

  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
      ).copyWith(
        primary: primary,
        onPrimary: baseDark,
        primaryContainer: const Color(0xFF4A0D26),
        onPrimaryContainer: const Color(0xFFFFC2D4),
        secondary: secondary,
        onSecondary: baseDark,
        secondaryContainer: const Color(0xFF3A2F0D),
        onSecondaryContainer: const Color(0xFFFFE3A1),
        tertiary: tertiary,
        onTertiary: baseDark,
        tertiaryContainer: const Color(0xFF3A1C2A),
        onTertiaryContainer: const Color(0xFFF3C3D5),
        surface: surface,
        surfaceDim: const Color(0xFF0C0D10),
        surfaceBright: const Color(0xFF191B22),
        surfaceContainerLowest: const Color(0xFF0A0B0E),
        surfaceContainerLow: surfaceLow,
        surfaceContainer: const Color(0xFF1B1E25),
        surfaceContainerHigh: const Color(0xFF21242C),
        surfaceContainerHighest: const Color(0xFF272B35),
        onSurface: const Color(0xFFF4F2EE),
        onSurfaceVariant: const Color(0xFF8F9BB3),
        outline: const Color(0xFF3A3F4A),
        outlineVariant: const Color(0xFF2E323B),
        error: const Color(0xFFCF6679),
        onError: const Color(0xFF1E1014),
        errorContainer: const Color(0xFF401B24),
        onErrorContainer: const Color(0xFFF7D4DC),
        shadow: Colors.black,
        scrim: Colors.black,
        inverseSurface: const Color(0xFFF4F2EE),
        onInverseSurface: baseDark,
        inversePrimary: const Color(0xFFFF86A8),
      );

  final textTheme = _buildPremiumTextTheme(colorScheme, Brightness.dark);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      elevation: 0,
      scrolledUnderElevation: 2,
      surfaceTintColor: colorScheme.primary.withValues(alpha: 0.18),
      systemOverlayStyle: SystemUiOverlayStyle.light,
      iconTheme: IconThemeData(color: colorScheme.onSurface),
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: colorScheme.outline),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 1),
      ),
      contentPadding: const EdgeInsets.all(18),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: colorScheme.surfaceContainerHigh,
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurface,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant,
      thickness: 1,
    ),
  );
}

TextTheme _buildPremiumTextTheme(
  ColorScheme colorScheme,
  Brightness brightness,
) {
  final base = GoogleFonts.manropeTextTheme(
    brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme,
  );

  TextStyle? headline(TextStyle? style) {
    return GoogleFonts.playfairDisplay(
      textStyle: style,
      fontWeight: FontWeight.w600,
    );
  }

  final blended = base.copyWith(
    displayLarge: headline(base.displayLarge),
    displayMedium: headline(base.displayMedium),
    displaySmall: headline(base.displaySmall),
    headlineLarge: headline(base.headlineLarge),
    headlineMedium: headline(base.headlineMedium),
    headlineSmall: headline(base.headlineSmall),
  );

  return blended.apply(
    bodyColor: colorScheme.onSurface,
    displayColor: colorScheme.onSurface,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await LocalNotificationService.initialize();
  await PushNotificationService.initialize();
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppState _appState;
  late final FirebaseAnalytics _analytics;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  int? _lastSyncedOneSignalUserId;
  bool _oneSignalLoggedOutSynced = false;

  @override
  void initState() {
    super.initState();
    _appState = AppState();
    _appState.addListener(_handleAppStateChange);
    _appState.initialize();
    _analytics = FirebaseAnalytics.instance;
    unawaited(
      LocalNotificationService.setTapHandler(_handleLocalNotificationTapAction),
    );
    unawaited(PushNotificationService.setTapHandler(_handlePushTapAction));
    unawaited(_syncOneSignalIdentity());
  }

  void _handleAppStateChange() {
    unawaited(_syncOneSignalIdentity());
  }

  Future<void> _syncOneSignalIdentity() async {
    final isLoggedIn = _appState.isLoggedIn;
    final userId = _appState.user?.id;

    if (isLoggedIn && userId != null) {
      if (_lastSyncedOneSignalUserId == userId) return;
      await PushNotificationService.syncAuthenticatedUser(userId);
      _lastSyncedOneSignalUserId = userId;
      _oneSignalLoggedOutSynced = false;
      return;
    }

    if (_oneSignalLoggedOutSynced) return;
    await PushNotificationService.clearAuthenticatedUser();
    _lastSyncedOneSignalUserId = null;
    _oneSignalLoggedOutSynced = true;
  }

  Future<void> _handleLocalNotificationTapAction(String action) async {
    await _appState.reloadFromStorage();
    if (!mounted) return;

    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_handleLocalNotificationTapAction(action));
      });
      return;
    }

    navigator.popUntil((route) => route.isFirst);

    if (action == LocalNotificationService.actionGuestSignupNudge) {
      if (!_appState.isLoggedIn) {
        await navigator.push(
          MaterialPageRoute(builder: (context) => const SignupScreen()),
        );
      }
      return;
    }

    if (action == LocalNotificationService.actionUpgradeNudge) {
      if (_appState.isLoggedIn && !_appState.isSubscribed) {
        await navigator.push(
          MaterialPageRoute(builder: (context) => const PricingScreen()),
        );
      }
      return;
    }

    // Daily refill taps intentionally stay on the default home flow.
  }

  Future<void> _handlePushTapAction(PushTapAction action) async {
    await _appState.reloadFromStorage();
    if (!mounted) return;

    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_handlePushTapAction(action));
      });
      return;
    }

    navigator.popUntil((route) => route.isFirst);

    if (action.action == PushNotificationService.actionCommunityComment) {
      final postId = action.postId;
      if (postId == null) return;
      await navigator.push(
        MaterialPageRoute(
          builder: (context) => CommunityPostRouteScreen(postId: postId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _appState,
      builder: (context, child) {
        return AppStateScope(
          notifier: _appState,
          child: MaterialApp(
            navigatorKey: _navigatorKey,
            debugShowCheckedModeBanner: false,
            onGenerateTitle: (context) => context.l10n.appTitle,
            theme: _buildPremiumLightTheme(),
            darkTheme: buildPremiumDarkNeonTheme(),
            themeMode: _appState.themeMode == AppThemeMode.premiumLightGold
                ? ThemeMode.light
                : ThemeMode.dark,
            locale: _appState.localeOverride,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) {
              return RepaintBoundary(child: child ?? const SizedBox.shrink());
            },
            navigatorObservers: [
              FirebaseAnalyticsObserver(analytics: _analytics),
            ],
            home: const SplashScreen(),
          ),
        );
      },
    );
  }

  ThemeData _buildPremiumLightTheme() {
    const baseLight = Color(0xFF1C1C1E); // Charcoal
    const background = Color(0xFFF9F8F6); // Alabaster
    const surface = Color(0xFFFFFFFF); // Porcelain
    const surfaceLow = Color(0xFFFFFFFF);
    const primary = Color(0xFF991B38); // Merlot
    const secondary = Color(0xFFC4A462); // Champagne
    const tertiary = Color(0xFFC22E53); // Raspberry
    const stoneGrey = Color(0xFF8E8E93); // Stone
    const softBlush = Color(0xFFFAF0F2); // Soft Blush

    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: primary,
          onPrimary: const Color(0xFFFFFFFF),
          primaryContainer: softBlush,
          onPrimaryContainer: baseLight,
          secondary: secondary,
          onSecondary: baseLight,
          secondaryContainer: const Color(0xFFF2E7D2),
          onSecondaryContainer: baseLight,
          tertiary: tertiary,
          onTertiary: baseLight,
          tertiaryContainer: softBlush,
          onTertiaryContainer: baseLight,
          surface: surface,
          surfaceDim: const Color(0xFFF1EEE9),
          surfaceBright: surface,
          surfaceContainerLowest: surface,
          surfaceContainerLow: surfaceLow,
          surfaceContainer: const Color(0xFFF7F4F0),
          surfaceContainerHigh: surface,
          surfaceContainerHighest: const Color(0xFFF2EEEA),
          onSurface: baseLight,
          onSurfaceVariant: stoneGrey,
          outline: const Color(0xFFE6E1D9),
          outlineVariant: const Color(0xFFEDE7E1),
          error: const Color(0xFF8C1D18),
          onError: const Color(0xFFFFFFFF),
          errorContainer: const Color(0xFFF2B8B5),
          onErrorContainer: const Color(0xFF601410),
          shadow: const Color(0xFF9E9E9E),
          scrim: Colors.black,
          inverseSurface: baseLight,
          onInverseSurface: background,
          inversePrimary: tertiary,
        );

    final textTheme = _buildPremiumTextTheme(colorScheme, Brightness.light);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 2,
        surfaceTintColor: colorScheme.secondary.withValues(alpha: 0.12),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0.6,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: BorderSide(color: colorScheme.outlineVariant),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.secondary, width: 1),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.surfaceContainerHighest,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
      ),
    );
  }

  @override
  void dispose() {
    unawaited(LocalNotificationService.setTapHandler(null));
    unawaited(PushNotificationService.setTapHandler(null));
    _appState.removeListener(_handleAppStateChange);
    _appState.dispose();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Main shell — bottom navigation
// ---------------------------------------------------------------------------

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  bool _prevLoggedIn = false;
  VoidCallback? _communitySortAction;
  VoidCallback? _communityRefreshAction;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = <Widget>[
      const ConversationsScreen(showAppBar: false),
      CommunityScreen(
        showAppBar: false,
        onSortActionChanged: (action) {
          _communitySortAction = action;
        },
        onRefreshActionChanged: (action) {
          _communityRefreshAction = action;
        },
      ),
      const ProfileScreen(),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // When user logs out from the Profile tab, return to Home tab.
    final appState = AppStateScope.of(context);
    if (_prevLoggedIn && !appState.isLoggedIn && _selectedIndex == 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedIndex = 0);
      });
    }
    _prevLoggedIn = appState.isLoggedIn;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final appState = AppStateScope.of(context);
    final showMainAppBar = _selectedIndex != 2;

    return Scaffold(
      appBar: showMainAppBar ? _buildMainAppBar(theme) : null,
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) async {
          HapticFeedback.selectionClick();
          if (i == 2 && !appState.isLoggedIn) {
            final didLogin = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
            if (!mounted) return;
            if (didLogin == true) {
              setState(() => _selectedIndex = 0);
            }
            return;
          }
          if (i == 1) {
            _communityRefreshAction?.call();
          }
          setState(() => _selectedIndex = i);
        },
        backgroundColor: isLight ? cs.surface : cs.surfaceContainerLow,
        indicatorColor: cs.primary.withValues(alpha: 0.15),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: cs.primary),
            label: context.l10n.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: cs.primary),
            label: context.l10n.communityTitle,
          ),
          if (appState.isLoggedIn)
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: cs.primary),
              label: context.l10n.profileTitle,
            )
          else
            NavigationDestination(
              icon: const Icon(Icons.login_outlined),
              selectedIcon: Icon(Icons.login, color: cs.primary),
              label: context.l10n.commonSignIn,
            ),
        ],
      ),
    );
  }

  void _openSettings() {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  PreferredSizeWidget _buildMainAppBar(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = context.l10n;
    final subtitle = _selectedIndex == 1
        ? l10n.communityTitle
        : l10n.conversationsAppbarSubtitle;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 0,
      title: Row(
        children: [
          const SizedBox(width: 16),
          Image.asset(
            'assets/images/icons/appstore_transparent.png',
            width: 32,
            height: 32,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.appTitle,
                style: textTheme.headlineSmall?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                subtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (_selectedIndex == 1)
          IconButton(
            onPressed: _communitySortAction,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.outlineVariant),
                color: Colors.transparent,
              ),
              child: Icon(
                Icons.sort_outlined,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
          ),
        IconButton(
          onPressed: _openSettings,
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.outlineVariant),
              color: Colors.transparent,
            ),
            child: Icon(
              Icons.settings_outlined,
              color: colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _breathController;
  late Animation<double> _fadeIn;
  late Animation<double> _scale;
  late Animation<double> _breathOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _breathController = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    );

    _fadeIn = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _scale = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
    _breathOpacity = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
    _breathController.repeat(reverse: true);
    _initializeApp();
  }

  @override
  void dispose() {
    _controller.dispose();
    _breathController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(milliseconds: 1800));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const MainShell(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final splashTheme = buildPremiumDarkNeonTheme();
    final colorScheme = splashTheme.colorScheme;
    final textTheme = splashTheme.textTheme;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeIn.value,
              child: Transform.scale(scale: _scale.value, child: child),
            );
          },
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                const Spacer(flex: 3),

                FadeTransition(
                  opacity: _breathOpacity,
                  child: Image.asset(
                    'assets/images/icons/appstore_transparent.png',
                    width: 140,
                    height: 140,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 32),

                // App name
                Text(
                  l10n.appTitle,
                  style: textTheme.displaySmall?.copyWith(
                    fontSize: 36,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.6,
                    height: 1.1,
                  ),
                ),

                const SizedBox(height: 12),

                // Tagline
                Text(
                  l10n.splashTagline,
                  style: textTheme.titleSmall?.copyWith(
                    color: colorScheme.secondary,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const Spacer(flex: 3),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
