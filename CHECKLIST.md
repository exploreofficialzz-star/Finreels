# FinReels — Pre-Launch Checklist
`com.chastech.finreels` · chAs Tech Group

Work through every item before submitting to Google Play and App Store.

---

## 🔑 Step 1 — AdMob Setup

Android production ad unit IDs are already live in `lib/config/app_config.dart`
and `android/app/src/main/AndroidManifest.xml`. iOS still mirrors the Android
App ID — create a separate iOS app in AdMob and update both files.

- [x] Android AdMob App ID set in `AndroidManifest.xml` ✓
- [x] Android ad unit IDs set in `lib/config/app_config.dart` ✓
- [x] `kDebugAds = false` ✓
- [ ] Create **iOS app** in AdMob Console → copy iOS App ID
- [ ] Paste iOS App ID → `ios/Runner/Info.plist` (`GADApplicationIdentifier`)
- [ ] Paste iOS App ID → `lib/config/app_config.dart` (iOS branch of `admobAppId`)
- [ ] Create iOS Banner ad unit → paste into iOS branch of `bannerAdUnitId`
- [ ] Create iOS Interstitial ad unit → paste into iOS branch of `interstitialAdUnitId`
- [ ] Create **App Open** ad unit (Android) → replace test ID in `appOpenAdUnitId` Android branch
- [ ] Create **App Open** ad unit (iOS) → replace test ID in `appOpenAdUnitId` iOS branch

---

## 💳 Step 2 — In-App Purchases

> ⚠️ The app uses `buyNonConsumable` (one-time purchase that grants a
> time-windowed ad-free period). Create them as **one-time products / managed
> products**, NOT subscriptions — subscriptions require `buySubscription` in
> the Flutter code, which is different.

### Google Play Console
- [ ] Go to **Monetize → Products → In-app products**
- [ ] Create one-time product: `finreels_no_ads_1day` — $0.99 — Active
- [ ] Create one-time product: `finreels_no_ads_weekly` — $2.99 — Active
- [ ] Create one-time product: `finreels_no_ads_monthly` — $8.99 — Active

### App Store Connect
- [ ] Go to **My Apps → FinReels → In-App Purchases → Manage**
- [ ] Create **Non-Consumable**: `finreels_no_ads_1day` — $0.99
- [ ] Create **Non-Consumable**: `finreels_no_ads_weekly` — $2.99
- [ ] Create **Non-Consumable**: `finreels_no_ads_monthly` — $8.99
- [ ] Submit all 3 for review alongside the app

---

## 🤖 Step 3 — Android Signing

```bash
# Generate keystore (run once — store the .jks file securely, never commit it)
keytool -genkey -v -keystore finreels.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias finreels \
  -storepass YOUR_STORE_PASS \
  -keypass YOUR_KEY_PASS \
  -dname "CN=Chas Tech Group, OU=Mobile, O=ChasTech, L=City, S=ST, C=US"

# Encode for GitHub secret
base64 -i finreels.jks | pbcopy   # macOS
base64 finreels.jks | xclip       # Linux
```

- [ ] Add GitHub Secret: `KEYSTORE_BASE64`
- [ ] Add GitHub Secret: `KEYSTORE_STORE_PASSWORD`
- [ ] Add GitHub Secret: `KEYSTORE_KEY_ALIAS` = `finreels`
- [ ] Add GitHub Secret: `KEYSTORE_KEY_PASSWORD`
- [ ] Confirm `finreels.jks` and `android/key.properties` are in `.gitignore`

---

## 🍎 Step 4 — iOS Signing

- [ ] Create App ID `com.chastech.finreels` in Apple Developer portal
- [ ] Create Distribution Certificate → export as `.p12`
- [ ] Create App Store provisioning profile → download `.mobileprovision`
- [ ] Update `scripts/ExportOptions.plist`: replace `YOUR_TEAM_ID` and profile name
- [ ] Add GitHub Secret: `IOS_CERTIFICATE_BASE64`
- [ ] Add GitHub Secret: `IOS_CERTIFICATE_PASSWORD`
- [ ] Add GitHub Secret: `IOS_PROVISION_PROFILE_BASE64`
- [ ] Add GitHub Secret: `IOS_KEYCHAIN_PASSWORD`
- [ ] Add GitHub Secret: `IOS_CODE_SIGN_IDENTITY`
- [ ] Add GitHub Secret: `IOS_PROVISIONING_PROFILE_NAME`

---

## 🔔 Step 5 — Notifications

- [ ] Confirm WorkManager background RSS check fires on a real Android device (logcat)
- [ ] Confirm notification fires when a new video appears in an RSS feed
- [ ] Test cold-launch deep-link: tap notification → correct video opens
- [ ] Test warm-launch deep-link: app in background → tap notification → correct video

---

## 📱 Step 6 — Device Testing

- [ ] Android: API 23 (min), API 29 (typical), API 35 (max)
- [ ] Android: dark mode adapts (Settings → Display → Dark)
- [ ] Android: light mode adapts
- [ ] iOS: iPhone 13 (iOS 15) and iPhone 15 Pro (iOS 17+)
- [ ] iOS: dark/light mode switches instantly
- [ ] Both: Airplane mode → connectivity overlay appears
- [ ] Both: Reconnect → overlay auto-dismisses
- [ ] Both: Ad blocker enabled → ad-block gate appears
- [ ] Both: Ad blocker disabled → tap "I've Disabled It" → gate clears
- [ ] Both: Open 2 videos → interstitial fires on 2nd (cycle length = 2)
- [ ] Both: Scroll 4 shorts → interstitial fires on 4th
- [ ] Both: Purchase ad-free tier → ads disappear immediately
- [ ] Both: Kill app and reopen → App Open ad fires (2 h cooldown)
- [ ] Both: Books tab → EPUB reader opens for public-domain titles
- [ ] Both: Books tab → PDF reader opens for Five Buckets playbooks
- [ ] Both: Think and Grow Rich → Key Insights reader works

---

## 🏪 Step 7 — Store Listings

### Google Play
- [ ] Package: `com.chastech.finreels`
- [ ] Title (max 30 chars): `FinReels – Finance Videos`
- [ ] Short description (80 chars): `Top finance & entrepreneurship channels + free classic books`
- [ ] Full description: mention 12 channels, Books library, ad-free IAP
- [ ] Screenshots: portrait, 5 minimum
- [ ] Feature graphic: 1024×500
- [ ] Category: **Finance**
- [ ] Content rating: complete questionnaire (Everyone)
- [ ] Privacy policy URL (required for AdMob)
- [ ] Upload **AAB** (not APK) for production

### App Store Connect
- [ ] Bundle ID: `com.chastech.finreels`
- [ ] Name: `FinReels`
- [ ] Subtitle: `Finance Videos & Books`
- [ ] Keywords: `finance,money,invest,business,wealth,entrepreneur,financial literacy`
- [ ] Screenshots: 6.7", 5.5", 12.9" iPad
- [ ] Privacy policy URL
- [ ] App Privacy: declare `User ID`, `Purchase History`, `Financial Info`
- [ ] Age Rating: **4+**

---

## 🚀 Step 8 — Release

```bash
git tag v1.0.0 -m "Initial release"
git push origin v1.0.0
```

- [ ] GitHub Actions Android build passes → download AAB
- [ ] GitHub Actions iOS build passes → download IPA
- [ ] Upload AAB to Google Play → Internal Testing → Production
- [ ] Upload IPA via Transporter or Xcode → App Store Review
- [ ] Monitor AdMob dashboard for first impressions
- [ ] Monitor crash reports

---

## ✅ Done!
All boxes checked = FinReels is production-ready.
