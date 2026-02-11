# 実装チェックリスト

## コード品質

### 基本
- [ ] `flutter analyze` がエラーなし
- [ ] `dart format` が適用されている
- [ ] lint警告が解消されている
- [ ] TODO/FIXMEにチケット番号が付いている

### 命名規則
- [ ] クラス名はUpperCamelCase
- [ ] 変数・関数名はlowerCamelCase
- [ ] 定数はlowerCamelCase
- [ ] ファイル名はsnake_case
- [ ] 意図が明確な命名

### コード構造
- [ ] 1ファイル400行以内を目安
- [ ] 1関数50行以内を目安
- [ ] 適切なWidget分割
- [ ] 重複コードなし

---

## Flutter/Dart

### Widget
- [ ] constコンストラクタを可能な限り使用
- [ ] StatelessWidget優先（Riverpod使用時）
- [ ] build()内で重い処理をしない
- [ ] 適切なKeyの使用（ListView等）

### パフォーマンス
- [ ] ListView.builderで遅延構築
- [ ] 画像キャッシュを使用
- [ ] 不要な再ビルドを避ける
- [ ] 重い処理はIsolateで実行

### メモリ管理
- [ ] dispose()でリソース解放
- [ ] StreamSubscriptionをキャンセル
- [ ] AnimationControllerをdispose

---

## 状態管理（Riverpod）

- [ ] コード生成（riverpod_generator）を使用
- [ ] AsyncValueを適切にハンドリング
- [ ] Providerの粒度が適切
- [ ] 循環参照なし

---

## エラーハンドリング

- [ ] try-catchで例外処理
- [ ] ユーザーフレンドリーなエラーメッセージ
- [ ] ログ記録（本番用）
- [ ] リトライ機構（ネットワーク系）

---

## UI/UX

- [ ] ローディング状態を表示
- [ ] エラー状態を表示
- [ ] 空状態を表示
- [ ] タッチフィードバック
- [ ] キーボード対応（TextFieldのfocus、dismiss）

---

## アクセシビリティ

- [ ] Semanticsラベル設定
- [ ] コントラスト比4.5:1以上
- [ ] タッチターゲット48dp以上
- [ ] スクリーンリーダー対応確認

---

## セキュリティ

- [ ] ハードコードされた秘密情報なし
- [ ] 機密データはSecureStorage使用
- [ ] 入力値バリデーション
- [ ] ログに機密情報を出力しない

---

## テスト

- [ ] 新規コードにユニットテスト
- [ ] 新規画面にウィジェットテスト
- [ ] カバレッジ目標達成（80%目安）
- [ ] エッジケースがテストされている
