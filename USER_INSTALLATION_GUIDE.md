# 📱 NookNote インストール＆使用ガイド

**NookNoteを初めて使う方向けの完全ガイドです。プログラミング知識は不要です！**

---

## 📋 事前準備（5分）

### 必要なもの
- ✅ **Mac** (macOS 12.0以降 - 2021年以降のMacなら大丈夫)
- ✅ **GitHubアカウント** (無料で作成可能)
- ✅ **使いたいGitHubリポジトリ** (自分のでも他人のでもOK)

### GitHubアカウントがない場合
1. [GitHub.com](https://github.com) にアクセス
2. **Sign up** をクリックして無料アカウントを作成

---

## 🔑 ステップ1: GitHubアクセストークンの作成（3分）

NookNoteがあなたのGitHubアカウントでDiscussionsにアクセスするための「鍵」を作ります。

### 1-1. GitHubにログイン
1. [GitHub.com](https://github.com) でログイン
2. 右上の **自分のアイコン** をクリック
3. **Settings** (設定) を選択

![GitHub Settings](https://docs.github.com/assets/cb-34573/images/help/settings/userbar-account-settings.png)

### 1-2. トークン作成ページへ
1. 左サイドバーの一番下 **Developer settings** をクリック
2. **Personal access tokens** → **Tokens (classic)** をクリック
3. **Generate new token** → **Generate new token (classic)** を選択

### 1-3. トークンの設定
以下のように設定してください：

| 項目 | 設定値 |
|------|--------|
| **Note** | `NookNote App` (何のトークンか分かる名前) |
| **Expiration** | `90 days` または `No expiration` |
| **Select scopes** | 以下の3つにチェック ✅ |

**重要**: 以下の3つの権限に必ずチェックを入れてください：
- ✅ **`repo`** - リポジトリへのアクセス
- ✅ **`read:discussion`** - Discussionの読み取り  
- ✅ **`write:discussion`** - Discussionの書き込み

### 1-4. トークンを保存
1. **Generate token** をクリック
2. **⚠️ 超重要**: 表示された長い文字列をコピーして、どこかに保存
   - 例: `ghp_1234567890abcdefghijklmnopqrstuvwxyz`
   - **この画面を閉じると二度と見れません！**
   - メモ帳などに一時的に保存してください

---

## 📦 ステップ2: NookNoteのダウンロード＆インストール（2分）

### 2-1. アプリをダウンロード
1. 👉 **[こちらからNookNoteをダウンロード](https://github.com/taizo-pro/nook-note/releases/latest)**
2. **Assets** の下にある `NookNote-v1.0.0.dmg` をクリック
3. ダウンロードが完了するまで待つ（約1.4MB、数秒で完了）

### 2-2. インストール
1. ダウンロードした `NookNote-v1.0.0.dmg` ファイルをダブルクリック
2. 新しいウィンドウが開いたら、**NookNote.app** を **Applications** フォルダにドラッグ&ドロップ
3. DMGウィンドウを閉じる（右クリック → 取り出し）

![DMG Installation](https://support.apple.com/library/content/dam/edam/applecare/images/en_US/macos/Big-Sur/macos-big-sur-installer-drag-to-applications.jpg)

### 2-3. 初回起動（重要！）
macOSのセキュリティ機能により、初回だけ特別な手順が必要です：

1. **Finder** → **アプリケーション** フォルダを開く
2. **NookNote** アプリを探す
3. **右クリック** → **開く** を選択（ダブルクリックではダメ）
4. 「開発元を確認できません」という警告が出たら **開く** をクリック

![Security Warning](https://support.apple.com/library/content/dam/edam/applecare/images/en_US/macos/Big-Sur/macos-big-sur-security-privacy-gatekeeper-open-anyway.jpg)

> 💡 **なぜこの手順が必要？**: NookNoteは無料配布のため、Apple Developer Program（年間$99）に参加していません。そのため、最初だけ手動で安全性を確認する必要があります。

---

## ⚙️ ステップ3: NookNoteの設定（2分）

### 3-1. アプリが起動したことを確認
- メニューバー（画面上部）にNookNoteの小さなアイコンが表示されます
- 見つからない場合は、時計の近くを探してください

### 3-2. 設定画面を開く
1. メニューバーのNookNoteアイコンをクリック
2. ポップアップが表示されたら、⚙️（歯車）アイコンをクリック
   - または、キーボードで `⌘,`（Command + カンマ）を押す

### 3-3. GitHub情報を入力
設定画面で以下の3つを入力します：

#### Repository Owner（リポジトリ所有者）
- **自分のリポジトリの場合**: GitHubのユーザー名
  - 例: `yamada-taro` 
- **他人/会社のリポジトリの場合**: その所有者名
  - 例: `microsoft`, `apple`, `google`

#### Repository Name（リポジトリ名）
- 使いたいリポジトリの名前
  - 例: `my-project`, `vscode`, `swift`

#### Personal Access Token（アクセストークン）
- ステップ1で作成した長い文字列を貼り付け
  - 例: `ghp_1234567890abcdefghijklmnopqrstuvwxyz`

### 3-4. 設定を保存
1. **Save Settings** ボタンをクリック
2. 「設定が保存されました」のようなメッセージが表示されればOK

---

## 🎉 ステップ4: 使ってみよう！（実際の操作）

### 4-1. Discussionsを見る
1. メニューバーのNookNoteアイコンをクリック
2. 「Discussions」タブが選択されていることを確認
3. リポジトリのDiscussion一覧が表示されます
4. 任意のDiscussionをクリックして詳細を確認

### 4-2. 新しいDiscussionを投稿
1. **New Post** タブをクリック
2. 以下を入力：
   - **Category**: General, Ideas, Q&A, Show and tellから選択
   - **Title**: 分かりやすいタイトル
   - **Body**: 内容（普通の文章でOK、Markdown記法も使用可能）
3. 入力完了したら **Post** ボタンをクリック
   - または `⌘ + Enter`（Command + Enter）で投稿

### 4-3. コメントを追加
1. 既存のDiscussionを開く
2. 下部のコメント入力欄に返信内容を入力
3. **Comment** ボタンをクリックまたは `⌘ + Enter`

### 4-4. 便利な機能
- **検索**: 上部の検索バーでDiscussionを検索
- **フィルター**: カテゴリーや状態でDiscussionを絞り込み
- **更新**: `⌘ + R` で最新のDiscussionを取得
- **設定**: `⌘ + ,` で設定画面を開く

---

## ⌨️ 覚えておくと便利なキーボードショートカット

| キー | 動作 |
|------|------|
| `⌘ + N` | 新しいDiscussion作成 |
| `⌘ + R` | Discussionを更新 |
| `⌘ + F` | 検索バーにフォーカス |
| `⌘ + ,` | 設定画面を開く |
| `⌘ + W` | ウィンドウを閉じる |
| `⌘ + Enter` | 投稿・コメント送信 |

---

## 🚨 よくある問題と解決方法

### ❌ 問題1: 「開発元を確認できません」エラー
**解決法**: 必ず **右クリック → 開く** を使用してください。普通のダブルクリックでは開けません。

### ❌ 問題2: アプリが起動しない
**解決法**: 
1. **システム設定** → **プライバシーとセキュリティ** を開く
2. **セキュリティ** セクションで **このまま開く** をクリック

### ❌ 問題3: 「GitHub APIエラー」が表示される
**解決法**:
1. Personal Access Tokenが正しくコピーされているか確認
2. トークンの権限（repo, read:discussion, write:discussion）が設定されているか確認
3. Repository OwnerとRepository Nameのスペルが正しいか確認

### ❌ 問題4: Discussionsが表示されない
**解決法**:
1. 指定したリポジトリでDiscussions機能が有効になっているか確認
   - リポジトリページの **Settings** → **Features** → **Discussions** がオンになっているか
2. プライベートリポジトリの場合、トークンにアクセス権限があるか確認

### ❌ 問題5: メニューバーにアイコンが見つからない
**解決法**:
1. メニューバーの右端（時計の近く）を確認
2. メニューバーが満杯の場合、他のアプリを非表示にする
3. macOSを再起動してから再度確認

---

## 🆘 それでも解決しない場合

### コミュニティに質問
- **GitHub Discussions**: [質問・相談フォーラム](https://github.com/taizo-pro/nook-note/discussions)
- **バグ報告**: [GitHub Issues](https://github.com/taizo-pro/nook-note/issues/new/choose)

### 質問する時に含めてほしい情報
1. macOSのバージョン（システム設定 → 一般 → 情報で確認）
2. NookNoteのバージョン（v1.0.0など）
3. エラーメッセージの正確な内容
4. 何をしようとした時に問題が発生したか

---

## 🎯 上級者向けのヒント

### カスタマイズ
- **更新頻度**: 設定で自動更新の間隔を調整可能
- **通知**: システム通知のオン・オフを設定可能
- **テーマ**: macOSのダーク/ライトモードに自動対応

### 複数リポジトリの使用
現在は1つのリポジトリのみ対応。複数のリポジトリを使いたい場合は設定を変更して切り替え。

### セキュリティ
- Personal Access Tokenは安全に保管
- 定期的にトークンを更新（90日期限を設定している場合）
- 不要になったトークンはGitHubで削除

---

## 🎉 完了！

**おめでとうございます！** NookNoteのセットアップが完了しました。

これで、GitHubのDiscussionsをMacのメニューバーから素早くアクセスできるようになりました。質問、アイデア、ディスカッションを気軽に投稿・閲覧して、オープンソースコミュニティに参加しましょう！

**楽しいGitHub Discussionsライフを！** 🚀