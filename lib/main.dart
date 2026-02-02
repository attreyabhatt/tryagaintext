import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:google_fonts/google_fonts.dart';
import 'state/app_state.dart';
import 'views/screens/conversations_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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

  @override
  void initState() {
    super.initState();
    _appState = AppState();
    _appState.initialize();
    _analytics = FirebaseAnalytics.instance;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _appState,
      builder: (context, child) {
        return AppStateScope(
          notifier: _appState,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'FlirtFix',
            theme: _buildPremiumLightTheme(),
            darkTheme: _buildPremiumDarkNeonTheme(),
            themeMode: _appState.themeMode == AppThemeMode.premiumLightGold
                ? ThemeMode.light
                : ThemeMode.dark,
            builder: (context, child) {
              final theme = Theme.of(context);
              final isLight = theme.brightness == Brightness.light;
              final decoration = isLight
                  ? const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFF9F8F4),
                          Color(0xFFF0EFEA),
                        ],
                      ),
                    )
                  : BoxDecoration(color: theme.colorScheme.surface);
              return DecoratedBox(
                decoration: decoration,
                child: child ?? const SizedBox.shrink(),
              );
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
    const baseLight = Color(0xFF2C2C2C); // Onyx
    const background = Color(0xFFF9F8F4); // Alabaster White
    const surface = Color(0xFFFFFFFF); // Pure White
    const surfaceLow = Color(0xFFFFFFFF);
    const primary = Color(0xFFD81B60); // Velvet Rose
    const secondary = Color(0xFFBFA055); // Burnished Gold
    const tertiary = Color(0xFFC08A7A); // Rose Gold
    const stoneGrey = Color(0xFF8E8E93);
    const vaporGrey = Color(0xFFF2F2F5);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: primary,
      onPrimary: const Color(0xFFFFFFFF),
      primaryContainer: const Color(0xFFF7DCE7),
      onPrimaryContainer: baseLight,
      secondary: secondary,
      onSecondary: baseLight,
      secondaryContainer: const Color(0xFFF3E6C8),
      onSecondaryContainer: baseLight,
      tertiary: tertiary,
      onTertiary: baseLight,
      tertiaryContainer: const Color(0xFFF3E2DC),
      onTertiaryContainer: baseLight,
      surface: surface,
      surfaceDim: const Color(0xFFF0EFEA),
      surfaceBright: surface,
      surfaceContainerLowest: surface,
      surfaceContainerLow: surfaceLow,
      surfaceContainer: const Color(0xFFF7F6F2),
      surfaceContainerHigh: vaporGrey,
      surfaceContainerHighest: const Color(0xFFEFEDE6),
      onSurface: baseLight,
      onSurfaceVariant: stoneGrey,
      outline: const Color(0xFFE5E5EA),
      outlineVariant: const Color(0xFFEDEBE4),
      shadow: const Color(0xFF9E9E9E),
      scrim: Colors.black,
      inverseSurface: baseLight,
      onInverseSurface: background,
      inversePrimary: const Color(0xFFFF5C8D),
    );

    final textTheme = _buildPremiumTextTheme(
      colorScheme,
      Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.transparent,
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
        shadowColor: const Color(0xFF9E9E9E).withValues(alpha: 0.12),
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
        fillColor: vaporGrey,
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

  ThemeData _buildPremiumDarkNeonTheme() {
    const baseDark = Color(0xFF0E0F12);
    const surface = Color(0xFF12141A);
    const surfaceLow = Color(0xFF16181F);
    const primary = Color(0xFFFF2D6D);
    const secondary = Color(0xFFD4AF37);
    const tertiary = Color(0xFFB95A7B);

    final colorScheme = ColorScheme.fromSeed(
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
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: const Color(0xFFF4F2EE),
      onInverseSurface: baseDark,
      inversePrimary: const Color(0xFFFF86A8),
    );

    final textTheme = _buildPremiumTextTheme(
      colorScheme,
      Brightness.dark,
    );

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

  @override
  void dispose() {
    _appState.dispose();
    super.dispose();
  }
}

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
    _breathOpacity = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _breathController,
      curve: Curves.easeInOut,
    ));
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
              const ConversationsScreen(),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
                  'FlirtFix',
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
                  'Master the Art of Conversation.',
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
