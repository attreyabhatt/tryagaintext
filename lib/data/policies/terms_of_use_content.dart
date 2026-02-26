import 'package:flirtfix/l10n/gen/app_localizations.dart';
import 'privacy_policy_content.dart';

String termsOfUseEffectiveDate(AppLocalizations l10n) =>
    l10n.policyTermsEffectiveDate;

List<PolicySection> termsOfUseSections(AppLocalizations l10n) => [
  PolicySection(title: l10n.policyTermsTitle, content: '', isHeading: true),
  PolicySection(
    title: l10n.policyTermsSectionAgreementTitle,
    content: l10n.policyTermsSectionAgreementContent,
  ),
  PolicySection(
    title: l10n.policyTermsSectionServiceDescriptionTitle,
    content: l10n.policyTermsSectionServiceDescriptionContent,
  ),
  PolicySection(
    title: l10n.policyTermsSectionAcceptableUseTitle,
    content: l10n.policyTermsSectionAcceptableUseContent,
  ),
  PolicySection(
    title: l10n.policyTermsSectionFairUseTitle,
    content: l10n.policyTermsSectionFairUseContent,
  ),
  PolicySection(
    title: l10n.policyTermsSectionRegistrationTitle,
    content: l10n.policyTermsSectionRegistrationContent,
  ),
  PolicySection(
    title: l10n.policyTermsSectionSubscriptionTitle,
    content: l10n.policyTermsSectionSubscriptionContent,
  ),
  PolicySection(
    title: l10n.policyTermsSectionIpRightsTitle,
    content: l10n.policyTermsSectionIpRightsContent,
  ),
  PolicySection(
    title: l10n.policyTermsSectionDisclaimerTitle,
    content: l10n.policyTermsSectionDisclaimerContent,
  ),
  PolicySection(
    title: l10n.policyTermsSectionLiabilityTitle,
    content: l10n.policyTermsSectionLiabilityContent,
  ),
  PolicySection(
    title: l10n.policyTermsSectionAvailabilityTitle,
    content: l10n.policyTermsSectionAvailabilityContent,
  ),
  PolicySection(
    title: l10n.policyTermsSectionTerminationTitle,
    content: l10n.policyTermsSectionTerminationContent,
  ),
  PolicySection(
    title: l10n.policyTermsSectionLawTitle,
    content: l10n.policyTermsSectionLawContent,
  ),
  PolicySection(
    title: l10n.policyTermsSectionDisputeTitle,
    content: l10n.policyTermsSectionDisputeContent,
  ),
  PolicySection(
    title: l10n.policyTermsSectionChangesTitle,
    content: l10n.policyTermsSectionChangesContent,
  ),
  PolicySection(
    title: l10n.policyTermsSectionSeverabilityTitle,
    content: l10n.policyTermsSectionSeverabilityContent,
  ),
  PolicySection(
    title: l10n.policyTermsSectionEntireAgreementTitle,
    content: l10n.policyTermsSectionEntireAgreementContent,
  ),
  PolicySection(
    title: l10n.policyTermsSectionContactTitle,
    content: l10n.policyTermsSectionContactContent,
  ),
];
