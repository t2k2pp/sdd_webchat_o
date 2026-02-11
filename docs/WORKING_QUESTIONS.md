# Working Questions & Assumptions

更新日: 2026-02-11
目的: 離席中でも実装を止めないため、未確定事項を明示し、暫定前提で進行する。

## Open Questions

1. 想定する初期ターゲット最小OSバージョン
- Android minSdkVersion
- iOS/iPadOS deployment target

2. 初期UI言語
- 日本語固定
- 日本語/英語切替

3. 初期接続先の優先順位
- Ollama優先
- LM Studio優先
- llama.cpp優先

4. SearXNGの初期既定値
- ON/OFF
- タイムアウト
- safesearch

5. HTML Artifact のセキュリティポリシー
- JavaScript禁止を既定にするか
- 外部リソース読み込みの可否

6. 履歴DB運用ポリシー
- JSON移行後バックアップファイルを自動削除するか
- 履歴DBの暗号化を必須化するか

7. MCPブリッジ仕様の確定
- `POST /tools/call` 以外に `tools/list` などの標準エンドポイント互換をどこまで持つか
- 認証方式（Bearer固定 / APIキー / mTLS）の標準化

8. Skill実行の拡張範囲
- 現在の要約/手順抽出ベースから、スクリプト実行型まで広げるか
- Skillごとの権限境界（ファイル読取のみ/書込可/外部アクセス可）をどう定義するか

## Default Assumptions (現在の実装前提)

- Flutter stable最新で進める
- Android min SDKは Flutter既定値を維持（後で確定）
- iOS targetは Flutter既定値を維持（後で確定）
- 初期言語は日本語ベース（内部実装はi18n拡張可能にする）
- 初期LLM接続は Ollama を第一候補
- SearXNGは既定OFF（チャットで即時切替可能）
- Artifact HTML は将来的に sandbox 表示。Phase 0ではプレースホルダーまで
- 接続先既定値:
  - Ollama: `http://192.168.1.40:11434`
  - SearXNG: `http://192.168.1.40:8080`
  - 既定モデル: `qwen3-coder-next`

## Confirmation Checklist (作業再開時に確認)

- [ ] 最小OSバージョンの確定
- [ ] 初期UI言語方針の確定
- [ ] デフォルトLLM接続先の確定
- [ ] SearXNG既定値の確定
- [ ] HTML Artifact セキュリティ方針の確定
- [ ] 履歴DBバックアップ/暗号化方針の確定
- [ ] MCPブリッジAPI/認証方針の確定
- [ ] Skill実行の権限モデル確定
