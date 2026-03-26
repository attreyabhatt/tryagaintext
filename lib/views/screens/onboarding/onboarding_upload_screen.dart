import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flirtfix/models/suggestion.dart';
import 'package:flirtfix/services/api_client.dart';
import 'package:flirtfix/l10n/l10n.dart';
import 'package:flirtfix/utils/app_logger.dart';
import 'package:flirtfix/views/widgets/premium_gradient_button.dart';

class OnboardingUploadScreen extends StatefulWidget {
  final VoidCallback onContinue;
  final VoidCallback onSkip;
  final VoidCallback onTrialExpired;

  const OnboardingUploadScreen({
    super.key,
    required this.onContinue,
    required this.onSkip,
    required this.onTrialExpired,
  });

  @override
  State<OnboardingUploadScreen> createState() => _OnboardingUploadScreenState();
}

class _OnboardingUploadScreenState extends State<OnboardingUploadScreen> {
  final ApiClient _apiClient = ApiClient();
  File? _selectedImage;
  bool _isPressed = false;
  bool _isProcessing = false;
  List<Suggestion> _suggestions = [];
  String? _errorMessage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    HapticFeedback.heavyImpact();
    final imageFile = File(picked.path);
    setState(() {
      _selectedImage = imageFile;
      _isProcessing = true;
      _suggestions = [];
      _errorMessage = null;
    });

