package training.aidd.library;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

/**
 * Spring コンテキストが起動できることを確認するスモークテスト。
 *
 * <p>環境構築チェックリスト STEP 5-1 で {@code ./gradlew build} がここまで通ることが、
 * 研修プロジェクトの最低保証ラインです。
 */
@SpringBootTest
class LibraryApplicationTests {

    @Test
    void contextLoads() {
        // Spring コンテキストの初期化が成功すれば PASS。
        // アサーションは不要(@SpringBootTest がコンテキスト起動を試みる)。
    }
}
