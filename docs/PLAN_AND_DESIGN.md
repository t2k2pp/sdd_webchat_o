# SDD WebChat モバイルアプリ 計画・設計

最終更新: 2026-02-12
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
- SearXNG ON/OFFトグル
- モデル接続先の複数登録、選択、編集、削除
- モデルプロバイダ実装
  - Ollama
  - OpenAI互換（LM Studio / llama.cpp）
  - Gemini API
  - Azure OpenAI
- 設定画面のセクション分割
  - Search
  - System Prompt
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
- Agentic Search反復実行（SearXNG検索 + 確信値判定 + 次クエリ反復）
- 会話履歴のローカル永続化（ファイルベース）
- 履歴のコピー / エクスポート(Markdown) / 共有
- 履歴から会話を再ロードしてチャット再開
- Project機能
  - プロジェクト作成/編集/削除
  - アクティブプロジェクト選択
  - 追加システムプロンプト設定
  - 事前添付ファイル登録
  - チャット時にプロジェクト文脈を注入
- HTML Artifact表示
  - LLM応答からHTMLを抽出
  - ChatメッセージからArtifactを全画面表示
- Integrations機能
  - Skillsレジストリ（追加/有効化/削除）
  - Sub Agentsレジストリ（追加/選択/削除）
  - MCPサーバーレジストリ（追加/有効化/削除）
  - チャット時に有効設定をsystem文脈へ注入

### 未実装（計画残）
- 会話履歴のDB移行（現状ファイルベース）
- トークン/コストの日次・月次レポート

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
  - `InMemorySettingsRepository`（暫定）

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

1. 設定の永続化（secure storage + DB）
2. 履歴/設定のDB正規化
3. プロジェクト添付の高度化（検索インデックス/埋め込み）
4. Artifactの安全ポリシー強化（sandbox/CSP）
5. Integrations実行連携（MCP実行ハンドラ/Skill実行器）
