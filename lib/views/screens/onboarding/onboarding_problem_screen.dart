import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flirtfix/l10n/l10n.dart';
import 'package:flirtfix/views/widgets/premium_gradient_button.dart';

class OnboardingProblemScreen extends StatelessWidget {
  final Set<String> selectedProblems;
  final ValueChanged<String> onToggleProblem;
  final VoidCallback onContinue;

  const OnboardingProblemScreen({
    super.key,
    required this.selectedProblems,
    required this.onToggleProblem,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;

    final problems = [
      _ProblemOption(
        title: l10n.onboardingProblemFizzleTitle,
        subtitle: l10n.onboardingProblemFizzleSubtitle,
        icon: Icons.trending_down_rounded,
      ),
      _ProblemOption(
        title: l10n.onboardingProblemOpenTitle,
        subtitle: l10n.onboardingProblemOpenSubtitle,
        icon: Icons.chat_bubble_outline_rounded,
      ),
      _ProblemOption(
        title: l10n.onboardingProblemReadTitle,
        subtitle: l10n.onboardingProblemReadSubtitle,
        icon: Icons.visibility_off_outlined,
      ),
      _ProblemOption(
        title: l10n.onboardingProblemBoringTitle,
        subtitle: l10n.onboardingProblemBoringSubtitle,
        icon: Icons.sentiment_neutral_outlined,
      ),
      _ProblemOption(
        title: l10n.onboardingProblemFlirtTitle,
        subtitle: l10n.onboardingProblemFlirtSubtitle,
        icon: Icons.favorite_border_rounded,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),
          Text(
            l10n.onboardingProblemTitle,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          )
              .animate()
              .fadeIn(
                duration: 500.ms,
                curve: Curves.easeOutExpo,
              )
              .slideY(begin: 0.1, curve: Curves.easeOutExpo),
          const SizedBox(height: 8),
          Text(
            l10n.onboardingProblemSubtitle,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          )
              .animate()
              .fadeIn(
                duration: 500.ms,
                delay: 100.ms,
                curve: Curves.easeOutExpo,
              ),
          const SizedBox(height: 32),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final problem = problems[index];
                      final isSelected =
                          selectedProblems.contains(problem.title);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ProblemCard(
                          problem: problem,
                          isSelected: isSelected,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            onToggleProblem(problem.title);
                          },
                        ),
                      )
                          .animate()
                          .fadeIn(
                            duration: 400.ms,
                            delay: (200 + index * 80).ms,
                            curve: Curves.easeOutExpo,
                          )
                          .slideY(
                            begin: 0.1,
                            delay: (200 + index * 80).ms,
                            duration: 400.ms,
                            curve: Curves.easeOutExpo,
                          );
                    },
                    childCount: problems.length,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PremiumGradientButton(
            onPressed: selectedProblems.isNotEmpty ? onContinue : null,
            child: Text(l10n.commonContinue),
          )
              .animate()
              .fadeIn(
                duration: 400.ms,
                delay: 700.ms,
                curve: Curves.easeOutExpo,
              ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ProblemOption {
  final String title;
  final String subtitle;
  final IconData icon;

  const _ProblemOption({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _ProblemCard extends StatelessWidget {
  final _ProblemOption problem;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProblemCard({
    required this.problem,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF3A2F0D)
              : colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? colorScheme.secondary : colorScheme.outline,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.secondary.withValues(alpha: 0.15)
                    : colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                problem.icon,
                color: isSelected
                    ? colorScheme.secondary
                    : colorScheme.onSurfaceVariant,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    problem.title,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    problem.subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isSelected ? 1.0 : 0.0,
              child: Icon(
                Icons.check_circle_rounded,
                color: colorScheme.secondary,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
