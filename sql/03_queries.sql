-- ============================================================
-- 03_queries.sql — 핵심 쿼리 20개
-- ============================================================
-- 실행:  sqlite3 study_tracker.db < sql/03_queries.sql
--
-- 구성 (과제 요구 대비)
--   기본 조회  Q01~Q05   (요구 4개 이상) — WHERE, ORDER BY, LIMIT
--   조인       Q06~Q10   (요구 4개 이상) — INNER JOIN 3, LEFT JOIN 2
--   집계       Q11~Q14   (요구 3개 이상) — COUNT/SUM/AVG + GROUP BY
--   서브쿼리   Q15~Q16   (요구 1개 이상)
--   수정/삭제  Q17~Q18   (요구 2개 이상) — UPDATE, DELETE
--   인덱스     Q19       (요구 1개 이상) — 01_schema.sql 에도 있음
--   보너스     Q20       — 같은 요구를 JOIN 과 서브쿼리 두 방식으로
-- ============================================================

PRAGMA foreign_keys = ON;

-- ============================================================
-- [기본 조회]
-- ============================================================

-- Q01. 전체 회원을 가입일 순으로 본다. (가장 기본적인 SELECT)
SELECT id, name, email, joined_on
FROM member
ORDER BY joined_on, id;

-- Q02. 2시간(120분) 이상 공부한 기록만 최신순으로. (WHERE + ORDER BY)
SELECT title, studied_on, minutes
FROM study_log
WHERE minutes >= 120
ORDER BY studied_on DESC;

-- Q03. 가장 최근 학습 기록 5건만. (LIMIT)
--      LIMIT 는 "앞에서 N개만" 이라는 뜻이고, 정렬과 함께 써야 의미가 있다.
SELECT title, studied_on, minutes
FROM study_log
ORDER BY studied_on DESC, id DESC
LIMIT 5;

-- Q04. 제목에 'SQL' 또는 '쿼리'가 들어간 기록 검색. (LIKE)
--      % 는 "앞뒤에 무엇이 오든" 이라는 뜻의 와일드카드다.
SELECT title, studied_on
FROM study_log
WHERE title LIKE '%SQL%' OR title LIKE '%쿼리%'
ORDER BY studied_on DESC;

-- Q05. 10월에 등록된 필수 미션 목록. (여러 조건 + BETWEEN)
SELECT code, title, est_hours
FROM mission
WHERE is_required = 1 AND est_hours BETWEEN 10 AND 25
ORDER BY est_hours DESC;

-- ============================================================
-- [조인]
--   JOIN 은 "흩어져 있는 테이블을 연결해 한 번에 뽑는 것"이다.
--   테이블을 나눠 저장했기 때문에 다시 합치는 수단이 필요하고, 그게 JOIN 이다.
-- ============================================================

-- Q06. [INNER JOIN] 학습 기록에 누가 어떤 분야를 공부했는지 붙여서 본다.
--      INNER JOIN 은 "양쪽에 다 있는 것만" 남긴다.
SELECT m.name        AS 회원,
       c.name        AS 분야,
       s.title       AS 제목,
       s.studied_on  AS 학습일,
       s.minutes     AS 분
FROM study_log s
INNER JOIN member   m ON s.member_id   = m.id
INNER JOIN category c ON s.category_id = c.id
ORDER BY s.studied_on DESC
LIMIT 10;

-- Q07. [INNER JOIN] 동료평가 결과에 미션명과 사람 이름을 붙인다.
--      member 테이블을 '받은 사람'과 '한 사람' 두 번 조인한다.
--      같은 테이블을 두 번 쓰므로 별칭(ee, er)을 꼭 달아야 구분된다.
SELECT mi.code                AS 미션,
       ee.name                AS 받은사람,
       er.name                AS 평가자,
       e.result               AS 결과,
       e.evaluated_on         AS 평가일
FROM evaluation e
INNER JOIN mission mi ON e.mission_id   = mi.id
INNER JOIN member  ee ON e.evaluatee_id = ee.id
INNER JOIN member  er ON e.evaluator_id = er.id
ORDER BY e.evaluated_on DESC
LIMIT 10;

-- Q08. [INNER JOIN + WHERE] 하은이 받은 평가만.
SELECT mi.code, er.name AS 평가자, e.result, e.comment
FROM evaluation e
INNER JOIN mission mi ON e.mission_id = mi.id
INNER JOIN member  er ON e.evaluator_id = er.id
WHERE e.evaluatee_id = (SELECT id FROM member WHERE name = '하은')
ORDER BY e.evaluated_on;

-- Q09. [LEFT JOIN] 학습 기록이 하나도 없는 회원까지 포함해서 건수를 본다.
--      LEFT JOIN 은 "왼쪽 테이블은 다 남기고, 오른쪽은 있으면 붙인다".
--      INNER JOIN 이었다면 기록이 없는 회원은 아예 사라졌을 것이다.
SELECT m.name                 AS 회원,
       COUNT(s.id)            AS 기록수,
       COALESCE(SUM(s.minutes), 0) AS 총분
