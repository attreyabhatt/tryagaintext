import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/l10n.dart';
import '../../services/api_client.dart';
import '../widgets/luxury_text_field.dart';
import '../widgets/thinking_indicator.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();

    if (_newController.text != _confirmController.text) {
      setState(() {
        _errorMessage = context.l10n.validationPasswordsDoNotMatch;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final apiClient = ApiClient();
    final error = await apiClient.changePassword(
      currentPassword: _currentController.text,
      newPassword: _newController.text,
    );

    if (!mounted) return;

    if (error == null) {
      final l10n = context.l10n;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(l10n.changePasswordUpdatedTitle),
          content: Text(l10n.changePasswordUpdatedMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.commonOk),
            ),
          ],
        ),
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } else {
      setState(() {
        _errorMessage = _mapChangePasswordError(error);
      });
    }

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text(l10n.changePasswordTitle), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LuxuryTextField(
                  controller: _currentController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: l10n.changePasswordCurrentLabel,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.changePasswordValidationCurrent;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                LuxuryTextField(
                  controller: _newController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: l10n.changePasswordNewLabel,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.changePasswordValidationNew;
                    }
                    if (value.length < 6) {
                      return l10n.validationPasswordMinLength;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                LuxuryTextField(
                  controller: _confirmController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: l10n.changePasswordConfirmLabel,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.changePasswordValidationConfirm;
                    }
                    return null;
                  },
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
                          l10n.changePasswordUpdateButton,
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
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String _mapChangePasswordError(String code) {
    final l10n = context.l10n;
    return switch (code) {
      'network_error' => l10n.errorNetworkTryAgain,
      'password_update_failed' => l10n.changePasswordUpdateFailed,
      _ => code,
    };
  }
}
