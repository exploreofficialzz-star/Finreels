import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalScreen(
      title: 'Privacy Policy',
      lastUpdated: 'July 2026',
      sections: [
        _LegalSection(
          heading: 'Introduction',
          body:
              'FinReels ("we", "our", or "us") is operated by chAs Tech Group. '
              'This Privacy Policy explains how we collect, use, and protect your '
              'information when you use the FinReels mobile application. By using '
              'FinReels, you agree to the practices described in this policy.',
        ),
        _LegalSection(
          heading: '1. Information We Collect',
          body:
              'FinReels is designed with your privacy in mind. We collect minimal '
              'data to operate the app:\n\n'
              '• Device Information — Device type, operating system version, and '
              'app version to ensure compatibility and diagnose issues.\n\n'
              '• Usage Analytics — Aggregated, anonymised data about which '
              'content is viewed, to help us improve the feed quality. This data '
              'cannot be used to identify you personally.\n\n'
              '• Notification Preferences — Whether you have enabled or disabled '
              'push notifications. This preference is stored locally on your device.\n\n'
              '• Purchase Records — If you purchase an ad-free period, the '
              'payment is processed by Google Play (or, for the app when '
              'installed outside the Play Store, by Paystack). We only '
              'receive a confirmation of the purchase; we do not store your '
              'payment card details.\n\n'
              'We do not require account registration. We do not collect your '
              'name, email address, or any other personally identifiable '
              'information unless you contact us directly, or unless you '
              'choose to pay via Paystack (which requires an email address '
              'to process the transaction — see Section 3 below).',
        ),
        _LegalSection(
          heading: '2. How We Use Your Information',
          body:
              'The information we collect is used solely to:\n\n'
              '• Deliver and improve the FinReels content feed.\n'
              '• Serve relevant advertisements via Google AdMob and its '
              'mediation partners, including Unity Ads (free tier only).\n'
              '• Process and verify in-app purchases.\n'
              '• Diagnose crashes and performance issues.\n'
              '• Respond to support requests you send us.',
        ),
        _LegalSection(
          heading: '3. Advertising & Third-Party SDKs',
          body:
              'Free users see ads delivered by Google AdMob. To maximise '
              'how often a relevant ad is available, AdMob also uses '
              'mediation — it may route some ad requests to a second '
              'advertising network, Unity Ads, when that network can offer '
              'a better-performing ad. Both AdMob and Unity Ads may collect '
              'and process certain device identifiers to serve personalised '
              'ads in accordance with their own respective privacy '
              'policies. Where required by applicable law (for example in '
              'the EEA, UK, and Switzerland), we ask for your consent to '
              'this via a consent form shown on first launch, and you can '
              'change your choice at any time from Settings → Privacy '
              'Options. You can also opt out of personalised advertising '
              'through your device\'s ad settings.\n\n'
              'We also use the following third-party services, each governed by '
              'their own privacy policies:\n\n'
              '• Google AdMob — advertising and ad mediation\n'
              '• Unity Ads — advertising (served via AdMob mediation)\n'
              '• Google Play In-App Purchases — payment processing for '
              'purchases made when FinReels is installed from the Play '
              'Store\n'
              '• Paystack — payment processing for purchases made when '
              'FinReels is installed outside the Play Store (for example, '
              'directly from our website). Paystack receives the email '
              'address and payment details you provide it directly; we do '
              'not see or store your card details\n'
              '• YouTube — FinReels displays publicly available video '
              'information (titles, thumbnails, descriptions) from '
              'YouTube channels\' public RSS feeds, and links out to the '
              'YouTube app or website to actually play videos',
        ),
        _LegalSection(
          heading: '4. Data Retention',
          body:
              'Analytics data is retained in aggregated form for up to 12 months. '
              'Purchase records are retained for as long as your purchased '
              'ad-free period is active and for up to 12 months afterwards '
              'for accounting purposes. Locally stored preferences (e.g. '
              'notification settings, saved videos) remain on your device '
              'until the app is uninstalled.',
        ),
        _LegalSection(
          heading: '5. Children\'s Privacy',
          body:
              'FinReels is not directed at children under the age of 13. We do '
              'not knowingly collect personal information from children. If you '
              'believe a child has provided us with personal information, please '
              'contact us and we will delete it promptly.',
        ),
        _LegalSection(
          heading: '6. Data Security',
          body:
              'We implement industry-standard technical and organisational measures '
              'to protect your information. However, no method of electronic '
              'transmission or storage is 100% secure. We cannot guarantee '
              'absolute security.',
        ),
        _LegalSection(
          heading: '7. Your Rights',
          body:
              'Depending on your jurisdiction, you may have the right to:\n\n'
              '• Access the personal data we hold about you.\n'
              '• Request correction of inaccurate data.\n'
              '• Request deletion of your data.\n'
              '• Opt out of personalised advertising.\n\n'
              'To exercise any of these rights, contact us at '
              'chastechnologiesllc@gmail.com.',
        ),
        _LegalSection(
          heading: '8. Changes to This Policy',
          body:
              'We may update this Privacy Policy from time to time. We will '
              'notify you of significant changes by updating the "Last Updated" '
              'date at the top of this page. Continued use of FinReels after '
              'changes constitutes your acceptance of the revised policy.',
        ),
        _LegalSection(
          heading: '9. Contact Us',
          body:
              'If you have any questions about this Privacy Policy, please '
              'contact us at:\n\nchastechnologiesllc@gmail.com',
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Terms of Service screen
// ─────────────────────────────────────────────────────────────────────────────

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalScreen(
      title: 'Terms of Service',
      lastUpdated: 'July 2026',
      sections: [
        _LegalSection(
          heading: 'Introduction',
          body:
              'Welcome to FinReels. By downloading or using this app, you agree '
              'to be bound by these Terms of Service ("Terms"). Please read them '
              'carefully. If you do not agree, do not use FinReels.',
        ),
        _LegalSection(
          heading: '1. Use of the App',
          body:
              'FinReels is a financial literacy content aggregator. You may use '
              'the app for personal, non-commercial purposes only. You agree not to:\n\n'
              '• Reproduce, distribute, or sell any content from FinReels.\n'
              '• Attempt to reverse-engineer, decompile, or tamper with the app.\n'
              '• Use the app for any unlawful or fraudulent purpose.\n'
              '• Circumvent or disable any advertising or purchase system.',
        ),
        _LegalSection(
          heading: '2. Content',
          body:
              'FinReels aggregates publicly available financial education content '
              'from YouTube and other sources. All video content, thumbnails, and '
              'channel names are the intellectual property of their respective '
              'creators and are subject to their own terms and licences.\n\n'
              'We do not host, upload, or claim ownership of any video content '
              'displayed in the app. FinReels accesses content via publicly '
              'available RSS feeds in compliance with the respective platform\'s '
              'terms of service.',
        ),
        _LegalSection(
          heading: '3. Purchases & Payments',
          body:
              'FinReels offers optional one-time purchases (Ad-Free periods). '
              'If FinReels is installed from the Google Play Store, purchases '
              'are processed through Google Play and are subject to Google '
              'Play\'s billing terms. If FinReels is installed outside the '
              'Play Store (for example, directly from our website), purchases '
              'are instead processed through Paystack.\n\n'
              '• Each purchase grants ad-free access for the selected period '
              '(1 day, 7 days, or 31 days) from the date of purchase.\n'
              '• These are one-time payments, not subscriptions — they do '
              'not renew or recur automatically.\n'
              '• All sales are final. Refunds for Google Play purchases are '
              'subject to Google Play\'s refund policy; refunds for Paystack '
              'purchases are subject to Paystack\'s and our own refund '
              'practices — contact us using the details in Section 9 of our '
              'Privacy Policy.\n'
              '• "Restore Previous Purchase" in Settings applies to Google '
              'Play purchases only, and reactivates an unexpired ad-free '
              'period after reinstalling the app on the same Google account.',
        ),
        _LegalSection(
          heading: '4. Intellectual Property',
          body:
              'The FinReels app, including its design, logo, original code, and '
              'branding, is owned by chAs Tech Group and protected by applicable '
              'intellectual property laws. You may not reproduce or use our '
              'branding without prior written permission.',
        ),
        _LegalSection(
          heading: '5. Disclaimer of Warranties',
          body:
              'FinReels is provided "as is" without warranty of any kind. We do '
              'not guarantee that the app will be uninterrupted, error-free, or '
              'free of viruses. We make no representations about the accuracy or '
              'completeness of any content displayed.',
        ),
        _LegalSection(
          heading: '6. Limitation of Liability',
          body:
              'To the maximum extent permitted by law, chAs Tech Group shall not '
              'be liable for any indirect, incidental, special, or consequential '
              'damages arising from your use of, or inability to use, FinReels — '
              'including any financial decisions made based on content viewed '
              'in the app.',
        ),
        _LegalSection(
          heading: '7. Termination',
          body:
              'We reserve the right to suspend or terminate your access to '
              'FinReels at any time, without notice, if we believe you have '
              'violated these Terms.',
        ),
        _LegalSection(
          heading: '8. Changes to These Terms',
          body:
              'We may update these Terms from time to time. Continued use of '
              'FinReels after changes take effect constitutes your acceptance '
              'of the revised Terms.',
        ),
        _LegalSection(
          heading: '9. Contact',
          body:
              'For questions about these Terms, contact us at:\n\n'
              'chastechnologiesllc@gmail.com',
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Content Disclaimer screen
// ─────────────────────────────────────────────────────────────────────────────

class ContentDisclaimerScreen extends StatelessWidget {
  const ContentDisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalScreen(
      title: 'Content Disclaimer',
      lastUpdated: 'May 2025',
      sections: [
        _LegalSection(
          heading: 'Important Notice',
          body:
              'Please read this disclaimer carefully before using FinReels. '
              'All content available through FinReels — including videos, '
              'shorts, blogs, and books — is provided for educational and '
              'informational purposes only.',
        ),
        _LegalSection(
          heading: '1. Not Financial Advice',
          body:
              'Nothing in FinReels constitutes financial, investment, tax, legal, '
              'or accounting advice. The content is designed to improve general '
              'financial literacy and awareness. It does not take into account '
              'your personal financial situation, objectives, or needs.\n\n'
              'You should not rely on any content in this app as a basis for '
              'making financial or investment decisions. Always consult a '
              'qualified financial professional before making any investment or '
              'financial decision.',
        ),
        _LegalSection(
          heading: '2. Third-Party Content',
          body:
              'FinReels aggregates content created by independent third-party '
              'creators and channels. We do not endorse, verify, or take '
              'responsibility for the accuracy, completeness, or suitability of '
              'any third-party content shown in the app.\n\n'
              'Opinions expressed by content creators are their own and do not '
              'necessarily reflect the views of chAs Tech Group or FinReels.',
        ),
        _LegalSection(
          heading: '3. No Guarantee of Results',
          body:
              'Past performance of any investment strategy, market, or financial '
              'product mentioned in content shown on FinReels is not indicative '
              'of future results. Investing involves risk, including the possible '
              'loss of principal.',
        ),
        _LegalSection(
          heading: '4. Accuracy of Information',
          body:
              'Financial laws, regulations, tax rules, and market conditions '
              'change frequently. Content displayed in FinReels may not reflect '
              'the most current developments. We make no warranty, express or '
              'implied, regarding the accuracy, timeliness, or completeness of '
              'any information provided.',
        ),
        _LegalSection(
          heading: '5. External Links & Sources',
          body:
              'Content in FinReels may reference or link to external websites '
              'and resources. We are not responsible for the content, privacy '
              'practices, or accuracy of any external sites. Accessing external '
              'links is at your own risk.',
        ),
        _LegalSection(
          heading: '6. Limitation of Liability',
          body:
              'chAs Tech Group, its developers, and affiliates shall not be '
              'held liable for any financial loss, damage, or negative outcome '
              'resulting from reliance on content viewed through FinReels. '
              'Use of this app is entirely at your own risk.',
        ),
        _LegalSection(
          heading: '7. Contact',
          body:
              'If you have concerns about any content displayed in FinReels, '
              'please contact us at:\n\nchastechnologiesllc@gmail.com',
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared legal scaffold
// ─────────────────────────────────────────────────────────────────────────────

class _LegalScreen extends StatelessWidget {
  final String title;
  final String lastUpdated;
  final List<_LegalSection> sections;

  const _LegalScreen({
    required this.title,
    required this.lastUpdated,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.bgColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.bgColor(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: isDark ? AppTheme.darkText : AppTheme.lightText, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          // Last updated badge
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.gold.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppTheme.gold.withValues(alpha: 0.25), width: 0.5),
            ),
            child: Text(
              'Last updated: $lastUpdated',
              style: const TextStyle(
                color: AppTheme.gold,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Sections
          ...sections.map((s) => _SectionWidget(section: s)),
        ],
      ),
    );
  }
}

class _LegalSection {
  final String heading;
  final String body;
  const _LegalSection({required this.heading, required this.body});
}

class _SectionWidget extends StatelessWidget {
  final _LegalSection section;
  const _SectionWidget({required this.section});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.heading,
            style: TextStyle(
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
              fontWeight: FontWeight.w700,
              fontSize: 15,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            section.body,
            style: TextStyle(
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
              fontSize: 14,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}