FROM member m
LEFT JOIN study_log s ON m.id = s.member_id
GROUP BY m.id, m.name
ORDER BY 기록수 DESC, m.name;

-- Q10. [LEFT JOIN] 아직 아무도 평가받지 않은 미션 찾기.
--      오른쪽이 비어 있는 행(= NULL)만 남기면 "연결되지 않은 것"이 된다.
SELECT mi.code, mi.title, mi.is_required
FROM mission mi
LEFT JOIN evaluation e ON mi.id = e.mission_id
WHERE e.id IS NULL
ORDER BY mi.code;

-- ============================================================
-- [집계]
--   GROUP BY 는 "같은 값끼리 묶어라", 집계 함수는 "묶은 것을 하나로 줄여라" 이다.
-- ============================================================

-- Q11. [COUNT + SUM + GROUP BY] 분야별 학습 건수와 총 시간.
SELECT c.name                AS 분야,
       COUNT(*)              AS 건수,
       SUM(s.minutes)        AS 총분,
       SUM(s.minutes) / 60   AS 시간
FROM study_log s
INNER JOIN category c ON s.category_id = c.id
GROUP BY c.id, c.name
ORDER BY 총분 DESC;

-- Q12. [AVG + GROUP BY] 회원별 평균 학습 시간. 평균 90분 이상만.
--      WHERE 가 아니라 HAVING 을 쓰는 이유:
--      WHERE 는 '묶기 전' 각 행을 거르고, HAVING 은 '묶은 뒤' 그룹을 거른다.
--      평균은 묶어야 나오는 값이므로 HAVING 이어야 한다.
SELECT m.name            AS 회원,
       COUNT(*)          AS 기록수,
       ROUND(AVG(s.minutes), 1) AS 평균분
FROM study_log s
INNER JOIN member m ON s.member_id = m.id
GROUP BY m.id, m.name
HAVING AVG(s.minutes) >= 90
ORDER BY 평균분 DESC;

-- Q13. [GROUP BY + 날짜] 월별 학습 시간 추이.
--      ⚠️ SQLite 전용 문법: strftime('%Y-%m', 날짜컬럼)
--         MySQL 이면 DATE_FORMAT(studied_on, '%Y-%m'),
--         PostgreSQL 이면 TO_CHAR(studied_on, 'YYYY-MM') 을 쓴다.
SELECT strftime('%Y-%m', studied_on) AS 월,
       COUNT(*)                      AS 건수,
       SUM(minutes)                  AS 총분,
       ROUND(SUM(minutes) / 60.0, 1) AS 시간
FROM study_log
GROUP BY 월
ORDER BY 월;

-- Q14. [COUNT + 조건부 집계] 미션별 PASS/FAIL 현황.
--      CASE WHEN 을 SUM 안에 넣으면 "조건에 맞는 것만 세기"가 된다.
SELECT mi.code                                        AS 미션,
       COUNT(*)                                       AS 전체평가,
       SUM(CASE WHEN e.result = 'PASS' THEN 1 ELSE 0 END) AS PASS,
       SUM(CASE WHEN e.result = 'FAIL' THEN 1 ELSE 0 END) AS FAIL,
       ROUND(100.0 * SUM(CASE WHEN e.result = 'PASS' THEN 1 ELSE 0 END) / COUNT(*), 1) AS 통과율
FROM evaluation e
INNER JOIN mission mi ON e.mission_id = mi.id
GROUP BY mi.id, mi.code
ORDER BY mi.code;

-- ============================================================
-- [서브쿼리]
--   쿼리 안에 쿼리를 넣는 것. "먼저 안쪽을 구하고, 그 결과로 바깥을 거른다".
-- ============================================================

-- Q15. [서브쿼리] 학습 기록이 하나도 없는 회원 찾기. (NOT IN)
SELECT name, email, joined_on
FROM member
WHERE id NOT IN (SELECT DISTINCT member_id FROM study_log)
ORDER BY name;

-- Q16. [서브쿼리] 전체 평균보다 오래 공부한 기록들.
--      안쪽 쿼리가 먼저 '전체 평균'이라는 숫자 하나를 만들고,
--      바깥쪽이 그 숫자와 각 행을 비교한다.
SELECT s.title,
       s.minutes,
       (SELECT ROUND(AVG(minutes), 1) FROM study_log) AS 전체평균
FROM study_log s
WHERE s.minutes > (SELECT AVG(minutes) FROM study_log)
ORDER BY s.minutes DESC
LIMIT 10;

-- ============================================================
-- [수정 / 삭제]
--   ⚠️ UPDATE 와 DELETE 에 WHERE 를 빠뜨리면 '전체'가 바뀌거나 지워진다.
--      실행 전에 같은 조건으로 SELECT 를 먼저 돌려 대상을 확인하는 습관이 안전하다.
-- ============================================================

