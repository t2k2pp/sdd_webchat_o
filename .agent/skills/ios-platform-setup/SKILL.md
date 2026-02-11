---
name: ios-platform-setup
description: iOS プラットフォーム設定スキル。Xcode設定、証明書、プロビジョニングプロファイル、Capabilities、CocoaPods、エンタイトルメント設定を支援。Flutter iOS開発環境構築時に使用。
---

# iOS プラットフォーム設定スキル

## 前提条件

| 要件 | 詳細 |
|------|------|
| macOS | 必須（Windowsでは不可） |
| Xcode | 15.0+ (2025年以降は最新版推奨) |
| Apple Developer Program | 年間$99（ストア公開に必要） |

---

## 開発環境セットアップ

### 1. Xcode インストール
```bash
# App Storeからインストール後
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch

# ライセンス同意
sudo xcodebuild -license accept

# コマンドラインツール
xcode-select --install
```

### 2. Apple Silicon対応（M1/M2/M3）
```bash
# Rosetta 2 インストール
sudo softwareupdate --install-rosetta --agree-to-license
```

### 3. CocoaPods
```bash
# インストール
sudo gem install cocoapods

# リポジトリ更新
pod setup

# Flutterプロジェクトで使用
cd ios
pod install
```

### 4. Flutter iOS確認
```bash
flutter doctor -v
# [✓] Xcode - develop for iOS and macOS 確認
```

---

## 証明書とプロビジョニング

### 証明書の種類
| 種類 | 用途 | 有効期限 |
|------|------|---------|
| Development | 開発・デバッグ | 1年 |
| Distribution | App Store/AdHoc配布 | 1年 |

### 手動作成手順

#### 1. 証明書署名要求（CSR）作成
```
キーチェーンアクセス → 証明書アシスタント → 認証局に証明書を要求
→ メールアドレス入力 → ディスクに保存
```

#### 2. Apple Developer Portalで証明書作成
```
1. developer.apple.com → Certificates, IDs & Profiles
2. Certificates → + ボタン
3. iOS Distribution (App Store and Ad Hoc) 選択
4. CSRファイルをアップロード
5. 証明書ダウンロード → ダブルクリックでキーチェーンに追加
```

#### 3. App ID作成
```
1. Identifiers → + ボタン
2. App IDs → App 選択
3. Bundle ID入力（例: com.company.appname）
4. 必要なCapabilities選択
```

#### 4. プロビジョニングプロファイル作成
```
1. Profiles → + ボタン
2. App Store選択（配布用）またはDevelopment（開発用）
3. App ID選択
4. 証明書選択
5. デバイス選択（Development時のみ）
6. プロファイル名入力 → ダウンロード
```

---

## Xcode プロジェクト設定

### Signing & Capabilities
```
1. ios/Runner.xcworkspace を Xcodeで開く
2. Runner → Signing & Capabilities
3. Team: Apple Developer Team選択
4. Bundle Identifier: 一意のID設定
5. ☑️ Automatically manage signing（推奨）
```

### 手動署名（CI/CD用）
```
Signing & Capabilities → ☐ Automatically manage signing OFF
→ Provisioning Profile 手動選択
```

---

## Capabilities（機能追加）

### よく使うCapabilities
| Capability | 用途 | 設定 |
|-----------|------|------|
| Push Notifications | プッシュ通知 | APNs証明書必要 |
| Sign in with Apple | Appleログイン | App ID設定必要 |
| Associated Domains | ユニバーサルリンク | apple-app-site-association必要 |
| Background Modes | バックグラウンド処理 | 種類選択 |
| App Groups | アプリ間データ共有 | グループID設定 |
| HealthKit | ヘルスデータアクセス | Info.plist説明必要 |

### Capability追加手順
```
1. Xcode → Signing & Capabilities → + Capability
2. 使用したいCapability追加
3. Apple Developer PortalでApp IDにも同じCapability追加
4. プロビジョニングプロファイル再生成
```

---

## Info.plist 設定

### 必須の権限説明
```xml
<!-- ios/Runner/Info.plist -->

<!-- カメラ使用 -->
<key>NSCameraUsageDescription</key>
<string>写真撮影のためにカメラを使用します</string>

<!-- 写真ライブラリ -->
<key>NSPhotoLibraryUsageDescription</key>
<string>写真を選択するためにライブラリにアクセスします</string>

<!-- 位置情報 -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>現在地を表示するために位置情報を使用します</string>

<!-- Face ID -->
<key>NSFaceIDUsageDescription</key>
<string>セキュアなログインのためにFace IDを使用します</string>

<!-- HealthKit -->
<key>NSHealthShareUsageDescription</key>
<string>健康データを読み取るためにHealthKitを使用します</string>
<key>NSHealthUpdateUsageDescription</key>
<string>健康データを保存するためにHealthKitを使用します</string>
```

### アプリ設定
```xml
<!-- 最小iOSバージョン -->
<key>MinimumOSVersion</key>
<string>13.0</string>

<!-- ディスプレイ名 -->
<key>CFBundleDisplayName</key>
<string>アプリ名</string>

<!-- バージョン -->
<key>CFBundleShortVersionString</key>
<string>1.0.0</string>

<!-- ビルド番号 -->
<key>CFBundleVersion</key>
<string>1</string>
```

---

## Fastlane Match（証明書管理自動化）

### セットアップ
```bash
cd ios
fastlane match init
# Git リポジトリURL入力（プライベート推奨）
```

### 証明書生成
```bash
# 開発用
fastlane match development

# 配布用
fastlane match appstore
```

### CI/CDで使用
```ruby
# Fastfile
lane :build do
  setup_ci if ENV['CI']
  match(type: "appstore", readonly: true)
  build_app(scheme: "Runner")
end
```

---

## トラブルシューティング

### "No signing certificate" エラー
```
解決: キーチェーンに証明書がインポートされているか確認
→ キーチェーンアクセス → ログイン → 証明書
```

### "Provisioning profile doesn't match" エラー
```
解決:
1. Bundle IDがApp IDと一致しているか確認
2. Xcodeでプロファイル再ダウンロード
   Preferences → Accounts → Download Manual Profiles
```

### CocoaPods エラー
```bash
# キャッシュクリア
cd ios
rm -rf Pods Podfile.lock
pod cache clean --all
pod install --repo-update
```

---

## チェックリスト

iOS開発環境構築時:
- [ ] Xcode最新版インストール
- [ ] Apple Developer Program登録
- [ ] App ID作成（Bundle ID設定）
- [ ] 証明書作成（Development/Distribution）
- [ ] プロビジョニングプロファイル作成
- [ ] Xcodeで署名設定
- [ ] 必要なCapabilities追加
- [ ] Info.plist権限説明追加
- [ ] CocoaPods設定
- [ ] 実機でビルド・動作確認
