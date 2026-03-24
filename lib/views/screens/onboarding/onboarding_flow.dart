import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flirtfix/main.dart';
import 'package:flirtfix/views/screens/pricing_screen.dart';
import 'onboarding_problem_screen.dart';
import 'onboarding_analysis_screen.dart';
import 'onboarding_solution_screen.dart';
import 'onboarding_upload_screen.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  static const String _onboardingCompletedKey = 'onboarding_completed';

  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompletedKey) ?? false;
  }

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  final Set<String> _selectedProblems = {};

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleProblem(String problem) {
    setState(() {
      if (_selectedProblems.contains(problem)) {
        _selectedProblems.remove(problem);
      } else {
        _selectedProblems.add(problem);
      }
    });
  }

  void _goToNextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _onUploadStepComplete() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const PricingScreen(guestConversionMode: true),
      ),
    );
    if (!mounted) return;
    await _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(OnboardingFlow._onboardingCompletedKey, true);
    if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    final theme = buildPremiumDarkNeonTheme();

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: SafeArea(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              OnboardingProblemScreen(
                selectedProblems: _selectedProblems,
                onToggleProblem: _toggleProblem,
                onContinue: _goToNextPage,
              ),
              OnboardingAnalysisScreen(
                onContinue: _goToNextPage,
              ),
              OnboardingSolutionScreen(
                onContinue: _goToNextPage,
              ),
              OnboardingUploadScreen(
                onContinue: _onUploadStepComplete,
                onSkip: _onUploadStepComplete,
                onTrialExpired: _completeOnboarding,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
