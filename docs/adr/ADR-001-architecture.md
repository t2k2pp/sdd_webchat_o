# ADR-001: Flutter + Clean Architecture + Riverpod を採用

- Status: Accepted
- Date: 2026-02-11

## Context
Android / iOS / iPadOS を単一コードベースで高速開発しつつ、LLM・検索・MCP統合のような拡張を長期運用したい。

## Decision
- Flutterを採用してクロスプラットフォームを実現
- Clean Architectureで関心分離
- Riverpodで状態管理と依存性注入を統一

## Consequences
### Positive
- 共有コード最大化で開発速度向上
- 機能追加時の影響範囲を限定
- テストしやすい構造

### Negative
- 初期設計コストが上がる
- レイヤー分割による実装量増加
