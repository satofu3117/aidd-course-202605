# library-app

AI駆動型Java開発研修用の図書管理アプリケーション雛形です。

必須機能は図書のCRUDです。任意レベルとして、予約システム、楽観ロック、貸出期限通知、管理者向け利用状況APIを追加していく想定です。

## 技術スタック

| 項目 | 採用 |
| --- | --- |
| 言語 | Java 25 |
| フレームワーク | Spring Boot 4.0.6 |
| ビルド | Gradle wrapper |
| 永続化 | Spring Data JPA / Hibernate |
| データベース | H2 in-memory |
| テスト | JUnit 5 / AssertJ / Mockito |

Java 25 は Gradle toolchain で指定されています。ローカルに Java 25 がない場合は、初回ビルド時に Foojay toolchain resolver が自動取得します。

## ディレクトリ構成

```text
.
├── build.gradle.kts
├── settings.gradle.kts
├── gradle.properties
├── check-setup.sh
├── CLAUDE.md
├── PROJECT_STRUCTURE.md
└── src
    ├── main
    │   ├── java/training/aidd/library/LibraryApplication.java
    │   └── resources/application.properties
    └── test
        └── java/training/aidd/library/LibraryApplicationTests.java
```

主要な設定は `build.gradle.kts` と `src/main/resources/application.properties` にあります。

## 環境構築

### 1. プロジェクトルートへ移動

```bash
cd /path/to/aidd-seminar
```

以降のコマンドは、`build.gradle.kts` があるディレクトリで実行してください。

### 2. Gradle wrapperの実行権限を確認

macOS / Linux で `./gradlew` が実行できない場合は、実行権限を付与します。

```bash
chmod +x ./gradlew
```

### 3. GradleとJVMを確認

```bash
./gradlew --version
```

初回実行時は Gradle wrapper や Java toolchain の取得に時間がかかることがあります。社内プロキシが必要な環境では、`gradle.properties` のプロキシ設定欄を編集してください。

### 4. ビルド

```bash
./gradlew build
```

ビルドに成功すると、コンパイル、テスト、Spring Boot の成果物生成まで確認できます。

## 開発時のコマンド

### テスト実行

```bash
./gradlew test
```

### アプリケーション起動

```bash
./gradlew bootRun
```

起動後、デフォルトでは `http://localhost:8080` でアプリケーションが動作します。

## 動作確認

### Health endpoint

```bash
curl http://localhost:8080/actuator/health
```

`UP` が返ればアプリケーションは起動しています。

### H2 Console

ブラウザで以下を開きます。

```text
http://localhost:8080/h2-console
```

接続情報は次の通りです。

| 項目 | 値 |
| --- | --- |
| JDBC URL | `jdbc:h2:mem:librarydb;DB_CLOSE_DELAY=-1;MODE=PostgreSQL` |
| User Name | `sa` |
| Password | 空欄 |

## 自己診断

環境構築後、自己診断スクリプトを実行できます。

```bash
bash check-setup.sh
```

`[FAIL]` が出た場合は、表示されたメッセージに従って `gradlew` の実行権限、Java 25、`CLAUDE.md`、`.claude/settings.json` などを確認してください。

## 関連ドキュメント

- [`CLAUDE.md`](./CLAUDE.md): この研修プロジェクトでAIに渡す前提、技術スタック、実装ルール
- [`PROJECT_STRUCTURE.md`](./PROJECT_STRUCTURE.md): 雛形プロジェクトのファイル構成と採用バージョンの説明
- [`check-setup.sh`](./check-setup.sh): 環境セットアップ自己診断スクリプト

## 免責事項

この雛形は研修専用です。業務目的で利用したことにより発生したいかなる損害についても、当社は一切の責任を負いません。

また、AIを用いて生成・修正された出力の正確性、完全性、有用性についても、当社は一切の責任を負いません。業務環境や本番環境で利用する場合は、利用者自身の責任で内容を確認し、各種設定を適切に見直してください。
