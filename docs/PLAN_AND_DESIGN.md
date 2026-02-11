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

### 未実装（計画残）
- Agentic Web Search本体（検索反復オーケストレータ）
- 会話履歴の永続化（DB運用）
- チャットエクスポート/共有
- HTML Artifact表示
- Project機能（添付ファイル・追加プロンプト）
- Skills/SubAgents/MCP統合本体
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

1. Agentic Search本体実装（反復停止条件込み）
2. 設定の永続化（secure storage + DB）
3. 履歴/エクスポート/共有
4. Project機能
5. Skills/SubAgents/MCP

