# 🚀 NookNote - 5分でスタートガイド

このガイドに従えば、5分でNookNoteを手元で動かすことができます。

## ステップ 1: 必要なものを確認

✅ **macOS 12.0以降** (Monterey, Ventura, Sonoma)  
✅ **GitHubアカウント**  
✅ **ターミナル** (アプリケーション/ユーティリティ内)

## ステップ 2: プロジェクトを取得

ターミナルを開いて以下を実行：

```bash
# プロジェクトをクローン
git clone https://github.com/taizo-pro/nook-note.git
cd nook-note

# アプリをビルド（初回は時間がかかる場合があります）
swift build --configuration release
```

## ステップ 3: GitHubトークンを取得

1. [GitHub Personal Access Tokens](https://github.com/settings/tokens) を開く
2. **"Generate new token (classic)"** をクリック
3. 名前: `NookNote` など適当な名前
4. **以下の権限にチェック**:
   - `repo` (リポジトリアクセス)
   - `read:discussion` (ディスカッション読み取り)
   - `write:discussion` (ディスカッション書き込み)
5. **"Generate token"** をクリック
6. 🔴 **重要**: 表示されたトークンをコピー（後で見れません）

## ステップ 4: アプリを起動

```bash
# NookNoteを起動
swift run
```

メニューバーにNookNoteのアイコンが表示されます 🎉

## ステップ 5: 設定

1. メニューバーのNookNoteアイコンをクリック
2. **歯車アイコン** または `⌘,` で設定を開く
3. 以下を入力:
   - **Repository Owner**: あなたのGitHubユーザー名
   - **Repository Name**: 使いたいリポジトリ名
   - **Personal Access Token**: ステップ3でコピーしたトークン
4. **"Save Settings"** をクリック

## ステップ 6: 使ってみる！

- **ディスカッションを見る**: "Discussions" タブで既存のディスカッションを閲覧
- **新規投稿**: "New Post" タブまたは `⌘N` で新しいディスカッションを作成
- **検索**: 上部の検索バーでディスカッションを検索
- **詳細表示**: ディスカッションをクリックでコメントも見れます

## 🎯 便利なキーボードショートカット

| ショートカット | 動作 |
|---------------|------|
| `⌘N` | 新規投稿 |
| `⌘R` | 更新 |
| `⌘L` | フィルター切替 |
| `⌘F` | 検索にフォーカス |
| `⌘K` | フォームクリア |

## ❗ よくある問題

### "开发者无法验证" / "Cannot verify developer" エラー
1. Finderでアプリを右クリック → **"開く"**
2. **"開く"** を再度クリック

### ディスカッションが表示されない
- リポジトリ名とオーナー名が正しいか確認
- トークンに正しい権限があるか確認
- リポジトリでDiscussionsが有効になっているか確認

### ビルドエラー
```bash
# 依存関係をクリア
rm -rf .build
swift build --configuration release
```

## 🔧 開発者向け情報

```bash
# デバッグビルド
swift build

# テスト実行
swift test

# Xcodeで開く
open Package.swift
```

## 📞 サポート

問題があれば [Issues](https://github.com/taizo-pro/nook-note/issues) で報告してください！

---

**これで完了です！** 🎉 NookNoteを使ってGitHub Discussionsを快適に管理しましょう。