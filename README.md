# FinReels 🎬
**Financial Literacy Video Hub** — by chAs Tech Group  
`com.chastech.finreels`

FinReels aggregates the best financial literacy and entrepreneurship YouTube
channels into one clean, ad-supported mobile app for Android and iOS — plus
a curated Books library of public-domain classics and original masterclass playbooks.

---

## Channels (12)

| Channel | Category | Focus |
|---|---|---|
| The Diary Of A CEO | Entrepreneurship | CEO interviews & success mindset |
| Alex Hormozi | Sales & Business | Offers, sales & business scaling |
| Iman Gadzhi | Entrepreneurship | Online business & agency building |
| Magnates Media | How They Got Rich | Business documentaries & empire stories |
| My First Million | Entrepreneurship | Business ideas & wealth case studies |
| HubSpot Marketing | Sales & Marketing | Marketing strategies & business growth |
| Neil Patel | Sales & Marketing | Digital marketing & SEO |
| Dan Lok | Sales & Marketing | High ticket sales & closing |
| Jordan Platten | Sales & Marketing | SMMA & social media marketing |
| School of Hard Knocks | How They Got Rich | Millionaire interviews & wealth journeys |
| Vusi Thembekwayo | Entrepreneurship | Leadership, strategy & disruption |
| Marketing Explained | Sales & Marketing | Digital marketing tutorials & strategies |

All channel IDs are verified directly from YouTube channel pages and pull live
RSS feeds — no API key required.

---

## Books Library

### Free Finance Library (8 public-domain classics via EPUB)
- *The Richest Man in Babylon* — George S. Clason
- *Think and Grow Rich* — Napoleon Hill *(includes in-app key insights)*
- *The Science of Getting Rich* — Wallace D. Wattles
- *The Art of Money Getting* — P. T. Barnum
- *As a Man Thinketh* — James Allen
- *Eight Pillars of Prosperity* — James Allen
- *The Master Key System* — Charles F. Haanel
- *Extraordinary Popular Delusions* — Charles Mackay

### Masterclass Playbooks (2 original PDFs bundled in the app)
- *The Five Buckets: Build What They Can Never Take From You*
- *The Five Buckets: A Field Manual for Unstoppable Success*

---

## Architecture

| Layer | Detail |
|---|---|
| **Feed** | YouTube RSS via `dart:http` — no API key, no backend |
| **Codebase** | Pure Flutter (Dart) — single codebase for Android + iOS |
| **Theme** | System-adaptive — pure white light / pure black dark |
| **AdMob** | Banner + Interstitial + App Open + Unity Ads mediation |
| **IAP** | 3 ad-free tiers (non-consumable one-time purchases) |
| **Background** | WorkManager RSS polling + local notifications |
| **Connectivity** | Multi-endpoint probing — no false positives |
| **Ad-block detect** | 4 ad-server probes; gates if 2+ fail |
| **Books** | 8 public-domain EPUBs via `flutter_epub_viewer` + 2 bundled PDFs |
| **Startup** | Parallel service init (6 s ceiling); instant first frame |

---

## Quick Start

```bash
git clone https://github.com/YOUR_ORG/finreels.git
cd finreels
flutter pub get
flutter run
```

---

## Before Production Release

### 1. AdMob
Edit `lib/config/app_config.dart` — `kDebugAds` is already `false` and all
Android production ad unit IDs are live. Create a **separate iOS app** in AdMob
and update:
- `ios/Runner/Info.plist` → `GADApplicationIdentifier`
- `lib/config/app_config.dart` → iOS branches of each `get` (currently mirroring Android IDs)

Also create an **App Open** ad unit and replace the test IDs in `appOpenAdUnitId`
(see the comment in `app_config.dart`).

### 2. IAP Products
The app uses **non-consumable one-time purchases** (not subscriptions).
Create them in **Google Play Console → Monetization → One-time products**
and **App Store Connect → In-App Purchases → Non-Consumable** with these IDs:

| ID | Price |
|---|---|
| `finreels_no_ads_1day` | $0.99 |
| `finreels_no_ads_weekly` | $2.99 |
| `finreels_no_ads_monthly` | $8.99 |

### 3. iOS Signing
Update `scripts/ExportOptions.plist`: replace `YOUR_TEAM_ID` and the
provisioning profile name with your Apple Developer Team values.

