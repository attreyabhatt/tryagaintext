import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/l10n.dart';
import '../../services/api_client.dart';
import '../widgets/luxury_text_field.dart';
import '../widgets/thinking_indicator.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _emailController = TextEditingController();
  String _reason = 'bug';
  bool _isSubmitting = false;
  String? _errorMessage;

  final _apiClient = ApiClient();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    final l10n = context.l10n;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final ok = await _apiClient.reportIssue(
        reason: _reason,
        title: _titleController.text.trim(),
        subject: _messageController.text.trim(),
        email: _emailController.text.trim(),
      );

      if (!mounted) return;
      if (ok) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.reportIssueThanksTitle),
            content: Text(l10n.reportIssueThanksMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.commonOk),
              ),
            ],
          ),
        ).then((_) {
          if (mounted) Navigator.pop(context);
        });
      } else {
        setState(() {
          _errorMessage = l10n.reportIssueSendFailed;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = l10n.reportIssueSendFailed;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;
    final isLight = theme.brightness == Brightness.light;
    final cardShadow = isLight
        ? BoxShadow(
            color: const Color(0xFF9E9E9E).withValues(alpha: 0.12),
            blurRadius: 25,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          )
        : BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text(l10n.reportIssueTitle), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [cardShadow],
                  ),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _reason,
                        decoration: InputDecoration(
                          labelText: l10n.reportIssueReasonLabel,
                          prefixIcon: Icon(
                            Icons.flag_outlined,
                            color: colorScheme.primary,
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'bug',
                            child: Text(l10n.reportIssueReasonBug),
                          ),
                          DropdownMenuItem(
                            value: 'payment',
                            child: Text(l10n.reportIssueReasonPayment),
                          ),
                          DropdownMenuItem(
                            value: 'feedback',
                            child: Text(l10n.reportIssueReasonFeedback),
                          ),
                          DropdownMenuItem(
                            value: 'other',
                            child: Text(l10n.reportIssueReasonOther),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _reason = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      LuxuryTextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: l10n.reportIssueFormTitleLabel,
                          hintText: l10n.reportIssueFormTitleHint,
                        ),
                        showShadow: false,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.reportIssueValidationTitle;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      LuxuryTextField(
                        controller: _messageController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: l10n.reportIssueFormDetailsLabel,
                          hintText: l10n.reportIssueFormDetailsHint,
                        ),
                        showShadow: false,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.reportIssueValidationDetails;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      LuxuryTextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: l10n.commonEmailLabel,
                          hintText: l10n.commonEmailHint,
                        ),
                        showShadow: false,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.validationEnterYourEmail;
                          }
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value.trim())) {
                            return l10n.validationEnterValidEmail;
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.error),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: colorScheme.onErrorContainer),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: BreathingPulseIndicator(
                            size: 18,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : Text(
                          l10n.reportIssueSendButton,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
