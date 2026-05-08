package training.aidd.library;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * 図書管理アプリケーションのエントリーポイント。
 *
 * <p>研修では本クラスをそのまま使い、以下のパッケージを各自で追加していきます:
 * <ul>
 *   <li>{@code training.aidd.library.book} — 図書ドメイン(必須CRUD)</li>
 *   <li>{@code training.aidd.library.reservation} — 予約ドメイン(任意Lv1以降)</li>
 * </ul>
 *
 * <p>パッケージ構成は受講者の判断に任せますが、
 * {@link SpringBootApplication} がある本パッケージ配下に置くこと
 * (デフォルトでコンポーネントスキャン対象になります)。
 */
@SpringBootApplication
public class LibraryApplication {

    public static void main(String[] args) {
        SpringApplication.run(LibraryApplication.class, args);
    }
}
