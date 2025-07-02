# GitHub Discussions MenuBar App - 実装計画

## プロジェクト概要
GitHub DiscussionsにアクセスするmacOSメニューバーアプリを開発し、GitHub Releasesで無料配布する。

## 配布方針
- **配布方法**: GitHub Releases (.dmg)
- **コスト**: 完全無料（Apple Developer Program不要）
- **署名**: 自己署名証明書使用
- **制限**: 初回起動時にmacOSセキュリティ警告あり

## Phase 1: プロジェクト基盤構築 (1-2週間)

### 1.1 GitHubリポジトリ作成
- パブリックリポジトリ作成
- 適切なライセンス設定（MIT推奨）
- 基本的な.gitignore設定

### 1.2 Xcodeプロジェクト作成
- Swift macOSアプリプロジェクト初期化
- Bundle Identifier設定
- 最小バージョン設定（macOS 12.0+）

### 1.3 プロジェクト構造設定
- MVC/MVVM架構設計
- フォルダ構成（Models, Views, Controllers, Services）
- ビルド設定、スキーム設定

### 1.4 依存関係管理
- Swift Package Manager設定
- 必要ライブラリの選定・追加

## Phase 2: 基本アプリ骨格実装 (1-2週間)

### 2.1 MenuBarアプリ基盤
- NSStatusItem実装
- NSPopover設定
- メニューバーアイコン設定

### 2.2 基本UI構造
- SwiftUI ViewHierarchy構築
- ナビゲーション構造設計
- 基本レイアウト実装

### 2.3 設定画面
- リポジトリURL入力画面
- Personal Access Token入力画面
- 基本設定UI実装

### 2.4 データモデル
- Discussion構造体
- Comment構造体
- User構造体
- 設定データモデル

### 2.5 アプリライフサイクル
- 起動時処理
- 終了処理
- バックグラウンド処理

## Phase 3: GitHub API統合 (2-3週間)

### 3.1 認証システム
- Personal Access Token管理
- Keychain統合（認証情報安全保存）
- 認証状態管理

### 3.2 GitHub API Client
- URLSession設定
- GraphQL APIクライアント実装
- REST APIクライアント実装
- async/await対応

### 3.3 Discussions API
- Discussions一覧取得
- Discussion詳細取得
- コメント取得
- 新規Discussion作成
- コメント投稿

### 3.4 エラーハンドリング
- ネットワークエラー処理
- 認証エラー処理
- レート制限対応
- ユーザーフレンドリーなエラーメッセージ

## Phase 4: コア機能実装 (2-3週間)

### 4.1 Discussions一覧機能
- 一覧表示
- 検索・フィルタ機能
- ページネーション
- リフレッシュ機能

### 4.2 コメント投稿機能
- 新規Discussion作成
- 既存Discussionへの返信
- マークダウン対応
- プレビュー機能

### 4.3 リアルタイム更新
- 定期的データ同期
- バックグラウンド更新
- 更新通知

### 4.4 設定管理
- UserDefaults連携
- 設定の永続化
- 設定画面とのデータバインディング

### 4.5 通知システム
- 投稿成功/失敗フィードバック
- システム通知
- ステータス表示

## Phase 5: UI/UX向上 (1-2週間)

### 5.1 デザインシステム
- カラーパレット定義
- フォント設定
- コンポーネント統一

### 5.2 ローディング状態
- プログレスインジケータ
- スケルトンUI
- ローディングスピナー

### 5.3 キーボードショートカット
- ⌘N: 新規投稿
- ⌘R: リフレッシュ
- ⌘W: ウィンドウ閉じる

### 5.4 レスポンシブデザイン
- ポップアップサイズ最適化
- コンテンツの適応的レイアウト
- テキストサイズ対応

### 5.5 アニメーション
- 画面遷移アニメーション
- フィードバックアニメーション
- ローディングアニメーション

## Phase 6: テスト・品質保証 (1-2週間)

### 6.1 Unit Tests
- API Clientテスト
- データモデルテスト
- ビジネスロジックテスト
- テストカバレッジ80%以上

### 6.2 Integration Tests
- GitHub API連携テスト
- 認証フローテスト
- エラーハンドリングテスト

### 6.3 UI Tests
- 主要ユーザーフロー自動化
- アクセシビリティテスト
- キーボードナビゲーションテスト

### 6.4 手動テスト
- 実際の使用シナリオ検証
- エッジケーステスト
- ユーザビリティテスト

### 6.5 パフォーマンステスト
- メモリ使用量測定
- 起動速度測定
- API応答時間測定

## Phase 7: GitHub Releases配布準備 (1週間)

### 7.1 アプリアイコン
- 1024x1024 アイコン作成
- 各サイズ（16, 32, 128, 256, 512px）生成
- アイコンファイル統合

### 7.2 署名・パッケージング
- 自己署名証明書作成
- アプリケーション署名
- DMGファイル作成（create-dmgツール使用）

### 7.3 GitHub Actions CI/CD
- 自動ビルドワークフロー
- 自動テストワークフロー
- 自動リリースワークフロー

### 7.4 インストール手順
- 「開発元不明」警告対処法
- ステップバイステップガイド
- トラブルシューティング

## Phase 8: ドキュメント・サポート (1週間)

### 8.1 README.md
- プロジェクト概要
- 機能説明
- インストール手順
- 使用方法
- スクリーンショット

### 8.2 CHANGELOG.md
- バージョン履歴管理
- 変更点記録
- 既知の問題

### 8.3 ライセンス・法的事項
- LICENSE ファイル（MIT推奨）
- PRIVACY_POLICY.md
- 利用規約

### 8.4 コントリビューション
- CONTRIBUTING.md
- 開発者向けガイド
- コードスタイルガイド

### 8.5 GitHub Issues設定
- バグ報告テンプレート
- 機能要望テンプレート
- プルリクエストテンプレート

## 技術構成詳細

### 開発環境
- **言語**: Swift 5.9+
- **IDE**: Xcode 15+
- **最小バージョン**: macOS 12.0 (Monterey)

### フレームワーク・ライブラリ
- **UI**: SwiftUI
- **非同期処理**: Combine, async/await
- **ネットワーク**: URLSession
- **データ永続化**: UserDefaults, Keychain Services
- **テスト**: XCTest

### GitHub API
- **API バージョン**: GraphQL API v4, REST API v3
- **認証**: Personal Access Token
- **スコープ**: repo, read:discussion, write:discussion

### 配布・デプロイ
- **パッケージング**: create-dmg
- **CI/CD**: GitHub Actions
- **配布**: GitHub Releases
- **署名**: 自己署名証明書

## 無料配布の制約と対処法

### 制約
- 初回起動時に「開発元不明」の警告
- 自動更新機能なし
- Apple公式の信頼マークなし

### 対処法
- 詳細なインストール手順提供
- セキュリティ設定変更ガイド
- コミュニティサポート強化

## 予想開発期間
**合計: 8-12週間**
- Phase 1-2: 2-4週間
- Phase 3-4: 4-6週間
- Phase 5-6: 2-4週間
- Phase 7-8: 2週間

## リスク管理
- GitHub API仕様変更リスク
- macOS Security Policy変更リスク
- 開発期間の延長リスク

各フェーズ完了時にレビュー・調整を行い、次フェーズ開始前に方向性を確認します。