# CLAUDE.md — library-app プロジェクト前提

> **このファイルについて**
>
> 本ファイルは AI駆動型Java開発研修(2026年5月開講)の配布雛形です。
> Claude Code は本ファイルをセッション開始時に読み込み、本プロジェクトの「常識」として扱います。
>
> **このファイルは出発点です。** 研修 Day 3 以降、皆さん自身が **自分のプロジェクトに合わせて書き換える** ことを前提に書かれています。3行に削っても構いませんし、自分の業務文脈で大幅に書き直しても構いません。**配布版をそのまま使い続けるのではなく、自分の言葉で再構成すること** が研修の主要ワークの一つです。
>
> 関連ファイル:
> - `.claude/settings.json` — 権限ルール(隔離設定。`.claude/SETTINGS_GUIDE.md` で解説)
> - `build.gradle.kts` — 依存関係定義(任意Lv の追加候補をコメント済み)
> - `application.properties` — DB・Actuator・ログ設定

---

## プロジェクト概要

**library-app** は研修ハンズオン用の図書管理アプリケーションです。

- **必須機能**:図書の CRUD(Create / Read / Update / Delete)
- **任意Lv1**:予約システム(予約登録・キャンセル・一覧取得)
- **任意Lv2**:予約の排他制御(楽観ロック)
- **任意Lv3**:貸出期限通知(非同期処理)
- **任意Lv4**:管理者向け利用状況API

研修期間:2026/5/16〜6/13(全5回・毎週土曜 / 各2時間)。受講者ごとに個別実装し、コードは共有しません。

---

## 技術スタック(土台固定 — AIへの指示の前提)

| 項目 | 採用 | 備考 |
|---|---|---|
| **言語** | Java 25 (LTS) | 2025年9月リリース。toolchain で固定 |
| **フレームワーク** | Spring Boot 4.0.6 | 2026年1月GA、4.0.6が現行安定版 |
| **ビルド** | Gradle 9.5 (Kotlin DSL) | `JavaLanguageVersion.of(25)` |
| **永続化** | Spring Data JPA / Hibernate 7.x | H2 in-memory(研修中) |
| **テスト** | JUnit 5 (Jupiter) + AssertJ + Mockito | Spring Boot 4.0で **JUnit 4 は完全削除済み** |
| **JSON** | Jackson 3.x(`tools.jackson.*`) | Jackson 2の `com.fasterxml.jackson.databind.*` は**使わない** |
| **Servletコンテナ** | Tomcat 11(組み込み) | Undertowは Spring Boot 4.0 で削除済み |
| **namespace** | **`jakarta.*` のみ** | `javax.*` は使わない |
| **Lombok** | **使用しない** | records / class を素直に使う |
| **Null-safety** | **JSpecify**(`org.jspecify.annotations.Nullable` / `@NullMarked`) | `org.springframework.lang.Nullable` は使わない(Spring Boot 4.0で非推奨) |

> **業務移行時の補足**:業務現場では Lombok 採用率が高いことを承知しています。本研修で records を採用するのは「**AI が records を素直に書ける言語機能**」だからです。業務に戻ったら Lombok でも構いませんが、**「使う/使わないを CLAUDE.md に明記する習慣」** こそが本質です。

---

## 言語機能の方針

Java 25 の機能を積極活用してよい。ただし以下のいずれかを選ぶこと:

- **(A) Java 25 新機能を活用するなら、その理由をコードコメントに残す**
  例:`// Stream Gatherers を使用:集計ロジックを簡潔化するため`
- **(B) 従来構文で書くなら、それで問題ない**

→ 重要なのは「**なぜその選択をしたか**」を自分で説明できること。AI が新機能を提案してきても、自分が説明できなければ採用しない。

### 第一選択

- DTO・Value Object は **records を第一選択**
- 不変性が必要なら `final` + コンストラクタ注入
- パターンマッチング(switch expressions / sealed interfaces / record patterns)は積極使用してよい

### Preview 機能の取り扱い

- **Structured Concurrency**(Java 25でも JEP 505 として Preview)を使う場合は `--enable-preview` の有効化が必要
- `build.gradle.kts` のコメントに有効化方法を記載済み
- Preview 機能は API 変更の可能性があるため、業務コードには持ち込まない判断もアリ

---

## AIへの指示の方針

### やってよいこと

- 実装の生成・テストの生成・リファクタリング提案
- スタックトレースの読み解き(ただし要約してから渡す:Spring 系は内部フレームのノイズが多い)
- パッケージ構成の相談・命名の相談
- AsserJ / Mockito の書き方の確認

### 慎重にやること

- **「現代的に」「ベストプラクティスで」のような曖昧な指示は、まず一度試してから具体化する**
  - AI の解釈と自分の意図がズレることが多いため、初回は素直に投げて結果を見る
- AIの提案を採用する前に、**自分が説明できる状態になっているか**確認する
- スタックトレースをそのまま貼らない。要点(例外型・メッセージ・原因スタック上位3行)に絞る

### 避けること

- **`build.gradle.kts` の依存関係追加を AI に書かせない**
  - 理由:座標・バージョンの幻覚に加え、**Spring Boot 4.0 で starter 名が再編成されたばかり**で AI の学習が追いついていない
  - 雛形は `start.spring.io` で生成、AIには修正だけ任せる
  - 任意Lv で必要な依存は **`build.gradle.kts` 末尾コメント** に予告済み
- **AI が提案した import を盲目的に信じない**(後述のチェックリスト参照)

---

