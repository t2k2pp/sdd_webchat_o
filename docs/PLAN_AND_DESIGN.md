# SDD WebChat モバイルアプリ 計画・設計

最終更新: 2026-02-11
対象: Android / iOS / iPadOS

## 1. ゴール

ローカルで動くLLMに対して、以下を提供するクロスプラットフォームモバイルアプリを構築する。

- チャットUI
- SearXNG検索のON/OFF切替
- Agentic Web Search（検索→評価→再検索の反復）
- Ollama / LM Studio / llama.cpp 接続
- AgentSkills / Sub Agents / MCP 利用
- コンテキスト圧縮による長時間会話継続
- HTMLアーティファクト表示
- 会話履歴 / エクスポート / クリップボード / 外部共有
- システムプロンプト設定
- プロジェクト単位で追加システムプロンプトと事前添付ファイル

## 2. 技術スタック

- フレームワーク: Flutter (Dart)
- アーキテクチャ: Clean Architecture + Feature First
- 状態管理: Riverpod (code generation)
- 永続化: Drift(SQLite) + flutter_secure_storage
- 通信: dio
- Markdown/HTML表示: flutter_markdown + flutter_inappwebview(サンドボックス表示)
- ファイル連携: file_picker, share_plus

## 3. 高レベル構成

- Presentation Layer
  - Chat画面 / 履歴画面 / 設定画面 / プロジェクト画面
- Application Layer
  - Chat Orchestrator
  - Agentic Search Orchestrator
  - Compression Manager
  - Skill/SubAgent/MCP Resolver
- Domain Layer
  - Message, Conversation, Project, ModelEndpoint, SearchPolicy, ToolCall
- Data Layer
  - Local DB(履歴・設定)
  - LLM Gateway (Ollama/LM Studio/llama.cpp)
  - SearXNG Client
  - Skills Provider(agentskills.io)
  - SubAgents Provider(Claude Sub Agents形式)
  - MCP Client

## 4. 主要機能設計

### 4.1 LLM接続

- 共通インターフェース `LlmProviderClient`
- 実装:
  - `OllamaClient` (例: `http://<pc>:11434`)
  - `LmStudioClient` (OpenAI互換エンドポイント)
  - `LlamaCppClient` (サーバーモードのHTTP API)
- ストリーミング応答を標準化し、UIへ逐次反映

### 4.2 SearXNG ON/OFF

- チャット入力欄にトグルを配置
- 会話単位で状態保持（メッセージ送信時に設定スナップショットを保存）
- トグルOFF時は検索ツール呼び出しを禁止

### 4.3 Agentic Web Search

入力: 質問、最大反復回数 `max_iterations`、確信閾値 `confidence_threshold`

1. LLMが検索クエリを生成
2. SearXNG検索
3. 上位結果を抽出・要約
4. LLMが「回答候補 + 確信値(0.0-1.0)」を生成
5. `確信値 >= 閾値` なら終了
6. 未達なら検索クエリを改善して再試行
7. `max_iterations` 到達で最善回答を返却

無限ループ防止:
- `max_iterations` を必須設定
- 同一クエリの重複実行検知
- 最小改善量未満が連続した場合は早期停止

### 4.4 設定

- 接続設定
  - SearXNG Base URL / Timeout / Safesearch
  - Ollama URL
  - LM Studio URL
  - llama.cpp URL
- Agentic Search設定
  - 最大反復回数
  - 確信閾値
  - 既定ON/OFF
- システムプロンプト
  - グローバル
  - プロジェクト単位上書き

### 4.5 Skills / Sub Agents / MCP

- AgentSkills:
  - `https://agentskills.io/home` をソースとしてSkillメタ情報を同期
  - ローカルキャッシュしてオフライン参照可能にする
- Sub Agents:
  - Claude Sub Agents形式を取り込むパーサーを用意
  - ロール定義を会話実行時に選択可能
- MCP:
  - MCPサーバー定義(名称/コマンド/引数/環境変数)を管理
  - ツール一覧取得・実行を統一IFで扱う

### 4.6 コンテキスト圧縮

- トークン見積り器で閾値超過前に圧縮実行
- 圧縮は「要約 + 重要事実 + 未解決タスク + 禁止事項」を保持
- 原文は履歴DBに保持し、推論コンテキストは圧縮版を使用

### 4.7 アーティファクトHTML表示

- 応答内HTMLを「Artifact」として分離
- WebViewで表示（JS制限、外部URL制限、ローカルのみ許可ポリシー）

### 4.8 履歴 / エクスポート / 共有

- 会話一覧、検索、ピン留め
- JSON / Markdown / TXT でエクスポート
- クリップボードコピー
- `share_plus` で他アプリ連携

### 4.9 プロジェクト機能

- `Project` に以下を保持
  - 追加システムプロンプト
  - 事前添付ファイル群（ローカル参照）
  - モデル・検索ポリシーの既定値

## 5. データモデル（初期）

- Conversation(id, projectId, title, createdAt, updatedAt)
- Message(id, conversationId, role, content, artifactHtml, createdAt)
- Project(id, name, extraSystemPrompt, createdAt)
- ProjectAsset(id, projectId, filePath, mimeType, digest)
- EndpointConfig(id, providerType, baseUrl, apiKeyRef, timeoutMs)
- SearchPolicy(id, enabled, maxIterations, confidenceThreshold, timeRange, safesearch)
- SkillDef(id, source, name, version, body, updatedAt)
- SubAgentDef(id, name, role, instruction, toolsJson)
- McpServerDef(id, name, command, argsJson, envJson, enabled)

## 6. セキュリティ方針

- APIキー/トークンは `flutter_secure_storage`
- 通信はHTTPS優先（ローカル接続はユーザー明示許可）
- ログから機密情報をマスク
- HTML表示はサンドボックス化
- 外部実行(MCP)は許可制・監査ログ保存

## 7. 実装フェーズ計画

### Phase 0: 基盤
- Flutterプロジェクト作成
- Riverpod, Drift, dio, secure storage導入
- 画面遷移/テーマ/ロガー

### Phase 1: チャットMVP
- 会話作成・送受信
- Ollama接続
- 履歴保存・再表示

### Phase 2: マルチLLM
- LM Studio / llama.cpp 接続追加
- Provider切替UI

### Phase 3: SearXNG + Agentic Search
- SearXNGクライアント
- チャットトグルON/OFF
- 反復検索オーケストレータ
- 閾値・反復回数設定

### Phase 4: 拡張機能
- 圧縮機能
- Artifact HTML表示
- エクスポート/コピー/共有

### Phase 5: Skills/SubAgents/MCP
- Skill同期
- SubAgent実行文脈注入
- MCPサーバー登録/ツール実行

### Phase 6: 品質・公開準備
- セキュリティレビュー
- iOS/iPadOS/Android実機確認
- ストア提出準備

## 8. 主要リスクと対策

- ローカルLLM API差分: プロバイダアダプタ層で吸収
- 検索反復の遅延: タイムアウトと早期停止条件
- トークン枯渇: 事前圧縮 + 優先メモリ保持
- HTML安全性: 表示サンドボックス + CSP制限
- MCP外部依存: 接続テストと障害時フォールバック

## 9. 次の実装起点

1. Flutterプロジェクトひな型作成
2. `lib/features/chat` のMVP実装
3. `lib/features/settings` で接続設定保存
4. Ollama接続E2E確認
