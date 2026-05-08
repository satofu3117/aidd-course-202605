#!/usr/bin/env bash
# AIDD Training - 環境セットアップ自己診断スクリプト
# 受講者が STEP 9 で実行する。雛形リポジトリの直下に同梱して配布する。
# 実行は library-app プロジェクトのルートで(配置パスは問わない)。

set -u

PASS=0
FAIL=0
WARN=0

ok()   { echo "[OK]   $1"; PASS=$((PASS+1)); }
ng()   { echo "[FAIL] $1"; FAIL=$((FAIL+1)); }
warn() { echo "[WARN] $1"; WARN=$((WARN+1)); }

echo "=== AIDD Training Setup Check ==="
echo

# 1. プロジェクトルートで実行されているか(パス文字列ではなくマーカーファイルで判定)
if [ -f "build.gradle.kts" ] || [ -f "build.gradle" ]; then
  ok "プロジェクトルートで実行中(build.gradle.kts を検出)"
else
  ng "プロジェクトルートで実行されていません(build.gradle.kts が見つからない)"
  echo "       → library-app ディレクトリに移動してから再実行してください"
fi

# 2. 業務領域との混在を簡易チェック(隣接ディレクトリにヒューリスティック)
PARENT="$(dirname "$(pwd)")"
SUSPICIOUS_NEIGHBORS=$(ls "$PARENT" 2>/dev/null | grep -iE '^(work|client|prod|production|customer)' | head -3)
if [ -n "$SUSPICIOUS_NEIGHBORS" ]; then
  warn "親ディレクトリに業務系っぽい名前のフォルダがあります:"
  echo "$SUSPICIOUS_NEIGHBORS" | sed 's/^/         - /'
  echo "       → 業務リポジトリと同じ親ディレクトリに置いていないか確認してください"
fi

# 3. .claude/settings.json
if [ -f ".claude/settings.json" ]; then
  ok ".claude/settings.json が存在"

  # JSON として妥当か
  if command -v python3 >/dev/null 2>&1; then
    if python3 -m json.tool .claude/settings.json >/dev/null 2>&1; then
      ok ".claude/settings.json の JSON 構文が妥当"
    else
      ng ".claude/settings.json の JSON 構文エラー(末尾カンマ等を確認)"
    fi
  fi

  # deny ルールの存在
  if grep -q '"deny"' .claude/settings.json; then
    ok "deny ルールが設定されている"
  else
    ng "deny ルールが見つかりません(隔離が効きません)"
  fi

  # 重要な deny 項目の存在チェック(隔離テスト前の事前検証)
  for pattern in '~/.ssh' 'sudo' '\.env' 'rm -rf'; do
    if grep -q "$pattern" .claude/settings.json; then
      ok "deny 項目「${pattern}」を含む"
    else
      warn "deny 項目「${pattern}」が見つかりません(雛形の改ざん?)"
    fi
  done

  # bypassPermissions モードが指定されていないこと(あれば隔離が無効)
  if grep -q '"defaultMode"\s*:\s*"bypassPermissions"' .claude/settings.json; then
    ng "defaultMode が bypassPermissions です(隔離が無効化されています)"
  fi
else
  ng ".claude/settings.json がありません(隔離が効きません)"
fi

# 4. CLAUDE.md
if [ -f "CLAUDE.md" ]; then
  ok "CLAUDE.md が存在"

  # 配布版の必須キーワード(技術スタックの土台固定が書かれているか)
  for keyword in 'Java 25' 'Spring Boot' 'jakarta' 'JUnit 5'; do
    if grep -qF "$keyword" CLAUDE.md; then
      ok "CLAUDE.md にキーワード「${keyword}」を含む"
    else
      warn "CLAUDE.md にキーワード「${keyword}」が見つかりません"
    fi
  done
else
  ng "CLAUDE.md がありません"
fi

# 5. gradlew
if [ -x "./gradlew" ]; then
  ok "gradlew に実行権限あり"
else
  ng "gradlew が実行できません(chmod +x ./gradlew で修正)"
fi

