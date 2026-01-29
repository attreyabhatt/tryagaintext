import 'package:flutter/material.dart';
import '../../data/policies/privacy_policy_content.dart';
import '../../data/policies/terms_of_use_content.dart';
import '../../data/policies/refund_policy_content.dart';

class PolicyViewerScreen extends StatelessWidget {
  final String title;
  final String policyType;

  const PolicyViewerScreen({
    super.key,
    required this.title,
    required this.policyType,
  });

  List<PolicySection> _getPolicySections() {
    switch (policyType) {
      case 'privacy':
        return privacyPolicySections;
      case 'terms':
        return termsOfUseSections;
      case 'refund':
        return refundPolicySections;
      default:
        return [];
    }
  }

  String _getEffectiveDate() {
    switch (policyType) {
      case 'privacy':
        return privacyPolicyEffectiveDate;
      case 'terms':
        return termsOfUseEffectiveDate;
      case 'refund':
        return refundPolicyEffectiveDate;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sections = _getPolicySections();
    final effectiveDate = _getEffectiveDate();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: colorScheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Effective date
            if (effectiveDate.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  'Effective Date: $effectiveDate',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

            // Policy sections
            ...sections.map((section) {
              if (section.isHeading) {
                // Main heading
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    section.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                );
              } else {
                // Section with title and content
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section title
                      if (section.title.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: SelectableText(
                            section.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),

                      // Section content
                      if (section.content.isNotEmpty)
                        SelectableText(
                          section.content,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: colorScheme.onSurface.withValues(alpha: 0.87),
                          ),
                        ),
                    ],
                  ),
                );
              }
            }),

            // Bottom spacing
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
