#!/bin/bash
set -euo pipefail

# ────────────────────────────────────────────
# 1. PORT 解決（Railway が動的に割り当てる）
# ────────────────────────────────────────────
export SVN_PORT="${PORT:-80}"
echo "[entrypoint] Listening on port: $SVN_PORT"

# ────────────────────────────────────────────
# 2. Apache 設定をテンプレートから生成
# ────────────────────────────────────────────
envsubst '${SVN_PORT}' \
    < /etc/apache2/sites-available/svn.conf.template \
    > /etc/apache2/sites-available/svn.conf

a2ensite svn > /dev/null 2>&1 || true

# ports.conf の Listen 設定を上書き（デフォルト80との競合防止）
echo "Listen $SVN_PORT" > /etc/apache2/ports.conf

# ────────────────────────────────────────────
# 3. 永続ディレクトリ作成
# ────────────────────────────────────────────
mkdir -p /svn/repos /svn/conf

# ────────────────────────────────────────────
# 4. ヘルスチェック用ページ
# ────────────────────────────────────────────
mkdir -p /var/www/html
cat > /var/www/html/health.html <<EOF
OK
EOF

# ────────────────────────────────────────────
# 5. htpasswd 初期化（初回のみ）
# ────────────────────────────────────────────
if [ ! -f /svn/conf/passwd ]; then
    ADMIN_USER="${SVN_ADMIN_USER:-admin}"
    ADMIN_PASS="${SVN_ADMIN_PASS:-changeme}"

    htpasswd -cb /svn/conf/passwd "$ADMIN_USER" "$ADMIN_PASS"
    echo "[entrypoint] Created htpasswd: user=$ADMIN_USER"

    if [ "$ADMIN_PASS" = "changeme" ]; then
        echo "[entrypoint] WARNING: Using default password. Set SVN_ADMIN_PASS env var."
    fi
fi

# ────────────────────────────────────────────
# 6. 初期リポジトリ作成（環境変数で指定）
# ────────────────────────────────────────────
if [ -n "${SVN_REPO_NAME:-}" ]; then
    REPO_PATH="/svn/repos/$SVN_REPO_NAME"
    if [ ! -d "$REPO_PATH" ]; then
        svnadmin create "$REPO_PATH"
        echo "[entrypoint] Created repository: $REPO_PATH"
    else
        echo "[entrypoint] Repository already exists: $REPO_PATH"
    fi
fi

# ────────────────────────────────────────────
# 7. パーミッション修正
# ────────────────────────────────────────────
chown -R www-data:www-data /svn
chmod 700 /svn/conf

# ────────────────────────────────────────────
# 8. Apache 起動
# ────────────────────────────────────────────
echo "[entrypoint] Starting Apache..."
exec apache2ctl -D FOREGROUND
