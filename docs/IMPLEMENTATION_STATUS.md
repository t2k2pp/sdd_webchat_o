# 実装ステータス（仕様振り返り用）

最終更新: 2026-02-13

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
- Search Traceをワンタップでクリップボードへコピー可能
- Search Trace付き回答に Web検索利用バッジとステップ数を表示
- 文脈考慮型クエリ生成を実装済み（会話履歴から検索クエリを生成）
- Agentic Conditional Searchを実装済み（検索要否をLLMが自律判定）
- HTML検索結果の抽出文字数制限を設定化済み
- Search設定のレンジ値（反復回数/確信閾値/HTML文字数）を選択UI化
- Search上限を拡張（Max Iterations: 最大32、HTML抽出文字数: 最大2,000,000）
- Usage Reports画面で日次/月次のトークン・コスト集計を表示
- 履歴をローカル保存し、再読込・コピー・エクスポート・共有が可能
- 履歴永続化をJSONからSQLiteへ移行済み（既存JSONの初回自動移行あり）
- Project機能（CRUD/選択/追加プロンプト/添付ファイル）を実装済み
- 選択中Projectの文脈をチャット実行時に注入済み
- Project添付検索モード切替を実装済み（RAG / Agentic Search）
- Project添付をチャンク索引化し、BM25風スコアリングで検索精度を改善
- Project Retrieval Mode（Lexical / Hybrid）を実装済み
- Hybrid時に埋め込みモデルを使った再ランキングを実装済み（Ollama/OpenAI互換）
- Project埋め込みを永続キャッシュし、添付非変更時の再計算を回避
- HTML Artifact表示を実装済み（チャット内ボタンから全画面表示）
- AI応答は吹き出しを使わず全幅表示（先頭に🤖、将来アイコン用スロット確保）
- AI応答行に読み上げボタンを追加（TTSで再生/停止）
- SettingsでTTS設定を変更可能（有効/言語/速度/音量/ピッチ）
- Speech SettingsはLanguageプルダウン + Rate/Volume/PitchスライダーUI
- Speech Settingsのテスト再生は単一トグルボタン（再生/停止切替）
- SpeechのLanguage候補は端末の利用可能言語一覧から自動取得
- Artifact Security Mode切替を実装済み（Safe / Interactive / Trusted）
- Artifact表示時にモード別CSP・JS許可・外部遷移制御を適用
- 主要経路の例外握りつぶしを削減し、警告ログを追加
- Integrations/MCP/Skill/Settings読込/履歴移行の失敗をログ可視化
- エラー可視化ポリシーを文書化し、共通ヘルパーを導入
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
- Project添付検索の高度化（外部ベクトルDB連携・大規模添付最適化）

## 運用上の注意

- APIキーはSecure Storageに保存し、設定ファイルには保存しない
- コスト計算は入力単価/出力単価（1M tokens基準）の概算
- トークン数がAPIレスポンスに含まれない場合は推定値で補完
- Agentic SearchはSearXNG `format=json` が失敗する場合、HTML抽出フォールバックを使用
- Artifactは `webview_flutter` でレンダリング（モード別CSP/制限を適用済み）
- 旧 `conversations.json` はSQLite移行時にバックアップ名へリネームされる
- MCPは現状 HTTP/HTTPS ブリッジ方式のみ実行（`command` にURLを設定）
- Skill実行は現状「定義内容の要約・手順抽出」を返す軽量実行方式
- 棚卸しレビュー: `docs/MAINTENANCE_REVIEW_2026-02-13.md`
- エラー可視化方針: `docs/ERROR_VISIBILITY_POLICY.md`
