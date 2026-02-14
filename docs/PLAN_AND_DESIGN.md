# SDD WebChat モバイルアプリ 計画・設計

最終更新: 2026-02-13
対象: Android / iOS / iPadOS

## 1. ゴール

ローカルLLM中心のチャットアプリをFlutterで構築し、必要に応じてWeb検索（SearXNG）を使えるようにする。

- チャットUI
- SearXNG ON/OFF
- 複数モデル接続先の登録・選択
- Ollama / LM Studio / llama.cpp / Gemini API / Azure OpenAI 接続
- システムプロンプト設定
- Agentic Searchの設定（反復上限・確信閾値）
- トークン利用量と概算コスト可視化

## 2. 現在の実装状況

### 実装済み
- Flutterアプリ基盤（Riverpod / GoRouter / 画面骨格）
- ハンバーガーメニュー導線（Chat / Projects / History / Settings）
- チャット入力UI（最大7行拡張 + 下段アイコン列 + 送信アイコン）
- AI応答のMarkdownレンダリング表示（assistantは全幅レイアウト）
- チャット入力UIのポップアップ操作（SearXNG ON/OFF + モデル切替）
- チャット実行中の進捗表示（段階テキスト + 進捗インジケータ）
- 受け入れテスト（Widget）を追加し、主要UXを自動検証
- SearXNG ON/OFFトグル
- モデル接続先の複数登録、選択、編集、削除
- モデルプロバイダ実装
  - Ollama
  - OpenAI互換（LM Studio / llama.cpp）
  - Gemini API
  - Azure OpenAI
- 設定画面のセクション分割
  - Search
    - レンジ値は選択UI（slider/dropdown）を優先
  - System Prompt
  - Speech (TTS)
    - 言語候補は端末一覧から動的取得
  - Artifact Security
    - Safe / Interactive / Trusted の切替
  - Model Endpoints
- 全画面編集UI（ポップアップ廃止）
- モデル単位のトークン集計
  - 入力トークン総数
  - 出力トークン総数
- モデル単位の概算コスト算出
  - 実コスト
  - 比較用コスト
  - 節約額
- トークン集計リセット機能
- Usage Reports（日次/月次のトークン・コスト集計）
- 設定の永続化
  - `app_settings.json` への保存
  - API KeyのSecure Storage保存（平文ファイルに非保持）
- Agentic Search反復実行（SearXNG検索 + 確信値判定 + 次クエリ反復）
- Agentic Searchの実行トレース表示（query/hits/urls）
- 会話履歴のローカル永続化（SQLite、旧JSONから自動移行）
- 履歴のコピー / エクスポート(Markdown) / 共有
- 履歴から会話を再ロードしてチャット再開
- Project機能
  - プロジェクト作成/編集/削除
  - アクティブプロジェクト選択
  - 追加システムプロンプト設定
  - 事前添付ファイル登録
  - チャット時にプロジェクト文脈を注入
  - 添付検索モード切替（RAG / Agentic Search）
  - Retrieval Mode切替（Lexical / Hybrid）
  - 埋め込みモデル設定（空欄時は選択中チャットモデルを利用）
  - 添付チャンク索引化 + BM25風ランキング
  - Hybrid検索（BM25 + 埋め込み再ランキング）
  - 埋め込みの永続キャッシュ（添付非変更時は再利用）
- HTML Artifact表示
  - LLM応答からHTMLを抽出
  - ChatメッセージからArtifactを全画面表示
  - モード別セキュリティ（CSP/JS/外部遷移）を適用
- Integrations機能
  - Skillsレジストリ（追加/有効化/削除）
  - Sub Agentsレジストリ（追加/選択/削除）
  - MCPサーバーレジストリ（追加/有効化/削除）
  - チャット時に有効設定をsystem文脈へ注入
  - MCP実行連携（HTTPブリッジ `POST /tools/call`）
  - Skill実行器（Skill JSON要求の実行 + 結果再注入）

## 3. 現在のアーキテクチャ

- Presentation
  - `ChatScreen`
  - `ProjectsScreen`
  - `HistoryScreen`
  - `SettingsScreen` + セクションページ
- Application
  - `ChatController`
  - `SettingsController`
- Domain
  - `ChatMessage`
  - `ModelEndpoint`
  - `AppSettings`
- Data
  - `OllamaClient`
  - `OpenAiCompatibleClient`
  - `GeminiClient`
  - `AzureOpenAiClient`
  - `FileSettingsRepository`（設定JSON + Secure Storage）

## 4. 設定仕様（現行）

### Search
- SearXNG default ON/OFF
- SearXNG Base URL
- Agentic Search Policy
  - max iterations
  - confidence threshold
  - time range
  - safesearch

### System Prompt
- グローバルシステムプロンプト（全画面編集）

### Model Endpoints
- 複数エンドポイント登録
- 選択中エンドポイント1件のみチャットで利用
- エンドポイント項目
  - Provider
  - Name
  - Base URL
  - Model / Deployment
  - API Key（必要プロバイダのみ）
  - Azure API Version
  - Temperature
  - Max Tokens
  - Currency
  - Actual Input/Output Cost per 1M
  - Reference Input/Output Cost per 1M
- Usage
  - Input/Outputトークン総数
  - Actual / Reference / Saved 概算コスト
  - Usage reset

## 5. 次フェーズ優先度

1. プロジェクト添付の高度化（外部ベクトルDB連携・大規模添付最適化）
2. Artifactの安全ポリシー強化（sandbox/CSP）
