---
description: Flutter開発フロー全体。設計→セキュリティレビュー→実装→テスト→コードレビュー→バグ修正→リリースの流れ。
---

# Flutter開発フロー

## フェーズ概要

```
Phase 1: DESIGN (mobile-architect + uiux-designer)
    ↓
Phase 2: SECURITY_REVIEW (security-expert)
    ↓
Phase 2.5: ENVIRONMENT_CHECK ← ネイティブプラグイン使用時
    ↓
Phase 3: IMPLEMENT (flutter-developer)
    ↓
Phase 4: TEST (flutter-tdd-runner)
    ↓
Phase 5: REVIEW (flutter-reviewer)
    ↓
Phase 6: FIX (flutter-debugger) ← 問題があれば
    ↓
Phase 7: RELEASE
```

---

## Phase 1: 設計

### 実行エージェント
- `mobile-architect` - アーキテクチャ設計
- `uiux-designer` - UI/UX設計

### 成果物
- `docs/design/[feature]-design.md` - 機能設計書
- `docs/adr/ADR-XXX-[title].md` - 意思決定記録
- `docs/ui/[screen]-ui.md` - UI仕様書

### 完了条件
- [ ] 機能要件が定義されている
- [ ] 非機能要件が定義されている
- [ ] データモデルが設計されている
- [ ] UI仕様が作成されている
- [ ] レビュー承認済み

---

## Phase 2: セキュリティレビュー

### 実行エージェント
- `security-expert`

### 成果物
- `docs/security/[feature]-security-review.md`

### 完了条件
- [ ] 認証・認可設計がレビュー済み
- [ ] データ保護方針が確認済み
- [ ] CRITICALな問題がない

---

## Phase 2.5: 環境チェック（ネイティブプラグイン使用時）

### 参照スキル
- `flutter-environment-check`

### 実行条件
- ネイティブプラグイン（health, camera, geolocator等）を導入する場合

### チェック項目
- [ ] `flutter doctor -v` で全項目パス
- [ ] パッケージのREADME/Changelogで要件確認
- [ ] minSdk/NDK/Kotlin要件を確認
- [ ] iOS: Deployment Target/Swift/CocoaPods確認

---

## Phase 3: 実装

### 実行エージェント
- `flutter-developer`

### 参照スキル
- `ai-flutter-guidelines`（必須）
- `flutter-development`

### 成果物
- `lib/features/[feature]/` - 機能コード

### 完了条件
- [ ] 設計書に基づき実装完了
- [ ] `flutter analyze` がエラー・警告なし
- [ ] コードフォーマット適用済み
- [ ] ネイティブプラグイン使用時: `flutter build apk --debug` 成功
- [ ] iOS: `pod install` → `flutter build ios --debug` 成功

---

## Phase 4: テスト

### 実行エージェント
- `flutter-tdd-runner`

### 成果物
- `test/unit/[feature]/` - ユニットテスト
- `test/widget/[feature]/` - ウィジェットテスト
- `integration_test/[feature]/` - 統合テスト

### 完了条件
- [ ] ユニットテストカバレッジ 80%+
- [ ] ウィジェットテストカバレッジ 70%+
- [ ] 主要フローの統合テスト完了
- [ ] 全テストが通過

---

## Phase 5: コードレビュー

### 実行エージェント
- `flutter-reviewer`

### 成果物
- PRコメント/レビュー結果

### 完了条件
- [ ] CRITICAL問題なし
- [ ] HIGH問題なし
- [ ] レビュー承認済み

---

## Phase 6: バグ修正（必要時）

### 実行エージェント
- `flutter-debugger`

### トリガー
- テスト失敗
- レビュー指摘
- バグ報告

### 完了条件
- [ ] 問題が解決
- [ ] リグレッションテスト通過

---

## Phase 7: リリース

### チェックリスト
- [ ] 全テスト通過
- [ ] レビュー承認済み
- [ ] セキュリティレビュー済み
- [ ] ドキュメント更新済み
- [ ] CHANGELOGに追記

### コマンド
```bash
# リリースビルド
flutter build apk --release
flutter build appbundle --release

# バージョン更新（pubspec.yaml）
version: X.Y.Z+N
```
