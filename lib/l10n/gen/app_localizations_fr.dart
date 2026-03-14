// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'FlirtFix';

  @override
  String get splashTagline => 'Maîtrisez l\'Art de la Conversation.';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonClose => 'Fermer';

  @override
  String get commonContinue => 'Continuer';

  @override
  String get commonMaybeLater => 'Plus tard';

  @override
  String get commonOk => 'OK';

  @override
  String get commonOr => 'OU';

  @override
  String get commonSignIn => 'Se connecter';

  @override
  String get commonEmailLabel => 'E-mail';

  @override
  String get commonEmailHint => 'vous@exemple.com';

  @override
  String get commonPasswordHint => 'Mot de passe';

  @override
  String get commonUploaded => 'Téléchargé';

  @override
  String get errorNetworkTryAgain => 'Erreur réseau. Veuillez réessayer.';

  @override
  String get errorUnexpectedTryAgain =>
      'Oups ! Un problème est survenu. Veuillez réessayer.';

  @override
  String get validationEnterEmail => 'Veuillez entrer votre e-mail';

  @override
  String get validationEnterPassword => 'Veuillez entrer votre mot de passe';

  @override
  String get validationEnterValidEmail => 'Veuillez entrer un e-mail valide';

  @override
  String get validationEnterYourEmail => 'Veuillez entrer votre e-mail.';

  @override
  String get validationPasswordMinLength =>
      'Le mot de passe doit comporter au moins 6 caractères';

  @override
  String get validationPasswordsDoNotMatch =>
      'Les mots de passe ne correspondent pas';

  @override
  String get authLoginFailed => 'Échec de la connexion';

  @override
  String get authWelcomeBack => 'Content de vous revoir !';

  @override
  String get authAccountCreatedSignedIn => 'Compte créé. Vous êtes connecté';

  @override
  String get loginPrivateAccessTitle => 'Accès Privé';

  @override
  String get loginWelcome => 'Bienvenue.';

  @override
  String get loginSubtitle =>
      'Accédez à votre concierge de rencontres personnel.';

  @override
  String get loginMemberIdOrEmailLabel => 'ID Membre / E-mail';

  @override
  String get loginMemberIdOrEmailHint => 'Entrez votre ID membre ou e-mail';

  @override
  String get loginPasscodeLabel => 'Code d\'accès';

  @override
  String get loginPasscodeHint => 'Entrez votre code d\'accès';

  @override
  String get loginForgotPasscode => 'Code d\'accès oublié ?';

  @override
  String get loginAccessing => 'Accès en cours...';

  @override
  String get loginAccessButton => 'Accéder';

  @override
  String get loginPreviewExperience => 'Aperçu de l\'Expérience';

  @override
  String get signupBecomeMember => 'Devenir Membre';

  @override
  String get signupSubtitle =>
      'Votre voyage vers des connexions sans effort commence ici.';

  @override
  String get signupEmailLabel => 'E-mail de Correspondance';

  @override
  String get signupEmailHint => 'Entrez votre e-mail de correspondance';

  @override
  String get signupSecurePasscodeLabel => 'Code d\'accès sécurisé';

  @override
  String get signupSecurePasscodeHint => 'Créez un code d\'accès sécurisé';

  @override
  String get signupVerifyPasscodeLabel => 'Vérifier le code d\'accès';

  @override
  String get signupVerifyPasscodeHint => 'Vérifiez votre code d\'accès';

  @override
  String get signupValidationEnterCorrespondenceEmail =>
      'Veuillez entrer votre e-mail de correspondance';

  @override
  String get signupValidationEnterSecurePasscode =>
      'Veuillez entrer un code d\'accès sécurisé';

  @override
  String get signupValidationPasscodeMinLength =>
      'Le code d\'accès doit comporter au moins 6 caractères';

  @override
  String get signupValidationVerifyPasscode =>
      'Veuillez vérifier votre code d\'accès';

  @override
  String get signupClaimingAccess => 'Réclamation de l\'accès...';

  @override
  String get signupClaimAccessButton => 'Réclamer Votre Accès';

  @override
  String get signupAlreadyEstablishedPrompt => 'Déjà membre ? ';

  @override
  String get signupEnterHere => 'Entrez Ici';

  @override
  String get signupRegistrationFailed => 'Échec de l\'inscription';

  @override
  String get forgotPasswordTitle => 'Réinitialiser le mot de passe';

  @override
  String get forgotPasswordSubtitle =>
      'Entrez votre e-mail et nous vous enverrons un lien.';

  @override
  String get forgotPasswordEmailHint => 'Entrez votre adresse e-mail';

  @override
  String get forgotPasswordCheckEmailTitle => 'Vérifiez votre e-mail';

  @override
  String get forgotPasswordCheckEmailMessage =>
      'Si un compte existe, nous avons envoyé les instructions de réinitialisation.';

  @override
  String get forgotPasswordSendingResetLink => 'Envoi du lien...';

  @override
  String get forgotPasswordSendResetLinkButton => 'Envoyer le Lien';

  @override
  String get forgotPasswordResetFailed => 'Échec de la réinitialisation';

  @override
  String get changePasswordTitle => 'Changer le mot de passe';

  @override
  String get changePasswordCurrentLabel => 'Mot de passe actuel';

  @override
  String get changePasswordNewLabel => 'Nouveau mot de passe';

  @override
  String get changePasswordConfirmLabel => 'Confirmer le nouveau mot de passe';

  @override
  String get changePasswordValidationCurrent =>
      'Entrez votre mot de passe actuel';

  @override
  String get changePasswordValidationNew => 'Entrez un nouveau mot de passe';

  @override
  String get changePasswordValidationConfirm =>
      'Confirmez votre nouveau mot de passe';

  @override
  String get changePasswordUpdateButton => 'Mettre à jour le mot de passe';

  @override
  String get changePasswordUpdatedTitle => 'Mot de passe mis à jour';

  @override
  String get changePasswordUpdatedMessage =>
      'Votre mot de passe a été modifié avec succès.';

  @override
  String get changePasswordUpdateFailed => 'Échec de la mise à jour';

  @override
  String get deleteAccountTitle => 'Supprimer le Compte';

  @override
  String get deleteAccountConfirmDialogTitle => 'Êtes-vous absolument sûr ?';

  @override
  String get deleteAccountConfirmDialogMessage =>
      'Cette action est irréversible. Toutes vos données seront définitivement supprimées.';

  @override
  String get deleteAccountSuccess => 'Compte supprimé avec succès';

  @override
  String get deleteAccountWarningTitle => 'Avertissement : Action Définitive';

  @override
  String get deleteAccountWarningIntro => 'La suppression de votre compte va :';

  @override
  String get deleteAccountWarningChatHistory =>
      'Supprimer définitivement tout votre historique de chat';

  @override
  String get deleteAccountWarningProfileData =>
      'Supprimer votre profil et les données du compte';

  @override
  String get deleteAccountWarningIrreversible =>
      'Cette action est irréversible';

  @override
  String get deleteAccountWarningSubscription =>
      'Les abonnements actifs doivent être annulés séparément dans Google Play';

  @override
  String get deleteAccountEnterPassword =>
      'Entrez votre mot de passe pour confirmer';

  @override
  String get deleteAccountCheckboxConfirm =>
      'Je comprends que toutes mes données seront définitivement supprimées';

  @override
  String get deleteAccountDeleteButton => 'Supprimer Mon Compte';

  @override
  String get deleteAccountErrorInvalidPassword => 'Mot de passe invalide';

  @override
  String get deleteAccountErrorFailed =>
      'Échec de la suppression du compte. Veuillez réessayer.';

  @override
  String get reportIssueTitle => 'Signaler un Problème';

  @override
  String get reportIssueThanksTitle => 'Merci';

  @override
  String get reportIssueThanksMessage =>
      'Votre signalement a été envoyé. Nous vous recontacterons par e-mail.';

  @override
  String get reportIssueSendFailed =>
      'Impossible d\'envoyer votre signalement. Veuillez réessayer.';

  @override
  String get reportIssueReasonLabel => 'Raison';

  @override
  String get reportIssueReasonBug => 'Signalement de Bug';

  @override
  String get reportIssueReasonPayment => 'Paiements';

  @override
  String get reportIssueReasonFeedback => 'Commentaires';

  @override
  String get reportIssueReasonOther => 'Autre';

  @override
  String get reportIssueFormTitleLabel => 'Titre';

  @override
  String get reportIssueFormTitleHint => 'Bref résumé';

  @override
  String get reportIssueValidationTitle => 'Veuillez entrer un titre';

  @override
  String get reportIssueFormDetailsLabel => 'Détails';

  @override
  String get reportIssueFormDetailsHint => 'Dites-nous ce qui s\'est passé';

  @override
  String get reportIssueValidationDetails => 'Veuillez entrer les détails';

  @override
  String get reportIssueSendButton => 'Envoyer le Signalement';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileHelpPolicies => 'Aide & Politiques';

  @override
  String get profileGuest => 'Invité';

  @override
  String get profileGuestPreview => 'Aperçu Invité';

  @override
  String get profileMemberAccess => 'Accès Membre';

  @override
  String get profilePreviewAccess => 'Accès Aperçu';

  @override
  String get profileMembershipStatus => 'Statut d\'Abonnement';

  @override
  String get profileMembershipActive => 'Actif - Élite';

  @override
  String get profileMembershipInactive => 'Inactif';

  @override
  String get profileManage => 'Gérer';

  @override
  String get profileSubscribe => 'S\'abonner';

  @override
  String get profileAmbience => 'Ambiance';

  @override
  String get profileAmbienceRoyalRomance => 'Romance Royale';

  @override
  String get profileAmbienceMidnightGold => 'Or de Minuit';

  @override
  String get profileLanguage => 'Langue';

  @override
  String get profileSecuritySettings => 'Paramètres de Sécurité';

  @override
  String get profileSignOut => 'Se déconnecter';

  @override
  String profileMember(Object memberName) {
    return 'Membre : $memberName';
  }

  @override
  String get languageSystem => 'Système';

  @override
  String get languageEnglish => 'Anglais';

  @override
  String get languageSpanish => 'Espagnol';

  @override
  String get languagePortuguese => 'Portugais';

  @override
  String get languageGerman => 'Allemand';

  @override
  String get languageFrench => 'Français';

  @override
  String get subscriptionActivated => 'Abonnement activé !';

  @override
  String get conversationsAddConversationFirst =>
      'Veuillez d\'abord ajouter votre conversation';

  @override
  String get conversationsAnalyzeChat => 'Analyser le Chat';

  @override
  String get conversationsAnalyzeProfile => 'Analyser le Profil';

  @override
  String get conversationsAppbarSubtitle => 'Votre Architecte de Conversation';

  @override
  String get conversationsCharacterDoctor => 'Docteur';

  @override
  String get conversationsCharacterLawyer => 'Avocat';

  @override
  String get conversationsCharacterLoganRoy => 'Logan Roy';

  @override
  String get conversationsCharacterNone => 'Aucun';

  @override
  String get conversationsCharacterSherlockHolmes => 'Sherlock Holmes';

  @override
  String get conversationsCharacterTommyShelby => 'Tommy Shelby';

  @override
  String get conversationsCommandHintEmpty => 'Des instructions spécifiques ?';

  @override
  String conversationsCommandHintWithSettings(Object settings) {
    return '($settings) Ajouter des détails...';
  }

  @override
  String get conversationsCommandShort => 'Court';

  @override
  String get conversationsCopiedToClipboard => 'Copié dans le presse-papiers !';

  @override
  String get conversationsCraftOpening => 'Créer une Accroche';

  @override
  String get conversationsCraftResponse => 'Créer une Réponse';

  @override
  String get conversationsCreateFreeAccountPrompt =>
      'Veuillez créer votre compte gratuit pour continuer.';

  @override
  String conversationsDailyLimitOpenerSubtitle(Object resetTime) {
    return 'Se réinitialise dans $resetTime\n\nVeuillez utiliser les accroches Recommandées. Formulées par des experts pour maximiser l\'engagement.';
  }

  @override
  String conversationsDailyLimitReplySubtitle(Object resetTime) {
    return 'Se réinitialise dans $resetTime';
  }

  @override
  String conversationsDailyLimitTitle(Object limitType) {
    return 'Limite quotidienne de $limitType atteinte';
  }

  @override
  String get conversationsExtractImageFailed =>
      'Échec de l\'extraction du texte. Veuillez réessayer.';

  @override
  String get conversationsGuestSheetBody =>
      'Créez votre compte gratuit pour révéler cette réponse et continuer avec FlirtFix.';

  @override
  String get conversationsGuestSheetHeadline => 'Rejoignez le Cercle Exclusif.';

  @override
  String get conversationsGuestSheetSecondary =>
      'Se connecter à un compte existant';

  @override
  String get conversationsGuestSheetSupport => 'Prend moins de 30 secondes.';

  @override
  String get conversationsKeepItShort => 'Faire court';

  @override
  String get conversationsLimitTypeOpener => 'accroches';

  @override
  String get conversationsLimitTypeReply => 'réponses';

  @override
  String get conversationsLoadingMayTakeSeconds =>
      'Cela peut prendre quelques secondes';

  @override
  String get conversationsModeCreative => 'Créer';

  @override
  String get conversationsModeRecommended => 'Le Coffre';

  @override
  String get conversationsNewChat => 'Nouveau chat';

  @override
  String get conversationsProfileHint =>
      'Choisissez la photo ou la bio la plus intéressante';

  @override
  String get conversationsRecommendedDescription =>
      'Scripts sélectionnés par les meilleurs experts en rencontres. Taux de réponse 3x plus élevé prouvé.';

  @override
  String get conversationsVaultHeadline => 'Le Guide du Coach.';

  @override
  String get conversationsRegenerate => 'Régénérer';

  @override
  String get conversationsResultsCuratedResponses => 'Réponses Sélectionnées';

  @override
  String get conversationsResultsYourApproach => 'Votre Approche';

  @override
  String get conversationsSelectCharacterHelper =>
      'Sélectionnez un personnage ou tapez le vôtre.';

  @override
  String get conversationsSelectCharacterTitle => 'Sélectionner un Personnage';

  @override
  String get conversationsSelectImageFailed =>
      'Échec de la sélection de l\'image. Veuillez réessayer.';

  @override
  String get conversationsSelectToneHelper =>
      'Sélectionnez un style ou tapez le vôtre.';

  @override
  String get conversationsSelectToneTitle => 'Sélectionner un Ton';

  @override
  String get conversationsSubscriptionRequired =>
      'Abonnement requis. Veuillez vous abonner pour continuer.';

  @override
  String get conversationsTabOpen => 'Ouvrir';

  @override
  String get conversationsTabRespond => 'Répondre';

  @override
  String get conversationsTapCraftOpeningHint =>
      'Appuyez sur \"Créer une Accroche\" pour générer des premiers messages personnalisés';

  @override
  String get conversationsTapCraftResponseHint =>
      'Appuyez sur \"Créer une Réponse\" pour générer des suggestions';

  @override
  String get conversationsSignUpToReveal => 'Inscrivez-vous pour révéler.';

  @override
  String get conversationsTapToUnlock => 'Appuyez pour débloquer';

  @override
  String get conversationsTheirProfile => 'Son profil';

  @override
  String conversationsTimeHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String conversationsTimeMinutes(int minutes) {
    return '${minutes}m';
  }

  @override
  String get conversationsToneCockyFunny => 'Taquin et Drôle';

  @override
  String get conversationsToneDefault => 'Défaut';

  @override
  String get conversationsToneFlirty => 'Dragueur';

  @override
  String get conversationsToneRomantic => 'Romantique';

  @override
  String get conversationsToneWitty => 'Spirituel';

  @override
  String get conversationsTooltipCharacter => 'Personnage';

  @override
  String get conversationsTooltipTone => 'Ton';

  @override
  String conversationsUnlockReplyBody(Object limitLabel, Object resetTime) {
    return 'Votre limite quotidienne de $limitLabel est atteinte. Se réinitialise dans $resetTime. Passez à Premium pour révéler la réponse.';
  }

  @override
  String get conversationsUnlockReplyHeadline => 'Débloquez cette réponse.';

  @override
  String get conversationsUnlockFullArchive => 'DÉBLOQUER L\'ARCHIVE COMPLÈTE';

  @override
  String get conversationsUnlockReplySupport =>
      'Déblocage instantané après le paiement.';

  @override
  String get conversationsUploadProfileFirst =>
      'Veuillez d\'abord télécharger une capture d\'écran du profil';

  @override
  String get conversationsWorkspaceReady => 'Espace de Travail Prêt';

  @override
  String get conversationsWorkspaceReadySubtitle =>
      'Téléchargez une capture d\'écran ou fournissez un contexte pour commencer à créer votre prochain message.';

  @override
  String get conversationsYourConversation => 'Votre conversation';

  @override
  String get reviewNeedsCalibration => 'Nécessite une Calibration';

  @override
  String get reviewFeedbackReceived => 'Commentaire reçu. Nous calibrons.';

  @override
  String get reviewRefineStrategyTitle => 'Affiner la Stratégie';

  @override
  String get reviewRefineStrategySubtitle =>
      'Dites-nous ce qui n\'a pas fonctionné. Vos commentaires calibrent le modèle.';

  @override
  String get reviewFeedbackHint => 'La réponse était trop agressive...';

  @override
  String get reviewFeedbackValidationMessage =>
      'Veuillez partager ce qui n\'a pas fonctionné.';

  @override
  String get reviewFeedbackSendFailed =>
      'Impossible d\'envoyer les commentaires. Veuillez réessayer.';

  @override
  String get reviewTransmitFeedback => 'Transmettre les Commentaires';

  @override
  String get reviewPromptQualityHeadline => 'Contrôle Qualité';

  @override
  String get reviewPromptQualitySubtext =>
      'L\'IA aide-t-elle la fluidité de votre conversation ?';

  @override
  String get reviewPromptQualityPositive => 'Les résultats sont Solides';

  @override
  String get reviewPromptSystemHeadline => 'État du Système';

  @override
  String get reviewPromptSystemSubtext =>
      'Vous avez généré plus de 50 réponses. Toujours précis ?';

  @override
  String get reviewPromptSystemPositive => 'L\'analyse est Parfaite';

  @override
  String get reviewPromptRedemptionHeadline =>
      'L\'analyse s\'est-elle améliorée ?';

  @override
  String get reviewPromptRedemptionSubtext =>
      'Dites-nous si les réponses sont meilleures maintenant.';

  @override
  String get reviewPromptRedemptionPositive => 'Oui, Bien Meilleur';

  @override
  String reviewPulseFeedbackTitle(Object tag) {
    return 'Commentaires Rapides - $tag';
  }

  @override
  String get thinkingExtractionReadingConversation =>
      'Lecture de la conversation';

  @override
  String get thinkingExtractionPickingContext => 'Analyse du contexte';

  @override
  String get thinkingExtractionUnderstandingVibe =>
      'Compréhension de l\'ambiance';

  @override
  String get thinkingReplyCraftingPerfectReply =>
      'Création de la réponse parfaite';

  @override
  String get thinkingReplyReadingBetweenLines => 'Lecture entre les lignes';

  @override
  String get thinkingReplyFindingRightWords => 'Recherche des mots justes';

  @override
  String get thinkingReplyAnalyzingEnergy => 'Analyse de son énergie';

  @override
  String get thinkingReplyWorkingMagic => 'Un peu de magie en cours';

  @override
  String get thinkingOpenerFindingStarters =>
      'Recherche de sujets de conversation';

  @override
  String get thinkingOpenerCraftingOpeningLine =>
      'Création de votre phrase d\'accroche';

  @override
  String get thinkingOpenerStudyingProfile => 'Étude de son profil';

  @override
  String get thinkingOpenerLookingCommonGround => 'Recherche de points communs';

  @override
  String get thinkingOpenerCreatingFirstImpression =>
      'Création de votre première impression';

  @override
  String get thinkingRecommendedLoadingOpeners =>
      'Chargement des accroches prouvées';

  @override
  String get thinkingRecommendedGrabbingGoodStuff =>
      'Sélection des meilleures options';

  @override
  String get pricingBillingUnavailable =>
      'La facturation n\'est pas disponible sur cet appareil.';

  @override
  String get pricingLoadingProductsTryAgain =>
      'Chargement des produits. Veuillez réessayer.';

  @override
  String get pricingProductUnavailable =>
      'Produit non disponible. Veuillez réessayer plus tard.';

  @override
  String get pricingSignInRequiredTitle => 'Connexion Requise';

  @override
  String get pricingSignInRequiredMessage =>
      'Veuillez vous connecter pour démarrer votre abonnement.';

  @override
  String get pricingPaymentDeclinedToast =>
      'Paiement refusé. Veuillez essayer une autre carte.';

  @override
  String get pricingPaymentDeclinedTitle => 'Paiement refusé';

  @override
  String get pricingPaymentDeclinedMessage =>
      'Votre paiement a été refusé. Veuillez essayer une autre méthode.';

  @override
  String get pricingTryAnotherCard => 'Essayer une autre carte';

  @override
  String get pricingVerificationFailed =>
      'Échec de la vérification de l\'achat.';

  @override
  String get pricingPreviousPurchaseApproved =>
      'Votre achat précédent a été approuvé et votre abonnement est actif.';

  @override
  String get pricingProductNotFound => 'Produit introuvable';

  @override
  String get pricingCouldNotStartPurchaseFlow =>
      'Impossible de démarrer le processus d\'achat';

  @override
  String pricingPurchaseError(Object error) {
    return 'Erreur d\'achat : $error';
  }

  @override
  String pricingPurchaseFailed(Object reason) {
    return 'Échec de l\'achat : $reason';
  }

  @override
  String get pricingRefreshing => 'Actualisation...';

  @override
  String get pricingRefreshPurchases => 'Actualiser les achats';

  @override
  String get pricingHeroLabel => 'ACCÈS ÉLITE';

  @override
  String get pricingHeroTitle => 'L\'AVANTAGE\nDÉLOYAL.';

  @override
  String get pricingHeroSubtitle =>
      'Débloquez la seule IA capable d\'une analyse psychologique profonde.';

  @override
  String get pricingFeatureReasoningTitle => 'Intelligence Haut Niveau';

  @override
  String get pricingFeatureReasoningSubtitle =>
      'Des réponses irrésistibles et percutantes, propulsées par notre IA la plus avancée.';

  @override
  String get pricingFeatureReasoningBadge => 'MODÈLE PRO';

  @override
  String get pricingFeatureFlowTitle => 'Le Playbook du Coach';

  @override
  String get pricingFeatureFlowSubtitle =>
      '20+ accroches éprouvées à fort taux de réponse, sélectionnées par des coaches dating élite.';

  @override
  String get pricingFeatureTonalityTitle => 'Zéro Limites';

  @override
  String get pricingFeatureTonalitySubtitle =>
      'Réponses et accroches illimitées. Ne heurtez plus jamais une barrière de paiement.';

  @override
  String get pricingFeatureContextTitle => 'Le Cercle Intérieur';

  @override
  String get pricingFeatureContextSubtitle =>
      'Accès à une communauté privée pour des avis de profil et des conseils en temps réel.';

  @override
  String get pricingWeeklyFallback => '6,99 \$ / semaine';

  @override
  String pricingWeeklyPrice(Object price) {
    return '$price / semaine';
  }

  @override
  String get pricingCoffeeLine =>
      'Seulement \$0.99 par jour. Résiliable à tout moment.';

  @override
  String get pricingUnlockEliteAccess => 'Débloquer l\'Accès Élite';

  @override
  String get pricingCancelAnytime =>
      'Annulez à tout moment via Google Play. Traitement sécurisé.';

  @override
  String get pricingSocialProof =>
      'Approuvé par plus de 10 000 hommes pour obtenir plus de rendez-vous.';

  @override
  String policyEffectiveDate(Object effectiveDate) {
    return 'Date d\'entrée en vigueur : $effectiveDate';
  }

  @override
  String get policyPrivacyTitle => 'Politique de Confidentialité';

  @override
  String get policyPrivacyEffectiveDate => '30 janvier 2026';

  @override
  String get policyPrivacySectionIntroTitle => 'Introduction';

  @override
  String get policyPrivacySectionIntroContent =>
      'FlirtFix s\'engage à protéger votre vie privée. Cette politique explique comment nous traitons vos informations.';

  @override
  String get policyPrivacySectionInfoCollectTitle =>
      '1. Informations que Nous Collectons';

  @override
  String get policyPrivacySectionInfoCollectContent =>
      'Nous collectons : e-mail, données de conversation, captures d\'écran téléchargées et informations de l\'appareil.';

  @override
  String get policyPrivacySectionInfoUseTitle =>
      '2. Comment Nous Utilisons Vos Informations';

  @override
  String get policyPrivacySectionInfoUseContent =>
      'Pour fournir l\'IA, gérer votre abonnement, traiter les paiements et améliorer l\'application.';

  @override
  String get policyPrivacySectionThirdPartyTitle => '3. Services Tiers';

  @override
  String get policyPrivacySectionThirdPartyContent =>
      'Nous utilisons Firebase et Google Play Billing qui ont leurs propres politiques de confidentialité.';

  @override
  String get policyPrivacySectionStorageSecurityTitle =>
      '4. Stockage et Sécurité des Données';

  @override
  String get policyPrivacySectionStorageSecurityContent =>
      'Vos données sont stockées de manière sécurisée (chiffrement HTTPS, authentification par jeton).';

  @override
  String get policyPrivacySectionRetentionTitle =>
      '5. Conservation des Données';

  @override
  String get policyPrivacySectionRetentionContent =>
      'Si vous supprimez votre compte, les images téléchargées et l\'historique sont définitivement effacés.';

  @override
  String get policyPrivacySectionRightsTitle => '6. Vos Droits';

  @override
  String get policyPrivacySectionRightsContent =>
      'Vous pouvez demander l\'accès ou la suppression de vos données via support@tryagaintext.com.';

  @override
  String get policyPrivacySectionComplianceTitle => '7. Conformité';

  @override
  String get policyPrivacySectionComplianceContent =>
      'Nous traitons les données personnellement légalement et ne les vendons pas.';

  @override
  String get policyPrivacySectionCookiesTitle => '8. Cookies et Suivi';

  @override
  String get policyPrivacySectionCookiesContent =>
      'L\'application utilise Firebase Analytics pour suivre les modèles d\'utilisation.';

  @override
  String get policyPrivacySectionChildrenTitle =>
      '9. Confidentialité des Enfants';

  @override
  String get policyPrivacySectionChildrenContent =>
      'FlirtFix est réservé aux utilisateurs de 18 ans et plus.';

  @override
  String get policyPrivacySectionSharingTitle => '10. Partage des Données';

  @override
  String get policyPrivacySectionSharingContent =>
      'Nous ne vendons pas vos informations personnelles.';

  @override
  String get policyPrivacySectionTransfersTitle =>
      '11. Transferts Internationaux';

  @override
  String get policyPrivacySectionTransfersContent =>
      'Vos informations peuvent être traitées dans des pays autres que le vôtre.';

  @override
  String get policyPrivacySectionChangesTitle => '12. Modifications';

  @override
  String get policyPrivacySectionChangesContent =>
      'L\'utilisation continue après des modifications vaut acceptation.';

  @override
  String get policyPrivacySectionContactTitle => '13. Nous Contacter';

  @override
  String get policyPrivacySectionContactContent =>
      'Questions : support@tryagaintext.com.';

  @override
  String get policyTermsTitle => 'Conditions d\'Utilisation';

  @override
  String get policyTermsEffectiveDate => '30 janvier 2026';

  @override
  String get policyTermsSectionAgreementTitle => 'Acceptation des Conditions';

  @override
  String get policyTermsSectionAgreementContent =>
      'En utilisant FlirtFix, vous acceptez ces Conditions d\'Utilisation.';

  @override
  String get policyTermsSectionServiceDescriptionTitle =>
      '1. Description du Service';

  @override
  String get policyTermsSectionServiceDescriptionContent =>
      'FlirtFix fournit une assistance conversationnelle par IA soumise à des limites d\'utilisation équitable.';

  @override
  String get policyTermsSectionAcceptableUseTitle =>
      '2. Utilisation Acceptable';

  @override
  String get policyTermsSectionAcceptableUseContent =>
      'Pas de harcèlement, d\'activité illégale ou de revente commerciale du contenu généré.';

  @override
  String get policyTermsSectionFairUseTitle =>
      '3. Politique d\'Utilisation Équitable';

  @override
  String get policyTermsSectionFairUseContent =>
      'Les plans illimités sont soumis à des contrôles anti-abus.';

  @override
  String get policyTermsSectionRegistrationTitle => '4. Inscription';

  @override
  String get policyTermsSectionRegistrationContent =>
      'Vous devez avoir au moins 18 ans et protéger vos identifiants.';

  @override
  String get policyTermsSectionSubscriptionTitle => '5. Abonnements';

  @override
  String get policyTermsSectionSubscriptionContent =>
      'Facturé hebdomadairement via Google Play avec renouvellement automatique.';

  @override
  String get policyTermsSectionIpRightsTitle => '6. Propriété Intellectuelle';

  @override
  String get policyTermsSectionIpRightsContent =>
      'Vous conservez la propriété de votre contenu. FlirtFix conserve la sienne.';

  @override
  String get policyTermsSectionDisclaimerTitle => '7. Exclusion de Garanties';

  @override
  String get policyTermsSectionDisclaimerContent =>
      'Les suggestions de l\'IA sont des conseils et ne garantissent pas de résultats.';

  @override
  String get policyTermsSectionLiabilityTitle => '8. Limite de Responsabilité';

  @override
  String get policyTermsSectionLiabilityContent =>
      'La responsabilité est limitée aux montants payés au cours des 12 derniers mois.';

  @override
  String get policyTermsSectionAvailabilityTitle => '9. Disponibilité';

  @override
  String get policyTermsSectionAvailabilityContent =>
      'Nous ne garantissons pas une disponibilité ininterrompue.';

  @override
  String get policyTermsSectionTerminationTitle => '10. Résiliation';

  @override
  String get policyTermsSectionTerminationContent =>
      'Nous pouvons suspendre l\'accès pour violation des politiques.';

  @override
  String get policyTermsSectionLawTitle => '11. Loi Applicable';

  @override
  String get policyTermsSectionLawContent =>
      'Ces conditions sont régies par les lois des États-Unis.';

  @override
  String get policyTermsSectionDisputeTitle => '12. Résolution des Litiges';

  @override
  String get policyTermsSectionDisputeContent =>
      'Contactez le support pour une résolution informelle d\'abord.';

  @override
  String get policyTermsSectionChangesTitle => '13. Modifications';

  @override
  String get policyTermsSectionChangesContent =>
      'L\'utilisation continue indique l\'acceptation des nouvelles conditions.';

  @override
  String get policyTermsSectionSeverabilityTitle => '14. Divisibilité';

  @override
  String get policyTermsSectionSeverabilityContent =>
      'Si une disposition est inapplicable, les autres restent en vigueur.';

  @override
  String get policyTermsSectionEntireAgreementTitle => '15. Accord Complet';

  @override
  String get policyTermsSectionEntireAgreementContent =>
      'Ces Conditions et Politiques forment l\'accord complet.';

  @override
  String get policyTermsSectionContactTitle => '16. Contact';

  @override
  String get policyTermsSectionContactContent =>
      'Support : support@tryagaintext.com.';

  @override
  String get policyRefundTitle => 'Politique de Remboursement';

  @override
  String get policyRefundEffectiveDate => '30 janvier 2026';

  @override
  String get policyRefundSectionOverviewTitle => 'Aperçu';

  @override
  String get policyRefundSectionOverviewContent =>
      'Les remboursements sont traités via les règles de Google Play Billing.';

  @override
  String get policyRefundSectionSubscriptionRefundsTitle =>
      '1. Remboursements d\'Abonnements';

  @override
  String get policyRefundSectionSubscriptionRefundsContent =>
      'Soumis à la fenêtre autorisée de la plateforme et à l\'examen de l\'utilisation.';

  @override
  String get policyRefundSectionGooglePlayProcessTitle =>
      '2. Processus Google Play';

  @override
  String get policyRefundSectionGooglePlayProcessContent =>
      'Utilisez les pages d\'aide de votre compte Google Play pour demander un remboursement.';

  @override
  String get policyRefundSectionCreditRefundsTitle => '3. Achats de Crédits';

  @override
  String get policyRefundSectionCreditRefundsContent =>
      'Généralement non remboursables sauf échec technique confirmé.';

  @override
  String get policyRefundSectionEligibilityTitle => '4. Éligibilité';

  @override
  String get policyRefundSectionEligibilityContent =>
      'La fraude ou les violations de la politique annulent l\'éligibilité.';

  @override
  String get policyRefundSectionCancellationTitle => '5. Annulation';

  @override
  String get policyRefundSectionCancellationContent =>
      'Vous pouvez annuler à tout moment via Google Play.';

  @override
  String get policyRefundSectionBillingIssuesTitle =>
      '6. Problèmes de Facturation';

  @override
  String get policyRefundSectionBillingIssuesContent =>
      'Contactez support@tryagaintext.com pour les frais inattendus.';

  @override
  String get policyRefundSectionProcessingTimeTitle => '7. Temps de Traitement';

  @override
  String get policyRefundSectionProcessingTimeContent =>
      'Peut prendre plusieurs jours ouvrables.';

  @override
  String get policyRefundSectionExceptionsTitle => '8. Exceptions';

  @override
  String get policyRefundSectionExceptionsContent =>
      'Les pannes prolongées peuvent faire l\'objet d\'exceptions.';

  @override
  String get policyRefundSectionFairUseAbuseTitle => '9. Abus';

  @override
  String get policyRefundSectionFairUseAbuseContent =>
      'Les abus de remboursement entraîneront une restriction du compte.';

  @override
  String get policyRefundSectionThirdPartyIssuesTitle =>
      '10. Problèmes de Paiement Tiers';

  @override
  String get policyRefundSectionThirdPartyIssuesContent =>
      'Google Play a l\'autorité finale sur les litiges.';

  @override
  String get policyRefundSectionNoRefundScenariosTitle =>
      '11. Scénarios Sans Remboursement';

  @override
  String get policyRefundSectionNoRefundScenariosContent =>
      'Pas de remboursement pour changement d\'avis après une utilisation substantielle.';

  @override
  String get policyRefundSectionDisputeTitle => '12. Résolution des Litiges';

  @override
  String get policyRefundSectionDisputeContent =>
      'Contactez le support si un remboursement est refusé.';

  @override
  String get policyRefundSectionPolicyChangesTitle => '13. Modifications';

  @override
  String get policyRefundSectionPolicyChangesContent =>
      'Les changements seront publiés dans l\'application.';

  @override
  String get policyRefundSectionContactTitle => '14. Contact';

  @override
  String get policyRefundSectionContactContent =>
      'E-mail : support@tryagaintext.com.';

  @override
  String get communityTitle => 'Communauté';

  @override
  String get communityCategoryAll => 'Tout';

  @override
  String get communityCategoryHelpMeReply => 'Aidez-moi à Répondre 🚨';

  @override
  String get communityCategoryDatingAdvice => 'Conseils Rencontres 💘';

  @override
  String get communityCategoryRateMyProfile => 'Évaluez Mon Profil 📸';

  @override
  String get communityCategoryWins => 'Victoires 🏆';

  @override
  String get communitySignInToCreatePost =>
      'Connectez-vous pour créer une publication.';

  @override
  String get communityCouldNotLoadPosts =>
      'Impossible de charger les publications.';

  @override
  String get communityTryAgain => 'Réessayer';

  @override
  String get communityNoPostsYet => 'Pas encore de publications';

  @override
  String get communityBeTheFirst =>
      'Soyez le premier à partager quelque chose !';

  @override
  String get communitySignInToVote => 'Connectez-vous pour voter.';

  @override
  String get communitySortPostsTitle => 'Trier les publications';

  @override
  String get communitySortTooltip => 'Trier';

  @override
  String get communitySortHot => 'Populaire';

  @override
  String get communitySortNew => 'Nouveau';

  @override
  String get communitySortTop => 'Top';

  @override
  String get communitySignInToComment => 'Connectez-vous pour commenter.';

  @override
  String get communitySignInToLikeComments =>
      'Connectez-vous pour aimer les commentaires.';

  @override
  String get communityDeleteCommentTitle => 'Supprimer le commentaire ?';

  @override
  String get communityDeletePostTitle => 'Supprimer la publication ?';

  @override
  String get communityCannotBeUndone => 'Cette action est irréversible.';

  @override
  String get communityDelete => 'Supprimer';

  @override
  String get communityUnableToLoadImage => 'Impossible de charger l\'image';

  @override
  String get communityCloseImagePreview => 'Fermer l\'aperçu de l\'image';

  @override
  String communityCommentsCount(int count) {
    return 'Commentaires ($count)';
  }

  @override
  String get communityNoCommentsYet => 'Pas encore de commentaires';

  @override
  String get communityStartTheConversation => 'Lancez la conversation !';

  @override
  String get communityAddAComment => 'Ajouter un commentaire...';

  @override
  String get communitySignInToCommentHint => 'Connectez-vous pour commenter';

  @override
  String get communityProBadge => 'PRO';

  @override
  String get communityOpBadge => 'OP';

  @override
  String get communityUnableToOpenPost =>
      'Impossible d\'ouvrir cette publication pour le moment.';

  @override
  String get createPostAdjustPhoto => 'Ajuster la Photo';

  @override
  String get createPostDone => 'Terminé';

  @override
  String get createPostValidationTitle => 'Veuillez ajouter un titre.';

  @override
  String get createPostValidationContent => 'Veuillez ajouter du contenu.';

  @override
  String get createPostValidationCategory => 'Veuillez choisir une catégorie.';

  @override
  String get createPostPostButton => 'Publier';

  @override
  String get createPostCategoryLabel => 'Catégorie';

  @override
  String get createPostTitleLabel => 'Titre';

  @override
  String get createPostTitleHint => 'Qu\'avez-vous en tête ?';

  @override
  String get createPostContentLabel => 'Que s\'est-il passé ?';

  @override
  String get createPostContentHint =>
      'Partagez votre histoire, conseil ou question...';

  @override
  String get createPostCropPhoto => 'Recadrer la photo';

  @override
  String get createPostBlurSensitiveInfo => 'Flouter les infos sensibles';

  @override
  String get createPostProcessingPhoto => 'Traitement de la photo...';

  @override
  String get createPostAddPhoto => 'Ajouter une Photo';

  @override
  String get createPostChangePhoto => 'Changer la Photo';

  @override
  String get createPostPhotoTip =>
      'Conseil : Recadrez et floutez les infos sensibles avant de publier.';

  @override
  String get createPostHideUsername => 'Masquer mon nom d\'utilisateur';

  @override
  String get createPostPostAnonymously => 'Publier anonymement';

  @override
  String get createPostAddPoll => 'Ajouter un Sondage';

  @override
  String get createPostPollSubtitle => '\"Envoie-le\" ou \"Ne l\'envoie pas\"';

  @override
  String get communityFeaturedBadge => 'EN VEDETTE';

  @override
  String get communityTrendingBadge => 'TENDANCE';

  @override
  String get communityNewBadge => 'NOUVEAU';

  @override
  String get communityTimeJustNow => 'à l\'instant';

  @override
  String communityTimeMinutesAgo(int minutes) {
    return 'il y a ${minutes}m';
  }

  @override
  String communityTimeHoursAgo(int hours) {
    return 'il y a ${hours}h';
  }

  @override
  String communityTimeDaysAgo(int days) {
    return 'il y a ${days}j';
  }

  @override
  String communityTimeWeeksAgo(int weeks) {
    return 'il y a ${weeks}sem';
  }

  @override
  String get communityAnonymous => 'Anonyme';

  @override
  String get navHome => 'Accueil';
}
