# FinReels — Pre-Launch Checklist
`com.chastech.finreels` · Chas Tech Group

Work through every item before submitting to Google Play and App Store.

---

## 🔑 Step 1 — AdMob Setup
- [ ] Create app in [AdMob Console](https://admob.google.com)
- [ ] Copy **Android App ID** → paste into `android/app/src/main/AndroidManifest.xml` (`GADApplicationIdentifier`)
- [ ] Copy **iOS App ID** → paste into `ios/Runner/Info.plist` (`GADApplicationIdentifier`)
- [ ] Copy **Android App ID** → paste into `lib/config/app_config.dart` (`admobAppId` Android branch)
- [ ] Copy **iOS App ID** → paste into `lib/config/app_config.dart` (`admobAppId` iOS branch)
- [ ] Create **Banner** ad units (Android + iOS) → paste into `bannerAdUnitId`
- [ ] Create **Interstitial** ad units (Android + iOS) → paste into `interstitialAdUnitId`
- [ ] Create **App Open** ad units (Android + iOS) → paste into `appOpenAdUnitId`
- [ ] Set `kDebugAds = false` in `lib/config/app_config.dart`

---

## 💳 Step 2 — In-App Purchases

### Google Play Console
- [ ] Go to **Monetization → Subscriptions**
- [ ] Create subscription: ID = `finreels_no_ads_1day`, price = $0.99, billing period = 1 day
- [ ] Create subscription: ID = `finreels_no_ads_weekly`, price = $2.99, billing period = 1 week
- [ ] Create subscription: ID = `finreels_no_ads_monthly`, price = $8.99, billing period = 1 month
- [ ] Activate all 3 subscriptions

### App Store Connect
- [ ] Go to **My Apps → FinReels → In-App Purchases → Manage**
- [ ] Create Auto-Renewable Subscription group: "Remove Ads"
- [ ] Add tier: `finreels_no_ads_1day` — $0.99 — 1 day
- [ ] Add tier: `finreels_no_ads_weekly` — $2.99 — 1 week
- [ ] Add tier: `finreels_no_ads_monthly` — $8.99 — 1 month
- [ ] Submit for review alongside the app

---

## 🤖 Step 3 — Android Signing

```bash
# Generate keystore (run once, store securely)
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

- [ ] Add GitHub Secret: `KEYSTORE_BASE64` (base64 of finreels.jks)
- [ ] Add GitHub Secret: `KEYSTORE_STORE_PASSWORD`
- [ ] Add GitHub Secret: `KEYSTORE_KEY_ALIAS` = `finreels`
- [ ] Add GitHub Secret: `KEYSTORE_KEY_PASSWORD`
- [ ] **Never commit** `finreels.jks` or `android/key.properties`

---

## 🍎 Step 4 — iOS Signing

- [ ] Create App ID `com.chastech.finreels` in Apple Developer portal
- [ ] Create Distribution Certificate → export as `.p12`
- [ ] Create App Store provisioning profile → download `.mobileprovision`
- [ ] Add GitHub Secret: `IOS_CERTIFICATE_BASE64` (base64 of .p12)
- [ ] Add GitHub Secret: `IOS_CERTIFICATE_PASSWORD`
- [ ] Add GitHub Secret: `IOS_PROVISION_PROFILE_BASE64` (base64 of .mobileprovision)
- [ ] Add GitHub Secret: `IOS_KEYCHAIN_PASSWORD` (any random password)
- [ ] Add GitHub Secret: `IOS_CODE_SIGN_IDENTITY` e.g. `iPhone Distribution: Chas Tech Group (TEAMID)`
- [ ] Add GitHub Secret: `IOS_PROVISIONING_PROFILE_NAME` e.g. `FinReels App Store`
- [ ] Update `scripts/ExportOptions.plist`: replace `YOUR_TEAM_ID` and profile name

---

## 🔔 Step 5 — Notifications

- [ ] Verify WorkManager background fetch runs on a real device (check logcat/console)
- [ ] Test notification fires when a new RSS entry appears
- [ ] Test tapping notification deep-links to the correct video

---

## 📱 Step 6 — Device Testing

- [ ] Android: Test on API 23, 29, 34 (min, typical, max)
- [ ] Android: Confirm dark mode adapts correctly (Settings → Display → Dark)
- [ ] Android: Confirm light mode adapts correctly
- [ ] iOS: Test on iPhone 13 (iOS 15) and iPhone 15 Pro (iOS 17)
- [ ] iOS: Confirm dark/light mode switches instantly
- [ ] Both: Airplane mode → connectivity overlay appears
- [ ] Both: Airplane mode → reconnect → overlay disappears automatically
- [ ] Both: Enable ad blocker → ad-block gate appears
- [ ] Both: Disable ad blocker → tap "I've Disabled It" → gate disappears
- [ ] Both: Open 3 videos → interstitial fires on 3rd
- [ ] Both: Switch channels 4 times → interstitial fires on 4th
- [ ] Both: Purchase a subscription → ads disappear immediately
- [ ] Both: Force-kill app and reopen → App Open Ad shows (after 2h cooldown)

---

## 🏪 Step 7 — Store Listings

### Google Play
- [ ] Package: `com.chastech.finreels`
- [ ] Title (max 30 chars): `FinReels – Finance Videos`
- [ ] Short description (80 chars): `Top financial literacy YouTube channels in one free app`
- [ ] Full description: mention all 5 channels + ad-free IAP
- [ ] Screenshots: portrait, 5 minimum
- [ ] Feature graphic: 1024×500
- [ ] Category: Finance
- [ ] Content rating: complete questionnaire (Everyone)
- [ ] Privacy policy URL (required for AdMob)
- [ ] Upload AAB (not APK) for production

### App Store Connect
- [ ] Bundle ID: `com.chastech.finreels`
- [ ] Name: `FinReels`
- [ ] Subtitle: `Financial Literacy Videos`
- [ ] Keywords: `finance,money,invest,stock,wealth,budget,financial literacy`
- [ ] Screenshots: 6.7", 5.5", 12.9" iPad
- [ ] Privacy policy URL
- [ ] App Privacy: declare `User ID`, `Purchase History`, `Financial Info` data types
- [ ] Age Rating: 4+

---

## 🚀 Step 8 — Release

```bash
# Tag → triggers full CI/CD build
git tag v1.0.0 -m "Initial release"
git push origin v1.0.0
```

- [ ] GitHub Actions Android build passes → download AAB
- [ ] GitHub Actions iOS build passes → download IPA
- [ ] Upload AAB to Google Play → Internal Testing → Production
- [ ] Upload IPA via Transporter or Xcode → App Store Review
- [ ] Monitor AdMob dashboard for first impressions
- [ ] Monitor Crashlytics (optional add-on) for crashes

---

## ✅ Done!
Once all boxes are checked, FinReels is production-ready.
