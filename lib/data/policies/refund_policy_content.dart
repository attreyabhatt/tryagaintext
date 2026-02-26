import 'package:flirtfix/l10n/gen/app_localizations.dart';
import 'privacy_policy_content.dart';

String refundPolicyEffectiveDate(AppLocalizations l10n) =>
    l10n.policyRefundEffectiveDate;

List<PolicySection> refundPolicySections(AppLocalizations l10n) => [
  PolicySection(title: l10n.policyRefundTitle, content: '', isHeading: true),
  PolicySection(
    title: l10n.policyRefundSectionOverviewTitle,
    content: l10n.policyRefundSectionOverviewContent,
  ),
  PolicySection(
    title: l10n.policyRefundSectionSubscriptionRefundsTitle,
    content: l10n.policyRefundSectionSubscriptionRefundsContent,
  ),
  PolicySection(
    title: l10n.policyRefundSectionGooglePlayProcessTitle,
    content: l10n.policyRefundSectionGooglePlayProcessContent,
  ),
  PolicySection(
    title: l10n.policyRefundSectionCreditRefundsTitle,
    content: l10n.policyRefundSectionCreditRefundsContent,
  ),
  PolicySection(
    title: l10n.policyRefundSectionEligibilityTitle,
    content: l10n.policyRefundSectionEligibilityContent,
  ),
  PolicySection(
    title: l10n.policyRefundSectionCancellationTitle,
    content: l10n.policyRefundSectionCancellationContent,
  ),
  PolicySection(
    title: l10n.policyRefundSectionBillingIssuesTitle,
    content: l10n.policyRefundSectionBillingIssuesContent,
  ),
  PolicySection(
    title: l10n.policyRefundSectionProcessingTimeTitle,
    content: l10n.policyRefundSectionProcessingTimeContent,
  ),
  PolicySection(
    title: l10n.policyRefundSectionExceptionsTitle,
    content: l10n.policyRefundSectionExceptionsContent,
  ),
  PolicySection(
    title: l10n.policyRefundSectionFairUseAbuseTitle,
    content: l10n.policyRefundSectionFairUseAbuseContent,
  ),
  PolicySection(
    title: l10n.policyRefundSectionThirdPartyIssuesTitle,
    content: l10n.policyRefundSectionThirdPartyIssuesContent,
  ),
  PolicySection(
    title: l10n.policyRefundSectionNoRefundScenariosTitle,
    content: l10n.policyRefundSectionNoRefundScenariosContent,
  ),
  PolicySection(
    title: l10n.policyRefundSectionDisputeTitle,
    content: l10n.policyRefundSectionDisputeContent,
  ),
  PolicySection(
    title: l10n.policyRefundSectionPolicyChangesTitle,
    content: l10n.policyRefundSectionPolicyChangesContent,
  ),
  PolicySection(
    title: l10n.policyRefundSectionContactTitle,
    content: l10n.policyRefundSectionContactContent,
  ),
];