-- Q17. [UPDATE] 오타로 들어간 분야 설명을 고친다.
--      (먼저 확인: SELECT * FROM category WHERE name = 'DB';)
UPDATE category
SET description = 'SQL, 스키마 설계, 조인, 인덱스'
WHERE name = 'DB';

SELECT name, description FROM category WHERE name = 'DB';

-- Q18. [DELETE] 10분 미만의 의미 없는 기록을 지운다.
--      (이번 샘플에는 대상이 없어 0행이 지워지는 것이 정상이다)
DELETE FROM study_log
WHERE minutes < 10;

SELECT changes() AS 삭제된행수;

-- ============================================================
-- [인덱스]
-- ============================================================

-- Q19. [CREATE INDEX] 분야별 조회가 늘어나서 인덱스를 추가한다.
--      적용 이유: study_log 를 category_id 로 묶거나 거르는 쿼리(Q11 등)가 반복된다.
--      인덱스가 없으면 매번 전체 행을 훑어야 하지만, 있으면 해당 분야의 행으로 바로 간다.
CREATE INDEX IF NOT EXISTS idx_study_log_category ON study_log(category_id);

-- 인덱스가 실제로 쓰이는지 확인하는 방법 (SQLite 전용: EXPLAIN QUERY PLAN)
EXPLAIN QUERY PLAN
SELECT * FROM study_log WHERE category_id = 5;

-- ============================================================
-- [보너스 1] 같은 요구를 JOIN 과 서브쿼리 두 방식으로
--   요구: "학습 기록이 하나도 없는 회원"
-- ============================================================

-- (가) 서브쿼리 방식 — Q15 와 동일
SELECT name FROM member
WHERE id NOT IN (SELECT DISTINCT member_id FROM study_log)
ORDER BY name;

-- (나) LEFT JOIN 방식 — 붙였는데 비어 있는 행만 남긴다
SELECT m.name
FROM member m
LEFT JOIN study_log s ON m.id = s.member_id
WHERE s.id IS NULL
ORDER BY m.name;

-- 차이:
--   · 결과는 같다.
--   · NOT IN 은 서브쿼리 결과에 NULL 이 섞이면 전체가 비어버리는 함정이 있다.
--     (NULL 과의 비교는 참도 거짓도 아니기 때문)
--   · LEFT JOIN 방식은 그 함정이 없고, 보통 대용량에서 더 빠르다.
--   · 읽기 쉬운 쪽은 서브쿼리다. 상황에 따라 고르면 된다.

-- ============================================================
-- [보너스 3] 미니 리포트 — 이 DB로 뽑는 핵심 지표 3개
-- ============================================================

-- 지표 ①  이수 현황: 미션별로 PASS 를 3명에게 받았는가? (3명이면 이수)
SELECT mi.code                AS 미션,
       m.name                 AS 회원,
       COUNT(*)               AS PASS수,
       CASE WHEN COUNT(*) >= 3 THEN '이수' ELSE '진행중' END AS 상태
FROM evaluation e
INNER JOIN mission mi ON e.mission_id   = mi.id
INNER JOIN member  m  ON e.evaluatee_id = m.id
WHERE e.result = 'PASS'
GROUP BY mi.id, m.id
ORDER BY m.name, mi.code;

-- 지표 ②  장학금 요건 체크 (본과정 기초: 월 4회 이상, 참여 2회·받기 2회 必)
--         '받기'는 evaluatee, '참여'는 evaluator 로 센다.
SELECT m.name AS 회원,
       SUM(CASE WHEN e.evaluatee_id = m.id THEN 1 ELSE 0 END) AS 받기,
       SUM(CASE WHEN e.evaluator_id = m.id THEN 1 ELSE 0 END) AS 참여,
       COUNT(*)                                               AS 합계,
       CASE
         WHEN SUM(CASE WHEN e.evaluatee_id = m.id THEN 1 ELSE 0 END) >= 2
          AND SUM(CASE WHEN e.evaluator_id = m.id THEN 1 ELSE 0 END) >= 2
          AND COUNT(*) >= 4
         THEN '충족' ELSE '미달'
       END AS 장학금요건
FROM member m
INNER JOIN evaluation e
        ON m.id IN (e.evaluatee_id, e.evaluator_id)
WHERE strftime('%Y-%m', e.evaluated_on) = '2026-10'
GROUP BY m.id, m.name
ORDER BY 합계 DESC, m.name;

-- 지표 ③  분야별 학습 집중도 TOP 5 (어디에 시간을 가장 많이 썼는가)
SELECT c.name                          AS 분야,
       SUM(s.minutes)                  AS 총분,
       ROUND(SUM(s.minutes) / 60.0, 1) AS 시간,
       COUNT(DISTINCT s.member_id)     AS 참여인원
FROM study_log s
INNER JOIN category c ON s.category_id = c.id
GROUP BY c.id, c.name
ORDER BY 총분 DESC
LIMIT 5;
