# 実装ステータス（仕様振り返り用）

最終更新: 2026-02-12

## 現在の到達点

- モバイル向けチャットUIは動作可能
- AI応答はMarkdownレンダリング表示（見出し/強調/コードブロック）
- チャット欄ポップアップで SearXNG ON/OFF とモデル切替が可能
- iPhoneシミュレータで起動確認済み
- ローカル/クラウド含む複数LLM接続先の選択が可能
- 設定は全画面編集 + セクション分割済み
- モデルごとにトークン利用量と概算金額を追跡可能
- Agentic Search（SearXNG反復 + 確信値停止）を実装済み
- 実行時コンテキストとして現在日時とWeb検索可否をプロンプト注入済み
- 最新/日付系クエリ向けに Freshness Guard を注入（検索OFF時の推測回答を抑制）
- 最新/日付系クエリは根拠URLが無い場合に「未確認」へ強制フォールバック
- SearXNG利用時は回答末尾に Search Trace（クエリ・ヒット数・参照URL）を表示
- Search Traceは折りたたみパネルで表示（本文と分離）
- Search Traceには各ステップの検索実行時刻を表示
- 履歴をローカル保存し、再読込・コピー・エクスポート・共有が可能
- 履歴永続化をJSONからSQLiteへ移行済み（既存JSONの初回自動移行あり）
- Project機能（CRUD/選択/追加プロンプト/添付ファイル）を実装済み
- 選択中Projectの文脈をチャット実行時に注入済み
- Project添付検索モード切替を実装済み（RAG / Agentic Search）
- HTML Artifact表示を実装済み（チャット内ボタンから全画面表示）
- AI応答は吹き出しを使わず全幅表示（先頭に🤖、将来アイコン用スロット確保）
- Integrations機能（Skills/SubAgents/MCPレジストリ）を実装済み
- 有効なSkills/SubAgent/MCP情報をチャット実行時に注入済み
- MCP実行連携を実装済み（LLMのMCP JSON要求を検出し、HTTPブリッジへツール実行）
- Skill実行器を実装済み（LLMのSkill JSON要求を検出し、有効Skillを実行して結果注入）
- Skillsは `.skill` / `.zip` アーカイブを取り込み可能
- 設定をローカル永続化済み（JSONファイル）
- モデルAPIキーをSecure Storageに保存済み（設定ファイルには非保持）

## 仕様差分サマリ（初期計画 대비）

### 追加で進んだ点
- Gemini API / Azure OpenAI 対応
- 接続先を1件固定ではなく複数登録方式へ変更
- モデルごとの運用メトリクス（token/cost/saving）を追加

### まだ残っている点
- Project添付検索の高度化（埋め込みベクトル索引・ハイブリッド検索）

## 運用上の注意

- APIキーはSecure Storageに保存し、設定ファイルには保存しない
- コスト計算は入力単価/出力単価（1M tokens基準）の概算
- トークン数がAPIレスポンスに含まれない場合は推定値で補完
- Agentic SearchはSearXNG `format=json` が失敗する場合、HTML抽出フォールバックを使用
- Artifactは `webview_flutter` でレンダリング（今後CSP/制限強化予定）
- 旧 `conversations.json` はSQLite移行時にバックアップ名へリネームされる
- MCPは現状 HTTP/HTTPS ブリッジ方式のみ実行（`command` にURLを設定）
- Skill実行は現状「定義内容の要約・手順抽出」を返す軽量実行方式
