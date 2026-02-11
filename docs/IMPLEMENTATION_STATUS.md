# 実装ステータス（仕様振り返り用）

最終更新: 2026-02-12

## 現在の到達点

- モバイル向けチャットUIは動作可能
- iPhoneシミュレータで起動確認済み
- ローカル/クラウド含む複数LLM接続先の選択が可能
- 設定は全画面編集 + セクション分割済み
- モデルごとにトークン利用量と概算金額を追跡可能
- Agentic Search（SearXNG反復 + 確信値停止）を実装済み
- 履歴をローカル保存し、再読込・コピー・エクスポート・共有が可能
- Project機能（CRUD/選択/追加プロンプト/添付ファイル）を実装済み
- 選択中Projectの文脈をチャット実行時に注入済み
- HTML Artifact表示を実装済み（チャット内ボタンから全画面表示）
- Integrations機能（Skills/SubAgents/MCPレジストリ）を実装済み
- 有効なSkills/SubAgent/MCP情報をチャット実行時に注入済み
- Skillsは `.skill` / `.zip` アーカイブを取り込み可能

## 仕様差分サマリ（初期計画 대비）

### 追加で進んだ点
- Gemini API / Azure OpenAI 対応
- 接続先を1件固定ではなく複数登録方式へ変更
- モデルごとの運用メトリクス（token/cost/saving）を追加

### まだ残っている点
- 会話履歴のDB永続化（現状はファイル保存）
- MCP実行連携（現状はレジストリ管理と文脈注入まで）
- Project添付の高度検索（RAG化）

## 運用上の注意

- APIキーは現状、設定入力値として保持している（次段階で secure storage へ移行予定）
- コスト計算は入力単価/出力単価（1M tokens基準）の概算
- トークン数がAPIレスポンスに含まれない場合は推定値で補完
- Agentic SearchはSearXNG `format=json` が失敗する場合、HTML抽出フォールバックを使用
- Artifactは `webview_flutter` でレンダリング（今後CSP/制限強化予定）
