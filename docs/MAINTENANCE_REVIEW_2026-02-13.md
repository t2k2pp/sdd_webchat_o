# メンテナンス棚卸し（2026-02-13）

## 方針
- ユーザーストーリーが弱い機能は追加しない
- 「開発者向け隠し機能」の新規追加は行わない
- 失敗時の握りつぶしは減らし、少なくともログを残す
- エラー可視化方針を固定（`docs/ERROR_VISIBILITY_POLICY.md`）

## 今回の改善
- Search設定のレンジ値入力をテキスト中心から選択UIへ変更
  - `Search Max HTML Chars`: プリセット選択化（最大2,000,000）
  - `Agentic Search Policy`
    - `Max Iterations`: プリセット選択化（最大32）
    - `Confidence Threshold`: スライダ化
- Model Endpoint編集
  - `Temperature`: スライダ化
- 例外ハンドリング改善（ログ追加）
  - `ProjectContextResolver` の添付読込/埋め込み/キャッシュ処理
  - `ChatController` のコンテキスト構築・設定読込・タイトル生成
  - `AgenticSearchOrchestrator` のステップJSON解析
  - `SkillRequestParser` / `McpRequestParser` のJSON解析失敗
  - IntegrationsのSkill URL取得失敗時ログ + UI通知
  - `FileSettingsRepository` 読込失敗、SQLite旧履歴移行失敗

## 確認したこと
- `Force Search` や追加の「開発者向けモード」は実装しない（ON/OFF + Autoを維持）
- 検索可否の最終責務はユーザー設定と既存フローを尊重する

## 残タスク（優先順）
1. エラー可視化方針の統一（ユーザー通知する失敗と内部ログのみの失敗を分離）
2. 設定UIの継続改善（数値入力の適切なコントロールを定期監査）
3. 検索品質の観測強化（NO_SEARCH率、検索実行率、失敗率メトリクス）