## テスト方針

- カバレッジ目標 **70%以上**(必須ではない・自己宣言制)
- テスト先行 / 実装先行はどちらでもよい(自分の指示設計に合わせる)
- アサーションは **AssertJ**:`assertThat(...).isEqualTo(...)` / `assertThat(...).hasSize(...)`
- モックは **Mockito**:`@Mock` / `@InjectMocks`
- **JUnit 4 のアノテーション(`@Before` / `@Test(expected = ...)` / `@RunWith` 等)は混入させない**
  - JUnit 5 では `@BeforeEach` / `assertThrows(...)` / `@ExtendWith(...)` を使う
- Spring の統合テストは `@SpringBootTest`(コンテキスト起動が重いので必要なときだけ)
- 軽量な MVC テストは `@WebMvcTest`、JPA 単独テストは `@DataJpaTest`

---

## アノテーション利用上の注意

- `@Transactional` の **propagation・self-invocation** の罠を理解した上で使う
  - 同クラス内のメソッド呼び出しでは `@Transactional` が効かない(Spring AOP の制約)
- **フィールド注入(`@Autowired` 直貼り)は避け、コンストラクタ注入を使う**
  - records では自然にコンストラクタ注入になる
- **JPA の `fetch` 戦略は N+1 問題に注意**(`EAGER` の安易な使用を避ける)
  - 関連は基本 `LAZY`、必要に応じて `@EntityGraph` または fetch join

---

## レビュー時のチェックリスト(AIが書いたコードに対して)

AI 生成コードをコミットする前に、以下を必ず確認:

- [ ] アノテーションの組み合わせは意図通りか(プロキシ・トランザクション境界)
- [ ] 依存関係の座標(`groupId:artifactId:version`)は実在するか
- [ ] **Jackson 2 系の import(`com.fasterxml.jackson.databind.*`)が混入していないか**
- [ ] **JUnit 4 系の書き方(`@Before` / `@Test(expected = ...)`)が混入していないか**
- [ ] **`org.springframework.lang.Nullable` が混入していないか** → JSpecify を使う
- [ ] **`javax.*` の import が混入していないか** → `jakarta.*` を使う
- [ ] N+1 クエリ・遅延読み込みの罠はないか
- [ ] テストは AssertJ で書かれているか(Hamcrest が混入していないか)
- [ ] 例外ハンドリングは握りつぶしていないか(`catch(Exception e) {}` 等)

---

## プロジェクト構造の方針

```
src/main/java/training/aidd/library/
├── LibraryApplication.java     ← エントリーポイント(変更不要)
├── book/                       ← 図書ドメイン(必須CRUD)
│   ├── BookController.java
│   ├── BookService.java
│   ├── BookRepository.java
│   └── Book.java               ← @Entity または record
└── reservation/                ← 予約ドメイン(任意Lv1以降)
    └── ...
```

**判断ポイント**:

- パッケージ分割は「機能ドメインごと」を推奨(`controller/` `service/` のような層別ではなく)
- ただしチームルール・個人の好みで層別にしてもよい
- いずれにせよ **一貫性が重要**。途中でルールを変えると AI の提案も揺れる

---

## 任意レベル(Lv1〜Lv4)に進む際のメモ

> **このセクションは Lv 進行時に皆さん自身が追記してください。** AIに「予約機能を追加して」と依頼する前に、ここに方針を書いておくと、AI が判断材料として参照できます。

### Lv1: 予約システム(到達目標:ベテラン・既習者)
- (例) 予約は `Book` と `User` の関連エンティティとして実装
- (例) 予約期間の重複チェックは Service 層で実装
- (記入欄)

### Lv2: 楽観ロック
- (例) `@Version` フィールドで実装
- (例) `OptimisticLockingFailureException` のハンドリング方針
- (記入欄)

### Lv3: 貸出期限通知(非同期処理)
- (例) Virtual Threads を有効化:`spring.threads.virtual.enabled=true`
- (例) `@Async` + `@EnableAsync` で実装、または Structured Concurrency(Preview)
- (記入欄)

### Lv4: 管理者向け利用状況API
- (例) Stream Gatherers で集計ロジックを記述
- (例) Actuator のカスタム情報として公開する選択肢もアリ
- (記入欄)

---

## 個人ルール(自由記入)

> **Day 3 以降、自分の指示設計の癖や好みを書き溜めていく場所です。**
>
> 例:
> - 「英語のクラス名は AI に提案させる前に自分で考える」
> - 「`@SuppressWarnings` を AI が付けてきたら必ず根拠を確認する」
> - 「3回試してダメだったら、AI を変えるかペアプロに切り替える」

(記入欄)

---

## チームルール(自由記入)

> **チーム内チェックインで合意した規律を残す場所です。**
>
> 例:
> - 「コミットメッセージは Conventional Commits」
> - 「PR は 200 行を超えたら分割」

(記入欄)

---

## このファイルの更新ログ

| 日付 | 変更者 | 変更内容 |
|---|---|---|
| 2026-05-08 | 講師(初版配布) | 雛形配布版として作成 |

(以降、書き換えのたびに追記してください)

---

## 補足:Skills(Agent Skills)について

`CLAUDE.md` が「プロジェクトの常識」を渡すものなら、`SKILL.md` という発展形は「**よくやる作業の手順書**」を必要なときだけ AI に渡す仕組みです。本研修では作りませんが、Day 5 で概念を扱います。詳細は別途配布される **「Agent Skills 概念紹介」** 資料を参照してください。