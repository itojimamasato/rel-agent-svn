# SVN Server on Railway

Apache + mod_dav_svn による WebDAV ベースの SVN サーバー。

## 構成

| コンポーネント | 内容 |
|---|---|
| ベースイメージ | ubuntu:22.04 |
| SVN方式 | WebDAV (mod_dav_svn) |
| 認証 | Basic認証 (htpasswd) |
| HTTPS | Railway プロキシが終端（Apache は HTTP） |
| 永続化 | Railway Volume → `/svn` |

## Railway デプロイ手順

### 1. GitHubリポジトリにプッシュ

```bash
git init
git add .
git commit -m "init SVN server"
git remote add origin https://github.com/YOUR_USER/svn-railway.git
git push -u origin main
```

### 2. Railway プロジェクト作成

1. https://railway.app にログイン
2. `New Project` → `Deploy from GitHub repo` → 上記リポジトリを選択

### 3. Volume を作成・マウント

Railway ダッシュボード:
1. プロジェクト画面 → サービスを選択
2. `Volumes` タブ → `Add Volume`
3. マウントパス: `/svn`
4. サイズ: 1GB〜（用途に応じて）

### 4. 環境変数を設定

Railway ダッシュボード → `Variables` タブ:

| 変数名 | 説明 | 例 |
|---|---|---|
| `SVN_ADMIN_USER` | 管理者ユーザー名 | `admin` |
| `SVN_ADMIN_PASS` | 管理者パスワード | `your_secure_password` |
| `SVN_REPO_NAME` | 初期作成するリポジトリ名（任意） | `myproject` |

※ `PORT` は Railway が自動設定するため不要。

### 5. デプロイ確認

```bash
# ヘルスチェック
curl https://YOUR-SERVICE.railway.app/health

# SVN リスト（ブラウザでも可）
svn list https://YOUR-SERVICE.railway.app/svn/myproject \
    --username admin --password your_secure_password
```

## 利用方法

### リポジトリへの接続

```bash
# チェックアウト
svn checkout https://YOUR-SERVICE.railway.app/svn/myproject \
    --username admin

# コミット
svn add yourfile.txt
svn commit -m "initial commit"
```

### 追加ユーザーの作成

コンテナ内で実行（Railway → `Deploy` → `Shell`）:

```bash
htpasswd /svn/conf/passwd newuser
```

### リポジトリの追加作成

```bash
svnadmin create /svn/repos/another-project
chown -R www-data:www-data /svn/repos/another-project
```

## 注意事項

- **Railway Free Tier**: 一定時間後にスリープする場合あり → 有料プランを推奨
- **バックアップ**: Railway Volume は冗長化されているが、定期的な `svnadmin dump` を推奨
- **本番利用**: IP制限・HTTPS強制・パスワードポリシーの強化を検討すること