    try {
      // Step 1: Extract text from image (OCR)
      final ocrText = await _apiClient.extractFromImage(imageFile);
      if (!mounted) return;

      // Step 2: Generate replies using the extracted text
      final suggestions = await _apiClient.generate(
        lastText: ocrText,
        situation: 'stuck_after_reply',
        tone: 'witty',
        inputSource: 'ocr',
        ocrText: ocrText,
      );
      if (!mounted) return;

      HapticFeedback.heavyImpact();
      setState(() {
        _suggestions = suggestions;
        _isProcessing = false;
      });
    } on ApiException catch (e) {
      AppLogger.error('Onboarding generate failed', e);
      if (!mounted) return;
      if (e.code == ApiErrorCode.trialExpired ||
          e.code == ApiErrorCode.insufficientCredits) {
        widget.onTrialExpired();
        return;
      }
      setState(() {
        _isProcessing = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      AppLogger.error('Onboarding generate failed', e is Exception ? e : null);
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMessage = context.l10n.onboardingUploadError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;
    final hasImage = _selectedImage != null;
    final hasResults = _suggestions.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Text(
                hasResults
                    ? l10n.onboardingUploadTitleResults
                    : (hasImage ? l10n.onboardingUploadTitleAnalyzing : l10n.onboardingUploadTitleDefault),
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              )
                  .animate()
                  .fadeIn(duration: 500.ms, curve: Curves.easeOutExpo)
                  .slideY(
                      begin: 0.1,
                      duration: 500.ms,
                      curve: Curves.easeOutExpo),
              const SizedBox(height: 8),
              Text(
                hasResults
                    ? l10n.onboardingUploadSubtitleResults
                    : (_isProcessing
                        ? l10n.onboardingUploadSubtitleAnalyzing
                        : l10n.onboardingUploadSubtitleDefault),
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
                  .animate()
                  .fadeIn(
                      duration: 500.ms,
                      delay: 100.ms,
                      curve: Curves.easeOutExpo),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: hasImage
              ? _buildResultsView(colorScheme, textTheme)
              : _buildUploadView(colorScheme, textTheme),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              PremiumGradientButton(
                onPressed:
                    _suggestions.isNotEmpty ? widget.onContinue : null,
                child: Text(l10n.commonContinue),
              )
                  .animate()
                  .fadeIn(
                      duration: 400.ms,
                      delay: 600.ms,
                      curve: Curves.easeOutExpo),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUploadView(ColorScheme colorScheme, TextTheme textTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: GestureDetector(
          onTapDown: (_) {
            HapticFeedback.lightImpact();
            setState(() => _isPressed = true);
          },
          onTapUp: (_) {
            setState(() => _isPressed = false);
            _pickImage();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedScale(
            scale: _isPressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOutCubic,
            child: _buildDropZone(colorScheme, textTheme),
          ),
        )
            .animate()
            .fadeIn(
                duration: 500.ms, delay: 300.ms, curve: Curves.easeOutExpo)
            .scale(
                begin: const Offset(0.95, 0.95),
                delay: 300.ms,
                duration: 500.ms,
                curve: Curves.easeOutExpo),
      ),
    );
  }

  Widget _buildResultsView(ColorScheme colorScheme, TextTheme textTheme) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Compact image preview
          GestureDetector(
            onTap: _isProcessing ? null : _pickImage,
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.secondary.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                image: DecorationImage(
                  image: FileImage(_selectedImage!),
                  fit: BoxFit.cover,
                ),
              ),
              child: Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.swap_horiz_rounded,
                          size: 16, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        l10n.onboardingUploadChange,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, curve: Curves.easeOutExpo),
          const SizedBox(height: 20),

          // Loading state
          if (_isProcessing)
            _buildLoadingIndicator(colorScheme, textTheme),

          // Error state
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Card(
                elevation: 0,
                color: colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: colorScheme.onErrorContainer),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Results header
          if (_suggestions.isNotEmpty)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.check_circle_outlined,
                    color: colorScheme.secondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.onboardingUploadCuratedResponses,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            )
                .animate()
                .fadeIn(duration: 400.ms, curve: Curves.easeOutExpo),
          if (_suggestions.isNotEmpty) const SizedBox(height: 16),

          // Reply cards
          ...List.generate(_suggestions.length, (index) {
            final suggestion = _suggestions[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _OnboardingReplyCard(
                index: index,
                message: suggestion.message,
                whyItWorks: suggestion.whyItWorks,
                colorScheme: colorScheme,
                textTheme: textTheme,
                onTap: () {
                  HapticFeedback.selectionClick();
                  Clipboard.setData(ClipboardData(text: suggestion.message));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.onboardingUploadCopied),
                      duration: const Duration(seconds: 1),
                      backgroundColor: colorScheme.secondaryContainer,
                    ),
                  );
                },
              ),
            )
                .animate()
                .fadeIn(
                  duration: 500.ms,
                  delay: (200 + index * 120).ms,
                  curve: Curves.easeOutExpo,
                )
                .slideY(
                  begin: 0.08,
                  delay: (200 + index * 120).ms,
                  duration: 500.ms,
                  curve: Curves.easeOutExpo,
                );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(
      ColorScheme colorScheme, TextTheme textTheme) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.secondary.withValues(alpha: 0.12),
            ),
            child: Center(
              child: Container(
                width: 32,
                height: 32,
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
              ),
          const SizedBox(height: 16),
          Text(
            l10n.onboardingUploadGenerating,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropZone(ColorScheme colorScheme, TextTheme textTheme) {
    final l10n = context.l10n;
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: colorScheme.secondary,
        borderRadius: 20,
        dashWidth: 8,
        dashGap: 6,
        strokeWidth: 1.5,
      ),
      child: Container(
        width: double.infinity,
        height: 320,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 56,
              color: colorScheme.secondary,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.onboardingUploadDropZone,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.onboardingUploadFormats,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reply card — matches dark mode suggestion card style from conversations
// ---------------------------------------------------------------------------

class _OnboardingReplyCard extends StatelessWidget {
  final int index;
  final String message;
  final String? whyItWorks;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final VoidCallback onTap;

  const _OnboardingReplyCard({
    required this.index,
    required this.message,
    required this.whyItWorks,
    required this.colorScheme,
    required this.textTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final badgeLabel = (index + 1).toString().padLeft(2, '0');
    const borderRadius = BorderRadius.all(Radius.circular(18));
    final hasWhyItWorks =
        whyItWorks != null && whyItWorks!.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: borderRadius,
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: borderRadius,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row — badge + copy icon
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: colorScheme.secondary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.secondary
                                    .withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            badgeLabel,
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSecondary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Icon(
                            Icons.copy_outlined,
                            size: 20,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Message text
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 15,
                        color: colorScheme.onSurface,
                        height: 1.4,
                      ),
                    ),

                    // "Why it works" chip
                    if (hasWhyItWorks) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lightbulb_outlined,
                              size: 16,
                              color: colorScheme.tertiary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                whyItWorks!.trim(),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: colorScheme.tertiary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dashed border painter
// ---------------------------------------------------------------------------

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;
  final double dashWidth;
  final double dashGap;
  final double strokeWidth;

  _DashedBorderPainter({
    required this.color,
    required this.borderRadius,
    required this.dashWidth,
    required this.dashGap,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final end = math.min(distance + dashWidth, metric.length);
        canvas.drawPath(
          metric.extractPath(distance, end),
          paint,
        );
        distance = end + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashGap != dashGap ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
