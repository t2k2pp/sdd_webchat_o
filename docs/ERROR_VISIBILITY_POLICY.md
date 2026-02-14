# Error Visibility Policy

## 目的
- 失敗を握りつぶさない
- ただし、すべてをユーザー通知しない
- UXを壊さず、原因追跡可能な運用にする

## ルール
1. `log only`
- 内部フォールバックが有効で、ユーザー操作継続に影響がない失敗
- 例: TTS言語設定失敗時に既定言語へフォールバック

2. `notify user`
- ユーザーが明示的に起こした操作が失敗した場合
- 例: URLからSkill取得、テスト再生

3. `hard error`
- 機能継続不能の失敗は画面/応答で明示
- 例: チャット送信失敗

## 実装
- 共通ヘルパー: `lib/core/logging/error_visibility.dart`
  - `ErrorVisibility.logOnly(...)`
  - `ErrorVisibility.notifyUser(...)`
