import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flirtfix/views/widgets/premium_gradient_button.dart';

class OnboardingAnalysisScreen extends StatefulWidget {
  final VoidCallback onContinue;

  const OnboardingAnalysisScreen({
    super.key,
    required this.onContinue,
  });

  @override
  State<OnboardingAnalysisScreen> createState() =>
      _OnboardingAnalysisScreenState();
}

class _OnboardingAnalysisScreenState extends State<OnboardingAnalysisScreen> {
  bool _showResult = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      setState(() => _showResult = true);
      HapticFeedback.lightImpact();
      Future.delayed(const Duration(milliseconds: 100), () {
        HapticFeedback.mediumImpact();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            switchInCurve: Curves.easeOutExpo,
            switchOutCurve: Curves.easeInOutCubic,
            child: _showResult
                ? _buildResult(colorScheme, textTheme)
                : _buildLoader(colorScheme, textTheme),
          ),
          const Spacer(flex: 2),
          if (_showResult)
            PremiumGradientButton(
              onPressed: widget.onContinue,
              child: const Text('Continue'),
            )
                .animate()
                .fadeIn(
                  duration: 500.ms,
                  delay: 400.ms,
                  curve: Curves.easeOutExpo,
                )
                .slideY(
                  begin: 0.2,
                  delay: 400.ms,
                  duration: 500.ms,
                  curve: Curves.easeOutExpo,
                ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildLoader(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      key: const ValueKey('loader'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.secondary.withValues(alpha: 0.12),
          ),
          child: Center(
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.secondary.withValues(alpha: 0.25),
              ),
            ),
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              begin: const Offset(0.85, 0.85),
              end: const Offset(1.0, 1.0),
              duration: 1200.ms,
              curve: Curves.easeInOutCubic,
            )
            .fadeIn(duration: 600.ms),
        const SizedBox(height: 32),
        Text(
          'Analyzing your\ncommunication style...',
          textAlign: TextAlign.center,
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ).animate().fadeIn(duration: 500.ms, delay: 300.ms),
      ],
    );
  }

  Widget _buildResult(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      key: const ValueKey('result'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "You're not alone.",
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        )
            .animate()
            .fadeIn(duration: 600.ms, curve: Curves.easeOutExpo)
            .slideY(
              begin: 0.1,
              duration: 600.ms,
              curve: Curves.easeOutExpo,
            ),
        const SizedBox(height: 16),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            children: [
              const TextSpan(text: '82% of matches are lost to '),
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.tertiary,
                    ],
                  ).createShader(
                    Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                  ),
                  child: Text(
                    'dry texting.',
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(
              duration: 600.ms,
              delay: 300.ms,
              curve: Curves.easeOutExpo,
            )
            .slideY(
              begin: 0.1,
              delay: 300.ms,
              duration: 600.ms,
              curve: Curves.easeOutExpo,
            ),
      ],
    );
  }
}
