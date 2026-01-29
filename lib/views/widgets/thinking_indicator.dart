import 'dart:async';
import 'package:flutter/material.dart';

/// Message sets for different loading contexts
const List<String> extractionMessages = [
  'Reading the conversation',
  'Picking up the context',
  'Understanding the vibe',
];

const List<String> replyMessages = [
  'Crafting the perfect reply',
  'Reading between the lines',
  'Finding the right words',
  'Analyzing her energy',
  'Working some magic',
];

const List<String> openerMessages = [
  'Finding conversation starters',
  'Crafting your opening line',
  'Studying her profile',
  'Looking for common ground',
  'Creating your first impression',
];

const List<String> recommendedMessages = [
  'Loading proven openers',
  'Grabbing the good stuff',
];

/// A Claude-style thinking indicator with animated dots and rotating messages.
class ThinkingIndicator extends StatefulWidget {
  final List<String> messages;
  final Color? color;
  final double fontSize;

  const ThinkingIndicator({
    super.key,
    required this.messages,
    this.color,
    this.fontSize = 16,
  });

  @override
  State<ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<ThinkingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _dotController;
  late List<Animation<double>> _dotAnimations;
  late Timer _messageTimer;
  int _currentMessageIndex = 0;
  double _messageOpacity = 1.0;

  @override
  void initState() {
    super.initState();
    _setupDotAnimations();
    _setupMessageRotation();
  }

  void _setupDotAnimations() {
    // Animation controller for dots - 1.2 second cycle
    _dotController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    // Create staggered animations for each dot
    _dotAnimations = List.generate(3, (index) {
      final startInterval = index * 0.2; // 0.0, 0.2, 0.4
      final peakInterval = startInterval + 0.2; // 0.2, 0.4, 0.6
      final endInterval = peakInterval + 0.2; // 0.4, 0.6, 0.8

      return TweenSequence<double>([
        // Fade in
        TweenSequenceItem(
          tween: Tween(begin: 0.3, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 1,
        ),
        // Fade out
        TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.3)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 1,
        ),
      ]).animate(
        CurvedAnimation(
          parent: _dotController,
          curve: Interval(
            startInterval,
            endInterval.clamp(0.0, 1.0),
            curve: Curves.linear,
          ),
        ),
      );
    });
  }

  void _setupMessageRotation() {
    // Rotate messages every 3 seconds
    _messageTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (widget.messages.length > 1) {
        _fadeToNextMessage();
      }
    });
  }

  void _fadeToNextMessage() async {
    // Fade out
    if (!mounted) return;
    setState(() => _messageOpacity = 0.0);
    await Future.delayed(const Duration(milliseconds: 200));

    // Change message
    if (!mounted) return;
    setState(() {
      _currentMessageIndex =
          (_currentMessageIndex + 1) % widget.messages.length;
    });

    // Fade in
    await Future.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;
    setState(() => _messageOpacity = 1.0);
  }

  @override
  void dispose() {
    _dotController.dispose();
    _messageTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = widget.color ?? colorScheme.onSurface;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Rotating message text
        AnimatedOpacity(
          opacity: _messageOpacity,
          duration: const Duration(milliseconds: 200),
          child: Text(
            widget.messages[_currentMessageIndex],
            style: TextStyle(
              color: textColor,
              fontSize: widget.fontSize,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        // Animated dots
        AnimatedBuilder(
          animation: _dotController,
          builder: (context, child) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Opacity(
                    opacity: _dotAnimations[index].value,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: textColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }
}

/// Compact version for inline use (e.g., image extraction)
class ThinkingIndicatorCompact extends StatefulWidget {
  final List<String> messages;
  final Color? color;
  final double fontSize;

  const ThinkingIndicatorCompact({
    super.key,
    required this.messages,
    this.color,
    this.fontSize = 13,
  });

  @override
  State<ThinkingIndicatorCompact> createState() =>
      _ThinkingIndicatorCompactState();
}

class _ThinkingIndicatorCompactState extends State<ThinkingIndicatorCompact>
    with TickerProviderStateMixin {
  late AnimationController _dotController;
  late List<Animation<double>> _dotAnimations;
  late Timer _messageTimer;
  int _currentMessageIndex = 0;
  double _messageOpacity = 1.0;

  @override
  void initState() {
    super.initState();
    _setupDotAnimations();
    _setupMessageRotation();
  }

  void _setupDotAnimations() {
    _dotController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    _dotAnimations = List.generate(3, (index) {
      final startInterval = index * 0.2;
      final endInterval = (startInterval + 0.4).clamp(0.0, 1.0);

      return TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween(begin: 0.3, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 1,
        ),
        TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.3)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 1,
        ),
      ]).animate(
        CurvedAnimation(
          parent: _dotController,
          curve: Interval(startInterval, endInterval, curve: Curves.linear),
        ),
      );
    });
  }

  void _setupMessageRotation() {
    _messageTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (widget.messages.length > 1) {
        _fadeToNextMessage();
      }
    });
  }

  void _fadeToNextMessage() async {
    if (!mounted) return;
    setState(() => _messageOpacity = 0.0);
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    setState(() {
      _currentMessageIndex =
          (_currentMessageIndex + 1) % widget.messages.length;
    });
    await Future.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;
    setState(() => _messageOpacity = 1.0);
  }

  @override
  void dispose() {
    _dotController.dispose();
    _messageTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = widget.color ?? colorScheme.onSurface;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Rotating message text
        Flexible(
          child: AnimatedOpacity(
            opacity: _messageOpacity,
            duration: const Duration(milliseconds: 200),
            child: Text(
              widget.messages[_currentMessageIndex],
              style: TextStyle(
                color: textColor,
                fontSize: widget.fontSize,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 4),
        // Animated dots inline
        AnimatedBuilder(
          animation: _dotController,
          builder: (context, child) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Opacity(
                    opacity: _dotAnimations[index].value,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: textColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }
}
