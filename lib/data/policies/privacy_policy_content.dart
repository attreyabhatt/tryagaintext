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

const String privacyPolicyEffectiveDate = 'January 30, 2026';

const List<PolicySection> privacyPolicySections = [
  PolicySection(
    title: 'Privacy Policy',
    content: '',
    isHeading: true,
  ),
  PolicySection(
    title: 'Introduction',
    content:
        'FlirtFix ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application FlirtFix (the "App"). Please read this privacy policy carefully. If you do not agree with the terms of this privacy policy, please do not access the App.',
  ),
  PolicySection(
    title: '1. Information We Collect',
    content:
        'We collect information that you provide directly to us when using FlirtFix:\n\n• Account Information: Email address, username, and password (hashed and securely stored)\n\n• Conversation Data: Messages and conversation text you submit for AI analysis\n\n• Uploaded Content: Screenshots of conversations and profile images you upload for analysis\n\n• Device Information: Android Device ID for device identification\n\n• Usage Data: Information about how you interact with our App, including features used, actions taken, and time spent\n\n• Payment Information: Purchase tokens, transaction IDs, and subscription status through Google Play Billing (we do not store credit card information)',
  ),
  PolicySection(
    title: '2. How We Use Your Information',
    content:
        'We use the information we collect to:\n\n• Provide AI-powered conversation assistance and suggestions\n\n• Analyze uploaded images and screenshots using AI technology\n\n• Manage your account and subscription\n\n• Process payments and billing\n\n• Improve and optimize our App and services\n\n• Communicate with you about updates, features, and support\n\n• Enforce our fair use policy and terms of service\n\n• Comply with legal obligations',
  ),
  PolicySection(
    title: '3. Third-Party Services',
    content:
        'We use the following third-party services that may collect information about you:\n\n• Firebase Analytics: For app usage analytics and user behavior insights\n\n• Firebase Crashlytics: For crash reporting and error tracking to improve app stability\n\n• Google Play Billing: For processing subscriptions and in-app purchases\n\nThese services have their own privacy policies addressing how they use such information.',
  ),
  PolicySection(
    title: '4. Data Storage and Security',
    content:
        'Your data is stored both locally on your device and on our secure servers:\n\n• Local Storage: Authentication tokens, user profile data, credits, and preferences are stored locally using device-encrypted storage (SharedPreferences)\n\n• Server Storage: Account information, conversation history, and uploaded images are stored on our backend servers with industry-standard security measures\n\n• Security Measures: We use token-based authentication, HTTPS encryption for all data transmission, and implement appropriate technical and organizational measures to protect your data',
  ),
  PolicySection(
    title: '5. Data Retention',
    content:
        'We retain your personal information for as long as your account is active or as needed to provide you services. When you delete your account:\n\n• All personal information is permanently removed from our servers\n\n• Uploaded images and conversation history are deleted\n\n• Local data is cleared from your device\n\n• Some data may be retained in backup systems for up to 30 days for recovery purposes',
  ),
  PolicySection(
    title: '6. Your Rights',
    content:
        'You have the following rights regarding your personal information:\n\n• Access: You can request a copy of your personal data\n\n• Correction: You can update or correct your information through your profile\n\n• Deletion: You can request deletion of your account and all associated data\n\n• Portability: You can request your data in a machine-readable format\n\n• Objection: You can object to certain processing of your data\n\nTo exercise these rights, contact us at support@tryagaintext.com',
  ),
  PolicySection(
    title: '7. GDPR and CCPA Compliance',
    content:
        'For users in the European Union and California:\n\n• We process personal data lawfully, fairly, and transparently\n\n• We collect data only for specified, explicit, and legitimate purposes\n\n• We limit data collection to what is necessary\n\n• We do not sell your personal information\n\n• You have the right to opt-out of data collection (though this may limit app functionality)\n\n• You may request disclosure of categories of personal information collected',
  ),
  PolicySection(
    title: '8. Cookies and Tracking',
    content:
        'The App uses Firebase Analytics which may use cookies and similar technologies to:\n\n• Track user sessions and app usage patterns\n\n• Analyze feature performance and user engagement\n\n• Identify and fix technical issues\n\nYou cannot disable analytics tracking without affecting app functionality.',
  ),
  PolicySection(
    title: '9. Children\'s Privacy',
    content:
        'FlirtFix is intended for users aged 18 and older. We do not knowingly collect personal information from anyone under 18 years of age. If you become aware that a child has provided us with personal information, please contact us at support@tryagaintext.com',
  ),
  PolicySection(
    title: '10. Data Sharing and Disclosure',
    content:
        'We do not sell, trade, or rent your personal information. We may share your information only in the following circumstances:\n\n• Service Providers: With third-party vendors who perform services on our behalf (Firebase, Google Play)\n\n• Legal Requirements: When required by law, subpoena, or legal process\n\n• Protection of Rights: To protect our rights, privacy, safety, or property\n\n• Business Transfers: In connection with a merger, sale, or asset transfer',
  ),
  PolicySection(
    title: '11. International Data Transfers',
    content:
        'Your information may be transferred to and processed in countries other than your country of residence. These countries may have data protection laws different from your jurisdiction. By using FlirtFix, you consent to such transfers.',
  ),
  PolicySection(
    title: '12. Changes to This Privacy Policy',
    content:
        'We may update this Privacy Policy from time to time. We will notify you of any changes by:\n\n• Updating the "Effective Date" at the top of this policy\n\n• Posting the new policy in the App\n\n• Sending you an email notification for material changes\n\nYour continued use of the App after changes become effective constitutes acceptance of the revised policy.',
  ),
  PolicySection(
    title: '13. Contact Us',
    content:
        'If you have questions or concerns about this Privacy Policy, please contact us:\n\nEmail: support@tryagaintext.com\n\nCompany: FlirtFix\n\nWe will respond to your inquiry within 30 days.',
  ),
];
