import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flirtfix/l10n/l10n.dart';
import 'package:flirtfix/views/widgets/gradient_icon.dart';
import 'package:flirtfix/views/widgets/premium_gradient_button.dart';

class OnboardingSolutionScreen extends StatelessWidget {
  final VoidCallback onContinue;

  const OnboardingSolutionScreen({
    super.key,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;

    final steps = [
      _SolutionStep(
        icon: Icons.camera_alt_outlined,
        iconGradient: LinearGradient(
          colors: [colorScheme.secondary, const Color(0xFFE8C84A)],
        ),
        title: l10n.onboardingSolutionStep1Title,
        subtitle: l10n.onboardingSolutionStep1Subtitle,
      ),
      _SolutionStep(
        icon: Icons.auto_awesome,
        iconGradient: LinearGradient(
          colors: [colorScheme.secondary, const Color(0xFFE8C84A)],
        ),
        title: l10n.onboardingSolutionStep2Title,
        subtitle: l10n.onboardingSolutionStep2Subtitle,
      ),
      _SolutionStep(
        icon: Icons.send_rounded,
        iconGradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.tertiary],
        ),
        title: l10n.onboardingSolutionStep3Title,
        subtitle: l10n.onboardingSolutionStep3Subtitle,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 1),
          Text(
            l10n.onboardingSolutionTitle,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms, curve: Curves.easeOutExpo)
              .slideY(begin: 0.1, duration: 500.ms, curve: Curves.easeOutExpo),
          const SizedBox(height: 48),
          ...List.generate(steps.length, (index) {
            final step = steps[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: _SolutionStepTile(
                step: step,
                stepNumber: index + 1,
              ),
            )
                .animate()
                .fadeIn(
                  duration: 500.ms,
                  delay: (400 + index * 300).ms,
                  curve: Curves.easeOutExpo,
                )
                .slideX(
                  begin: -0.15,
                  delay: (400 + index * 300).ms,
                  duration: 500.ms,
                  curve: Curves.easeOutExpo,
                );
          }),
          const Spacer(flex: 2),
          PremiumGradientButton(
            onPressed: onContinue,
            child: Text(l10n.onboardingGetStarted)
                .animate(onPlay: (c) => c.repeat())
                .shimmer(
                  duration: 1800.ms,
                  delay: 500.ms,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
          )
              .animate()
              .fadeIn(
                duration: 500.ms,
                delay: 1300.ms,
                curve: Curves.easeOutExpo,
              )
              .slideY(
                begin: 0.2,
                delay: 1300.ms,
                duration: 500.ms,
                curve: Curves.easeOutExpo,
              ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SolutionStep {
  final IconData icon;
  final Gradient iconGradient;
  final String title;
  final String subtitle;

  const _SolutionStep({
    required this.icon,
    required this.iconGradient,
    required this.title,
    required this.subtitle,
  });
}

class _SolutionStepTile extends StatelessWidget {
  final _SolutionStep step;
  final int stepNumber;

  const _SolutionStepTile({
    required this.step,
    required this.stepNumber,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          child: Center(
            child: GradientIcon(
              icon: step.icon,
              size: 26,
              gradient: step.iconGradient,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.title,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                step.subtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