---

## GitHub Actions — Required Secrets

### Android
| Secret | Value |
|---|---|
| `KEYSTORE_BASE64` | `base64 finreels.jks` |
| `KEYSTORE_STORE_PASSWORD` | keystore store password |
| `KEYSTORE_KEY_ALIAS` | key alias |
| `KEYSTORE_KEY_PASSWORD` | key password |

```bash
# Generate keystore (run once, store the .jks securely — never commit it)
keytool -genkey -v -keystore finreels.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias finreels -storepass YOUR_PASS -keypass YOUR_PASS \
  -dname "CN=Chas Tech Group, OU=Mobile, O=ChasTech, L=City, S=State, C=US"

base64 finreels.jks | pbcopy   # macOS — paste as KEYSTORE_BASE64
base64 finreels.jks | xclip    # Linux
```

### iOS
| Secret | Value |
|---|---|
| `IOS_CERTIFICATE_BASE64` | `base64 Certificates.p12` |
| `IOS_CERTIFICATE_PASSWORD` | p12 export password |
| `IOS_PROVISION_PROFILE_BASE64` | `base64 FinReels.mobileprovision` |
| `IOS_KEYCHAIN_PASSWORD` | any random string |
| `IOS_CODE_SIGN_IDENTITY` | e.g. `iPhone Distribution: Chas Tech Group` |
| `IOS_PROVISIONING_PROFILE_NAME` | e.g. `FinReels App Store` |

---

## Release Workflow

```bash
# Tag triggers the full signed CI build + GitHub Release
git tag v1.0.0 -m "Initial release"
git push origin v1.0.0
```

- **Android** outputs: `app-arm64-v8a-release.apk`, `app-release.aab`
- **iOS** outputs: `FinReels.ipa`

---

## Monetization

| Tier | Product ID | Price |
|---|---|---|
| Ads (default) | — | Free; AdMob Finance CPM ~$8–25 |
| 1-day ad-free | `finreels_no_ads_1day` | $0.99 |
| 7-day ad-free | `finreels_no_ads_weekly` | $2.99 |
| 30-day ad-free | `finreels_no_ads_monthly` | $8.99 |

---

## Project Structure

```
finreels/
├── lib/
│   ├── config/         ← app_config.dart (all IDs, keys, constants)
│   ├── data/           ← channel_data.dart (12 channels)
│   │                      book_insights_data.dart (Think & Grow Rich insights)
│   ├── models/         ← channel.dart, video.dart, feed_tab.dart
│   ├── providers/      ← feed_provider.dart (single source of truth)
│   ├── screens/        ← splash, home, channels (shorts tab), saved, settings,
│   │                      video_player, shorts_player, blog_feed, blog_reader,
│   │                      book_detail, channel_videos, privacy_policy
│   ├── services/       ← ad_service, ad_block_service, rss_service,
│   │                      iap_service, notification_service,
│   │                      background_service, connectivity_service,
│   │                      blog_rss_service
│   ├── theme/          ← app_theme.dart (adaptive light/dark)
│   ├── widgets/        ← connectivity_overlay, ad_block_overlay,
│   │                      banner_ad_widget, inline_video_card, video_card,
│   │                      book_cover_image, shimmer_loader
│   └── main.dart
├── android/
│   ├── app/build.gradle        ← AGP 8.6.0, minSdk 23, targetSdk 35
│   ├── settings.gradle         ← Kotlin 2.3.0, AGP 8.6.0
│   └── app/src/main/
│       ├── AndroidManifest.xml ← permissions, AdMob ID, WorkManager
│       └── kotlin/             ← MainActivity.kt, MainApplication.kt
├── ios/
│   └── Runner/Info.plist       ← AdMob ID, ATT, BGTask identifiers
├── assets/
│   ├── icons/          ← app_icon.png + adaptive variants
│   ├── sounds/         ← notification.wav, ding.wav
│   └── books/          ← bundled PDF masterclass playbooks + covers
├── scripts/
│   └── ExportOptions.plist
└── .github/workflows/
    ├── build_android.yml
    └── build_ios.yml
```

---

## License
Copyright © 2025 Chas Tech Group. All rights reserved.