# 6. Java バージョン (gradlew 経由)
#    Gradle 8.x: "JVM: 25.0.3 ..."
#    Gradle 9.x: "Launcher JVM: 25.0.3 ..." と "Daemon JVM: ..." の2行に分かれる
#    どちらでも JVM 行を取得できるようにする
if [ -x "./gradlew" ]; then
  JVM_LINE=$(./gradlew --version 2>/dev/null | grep -E "^(JVM|Launcher JVM):" | head -1)
  if [ -z "$JVM_LINE" ]; then
    ng "Gradle の JVM 情報が取得できません(./gradlew --version が失敗?)"
    echo "       → ./gradlew --version を直接実行してエラーを確認してください"
  elif echo "$JVM_LINE" | grep -qE "JVM:[[:space:]]*25"; then
    ok "Gradle が Java 25 を使用 ($JVM_LINE)"
  else
    ng "Gradle が Java 25 で動いていません: $JVM_LINE"
  fi
fi

# 7. ビルド成果物の存在(STEP 5 を実行済みか)
if [ -d "build" ] || [ -d ".gradle-cache" ] || [ -d ".gradle" ]; then
  ok "ビルドが一度は実行された形跡あり"
else
  warn "build/ が見当たりません。./gradlew build を実行してください"
fi

# 7.5 src 配下の必須ファイル(bootJar の main クラス検出に必要)
#     2026-05-04 教訓:src 欠落で bootJar が "Main class name has not been
#     configured" エラーになる事例があった。雛形完成度の検証として追加。
MAIN_JAVA="src/main/java/training/aidd/library/LibraryApplication.java"
APP_PROPS="src/main/resources/application.properties"
TEST_JAVA="src/test/java/training/aidd/library/LibraryApplicationTests.java"

if [ -f "$MAIN_JAVA" ]; then
  ok "メインクラス $MAIN_JAVA が存在"
  if grep -q '@SpringBootApplication' "$MAIN_JAVA"; then
    ok "メインクラスに @SpringBootApplication が記述されている"
  else
    ng "メインクラスに @SpringBootApplication が見つかりません"
  fi
else
  ng "メインクラスがありません: $MAIN_JAVA"
  echo "       → 雛形配布が不完全な可能性。講師に連絡してください"
fi

if [ -f "$APP_PROPS" ]; then
  ok "$APP_PROPS が存在"
else
  warn "$APP_PROPS が見当たりません(空でも build は通るが、起動時に DB 接続できない)"
fi

if [ -f "$TEST_JAVA" ]; then
  ok "テストクラス $TEST_JAVA が存在"
else
  warn "テストクラスが見当たりません(必須ではないが、./gradlew test は失敗します)"
fi

# 8. Claude Code コマンド
if command -v claude >/dev/null 2>&1; then
  CLAUDE_VER=$(claude --version 2>/dev/null | head -n 1)
  ok "claude コマンド利用可: $CLAUDE_VER"
else
  ng "claude コマンドが PATH にありません"
fi

# 9. Git
if command -v git >/dev/null 2>&1; then
  ok "git 利用可"
else
  ng "git が見つかりません"
fi

# 10. クラウド同期フォルダの簡易検知
PWD_LOWER="$(pwd | tr '[:upper:]' '[:lower:]')"
if echo "$PWD_LOWER" | grep -qE 'onedrive|icloud|dropbox|google drive|googledrive|box sync'; then
  warn "クラウド同期フォルダ配下にプロジェクトがある可能性があります"
  echo "       → 同期対象外のフォルダに移動することを推奨(FAQ Q7 参照)"
fi

echo
echo "=== Result ==="
echo "  Pass: $PASS / Warn: $WARN / Fail: $FAIL"
echo

if [ "$FAIL" -eq 0 ]; then
  echo "✅ All checks passed. You are ready for Day 1."
  if [ "$WARN" -gt 0 ]; then
    echo "   ($WARN 件の警告がありますが、研修進行は可能です。気になれば #setup-help で相談を)"
  fi
  exit 0
else
  echo "❌ $FAIL 件の重要な問題があります。Slack #setup-help に出力全文を貼って相談してください。"
  exit 1
fi