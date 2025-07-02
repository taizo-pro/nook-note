# ADR-001: GitHub Discussions MenuBar App の技術スタック選択

## ステータス
提案中

## コンテキスト
GitHub DiscussionsにアクセスするmacOSメニューバーアプリを開発する。
主な要件：
- メニューバーからの素早いアクセス
- GitHub API連携
- 作業ログ・メモ投稿機能
- 単一リポジトリ対応（設定可能）

## 検討した選択肢

### 選択肢1: Swift + SwiftUI (ネイティブ)
**メリット：**
- メニューバーアプリに最適化
- ネイティブ性能、低メモリ使用量
- macOS統合（Keychain、通知など）
- App Store配布可能

**デメリット：**
- Swift学習コストが高い
- macOS専用（移植性なし）
- GitHub API実装が一から必要

### 選択肢2: Electron + TypeScript/React
**メリット：**
- Web技術で開発可能
- GitHub API豊富なライブラリ
- クロスプラットフォーム対応
- 開発速度が早い

**デメリット：**
- メモリ使用量大（100MB+）
- 起動速度遅い
- バッテリー消費大

### 選択肢3: Tauri + Rust/TypeScript
**メリット：**
- 軽量（10-20MB）
- セキュア（Rust）
- Web技術でUI
- クロスプラットフォーム

**デメリット：**
- 比較的新しい技術
- macOSメニューバー対応が限定的
- コミュニティが小さい

### 選択肢4: Flutter Desktop
**メリット：**
- 単一コードベース
- 高性能UI
- 豊富なパッケージ

**デメリット：**
- デスクトップ対応が発展途上
- メニューバーアプリ作成が困難
- 学習コスト

## 決定
**Swift + SwiftUI** を選択

## 理由
1. **メニューバーアプリに最適**: NSStatusItem、NSPopoverの標準サポート
2. **ネイティブ体験**: macOSユーザーに馴染む操作性
3. **性能**: 低メモリ、高速起動、バッテリー効率
4. **統合**: Keychain認証、システム通知の自然な連携
5. **長期保守性**: Apple公式技術で将来性が高い

## トレードオフ
- Swift学習コストを受け入れる
- macOS専用となるが、要件上問題なし
- GitHub API実装コストはライブラリで軽減可能

## 実装方針
- SwiftUI for UI
- Combine for 非同期処理
- URLSession for GitHub API
- Keychain Services for 認証情報保存