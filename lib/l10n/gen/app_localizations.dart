import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'FlirtFix'**
  String get appTitle;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Master the Art of Conversation.'**
  String get splashTagline;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @commonMaybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get commonMaybeLater;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonOr.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get commonOr;

  /// No description provided for @commonSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get commonSignIn;

  /// No description provided for @commonEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get commonEmailLabel;

  /// No description provided for @commonEmailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get commonEmailHint;

  /// No description provided for @commonPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get commonPasswordHint;

  /// No description provided for @commonUploaded.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get commonUploaded;

  /// No description provided for @errorNetworkTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please try again.'**
  String get errorNetworkTryAgain;

  /// No description provided for @errorUnexpectedTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Oops! Something went wrong. Please try again.'**
  String get errorUnexpectedTryAgain;

  /// No description provided for @validationEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get validationEnterEmail;

  /// No description provided for @validationEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get validationEnterPassword;

  /// No description provided for @validationEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get validationEnterValidEmail;

  /// No description provided for @validationEnterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email.'**
  String get validationEnterYourEmail;

  /// No description provided for @validationPasswordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get validationPasswordMinLength;

  /// No description provided for @validationPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get validationPasswordsDoNotMatch;

  /// No description provided for @authLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get authLoginFailed;

  /// No description provided for @authWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get authWelcomeBack;

  /// No description provided for @authAccountCreatedSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Account created. You have been signed in'**
  String get authAccountCreatedSignedIn;

  /// No description provided for @loginPrivateAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Private Access'**
  String get loginPrivateAccessTitle;

  /// No description provided for @loginWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome.'**
  String get loginWelcome;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Access your personal dating concierge.'**
  String get loginSubtitle;

  /// No description provided for @loginMemberIdOrEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Member ID / Email'**
  String get loginMemberIdOrEmailLabel;

  /// No description provided for @loginMemberIdOrEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your member ID or email'**
  String get loginMemberIdOrEmailHint;

  /// No description provided for @loginPasscodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Passcode'**
  String get loginPasscodeLabel;

  /// No description provided for @loginPasscodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your passcode'**
  String get loginPasscodeHint;

  /// No description provided for @loginForgotPasscode.
  ///
  /// In en, this message translates to:
  /// **'Forgot passcode?'**
  String get loginForgotPasscode;

  /// No description provided for @loginAccessing.
  ///
  /// In en, this message translates to:
  /// **'Accessing...'**
  String get loginAccessing;

  /// No description provided for @loginAccessButton.
  ///
  /// In en, this message translates to:
  /// **'Access'**
  String get loginAccessButton;

  /// No description provided for @loginPreviewExperience.
  ///
  /// In en, this message translates to:
  /// **'Preview Experience'**
  String get loginPreviewExperience;

  /// No description provided for @signupBecomeMember.
  ///
  /// In en, this message translates to:
  /// **'Become a Member'**
  String get signupBecomeMember;

  /// No description provided for @signupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your journey to effortless connection begins here.'**
  String get signupSubtitle;

  /// No description provided for @signupEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Correspondence Email'**
  String get signupEmailLabel;

  /// No description provided for @signupEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your correspondence email'**
  String get signupEmailHint;

  /// No description provided for @signupSecurePasscodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Secure Passcode'**
  String get signupSecurePasscodeLabel;

  /// No description provided for @signupSecurePasscodeHint.
  ///
  /// In en, this message translates to:
  /// **'Create a secure passcode'**
  String get signupSecurePasscodeHint;

  /// No description provided for @signupVerifyPasscodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Verify Passcode'**
  String get signupVerifyPasscodeLabel;

  /// No description provided for @signupVerifyPasscodeHint.
  ///
  /// In en, this message translates to:
  /// **'Verify your passcode'**
  String get signupVerifyPasscodeHint;

  /// No description provided for @signupValidationEnterCorrespondenceEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your correspondence email'**
  String get signupValidationEnterCorrespondenceEmail;

  /// No description provided for @signupValidationEnterSecurePasscode.
  ///
  /// In en, this message translates to:
  /// **'Please enter a secure passcode'**
  String get signupValidationEnterSecurePasscode;

  /// No description provided for @signupValidationPasscodeMinLength.
  ///
  /// In en, this message translates to:
  /// **'Passcode must be at least 6 characters'**
  String get signupValidationPasscodeMinLength;

  /// No description provided for @signupValidationVerifyPasscode.
  ///
  /// In en, this message translates to:
  /// **'Please verify your passcode'**
  String get signupValidationVerifyPasscode;

  /// No description provided for @signupClaimingAccess.
  ///
  /// In en, this message translates to:
  /// **'Claiming access...'**
  String get signupClaimingAccess;

  /// No description provided for @signupClaimAccessButton.
  ///
  /// In en, this message translates to:
  /// **'Claim Your Access'**
  String get signupClaimAccessButton;

  /// No description provided for @signupAlreadyEstablishedPrompt.
  ///
  /// In en, this message translates to:
  /// **'Already established? '**
  String get signupAlreadyEstablishedPrompt;

  /// No description provided for @signupEnterHere.
  ///
  /// In en, this message translates to:
  /// **'Enter Here'**
  String get signupEnterHere;

  /// No description provided for @signupRegistrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get signupRegistrationFailed;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send a reset link.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @forgotPasswordEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get forgotPasswordEmailHint;

  /// No description provided for @forgotPasswordCheckEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get forgotPasswordCheckEmailTitle;

  /// No description provided for @forgotPasswordCheckEmailMessage.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for that email, we\'ve sent password reset instructions.'**
  String get forgotPasswordCheckEmailMessage;

  /// No description provided for @forgotPasswordSendingResetLink.
  ///
  /// In en, this message translates to:
  /// **'Sending reset link...'**
  String get forgotPasswordSendingResetLink;

  /// No description provided for @forgotPasswordSendResetLinkButton.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get forgotPasswordSendResetLinkButton;

  /// No description provided for @forgotPasswordResetFailed.
  ///
  /// In en, this message translates to:
  /// **'Password reset failed'**
  String get forgotPasswordResetFailed;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordTitle;

  /// No description provided for @changePasswordCurrentLabel.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get changePasswordCurrentLabel;

  /// No description provided for @changePasswordNewLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get changePasswordNewLabel;

  /// No description provided for @changePasswordConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get changePasswordConfirmLabel;

  /// No description provided for @changePasswordValidationCurrent.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password'**
  String get changePasswordValidationCurrent;

  /// No description provided for @changePasswordValidationNew.
  ///
  /// In en, this message translates to:
  /// **'Enter a new password'**
  String get changePasswordValidationNew;

  /// No description provided for @changePasswordValidationConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm your new password'**
  String get changePasswordValidationConfirm;

  /// No description provided for @changePasswordUpdateButton.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get changePasswordUpdateButton;

  /// No description provided for @changePasswordUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get changePasswordUpdatedTitle;

  /// No description provided for @changePasswordUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your password has been changed successfully.'**
  String get changePasswordUpdatedMessage;

  /// No description provided for @changePasswordUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Password update failed'**
  String get changePasswordUpdateFailed;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountConfirmDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Are you absolutely sure?'**
  String get deleteAccountConfirmDialogTitle;

  /// No description provided for @deleteAccountConfirmDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. All your data will be permanently deleted.'**
  String get deleteAccountConfirmDialogMessage;

  /// No description provided for @deleteAccountSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account deleted successfully'**
  String get deleteAccountSuccess;

  /// No description provided for @deleteAccountWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Warning: Permanent Action'**
  String get deleteAccountWarningTitle;

  /// No description provided for @deleteAccountWarningIntro.
  ///
  /// In en, this message translates to:
  /// **'Deleting your account will:'**
  String get deleteAccountWarningIntro;

  /// No description provided for @deleteAccountWarningChatHistory.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete all your chat history'**
  String get deleteAccountWarningChatHistory;

  /// No description provided for @deleteAccountWarningProfileData.
  ///
  /// In en, this message translates to:
  /// **'Remove your profile and account data'**
  String get deleteAccountWarningProfileData;

  /// No description provided for @deleteAccountWarningIrreversible.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone'**
  String get deleteAccountWarningIrreversible;

  /// No description provided for @deleteAccountWarningSubscription.
  ///
  /// In en, this message translates to:
  /// **'Active subscriptions must be canceled separately in Google Play'**
  String get deleteAccountWarningSubscription;

  /// No description provided for @deleteAccountEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to confirm'**
  String get deleteAccountEnterPassword;

  /// No description provided for @deleteAccountCheckboxConfirm.
  ///
  /// In en, this message translates to:
  /// **'I understand all my data will be permanently deleted'**
  String get deleteAccountCheckboxConfirm;

  /// No description provided for @deleteAccountDeleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete My Account'**
  String get deleteAccountDeleteButton;

  /// No description provided for @deleteAccountErrorInvalidPassword.
  ///
  /// In en, this message translates to:
  /// **'Invalid password'**
  String get deleteAccountErrorInvalidPassword;

  /// No description provided for @deleteAccountErrorFailed.
  ///
  /// In en, this message translates to:
  /// **'Account deletion failed. Please try again.'**
  String get deleteAccountErrorFailed;

  /// No description provided for @reportIssueTitle.
  ///
  /// In en, this message translates to:
  /// **'Report an Issue'**
  String get reportIssueTitle;

  /// No description provided for @reportIssueThanksTitle.
  ///
  /// In en, this message translates to:
  /// **'Thanks'**
  String get reportIssueThanksTitle;

  /// No description provided for @reportIssueThanksMessage.
  ///
  /// In en, this message translates to:
  /// **'Your report was sent. We will get back to you by email.'**
  String get reportIssueThanksMessage;

  /// No description provided for @reportIssueSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send your report. Please try again.'**
  String get reportIssueSendFailed;

  /// No description provided for @reportIssueReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reportIssueReasonLabel;

  /// No description provided for @reportIssueReasonBug.
  ///
  /// In en, this message translates to:
  /// **'Bug Report'**
  String get reportIssueReasonBug;

  /// No description provided for @reportIssueReasonPayment.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get reportIssueReasonPayment;

  /// No description provided for @reportIssueReasonFeedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get reportIssueReasonFeedback;

  /// No description provided for @reportIssueReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reportIssueReasonOther;

  /// No description provided for @reportIssueFormTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get reportIssueFormTitleLabel;

  /// No description provided for @reportIssueFormTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Short summary'**
  String get reportIssueFormTitleHint;

  /// No description provided for @reportIssueValidationTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get reportIssueValidationTitle;

  /// No description provided for @reportIssueFormDetailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get reportIssueFormDetailsLabel;

  /// No description provided for @reportIssueFormDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us what happened'**
  String get reportIssueFormDetailsHint;

  /// No description provided for @reportIssueValidationDetails.
  ///
  /// In en, this message translates to:
  /// **'Please enter details'**
  String get reportIssueValidationDetails;

  /// No description provided for @reportIssueSendButton.
  ///
  /// In en, this message translates to:
  /// **'Send Report'**
  String get reportIssueSendButton;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileHelpPolicies.
  ///
  /// In en, this message translates to:
  /// **'Help & Policies'**
  String get profileHelpPolicies;

  /// No description provided for @profileGuest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get profileGuest;

  /// No description provided for @profileGuestPreview.
  ///
  /// In en, this message translates to:
  /// **'Guest Preview'**
  String get profileGuestPreview;

  /// No description provided for @profileMemberAccess.
  ///
  /// In en, this message translates to:
  /// **'Member Access'**
  String get profileMemberAccess;

  /// No description provided for @profilePreviewAccess.
  ///
  /// In en, this message translates to:
  /// **'Preview Access'**
  String get profilePreviewAccess;

  /// No description provided for @profileMembershipStatus.
  ///
  /// In en, this message translates to:
  /// **'Membership Status'**
  String get profileMembershipStatus;

  /// No description provided for @profileMembershipActive.
  ///
  /// In en, this message translates to:
  /// **'Active - Elite'**
  String get profileMembershipActive;

  /// No description provided for @profileMembershipInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get profileMembershipInactive;

  /// No description provided for @profileManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get profileManage;

  /// No description provided for @profileSubscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get profileSubscribe;

  /// No description provided for @profileAmbience.
  ///
  /// In en, this message translates to:
  /// **'Ambience'**
  String get profileAmbience;

  /// No description provided for @profileAmbienceRoyalRomance.
  ///
  /// In en, this message translates to:
  /// **'Royal Romance'**
  String get profileAmbienceRoyalRomance;

  /// No description provided for @profileAmbienceMidnightGold.
  ///
  /// In en, this message translates to:
  /// **'Midnight Gold'**
  String get profileAmbienceMidnightGold;

  /// No description provided for @profileLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguage;

  /// No description provided for @profileSecuritySettings.
  ///
  /// In en, this message translates to:
  /// **'Security Settings'**
  String get profileSecuritySettings;

  /// No description provided for @profileSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get profileSignOut;

  /// No description provided for @profileMember.
  ///
  /// In en, this message translates to:
  /// **'Member: {memberName}'**
  String profileMember(Object memberName);

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get languageSpanish;

  /// No description provided for @subscriptionActivated.
  ///
  /// In en, this message translates to:
  /// **'Subscription activated!'**
  String get subscriptionActivated;

  /// No description provided for @conversationsAddConversationFirst.
  ///
  /// In en, this message translates to:
  /// **'Please add your conversation first'**
  String get conversationsAddConversationFirst;

  /// No description provided for @conversationsAnalyzeChat.
  ///
  /// In en, this message translates to:
  /// **'Analyze Chat'**
  String get conversationsAnalyzeChat;

  /// No description provided for @conversationsAnalyzeProfile.
  ///
  /// In en, this message translates to:
  /// **'Analyze Profile'**
  String get conversationsAnalyzeProfile;

  /// No description provided for @conversationsAppbarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your Conversation Architect'**
  String get conversationsAppbarSubtitle;

  /// No description provided for @conversationsCharacterDoctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get conversationsCharacterDoctor;

  /// No description provided for @conversationsCharacterLawyer.
  ///
  /// In en, this message translates to:
  /// **'Lawyer'**
  String get conversationsCharacterLawyer;

  /// No description provided for @conversationsCharacterLoganRoy.
  ///
  /// In en, this message translates to:
  /// **'Logan Roy'**
  String get conversationsCharacterLoganRoy;

  /// No description provided for @conversationsCharacterNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get conversationsCharacterNone;

  /// No description provided for @conversationsCharacterSherlockHolmes.
  ///
  /// In en, this message translates to:
  /// **'Sherlock Holmes'**
  String get conversationsCharacterSherlockHolmes;

  /// No description provided for @conversationsCharacterTommyShelby.
  ///
  /// In en, this message translates to:
  /// **'Tommy Shelby'**
  String get conversationsCharacterTommyShelby;

  /// No description provided for @conversationsCommandHintEmpty.
  ///
  /// In en, this message translates to:
  /// **'Any specific instructions?'**
  String get conversationsCommandHintEmpty;

  /// No description provided for @conversationsCommandHintWithSettings.
  ///
  /// In en, this message translates to:
  /// **'({settings}) Add details...'**
  String conversationsCommandHintWithSettings(Object settings);

  /// No description provided for @conversationsCommandShort.
  ///
  /// In en, this message translates to:
  /// **'Short'**
  String get conversationsCommandShort;

  /// No description provided for @conversationsCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard!'**
  String get conversationsCopiedToClipboard;

  /// No description provided for @conversationsCraftOpening.
  ///
  /// In en, this message translates to:
  /// **'Craft Opening'**
  String get conversationsCraftOpening;

  /// No description provided for @conversationsCraftResponse.
  ///
  /// In en, this message translates to:
  /// **'Craft Response'**
  String get conversationsCraftResponse;

  /// No description provided for @conversationsCreateFreeAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please create your free account to continue.'**
  String get conversationsCreateFreeAccountPrompt;

  /// No description provided for @conversationsDailyLimitOpenerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Resets in {resetTime}\n\nPlease use Recommended openers. Expertly formulated to maximize engagement and intrigue.'**
  String conversationsDailyLimitOpenerSubtitle(Object resetTime);

  /// No description provided for @conversationsDailyLimitReplySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Resets in {resetTime}'**
  String conversationsDailyLimitReplySubtitle(Object resetTime);

  /// No description provided for @conversationsDailyLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily {limitType} limit reached'**
  String conversationsDailyLimitTitle(Object limitType);

  /// No description provided for @conversationsExtractImageFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to extract text from image. Please try again.'**
  String get conversationsExtractImageFailed;

  /// No description provided for @conversationsGuestSheetBody.
  ///
  /// In en, this message translates to:
  /// **'Create your free account to reveal this response and continue with FlirtFix.'**
  String get conversationsGuestSheetBody;

  /// No description provided for @conversationsGuestSheetHeadline.
  ///
  /// In en, this message translates to:
  /// **'Join the Inner Circle.'**
  String get conversationsGuestSheetHeadline;

  /// No description provided for @conversationsGuestSheetSecondary.
  ///
  /// In en, this message translates to:
  /// **'Login to existing account'**
  String get conversationsGuestSheetSecondary;

  /// No description provided for @conversationsGuestSheetSupport.
  ///
  /// In en, this message translates to:
  /// **'Takes less than 30 seconds.'**
  String get conversationsGuestSheetSupport;

  /// No description provided for @conversationsKeepItShort.
  ///
  /// In en, this message translates to:
  /// **'Keep it short'**
  String get conversationsKeepItShort;

  /// No description provided for @conversationsLimitTypeOpener.
  ///
  /// In en, this message translates to:
  /// **'opener'**
  String get conversationsLimitTypeOpener;

  /// No description provided for @conversationsLimitTypeReply.
  ///
  /// In en, this message translates to:
  /// **'reply'**
  String get conversationsLimitTypeReply;

  /// No description provided for @conversationsLoadingMayTakeSeconds.
  ///
  /// In en, this message translates to:
  /// **'This might take a few seconds'**
  String get conversationsLoadingMayTakeSeconds;

  /// No description provided for @conversationsModeCreative.
  ///
  /// In en, this message translates to:
  /// **'Creative'**
  String get conversationsModeCreative;

  /// No description provided for @conversationsModeRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get conversationsModeRecommended;

  /// No description provided for @conversationsNewChat.
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get conversationsNewChat;

  /// No description provided for @conversationsProfileHint.
  ///
  /// In en, this message translates to:
  /// **'Pick the most interesting photo or bio section'**
  String get conversationsProfileHint;

  /// No description provided for @conversationsRecommendedDescription.
  ///
  /// In en, this message translates to:
  /// **'Expertly formulated to maximize engagement and intrigue.'**
  String get conversationsRecommendedDescription;

  /// No description provided for @conversationsRegenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get conversationsRegenerate;

  /// No description provided for @conversationsResultsCuratedResponses.
  ///
  /// In en, this message translates to:
  /// **'Curated Responses'**
  String get conversationsResultsCuratedResponses;

  /// No description provided for @conversationsResultsYourApproach.
  ///
  /// In en, this message translates to:
  /// **'Your Approach'**
  String get conversationsResultsYourApproach;

  /// No description provided for @conversationsSelectCharacterHelper.
  ///
  /// In en, this message translates to:
  /// **'Select a persona or type your own above.'**
  String get conversationsSelectCharacterHelper;

  /// No description provided for @conversationsSelectCharacterTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Character'**
  String get conversationsSelectCharacterTitle;

  /// No description provided for @conversationsSelectImageFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to select image. Please try again.'**
  String get conversationsSelectImageFailed;

  /// No description provided for @conversationsSelectToneHelper.
  ///
  /// In en, this message translates to:
  /// **'Select a style or type your own above.'**
  String get conversationsSelectToneHelper;

  /// No description provided for @conversationsSelectToneTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Tone'**
  String get conversationsSelectToneTitle;

  /// No description provided for @conversationsSubscriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Subscription required. Please subscribe to continue.'**
  String get conversationsSubscriptionRequired;

  /// No description provided for @conversationsTabOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get conversationsTabOpen;

  /// No description provided for @conversationsTabRespond.
  ///
  /// In en, this message translates to:
  /// **'Respond'**
  String get conversationsTabRespond;

  /// No description provided for @conversationsTapCraftOpeningHint.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Craft Opening\" to generate personalized first messages'**
  String get conversationsTapCraftOpeningHint;

  /// No description provided for @conversationsTapCraftResponseHint.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Craft Response\" to generate suggestions'**
  String get conversationsTapCraftResponseHint;

  /// No description provided for @conversationsTapToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Tap to unlock'**
  String get conversationsTapToUnlock;

  /// No description provided for @conversationsTheirProfile.
  ///
  /// In en, this message translates to:
  /// **'Their profile'**
  String get conversationsTheirProfile;

  /// No description provided for @conversationsTimeHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String conversationsTimeHoursMinutes(int hours, int minutes);

  /// No description provided for @conversationsTimeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String conversationsTimeMinutes(int minutes);

  /// No description provided for @conversationsToneCockyFunny.
  ///
  /// In en, this message translates to:
  /// **'Cocky Funny'**
  String get conversationsToneCockyFunny;

  /// No description provided for @conversationsToneDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get conversationsToneDefault;

  /// No description provided for @conversationsToneFlirty.
  ///
  /// In en, this message translates to:
  /// **'Flirty'**
  String get conversationsToneFlirty;

  /// No description provided for @conversationsToneRomantic.
  ///
  /// In en, this message translates to:
  /// **'Romantic'**
  String get conversationsToneRomantic;

  /// No description provided for @conversationsToneWitty.
  ///
  /// In en, this message translates to:
  /// **'Witty'**
  String get conversationsToneWitty;

  /// No description provided for @conversationsTooltipCharacter.
  ///
  /// In en, this message translates to:
  /// **'Character'**
  String get conversationsTooltipCharacter;

  /// No description provided for @conversationsTooltipTone.
  ///
  /// In en, this message translates to:
  /// **'Tone'**
  String get conversationsTooltipTone;

  /// No description provided for @conversationsUnlockReplyBody.
  ///
  /// In en, this message translates to:
  /// **'Your daily limit of {limitLabel} reached. Resets in {resetTime}. Continue to Premium to reveal the full response.'**
  String conversationsUnlockReplyBody(Object limitLabel, Object resetTime);

  /// No description provided for @conversationsUnlockReplyHeadline.
  ///
  /// In en, this message translates to:
  /// **'Unlock this reply.'**
  String get conversationsUnlockReplyHeadline;

  /// No description provided for @conversationsUnlockReplySupport.
  ///
  /// In en, this message translates to:
  /// **'Instant unlock after checkout.'**
  String get conversationsUnlockReplySupport;

  /// No description provided for @conversationsUploadProfileFirst.
  ///
  /// In en, this message translates to:
  /// **'Please upload a profile screenshot first'**
  String get conversationsUploadProfileFirst;

  /// No description provided for @conversationsWorkspaceReady.
  ///
  /// In en, this message translates to:
  /// **'Workspace Ready'**
  String get conversationsWorkspaceReady;

  /// No description provided for @conversationsWorkspaceReadySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload a screenshot or provide context to begin crafting your next move.'**
  String get conversationsWorkspaceReadySubtitle;

  /// No description provided for @conversationsYourConversation.
  ///
  /// In en, this message translates to:
  /// **'Your conversation'**
  String get conversationsYourConversation;

  /// No description provided for @reviewNeedsCalibration.
  ///
  /// In en, this message translates to:
  /// **'Needs Calibration'**
  String get reviewNeedsCalibration;

  /// No description provided for @reviewFeedbackReceived.
  ///
  /// In en, this message translates to:
  /// **'Feedback received. We are calibrating.'**
  String get reviewFeedbackReceived;

  /// No description provided for @reviewRefineStrategyTitle.
  ///
  /// In en, this message translates to:
  /// **'Refine Strategy'**
  String get reviewRefineStrategyTitle;

  /// No description provided for @reviewRefineStrategySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us what went wrong. Your feedback calibrates the model.'**
  String get reviewRefineStrategySubtitle;

  /// No description provided for @reviewFeedbackHint.
  ///
  /// In en, this message translates to:
  /// **'The reply was too aggressive...'**
  String get reviewFeedbackHint;

  /// No description provided for @reviewFeedbackValidationMessage.
  ///
  /// In en, this message translates to:
  /// **'Please share what went wrong.'**
  String get reviewFeedbackValidationMessage;

  /// No description provided for @reviewFeedbackSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send feedback. Please try again.'**
  String get reviewFeedbackSendFailed;

  /// No description provided for @reviewTransmitFeedback.
  ///
  /// In en, this message translates to:
  /// **'Transmit Feedback'**
  String get reviewTransmitFeedback;

  /// No description provided for @reviewPromptQualityHeadline.
  ///
  /// In en, this message translates to:
  /// **'Quality Check'**
  String get reviewPromptQualityHeadline;

  /// No description provided for @reviewPromptQualitySubtext.
  ///
  /// In en, this message translates to:
  /// **'Is the AI helping your conversation flow?'**
  String get reviewPromptQualitySubtext;

  /// No description provided for @reviewPromptQualityPositive.
  ///
  /// In en, this message translates to:
  /// **'Results are Solid'**
  String get reviewPromptQualityPositive;

  /// No description provided for @reviewPromptSystemHeadline.
  ///
  /// In en, this message translates to:
  /// **'System Status'**
  String get reviewPromptSystemHeadline;

  /// No description provided for @reviewPromptSystemSubtext.
  ///
  /// In en, this message translates to:
  /// **'You have generated over 50 responses. Still accurate?'**
  String get reviewPromptSystemSubtext;

  /// No description provided for @reviewPromptSystemPositive.
  ///
  /// In en, this message translates to:
  /// **'Analysis is Perfect'**
  String get reviewPromptSystemPositive;

  /// No description provided for @reviewPromptRedemptionHeadline.
  ///
  /// In en, this message translates to:
  /// **'Has the analysis improved?'**
  String get reviewPromptRedemptionHeadline;

  /// No description provided for @reviewPromptRedemptionSubtext.
  ///
  /// In en, this message translates to:
  /// **'Tell us if the responses are better now.'**
  String get reviewPromptRedemptionSubtext;

  /// No description provided for @reviewPromptRedemptionPositive.
  ///
  /// In en, this message translates to:
  /// **'Yes, Much Better'**
  String get reviewPromptRedemptionPositive;

  /// No description provided for @reviewPulseFeedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Pulse Feedback - {tag}'**
  String reviewPulseFeedbackTitle(Object tag);

  /// No description provided for @thinkingExtractionReadingConversation.
  ///
  /// In en, this message translates to:
  /// **'Reading the conversation'**
  String get thinkingExtractionReadingConversation;

  /// No description provided for @thinkingExtractionPickingContext.
  ///
  /// In en, this message translates to:
  /// **'Picking up the context'**
  String get thinkingExtractionPickingContext;

  /// No description provided for @thinkingExtractionUnderstandingVibe.
  ///
  /// In en, this message translates to:
  /// **'Understanding the vibe'**
  String get thinkingExtractionUnderstandingVibe;

  /// No description provided for @thinkingReplyCraftingPerfectReply.
  ///
  /// In en, this message translates to:
  /// **'Crafting the perfect reply'**
  String get thinkingReplyCraftingPerfectReply;

  /// No description provided for @thinkingReplyReadingBetweenLines.
  ///
  /// In en, this message translates to:
  /// **'Reading between the lines'**
  String get thinkingReplyReadingBetweenLines;

  /// No description provided for @thinkingReplyFindingRightWords.
  ///
  /// In en, this message translates to:
  /// **'Finding the right words'**
  String get thinkingReplyFindingRightWords;

  /// No description provided for @thinkingReplyAnalyzingEnergy.
  ///
  /// In en, this message translates to:
  /// **'Analyzing her energy'**
  String get thinkingReplyAnalyzingEnergy;

  /// No description provided for @thinkingReplyWorkingMagic.
  ///
  /// In en, this message translates to:
  /// **'Working some magic'**
  String get thinkingReplyWorkingMagic;

  /// No description provided for @thinkingOpenerFindingStarters.
  ///
  /// In en, this message translates to:
  /// **'Finding conversation starters'**
  String get thinkingOpenerFindingStarters;

  /// No description provided for @thinkingOpenerCraftingOpeningLine.
  ///
  /// In en, this message translates to:
  /// **'Crafting your opening line'**
  String get thinkingOpenerCraftingOpeningLine;

  /// No description provided for @thinkingOpenerStudyingProfile.
  ///
  /// In en, this message translates to:
  /// **'Studying her profile'**
  String get thinkingOpenerStudyingProfile;

  /// No description provided for @thinkingOpenerLookingCommonGround.
  ///
  /// In en, this message translates to:
  /// **'Looking for common ground'**
  String get thinkingOpenerLookingCommonGround;

  /// No description provided for @thinkingOpenerCreatingFirstImpression.
  ///
  /// In en, this message translates to:
  /// **'Creating your first impression'**
  String get thinkingOpenerCreatingFirstImpression;

  /// No description provided for @thinkingRecommendedLoadingOpeners.
  ///
  /// In en, this message translates to:
  /// **'Loading proven openers'**
  String get thinkingRecommendedLoadingOpeners;

  /// No description provided for @thinkingRecommendedGrabbingGoodStuff.
  ///
  /// In en, this message translates to:
  /// **'Grabbing the good stuff'**
  String get thinkingRecommendedGrabbingGoodStuff;

  /// No description provided for @pricingBillingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Billing is not available on this device.'**
  String get pricingBillingUnavailable;

  /// No description provided for @pricingLoadingProductsTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Loading products. Please try again.'**
  String get pricingLoadingProductsTryAgain;

  /// No description provided for @pricingProductUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Product not available. Please try again later.'**
  String get pricingProductUnavailable;

  /// No description provided for @pricingSignInRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign In Required'**
  String get pricingSignInRequiredTitle;

  /// No description provided for @pricingSignInRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to start your subscription and link it to your account.'**
  String get pricingSignInRequiredMessage;

  /// No description provided for @pricingPaymentDeclinedToast.
  ///
  /// In en, this message translates to:
  /// **'Payment declined. Please try another card.'**
  String get pricingPaymentDeclinedToast;

  /// No description provided for @pricingPaymentDeclinedTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment declined'**
  String get pricingPaymentDeclinedTitle;

  /// No description provided for @pricingPaymentDeclinedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your payment was declined. Please try another card or payment method.'**
  String get pricingPaymentDeclinedMessage;

  /// No description provided for @pricingTryAnotherCard.
  ///
  /// In en, this message translates to:
  /// **'Try another card'**
  String get pricingTryAnotherCard;

  /// No description provided for @pricingVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase verification failed.'**
  String get pricingVerificationFailed;

  /// No description provided for @pricingPreviousPurchaseApproved.
  ///
  /// In en, this message translates to:
  /// **'Your previous purchase was approved and your subscription is active.'**
  String get pricingPreviousPurchaseApproved;

  /// No description provided for @pricingProductNotFound.
  ///
  /// In en, this message translates to:
  /// **'Product not found'**
  String get pricingProductNotFound;

  /// No description provided for @pricingCouldNotStartPurchaseFlow.
  ///
  /// In en, this message translates to:
  /// **'Could not start purchase flow'**
  String get pricingCouldNotStartPurchaseFlow;

  /// No description provided for @pricingPurchaseError.
  ///
  /// In en, this message translates to:
  /// **'Purchase error: {error}'**
  String pricingPurchaseError(Object error);

  /// No description provided for @pricingPurchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase failed: {reason}'**
  String pricingPurchaseFailed(Object reason);

  /// No description provided for @pricingRefreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing...'**
  String get pricingRefreshing;

  /// No description provided for @pricingRefreshPurchases.
  ///
  /// In en, this message translates to:
  /// **'Refresh purchases'**
  String get pricingRefreshPurchases;

  /// No description provided for @pricingHeroLabel.
  ///
  /// In en, this message translates to:
  /// **'ELITE INTELLIGENCE'**
  String get pricingHeroLabel;

  /// No description provided for @pricingHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'THE UNFAIR\nADVANTAGE.'**
  String get pricingHeroTitle;

  /// No description provided for @pricingHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock the only AI capable of deep psychological analysis and subtext reading.'**
  String get pricingHeroSubtitle;

  /// No description provided for @pricingFeatureReasoningTitle.
  ///
  /// In en, this message translates to:
  /// **'Deep Reasoning Engine'**
  String get pricingFeatureReasoningTitle;

  /// No description provided for @pricingFeatureReasoningSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Openers analyzed by our most advanced, human-level model.'**
  String get pricingFeatureReasoningSubtitle;

  /// No description provided for @pricingFeatureReasoningBadge.
  ///
  /// In en, this message translates to:
  /// **'PRO MODEL'**
  String get pricingFeatureReasoningBadge;

  /// No description provided for @pricingFeatureFlowTitle.
  ///
  /// In en, this message translates to:
  /// **'Unrestricted Flow'**
  String get pricingFeatureFlowTitle;

  /// No description provided for @pricingFeatureFlowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlimited replies. Zero timers. Complete creative freedom.'**
  String get pricingFeatureFlowSubtitle;

  /// No description provided for @pricingFeatureTonalityTitle.
  ///
  /// In en, this message translates to:
  /// **'Adaptive Tonality'**
  String get pricingFeatureTonalityTitle;

  /// No description provided for @pricingFeatureTonalitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Switch between Charming, Cocky, or Sincere modes instantly.'**
  String get pricingFeatureTonalitySubtitle;

  /// No description provided for @pricingFeatureContextTitle.
  ///
  /// In en, this message translates to:
  /// **'Instant Context'**
  String get pricingFeatureContextTitle;

  /// No description provided for @pricingFeatureContextSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Seamless screenshot analysis without the wait.'**
  String get pricingFeatureContextSubtitle;

  /// No description provided for @pricingWeeklyFallback.
  ///
  /// In en, this message translates to:
  /// **'\$6.99 / week'**
  String get pricingWeeklyFallback;

  /// No description provided for @pricingWeeklyPrice.
  ///
  /// In en, this message translates to:
  /// **'\${price} / week'**
  String pricingWeeklyPrice(Object price);

  /// No description provided for @pricingCoffeeLine.
  ///
  /// In en, this message translates to:
  /// **'Less than a coffee a day.'**
  String get pricingCoffeeLine;

  /// No description provided for @pricingUnlockEliteAccess.
  ///
  /// In en, this message translates to:
  /// **'Unlock Elite Access'**
  String get pricingUnlockEliteAccess;

  /// No description provided for @pricingCancelAnytime.
  ///
  /// In en, this message translates to:
  /// **'Cancel anytime via Google Play. Secure processing.'**
  String get pricingCancelAnytime;

  /// No description provided for @pricingSocialProof.
  ///
  /// In en, this message translates to:
  /// **'Trusted by 10,000+ men to land more dates.'**
  String get pricingSocialProof;

  /// No description provided for @policyEffectiveDate.
  ///
  /// In en, this message translates to:
  /// **'Effective Date: {effectiveDate}'**
  String policyEffectiveDate(Object effectiveDate);

  /// No description provided for @policyPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get policyPrivacyTitle;

  /// No description provided for @policyPrivacyEffectiveDate.
  ///
  /// In en, this message translates to:
  /// **'January 30, 2026'**
  String get policyPrivacyEffectiveDate;

  /// No description provided for @policyPrivacySectionIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Introduction'**
  String get policyPrivacySectionIntroTitle;

  /// No description provided for @policyPrivacySectionIntroContent.
  ///
  /// In en, this message translates to:
  /// **'FlirtFix (\"we\", \"our\", or \"us\") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application FlirtFix (the \"App\"). Please read this policy carefully. If you do not agree with these terms, please do not access the App.'**
  String get policyPrivacySectionIntroContent;

  /// No description provided for @policyPrivacySectionInfoCollectTitle.
  ///
  /// In en, this message translates to:
  /// **'1. Information We Collect'**
  String get policyPrivacySectionInfoCollectTitle;

  /// No description provided for @policyPrivacySectionInfoCollectContent.
  ///
  /// In en, this message translates to:
  /// **'We collect information you provide directly to us when using FlirtFix:\n\n- Account information: email address, username, and password (hashed and securely stored)\n- Conversation data: messages and conversation text submitted for AI analysis\n- Uploaded content: screenshots and profile images you upload for analysis\n- Device information: Android device ID for device identification\n- Usage data: information about how you interact with the app\n- Payment information: purchase tokens, transaction IDs, and subscription status through Google Play Billing'**
  String get policyPrivacySectionInfoCollectContent;

  /// No description provided for @policyPrivacySectionInfoUseTitle.
  ///
  /// In en, this message translates to:
  /// **'2. How We Use Your Information'**
  String get policyPrivacySectionInfoUseTitle;

  /// No description provided for @policyPrivacySectionInfoUseContent.
  ///
  /// In en, this message translates to:
  /// **'We use collected information to:\n\n- Provide AI-powered conversation assistance and suggestions\n- Analyze uploaded images and screenshots\n- Manage your account and subscription\n- Process payments and billing\n- Improve and optimize our app and services\n- Communicate updates, features, and support\n- Enforce fair use and terms\n- Comply with legal obligations'**
  String get policyPrivacySectionInfoUseContent;

  /// No description provided for @policyPrivacySectionThirdPartyTitle.
  ///
  /// In en, this message translates to:
  /// **'3. Third-Party Services'**
  String get policyPrivacySectionThirdPartyTitle;

  /// No description provided for @policyPrivacySectionThirdPartyContent.
  ///
  /// In en, this message translates to:
  /// **'We use third-party services that may collect information about you:\n\n- Firebase Analytics for app usage analytics\n- Firebase Crashlytics for crash reporting and stability\n- Google Play Billing for subscriptions and in-app purchases\n\nThese services have their own privacy policies.'**
  String get policyPrivacySectionThirdPartyContent;

  /// No description provided for @policyPrivacySectionStorageSecurityTitle.
  ///
  /// In en, this message translates to:
  /// **'4. Data Storage and Security'**
  String get policyPrivacySectionStorageSecurityTitle;

  /// No description provided for @policyPrivacySectionStorageSecurityContent.
  ///
  /// In en, this message translates to:
  /// **'Your data is stored both locally on your device and on secure servers:\n\n- Local storage: auth tokens, profile data, credits, and preferences\n- Server storage: account information, conversation history, and uploaded images\n- Security measures: token-based auth, HTTPS encryption, and standard technical safeguards'**
  String get policyPrivacySectionStorageSecurityContent;

  /// No description provided for @policyPrivacySectionRetentionTitle.
  ///
  /// In en, this message translates to:
  /// **'5. Data Retention'**
  String get policyPrivacySectionRetentionTitle;

  /// No description provided for @policyPrivacySectionRetentionContent.
  ///
  /// In en, this message translates to:
  /// **'We retain personal information while your account is active or as needed to provide services. When you delete your account:\n\n- Personal information is removed from our servers\n- Uploaded images and conversation history are deleted\n- Local data is cleared from your device\n- Some backup data may be retained for up to 30 days'**
  String get policyPrivacySectionRetentionContent;

  /// No description provided for @policyPrivacySectionRightsTitle.
  ///
  /// In en, this message translates to:
  /// **'6. Your Rights'**
  String get policyPrivacySectionRightsTitle;

  /// No description provided for @policyPrivacySectionRightsContent.
  ///
  /// In en, this message translates to:
  /// **'You may request access, correction, deletion, portability, or objection regarding your personal information. Contact us at support@tryagaintext.com to exercise these rights.'**
  String get policyPrivacySectionRightsContent;

  /// No description provided for @policyPrivacySectionComplianceTitle.
  ///
  /// In en, this message translates to:
  /// **'7. GDPR and CCPA Compliance'**
  String get policyPrivacySectionComplianceTitle;

  /// No description provided for @policyPrivacySectionComplianceContent.
  ///
  /// In en, this message translates to:
  /// **'For users in the EU and California, we process personal data lawfully, fairly, and transparently. We do not sell personal information and honor applicable legal rights.'**
  String get policyPrivacySectionComplianceContent;

  /// No description provided for @policyPrivacySectionCookiesTitle.
  ///
  /// In en, this message translates to:
  /// **'8. Cookies and Tracking'**
  String get policyPrivacySectionCookiesTitle;

  /// No description provided for @policyPrivacySectionCookiesContent.
  ///
  /// In en, this message translates to:
  /// **'The app uses Firebase Analytics and similar technologies to track usage patterns, analyze feature performance, and identify technical issues.'**
  String get policyPrivacySectionCookiesContent;

  /// No description provided for @policyPrivacySectionChildrenTitle.
  ///
  /// In en, this message translates to:
  /// **'9. Children\'s Privacy'**
  String get policyPrivacySectionChildrenTitle;

  /// No description provided for @policyPrivacySectionChildrenContent.
  ///
  /// In en, this message translates to:
  /// **'FlirtFix is intended for users age 18 and older. We do not knowingly collect personal information from anyone under 18.'**
  String get policyPrivacySectionChildrenContent;

  /// No description provided for @policyPrivacySectionSharingTitle.
  ///
  /// In en, this message translates to:
  /// **'10. Data Sharing and Disclosure'**
  String get policyPrivacySectionSharingTitle;

  /// No description provided for @policyPrivacySectionSharingContent.
  ///
  /// In en, this message translates to:
  /// **'We do not sell or rent personal information. We may share data only with service providers, when required by law, to protect rights/safety, or during business transfers.'**
  String get policyPrivacySectionSharingContent;

  /// No description provided for @policyPrivacySectionTransfersTitle.
  ///
  /// In en, this message translates to:
  /// **'11. International Data Transfers'**
  String get policyPrivacySectionTransfersTitle;

  /// No description provided for @policyPrivacySectionTransfersContent.
  ///
  /// In en, this message translates to:
  /// **'Your information may be transferred to and processed in countries other than your country of residence, where data protection laws may differ.'**
  String get policyPrivacySectionTransfersContent;

  /// No description provided for @policyPrivacySectionChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'12. Changes to This Privacy Policy'**
  String get policyPrivacySectionChangesTitle;

  /// No description provided for @policyPrivacySectionChangesContent.
  ///
  /// In en, this message translates to:
  /// **'We may update this policy from time to time. We will update the effective date and post changes in the app. Continued use after changes become effective means acceptance.'**
  String get policyPrivacySectionChangesContent;

  /// No description provided for @policyPrivacySectionContactTitle.
  ///
  /// In en, this message translates to:
  /// **'13. Contact Us'**
  String get policyPrivacySectionContactTitle;

  /// No description provided for @policyPrivacySectionContactContent.
  ///
  /// In en, this message translates to:
  /// **'If you have questions, contact support@tryagaintext.com. Company: FlirtFix.'**
  String get policyPrivacySectionContactContent;

  /// No description provided for @policyTermsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get policyTermsTitle;

  /// No description provided for @policyTermsEffectiveDate.
  ///
  /// In en, this message translates to:
  /// **'January 30, 2026'**
  String get policyTermsEffectiveDate;

  /// No description provided for @policyTermsSectionAgreementTitle.
  ///
  /// In en, this message translates to:
  /// **'Agreement to Terms'**
  String get policyTermsSectionAgreementTitle;

  /// No description provided for @policyTermsSectionAgreementContent.
  ///
  /// In en, this message translates to:
  /// **'By accessing and using FlirtFix, you agree to be bound by these Terms of Use. If you do not agree, do not use the app.'**
  String get policyTermsSectionAgreementContent;

  /// No description provided for @policyTermsSectionServiceDescriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'1. Service Description'**
  String get policyTermsSectionServiceDescriptionTitle;

  /// No description provided for @policyTermsSectionServiceDescriptionContent.
  ///
  /// In en, this message translates to:
  /// **'FlirtFix is an AI-powered mobile app that provides conversation assistance, screenshot OCR, profile analysis, custom instruction support, and subscription-based access subject to fair use limits.'**
  String get policyTermsSectionServiceDescriptionContent;

  /// No description provided for @policyTermsSectionAcceptableUseTitle.
  ///
  /// In en, this message translates to:
  /// **'2. Acceptable Use Policy'**
  String get policyTermsSectionAcceptableUseTitle;

  /// No description provided for @policyTermsSectionAcceptableUseContent.
  ///
  /// In en, this message translates to:
  /// **'You may not use FlirtFix for harassment, illegal activity, policy circumvention, reverse engineering, bot access, or commercial resale of generated content.'**
  String get policyTermsSectionAcceptableUseContent;

  /// No description provided for @policyTermsSectionFairUseTitle.
  ///
  /// In en, this message translates to:
  /// **'3. Fair Use Policy'**
  String get policyTermsSectionFairUseTitle;

  /// No description provided for @policyTermsSectionFairUseContent.
  ///
  /// In en, this message translates to:
  /// **'Unlimited plans are subject to fair use limits, including daily and weekly usage controls and abuse detection. Excessive abuse may lead to temporary restriction or termination.'**
  String get policyTermsSectionFairUseContent;

  /// No description provided for @policyTermsSectionRegistrationTitle.
  ///
  /// In en, this message translates to:
  /// **'4. Account Registration'**
  String get policyTermsSectionRegistrationTitle;

  /// No description provided for @policyTermsSectionRegistrationContent.
  ///
  /// In en, this message translates to:
  /// **'You must be at least 18, provide accurate information, protect your credentials, and remain responsible for account activity.'**
  String get policyTermsSectionRegistrationContent;

  /// No description provided for @policyTermsSectionSubscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'5. Subscription Terms'**
  String get policyTermsSectionSubscriptionTitle;

  /// No description provided for @policyTermsSectionSubscriptionContent.
  ///
  /// In en, this message translates to:
  /// **'FlirtFix Unlimited is billed weekly through Google Play Billing with auto-renewal unless canceled. Pricing and availability may change with notice.'**
  String get policyTermsSectionSubscriptionContent;

  /// No description provided for @policyTermsSectionIpRightsTitle.
  ///
  /// In en, this message translates to:
  /// **'6. Intellectual Property Rights'**
  String get policyTermsSectionIpRightsTitle;

  /// No description provided for @policyTermsSectionIpRightsContent.
  ///
  /// In en, this message translates to:
  /// **'You retain ownership of your uploaded content. FlirtFix retains ownership of the app, branding, algorithms, and related intellectual property.'**
  String get policyTermsSectionIpRightsContent;

  /// No description provided for @policyTermsSectionDisclaimerTitle.
  ///
  /// In en, this message translates to:
  /// **'7. Disclaimer of Warranties'**
  String get policyTermsSectionDisclaimerTitle;

  /// No description provided for @policyTermsSectionDisclaimerContent.
  ///
  /// In en, this message translates to:
  /// **'The app is provided \"as is\" and \"as available\" without warranties. AI suggestions are guidance only and do not guarantee outcomes.'**
  String get policyTermsSectionDisclaimerContent;

  /// No description provided for @policyTermsSectionLiabilityTitle.
  ///
  /// In en, this message translates to:
  /// **'8. Limitation of Liability'**
  String get policyTermsSectionLiabilityTitle;

  /// No description provided for @policyTermsSectionLiabilityContent.
  ///
  /// In en, this message translates to:
  /// **'To the maximum extent permitted by law, FlirtFix is not liable for indirect or consequential damages. Liability is limited to amounts paid in the prior 12 months.'**
  String get policyTermsSectionLiabilityContent;

  /// No description provided for @policyTermsSectionAvailabilityTitle.
  ///
  /// In en, this message translates to:
  /// **'9. Service Availability'**
  String get policyTermsSectionAvailabilityTitle;

  /// No description provided for @policyTermsSectionAvailabilityContent.
  ///
  /// In en, this message translates to:
  /// **'Service may be interrupted for maintenance, updates, or third-party limitations. We do not guarantee uninterrupted availability.'**
  String get policyTermsSectionAvailabilityContent;

  /// No description provided for @policyTermsSectionTerminationTitle.
  ///
  /// In en, this message translates to:
  /// **'10. Termination'**
  String get policyTermsSectionTerminationTitle;

  /// No description provided for @policyTermsSectionTerminationContent.
  ///
  /// In en, this message translates to:
  /// **'We may suspend or terminate access for policy violations, fraud, legal requirements, or product discontinuation.'**
  String get policyTermsSectionTerminationContent;

  /// No description provided for @policyTermsSectionLawTitle.
  ///
  /// In en, this message translates to:
  /// **'11. Governing Law and Jurisdiction'**
  String get policyTermsSectionLawTitle;

  /// No description provided for @policyTermsSectionLawContent.
  ///
  /// In en, this message translates to:
  /// **'These terms are governed by the laws of the United States.'**
  String get policyTermsSectionLawContent;

  /// No description provided for @policyTermsSectionDisputeTitle.
  ///
  /// In en, this message translates to:
  /// **'12. Dispute Resolution'**
  String get policyTermsSectionDisputeTitle;

  /// No description provided for @policyTermsSectionDisputeContent.
  ///
  /// In en, this message translates to:
  /// **'Before legal action, contact support@tryagaintext.com for informal resolution. Unresolved disputes may proceed as allowed by applicable law and platform policy.'**
  String get policyTermsSectionDisputeContent;

  /// No description provided for @policyTermsSectionChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'13. Changes to Terms'**
  String get policyTermsSectionChangesTitle;

  /// No description provided for @policyTermsSectionChangesContent.
  ///
  /// In en, this message translates to:
  /// **'We may modify these terms at any time and update the effective date in-app. Continued use indicates acceptance.'**
  String get policyTermsSectionChangesContent;

  /// No description provided for @policyTermsSectionSeverabilityTitle.
  ///
  /// In en, this message translates to:
  /// **'14. Severability'**
  String get policyTermsSectionSeverabilityTitle;

  /// No description provided for @policyTermsSectionSeverabilityContent.
  ///
  /// In en, this message translates to:
  /// **'If one provision is unenforceable, the remaining provisions remain in effect.'**
  String get policyTermsSectionSeverabilityContent;

  /// No description provided for @policyTermsSectionEntireAgreementTitle.
  ///
  /// In en, this message translates to:
  /// **'15. Entire Agreement'**
  String get policyTermsSectionEntireAgreementTitle;

  /// No description provided for @policyTermsSectionEntireAgreementContent.
  ///
  /// In en, this message translates to:
  /// **'These Terms, together with our Privacy and Refund policies, form the entire agreement between you and FlirtFix.'**
  String get policyTermsSectionEntireAgreementContent;

  /// No description provided for @policyTermsSectionContactTitle.
  ///
  /// In en, this message translates to:
  /// **'16. Contact Information'**
  String get policyTermsSectionContactTitle;

  /// No description provided for @policyTermsSectionContactContent.
  ///
  /// In en, this message translates to:
  /// **'For questions about these Terms, contact support@tryagaintext.com.'**
  String get policyTermsSectionContactContent;

  /// No description provided for @policyRefundTitle.
  ///
  /// In en, this message translates to:
  /// **'Refund Policy'**
  String get policyRefundTitle;

  /// No description provided for @policyRefundEffectiveDate.
  ///
  /// In en, this message translates to:
  /// **'January 30, 2026'**
  String get policyRefundEffectiveDate;

  /// No description provided for @policyRefundSectionOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get policyRefundSectionOverviewTitle;

  /// No description provided for @policyRefundSectionOverviewContent.
  ///
  /// In en, this message translates to:
  /// **'This Refund Policy explains subscription and purchase refund handling. Transactions are processed via Google Play Billing and may also be subject to Google Play rules.'**
  String get policyRefundSectionOverviewContent;

  /// No description provided for @policyRefundSectionSubscriptionRefundsTitle.
  ///
  /// In en, this message translates to:
  /// **'1. Subscription Refunds'**
  String get policyRefundSectionSubscriptionRefundsTitle;

  /// No description provided for @policyRefundSectionSubscriptionRefundsContent.
  ///
  /// In en, this message translates to:
  /// **'Initial subscription refunds may be requested within the platform\'s allowed window and are subject to eligibility and usage review.'**
  String get policyRefundSectionSubscriptionRefundsContent;

  /// No description provided for @policyRefundSectionGooglePlayProcessTitle.
  ///
  /// In en, this message translates to:
  /// **'2. Google Play Refund Process'**
  String get policyRefundSectionGooglePlayProcessTitle;

  /// No description provided for @policyRefundSectionGooglePlayProcessContent.
  ///
  /// In en, this message translates to:
  /// **'To request a refund, use Google Play subscription management or account help pages and follow the refund workflow provided by Google Play.'**
  String get policyRefundSectionGooglePlayProcessContent;

  /// No description provided for @policyRefundSectionCreditRefundsTitle.
  ///
  /// In en, this message translates to:
  /// **'3. Credit Purchase Refunds'**
  String get policyRefundSectionCreditRefundsTitle;

  /// No description provided for @policyRefundSectionCreditRefundsContent.
  ///
  /// In en, this message translates to:
  /// **'Credit purchases are generally non-refundable once delivered, except where required by law or in confirmed technical delivery failures.'**
  String get policyRefundSectionCreditRefundsContent;

  /// No description provided for @policyRefundSectionEligibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'4. Refund Eligibility'**
  String get policyRefundSectionEligibilityTitle;

  /// No description provided for @policyRefundSectionEligibilityContent.
  ///
  /// In en, this message translates to:
  /// **'Refund eligibility depends on purchase timing, usage, and policy compliance. Fraud, abuse, or policy violations may void eligibility.'**
  String get policyRefundSectionEligibilityContent;

  /// No description provided for @policyRefundSectionCancellationTitle.
  ///
  /// In en, this message translates to:
  /// **'5. Subscription Cancellation'**
  String get policyRefundSectionCancellationTitle;

  /// No description provided for @policyRefundSectionCancellationContent.
  ///
  /// In en, this message translates to:
  /// **'You may cancel any time through Google Play. Cancellation stops future renewals and access typically remains until period end.'**
  String get policyRefundSectionCancellationContent;

  /// No description provided for @policyRefundSectionBillingIssuesTitle.
  ///
  /// In en, this message translates to:
  /// **'6. Billing Issues'**
  String get policyRefundSectionBillingIssuesTitle;

  /// No description provided for @policyRefundSectionBillingIssuesContent.
  ///
  /// In en, this message translates to:
  /// **'For duplicate or unexpected charges, contact support@tryagaintext.com with transaction details and also review Google Play account purchase history.'**
  String get policyRefundSectionBillingIssuesContent;

  /// No description provided for @policyRefundSectionProcessingTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'7. Refund Processing Time'**
  String get policyRefundSectionProcessingTimeTitle;

  /// No description provided for @policyRefundSectionProcessingTimeContent.
  ///
  /// In en, this message translates to:
  /// **'Refund processing times vary by provider and financial institution and may take several business days.'**
  String get policyRefundSectionProcessingTimeContent;

  /// No description provided for @policyRefundSectionExceptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'8. Exceptions and Special Cases'**
  String get policyRefundSectionExceptionsTitle;

  /// No description provided for @policyRefundSectionExceptionsContent.
  ///
  /// In en, this message translates to:
  /// **'Extended outages, incorrect billing, and verified technical failures may be reviewed for prorated or full refund exceptions.'**
  String get policyRefundSectionExceptionsContent;

  /// No description provided for @policyRefundSectionFairUseAbuseTitle.
  ///
  /// In en, this message translates to:
  /// **'9. Fair Use and Abuse'**
  String get policyRefundSectionFairUseAbuseTitle;

  /// No description provided for @policyRefundSectionFairUseAbuseContent.
  ///
  /// In en, this message translates to:
  /// **'Repeated refund abuse, policy violations, or fraudulent use may result in denial of refund requests and account restriction.'**
  String get policyRefundSectionFairUseAbuseContent;

  /// No description provided for @policyRefundSectionThirdPartyIssuesTitle.
  ///
  /// In en, this message translates to:
  /// **'10. Third-Party Payment Issues'**
  String get policyRefundSectionThirdPartyIssuesTitle;

  /// No description provided for @policyRefundSectionThirdPartyIssuesContent.
  ///
  /// In en, this message translates to:
  /// **'Google Play has final authority on payment and charge disputes for transactions processed through its billing platform.'**
  String get policyRefundSectionThirdPartyIssuesContent;

  /// No description provided for @policyRefundSectionNoRefundScenariosTitle.
  ///
  /// In en, this message translates to:
  /// **'11. No Refund Scenarios'**
  String get policyRefundSectionNoRefundScenariosTitle;

  /// No description provided for @policyRefundSectionNoRefundScenariosContent.
  ///
  /// In en, this message translates to:
  /// **'Refunds are generally not available for change of mind after substantial use, subjective dissatisfaction, or missed cancellation before renewal.'**
  String get policyRefundSectionNoRefundScenariosContent;

  /// No description provided for @policyRefundSectionDisputeTitle.
  ///
  /// In en, this message translates to:
  /// **'12. Dispute Resolution'**
  String get policyRefundSectionDisputeTitle;

  /// No description provided for @policyRefundSectionDisputeContent.
  ///
  /// In en, this message translates to:
  /// **'If a refund request is denied, contact support with additional details. If unresolved, dispute options may be available through the payment platform.'**
  String get policyRefundSectionDisputeContent;

  /// No description provided for @policyRefundSectionPolicyChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'13. Policy Changes'**
  String get policyRefundSectionPolicyChangesTitle;

  /// No description provided for @policyRefundSectionPolicyChangesContent.
  ///
  /// In en, this message translates to:
  /// **'We may update this policy and publish changes in-app with an updated effective date.'**
  String get policyRefundSectionPolicyChangesContent;

  /// No description provided for @policyRefundSectionContactTitle.
  ///
  /// In en, this message translates to:
  /// **'14. Contact for Refund Requests'**
  String get policyRefundSectionContactTitle;

  /// No description provided for @policyRefundSectionContactContent.
  ///
  /// In en, this message translates to:
  /// **'For refund requests or questions, email support@tryagaintext.com with your transaction details.'**
  String get policyRefundSectionContactContent;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
