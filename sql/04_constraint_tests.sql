-- ============================================================
-- 04_constraint_tests.sql — 제약조건 깨뜨려 보기 (보너스 과제 2)
-- ============================================================
-- 실행:  sqlite3 study_tracker.db < sql/04_constraint_tests.sql
--
-- 목적: "FK 가 실제로 동작하는가"를 눈으로 확인한다.
--       과제 요구: "FK가 실제로 동작하도록 설정한다 (없는 값 참조가 막혀야 한다)"
--
-- ⚠️ 아래 쿼리들은 **일부러 실패하도록** 만든 것이다.
--    에러 메시지가 뜨는 것이 정상이고, 에러가 안 뜨면 그게 문제다.
-- ============================================================

PRAGMA foreign_keys = ON;   -- ★ 이 줄이 없으면 아래 테스트 1,2가 '통과'해버린다

.print ''
.print '=== 테스트 1) 없는 회원 id 로 학습 기록 넣기 → FK 위반 ==='
.print '기대: FOREIGN KEY constraint failed'
INSERT INTO study_log (member_id, category_id, title, studied_on, minutes)
VALUES (9999, 1, '존재하지 않는 회원의 기록', '2026-10-13', 60);

.print ''
.print '=== 테스트 2) 없는 분야 id 로 학습 기록 넣기 → FK 위반 ==='
.print '기대: FOREIGN KEY constraint failed'
INSERT INTO study_log (member_id, category_id, title, studied_on, minutes)
VALUES (1, 9999, '존재하지 않는 분야의 기록', '2026-10-13', 60);

.print ''
.print '=== 테스트 3) 이미 있는 이메일로 회원 추가 → UNIQUE 위반 ==='
.print '기대: UNIQUE constraint failed: member.email'
INSERT INTO member (name, email, joined_on)
VALUES ('중복이', 'haeun@example.com', '2026-10-13');

.print ''
.print '=== 테스트 4) 이름 없이 회원 추가 → NOT NULL 위반 ==='
.print '기대: NOT NULL constraint failed: member.name'
INSERT INTO member (name, email, joined_on)
VALUES (NULL, 'noname@example.com', '2026-10-13');

.print ''
.print '=== 테스트 5) 학습시간 0분 → CHECK 위반 ==='
.print '기대: CHECK constraint failed'
INSERT INTO study_log (member_id, category_id, title, studied_on, minutes)
VALUES (1, 1, '0분 공부', '2026-10-13', 0);

.print ''
.print '=== 테스트 6) 자기 자신을 평가 → CHECK 위반 ==='
.print '기대: CHECK constraint failed'
INSERT INTO evaluation (mission_id, evaluatee_id, evaluator_id, evaluated_on, result)
VALUES (1, 1, 1, '2026-10-13', 'PASS');

.print ''
.print '=== 테스트 7) result 에 엉뚱한 값 → CHECK 위반 ==='
.print '기대: CHECK constraint failed'
INSERT INTO evaluation (mission_id, evaluatee_id, evaluator_id, evaluated_on, result)
VALUES (1, 1, 2, '2026-10-13', 'MAYBE');

.print ''
.print '=== 테스트 8) 사용 중인 분야 삭제 → FK RESTRICT 로 막힘 ==='
.print '기대: FOREIGN KEY constraint failed  (study_log 가 이 분야를 참조 중)'
DELETE FROM category WHERE name = 'DB';

.print ''
.print '=== 테스트 9) 회원 삭제 → CASCADE 로 학습 기록도 함께 삭제 (이건 성공) ==='
.print '삭제 전 태현(9)의 학습 기록 수:'
SELECT COUNT(*) FROM study_log WHERE member_id = 9;
DELETE FROM member WHERE id = 9;
.print '삭제 후 태현(9)의 학습 기록 수 (0이면 CASCADE 동작):'
SELECT COUNT(*) FROM study_log WHERE member_id = 9;
.print '→ 되돌리려면 ./run.sh 로 DB를 다시 만드세요.'

.print ''
.print '=== 테스트 10) PRAGMA 를 끄면 FK 가 무력화된다 (SQLite 함정) ==='
PRAGMA foreign_keys = OFF;
INSERT INTO study_log (member_id, category_id, title, studied_on, minutes)
VALUES (9999, 1, 'FK 꺼진 상태에서 넣은 유령 기록', '2026-10-13', 60);
.print '→ 에러 없이 들어갔다! 아래가 그 유령 행이다:'
SELECT id, member_id, title FROM study_log WHERE member_id = 9999;
.print '→ 정리'
DELETE FROM study_log WHERE member_id = 9999;
PRAGMA foreign_keys = ON;
