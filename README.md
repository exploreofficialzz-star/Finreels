# FinReels 🎬
**Financial Literacy Video Hub** — by chAs Tech Group  
`com.chastech.finreels`

FinReels aggregates the best financial literacy YouTube channels into one
clean, adaptive, ad-supported mobile app for Android and iOS.

---

## Channels

| Channel | Focus |
|---|---|
| School of Hard Knocks | Millionaire interviews & career mentorship |
| Graham Stephan | Real estate, investing & saving |
| The Financial Diet | Budgeting, career & lifestyle |
| Andrei Jikh | Stocks, crypto & minimalism |
| Whiteboard Finance | Stocks, real estate & FIRE |

---

## Architecture

- **Zero backend** — YouTube RSS feeds only
- **Pure Flutter** — single codebase for Android + iOS
- **System-adaptive theme** — pure white (light) / pure black (dark)
- **AdMob** — banner + interstitial + app-open ads
- **IAP** — 3 ad-free tiers via `in_app_purchase`
- **WorkManager** — background RSS polling + local notifications
- **Multi-endpoint connectivity checks** — no false positives
- **Ad-block detection** — 4 ad-server probes, gate if 2+ fail

---

## Quick Start

```bash
# 1. Clone
git clone https://github.com/YOUR_ORG/finreels.git
cd finreels

# 2. Install deps
flutter pub get

# 3. Run (debug — uses AdMob test IDs automatically)
flutter run
```

---

## Before Production Release

### 1. AdMob IDs
Edit `lib/config/app_config.dart`:
```dart
static const bool kDebugAds = false;          // ← MUST change
// Replace all ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX values
```
Also update `android/app/src/main/AndroidManifest.xml` (`GADApplicationIdentifier`)
and `ios/Runner/Info.plist` (`GADApplicationIdentifier`).

### 2. IAP Product IDs
In **Google Play Console** and **App Store Connect**, create subscriptions
with exactly these IDs:
- `finreels_no_ads_1day`  — $0.99
- `finreels_no_ads_weekly` — $2.99
- `finreels_no_ads_monthly` — $8.99

### 3. iOS Export
Update `scripts/ExportOptions.plist`:
- Replace `YOUR_TEAM_ID` with your Apple Team ID
- Replace `FinReels App Store` with your provisioning profile name

---

## GitHub Actions — Required Secrets

Set these under **Settings → Secrets and variables → Actions**:

### Android
| Secret | Value |
|---|---|
| `KEYSTORE_BASE64` | `base64 finreels.jks` |
| `KEYSTORE_STORE_PASSWORD` | keystore password |
| `KEYSTORE_KEY_ALIAS` | key alias |
| `KEYSTORE_KEY_PASSWORD` | key password |

Generate keystore:
```bash
keytool -genkey -v -keystore finreels.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias finreels -storepass YOUR_PASS -keypass YOUR_PASS \
  -dname "CN=Chas Tech Group, OU=Mobile, O=ChasTech, L=City, S=State, C=US"

base64 finreels.jks | pbcopy  # macOS — paste as KEYSTORE_BASE64
```

### iOS
| Secret | Value |
|---|---|
| `IOS_CERTIFICATE_BASE64` | `base64 Certificates.p12` |
| `IOS_CERTIFICATE_PASSWORD` | p12 export password |
| `IOS_PROVISION_PROFILE_BASE64` | `base64 FinReels.mobileprovision` |
| `IOS_KEYCHAIN_PASSWORD` | any random password |
| `IOS_CODE_SIGN_IDENTITY` | e.g. `iPhone Distribution: Chas Tech Group` |
| `IOS_PROVISIONING_PROFILE_NAME` | e.g. `FinReels App Store` |

---

## Release Workflow

```bash
# Tag triggers the full signed build + GitHub Release
git tag v1.0.0
git push origin v1.0.0
```

- Android: outputs `app-arm64-v8a-release.apk`, `app-release.aab`
- iOS: outputs `FinReels.ipa`

---

## Monetization

| Tier | Product | Revenue per user |
|---|---|---|
| Ads | AdMob (banner + interstitial + app-open) | Finance CPM: $8–$25 |
| 1-day | `finreels_no_ads_1day` | $0.99 |
| Weekly | `finreels_no_ads_weekly` | $2.99 |
| Monthly | `finreels_no_ads_monthly` | $8.99 |

---

## Project Structure

```
finreels/
├── lib/
│   ├── config/         ← app_config.dart (all IDs + constants)
│   ├── data/           ← channel_data.dart (5 channels)
│   ├── models/         ← channel.dart, video.dart
│   ├── providers/      ← feed_provider.dart
│   ├── screens/        ← splash, home, channels, saved, settings
│   ├── services/       ← connectivity, ad_block, rss, ads, iap,
│   │                      notifications, background
│   ├── theme/          ← app_theme.dart (adaptive light/dark)
│   ├── widgets/        ← connectivity_overlay, ad_block_overlay,
│   │                      video_card, banner_ad, shimmer
│   └── main.dart
├── android/
├── ios/
├── assets/
│   ├── icons/          ← 1024px master icon + adaptive variants
│   └── sounds/         ← notification.wav, ding.wav
├── scripts/            ← ExportOptions.plist
└── .github/workflows/  ← build_android.yml, build_ios.yml
```

---

## License
Copyright © 2025 Chas Tech Group. All rights reserved.
