import 'package:flirtfix/l10n/gen/app_localizations.dart';

class PolicySection {
  final String title;
  final String content;
  final bool isHeading;

  const PolicySection({
    required this.title,
    required this.content,
    this.isHeading = false,
  });
}

String privacyPolicyEffectiveDate(AppLocalizations l10n) =>
    l10n.policyPrivacyEffectiveDate;

List<PolicySection> privacyPolicySections(AppLocalizations l10n) => [
  PolicySection(title: l10n.policyPrivacyTitle, content: '', isHeading: true),
  PolicySection(
    title: l10n.policyPrivacySectionIntroTitle,
    content: l10n.policyPrivacySectionIntroContent,
  ),
  PolicySection(
    title: l10n.policyPrivacySectionInfoCollectTitle,
    content: l10n.policyPrivacySectionInfoCollectContent,
  ),
  PolicySection(
    title: l10n.policyPrivacySectionInfoUseTitle,
    content: l10n.policyPrivacySectionInfoUseContent,
  ),
  PolicySection(
    title: l10n.policyPrivacySectionThirdPartyTitle,
    content: l10n.policyPrivacySectionThirdPartyContent,
  ),
  PolicySection(
    title: l10n.policyPrivacySectionStorageSecurityTitle,
    content: l10n.policyPrivacySectionStorageSecurityContent,
  ),
  PolicySection(
    title: l10n.policyPrivacySectionRetentionTitle,
    content: l10n.policyPrivacySectionRetentionContent,
  ),
  PolicySection(
    title: l10n.policyPrivacySectionRightsTitle,
    content: l10n.policyPrivacySectionRightsContent,
  ),
  PolicySection(
    title: l10n.policyPrivacySectionComplianceTitle,
    content: l10n.policyPrivacySectionComplianceContent,
  ),
  PolicySection(
    title: l10n.policyPrivacySectionCookiesTitle,
    content: l10n.policyPrivacySectionCookiesContent,
  ),
  PolicySection(
    title: l10n.policyPrivacySectionChildrenTitle,
    content: l10n.policyPrivacySectionChildrenContent,
  ),
  PolicySection(
    title: l10n.policyPrivacySectionSharingTitle,
    content: l10n.policyPrivacySectionSharingContent,
  ),
  PolicySection(
    title: l10n.policyPrivacySectionTransfersTitle,
    content: l10n.policyPrivacySectionTransfersContent,
  ),
  PolicySection(
    title: l10n.policyPrivacySectionChangesTitle,
    content: l10n.policyPrivacySectionChangesContent,
  ),
  PolicySection(
    title: l10n.policyPrivacySectionContactTitle,
    content: l10n.policyPrivacySectionContactContent,
  ),
];
