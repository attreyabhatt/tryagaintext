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

/// Simple animated text that rotates through messages (no dots)
class AnimatedLoadingText extends StatefulWidget {
  final List<String> messages;
  final Color? color;
  final double fontSize;
  final FontWeight fontWeight;

  const AnimatedLoadingText({
    super.key,
    required this.messages,
    this.color,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w600,
  });

  @override
  State<AnimatedLoadingText> createState() => _AnimatedLoadingTextState();
}

class _AnimatedLoadingTextState extends State<AnimatedLoadingText> {
  late Timer _messageTimer;
  int _currentMessageIndex = 0;
  double _messageOpacity = 1.0;

  @override
  void initState() {
    super.initState();
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
      _currentMessageIndex = (_currentMessageIndex + 1) % widget.messages.length;
    });
    await Future.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;
    setState(() => _messageOpacity = 1.0);
  }

  @override
  void dispose() {
    _messageTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.color ?? Theme.of(context).colorScheme.onSurface;
    return AnimatedOpacity(
      opacity: _messageOpacity,
      duration: const Duration(milliseconds: 200),
      child: Text(
        widget.messages[_currentMessageIndex],
        textAlign: TextAlign.center,
        style: TextStyle(
          color: textColor,
          fontSize: widget.fontSize,
          fontWeight: widget.fontWeight,
        ),
      ),
    );
  }
}

class BreathingLogoIndicator extends StatefulWidget {
  final String assetPath;
  final double size;
  final Color glowColor;
  final Duration duration;

  const BreathingLogoIndicator({
    super.key,
    required this.assetPath,
    required this.size,
    required this.glowColor,
    this.duration = const Duration(milliseconds: 2000),
  });

  @override
  State<BreathingLogoIndicator> createState() => _BreathingLogoIndicatorState();
}

class _BreathingLogoIndicatorState extends State<BreathingLogoIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this)
      ..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.94, end: 1.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _glow = Tween<double>(begin: 0.25, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(BreathingLogoIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
      _controller
        ..reset()
        ..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final glow = _glow.value;
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(
                  alpha: 0.2 + (0.35 * glow),
                ),
                blurRadius: widget.size * (0.35 + glow),
                spreadRadius: widget.size * 0.05 * glow,
              ),
            ],
          ),
          child: Transform.scale(scale: _scale.value, child: child),
        );
      },
      child: ClipOval(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                widget.glowColor.withValues(alpha: 0.2),
                Colors.transparent,
              ],
            ),
          ),
          child: Center(
            child: Image.asset(
              widget.assetPath,
              width: widget.size * 0.55,
              height: widget.size * 0.55,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

class BreathingPulseIndicator extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;

  const BreathingPulseIndicator({
    super.key,
    required this.size,
    required this.color,
    this.duration = const Duration(milliseconds: 1600),
  });

  @override
  State<BreathingPulseIndicator> createState() => _BreathingPulseIndicatorState();
}

class _BreathingPulseIndicatorState extends State<BreathingPulseIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this)
      ..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _glow = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(BreathingPulseIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
      _controller
        ..reset()
        ..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final glow = _glow.value;
        return Transform.scale(
          scale: _scale.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  widget.color.withValues(alpha: 0.9),
                  widget.color.withValues(alpha: 0.45),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(
                    alpha: 0.2 + (0.45 * glow),
                  ),
                  blurRadius: widget.size * (0.35 + glow),
                  spreadRadius: widget.size * 0.08 * glow,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
