# 쿼리 실행 결과

> `tools/run_queries.py` 가 `sql/03_queries.sql` 을 쿼리 단위로 실행한 결과입니다.
> 재생성: `./run.sh`

- 총 24개 블록
- DB: `study_tracker.db` (SQLite 3.51.0)

---

## Q01. 전체 회원을 가입일 순으로 본다. (가장 기본적인 SELECT) · 기본 조회

```sql
SELECT id, name, email, joined_on
FROM member
ORDER BY joined_on, id;
```

**실행 결과**

```
id  name  email                joined_on 
--  ----  -------------------  ----------
1   하은  haeun@example.com    2026-09-03
2   지우  jiwoo@example.com    2026-09-03
3   민준  minjun@example.com   2026-09-03
4   서연  seoyeon@example.com  2026-09-03
5   도윤  doyun@example.com    2026-09-03
6   수아  sua@example.com      2026-09-10
7   준호  junho@example.com    2026-09-10
8   예린  yerin@example.com    2026-09-10
9   태현  taehyun@example.com  2026-09-17
10  나윤  nayoon@example.com   2026-09-17
```

## Q02. 2시간(120분) 이상 공부한 기록만 최신순으로. (WHERE + ORDER BY) · 기본 조회

```sql
SELECT title, studied_on, minutes
FROM study_log
WHERE minutes >= 120
ORDER BY studied_on DESC;
```

**실행 결과**

```
title                         studied_on  minutes
----------------------------  ----------  -------
이중연결리스트와 LRU          2026-10-10  180    
GROUP BY 와 집계 함수         2026-10-09  120    
해시맵과 체이닝               2026-10-08  160    
클래스와 계층 설계            2026-10-01  140    
제너레이터와 스트리밍 처리    2026-09-26  120    
fetch 와 async/await          2026-09-22  180    
querySelector 와 이벤트 흐름  2026-09-15  150    
DOM 조작 연습                 2026-09-14  130    
HTML 시맨틱 태그 정리         2026-09-08  120
```

## Q03. 가장 최근 학습 기록 5건만. (LIMIT) · 기본 조회

```sql
--      LIMIT 는 "앞에서 N개만" 이라는 뜻이고, 정렬과 함께 써야 의미가 있다.
SELECT title, studied_on, minutes
FROM study_log
ORDER BY studied_on DESC, id DESC
LIMIT 5;
```

**실행 결과**

```
title                            studied_on  minutes
-------------------------------  ----------  -------
인덱스는 언제 거는가             2026-10-13  85     
PK/FK 와 1:N 관계                2026-10-13  100    
충돌 마커 읽는 법                2026-10-12  50     
브랜치는 커밋을 가리키는 포인터  2026-10-12  60     
reset 과 revert 차이             2026-10-11  85
```

## Q04. 제목에 'SQL' 또는 '쿼리'가 들어간 기록 검색. (LIKE) · 기본 조회

```sql
--      % 는 "앞뒤에 무엇이 오든" 이라는 뜻의 와일드카드다.
SELECT title, studied_on
FROM study_log
WHERE title LIKE '%SQL%' OR title LIKE '%쿼리%'
ORDER BY studied_on DESC;
```

**실행 결과**

```
title                   studied_on
----------------------  ----------
SQLAlchemy 세션과 커밋  2026-09-24
반응형 미디어 쿼리      2026-09-11
```

## Q05. 10월에 등록된 필수 미션 목록. (여러 조건 + BETWEEN) · 기본 조회

```sql
SELECT code, title, est_hours
FROM mission
WHERE is_required = 1 AND est_hours BETWEEN 10 AND 25
ORDER BY est_hours DESC;

-- ============================================================
--   JOIN 은 "흩어져 있는 테이블을 연결해 한 번에 뽑는 것"이다.
--   테이블을 나눠 저장했기 때문에 다시 합치는 수단이 필요하고, 그게 JOIN 이다.
-- ============================================================
```

**실행 결과**

```
code  title                           est_hours
----  ------------------------------  ---------
B1-1  나를 소개하는 웹페이지          25       
B5-2  파일 변경 기록 프로그램         24       
B5-1  정보를 빠르게 찾는 저장소       22       
B3-1  웹사이트를 인터넷에 올리기      14       
B4-2  느려지거나 멈췄을 때 원인 찾기  14       
B2-1  나만의 용돈 기입장              12       
B4-1  컴퓨터가 자기 상태 점검         12       
B6-1  디지털 서랍장 (SQL)             10
```

## Q06. [INNER JOIN] 학습 기록에 누가 어떤 분야를 공부했는지 붙여서 본다. · 조인

```sql
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
```

**실행 결과**

```
회원  분야       제목                             학습일      분 
----  ---------  -------------------------------  ----------  ---
수아  DB         인덱스는 언제 거는가             2026-10-13  85 
하은  DB         PK/FK 와 1:N 관계                2026-10-13  100
도윤  Git        충돌 마커 읽는 법                2026-10-12  50 
하은  Git        브랜치는 커밋을 가리키는 포인터  2026-10-12  60 
민준  Git        reset 과 revert 차이             2026-10-11  85 
나윤  Algorithm  이중연결리스트와 LRU             2026-10-10  180
지우  DB         JOIN 기본기                      2026-10-10  95 
서연  DB         GROUP BY 와 집계 함수            2026-10-09  120
도윤  Algorithm  해시맵과 체이닝                  2026-10-08  160
준호  Cloud      VPC 와 서브넷                    2026-10-07  110
```

## Q07. [INNER JOIN] 동료평가 결과에 미션명과 사람 이름을 붙인다. · 조인

```sql
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
```

**실행 결과**

```
미션  받은사람  평가자  결과  평가일    
----  --------  ------  ----  ----------
B2-1  도윤      준호    PASS  2026-10-11
B2-1  민준      수아    PASS  2026-10-10
B2-1  서연      수아    PASS  2026-10-10
B2-1  지우      도윤    FAIL  2026-10-09
B2-1  도윤      하은    PASS  2026-10-08
B2-1  서연      하은    PASS  2026-10-07
B1-1  예린      태현    PASS  2026-10-07
B2-1  하은      수아    PASS  2026-10-06
B1-1  준호      예린    FAIL  2026-10-06
B2-1  하은      도윤    PASS  2026-10-05
```

## Q08. [INNER JOIN + WHERE] 하은이 받은 평가만. · 조인

```sql
SELECT mi.code, er.name AS 평가자, e.result, e.comment
FROM evaluation e
INNER JOIN mission mi ON e.mission_id = mi.id
INNER JOIN member  er ON e.evaluator_id = er.id
WHERE e.evaluatee_id = (SELECT id FROM member WHERE name = '하은')
ORDER BY e.evaluated_on;
```

**실행 결과**

```
code  평가자  result  comment                               
----  ------  ------  --------------------------------------
B1-1  지우    PASS    시맨틱 태그 선택 기준 설명이 명확함   
B1-1  민준    PASS    Flexbox/Grid 선택 이유를 코드로 짚어줌
B1-1  서연    PASS    이벤트→상태→렌더링 흐름 설명 좋았음   
B2-1  도윤    PASS    제너레이터 메모리 비교 시연이 인상적  
B2-1  수아    PASS    heapq.nlargest 설명 정확
```

## Q09. [LEFT JOIN] 학습 기록이 하나도 없는 회원까지 포함해서 건수를 본다. · 조인

```sql
--      LEFT JOIN 은 "왼쪽 테이블은 다 남기고, 오른쪽은 있으면 붙인다".
--      INNER JOIN 이었다면 기록이 없는 회원은 아예 사라졌을 것이다.
SELECT m.name                 AS 회원,
       COUNT(s.id)            AS 기록수,
       COALESCE(SUM(s.minutes), 0) AS 총분
FROM member m
LEFT JOIN study_log s ON m.id = s.member_id
GROUP BY m.id, m.name
ORDER BY 기록수 DESC, m.name;
```

**실행 결과**

```
회원  기록수  총분
----  ------  ----
하은  10      1100
민준  4       375 
지우  4       355 
도윤  3       350 
서연  3       285 
수아  2       185 
예린  2       150 
준호  2       205 
나윤  1       180 
태현  1       70
```

## Q10. [LEFT JOIN] 아직 아무도 평가받지 않은 미션 찾기. · 조인

```sql
--      오른쪽이 비어 있는 행(= NULL)만 남기면 "연결되지 않은 것"이 된다.
SELECT mi.code, mi.title, mi.is_required
FROM mission mi
LEFT JOIN evaluation e ON mi.id = e.mission_id
WHERE e.id IS NULL
ORDER BY mi.code;

-- ============================================================
--   GROUP BY 는 "같은 값끼리 묶어라", 집계 함수는 "묶은 것을 하나로 줄여라" 이다.
-- ============================================================
```

**실행 결과**

```
code  title                           is_required
----  ------------------------------  -----------
B1-2  요즘 웹사이트 (React SPA)       0          
B2-2  친구 3~5명과 협업               1          
B3-1  웹사이트를 인터넷에 올리기      1          
B3-2  AI가 커밋 설명 써주는 도우미    1          
B4-1  컴퓨터가 자기 상태 점검         1          
B4-2  느려지거나 멈췄을 때 원인 찾기  1          
B5-1  정보를 빠르게 찾는 저장소       1          
B5-2  파일 변경 기록 프로그램         1          
B6-1  디지털 서랍장 (SQL)             1          
B6-2  게시판형 웹 서비스              0
```

## Q11. [COUNT + SUM + GROUP BY] 분야별 학습 건수와 총 시간. · 집계

```sql
SELECT c.name                AS 분야,
       COUNT(*)              AS 건수,
       SUM(s.minutes)        AS 총분,
       SUM(s.minutes) / 60   AS 시간
FROM study_log s
INNER JOIN category c ON s.category_id = c.id
GROUP BY c.id, c.name
ORDER BY 총분 DESC;
```

**실행 결과**

```
분야        건수  총분  시간
----------  ----  ----  ----
JavaScript  5     670   11  
Python      6     595   9   
DB          5     475   7   
HTML/CSS    5     425   7   
Algorithm   2     340   5   
Backend     2     200   3   
Git         3     195   3   
Linux       2     155   2   
Cloud       1     110   1   
CS          1     90    1
```

## Q12. [AVG + GROUP BY] 회원별 평균 학습 시간. 평균 90분 이상만. · 집계

```sql
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
```

**실행 결과**

```
회원  기록수  평균분
----  ------  ------
나윤  1       180.0 
도윤  3       116.7 
하은  10      110.0 
준호  2       102.5 
서연  3       95.0  
민준  4       93.8  
수아  2       92.5
```

## Q13. [GROUP BY + 날짜] 월별 학습 시간 추이. · 집계

```sql
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
```

**실행 결과**

```
월       건수  총분  시간
-------  ----  ----  ----
2026-09  16    1665  27.8
2026-10  16    1590  26.5
```

## Q14. [COUNT + 조건부 집계] 미션별 PASS/FAIL 현황. · 집계

```sql
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
--   쿼리 안에 쿼리를 넣는 것. "먼저 안쪽을 구하고, 그 결과로 바깥을 거른다".
-- ============================================================
```

**실행 결과**

```
미션  전체평가  PASS  FAIL  통과율
----  --------  ----  ----  ------
B1-1  14        12    2     85.7  
B2-1  8         7     1     87.5
```

## Q15. [서브쿼리] 학습 기록이 하나도 없는 회원 찾기. (NOT IN) · 서브쿼리

```sql
SELECT name, email, joined_on
FROM member
WHERE id NOT IN (SELECT DISTINCT member_id FROM study_log)
ORDER BY name;
```

**실행 결과**

```
(결과 행 없음)
```

## Q16. [서브쿼리] 전체 평균보다 오래 공부한 기록들. · 서브쿼리

```sql
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
--   ⚠️ UPDATE 와 DELETE 에 WHERE 를 빠뜨리면 '전체'가 바뀌거나 지워진다.
--      실행 전에 같은 조건으로 SELECT 를 먼저 돌려 대상을 확인하는 습관이 안전하다.
-- ============================================================
```

**실행 결과**

```
title                         minutes  전체평균
----------------------------  -------  --------
fetch 와 async/await          180      101.7   
이중연결리스트와 LRU          180      101.7   
해시맵과 체이닝               160      101.7   
querySelector 와 이벤트 흐름  150      101.7   
클래스와 계층 설계            140      101.7   
DOM 조작 연습                 130      101.7   
HTML 시맨틱 태그 정리         120      101.7   
제너레이터와 스트리밍 처리    120      101.7   
GROUP BY 와 집계 함수         120      101.7   
FastAPI 레이어 분리           110      101.7
```

## Q17. [UPDATE] 오타로 들어간 분야 설명을 고친다. · 수정 / 삭제

```sql
--      (먼저 확인: SELECT * FROM category WHERE name = 'DB';)
UPDATE category
SET description = 'SQL, 스키마 설계, 조인, 인덱스'
WHERE name = 'DB';

SELECT name, description FROM category WHERE name = 'DB';
```

**실행 결과**

```
name  description                   
----  ------------------------------
DB    SQL, 스키마 설계, 조인, 인덱스
```

## Q18. [DELETE] 10분 미만의 의미 없는 기록을 지운다. · 수정 / 삭제

```sql
--      (이번 샘플에는 대상이 없어 0행이 지워지는 것이 정상이다)
DELETE FROM study_log
WHERE minutes < 10;

SELECT changes() AS 삭제된행수;

-- ============================================================
-- ============================================================
```

**실행 결과**

```
삭제된행수
----------
0
```

## Q19. [CREATE INDEX] 분야별 조회가 늘어나서 인덱스를 추가한다. · 인덱스

```sql
--      적용 이유: study_log 를 category_id 로 묶거나 거르는 쿼리(Q11 등)가 반복된다.
--      인덱스가 없으면 매번 전체 행을 훑어야 하지만, 있으면 해당 분야의 행으로 바로 간다.
CREATE INDEX IF NOT EXISTS idx_study_log_category ON study_log(category_id);

-- 인덱스가 실제로 쓰이는지 확인하는 방법 (SQLite 전용: EXPLAIN QUERY PLAN)
EXPLAIN QUERY PLAN
SELECT * FROM study_log WHERE category_id = 5;

-- ============================================================
--   요구: "학습 기록이 하나도 없는 회원"
-- ============================================================
```

**실행 결과**

```
QUERY PLAN
`--SEARCH study_log USING INDEX idx_study_log_category (category_id=?)
```

## (가). 서브쿼리 방식 — Q15 와 동일 · 보너스 1

```sql
SELECT name FROM member
WHERE id NOT IN (SELECT DISTINCT member_id FROM study_log)
ORDER BY name;
```

**실행 결과**

```
(결과 행 없음)
```

## (나). LEFT JOIN 방식 — 붙였는데 비어 있는 행만 남긴다 · 보너스 1

```sql
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
-- ============================================================
```

**실행 결과**

```
(결과 행 없음)
```

## 지표 ①. 이수 현황: 미션별로 PASS 를 3명에게 받았는가? (3명이면 이수) · 보너스 3

```sql
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
```

**실행 결과**

```
미션  회원  PASS수  상태  
----  ----  ------  ------
B1-1  도윤  1       진행중
B2-1  도윤  2       진행중
B1-1  민준  2       진행중
B2-1  민준  1       진행중
B1-1  서연  1       진행중
B2-1  서연  2       진행중
B1-1  수아  1       진행중
B1-1  예린  1       진행중
B1-1  지우  3       이수  
B1-1  하은  3       이수  
B2-1  하은  2       진행중
```

## 지표 ②. 장학금 요건 체크 (본과정 기초: 월 4회 이상, 참여 2회·받기 2회 必) · 보너스 3

```sql
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
```

**실행 결과**

```
회원  받기  참여  합계  장학금요건
----  ----  ----  ----  ----------
도윤  3     4     7     충족      
서연  3     2     5     충족      
수아  1     4     5     미달      
하은  2     3     5     충족      
민준  4     0     4     미달      
준호  1     2     3     미달      
예린  1     1     2     미달      
지우  2     0     2     미달      
태현  0     1     1     미달
```

## 지표 ③. 분야별 학습 집중도 TOP 5 (어디에 시간을 가장 많이 썼는가) · 보너스 3

```sql
SELECT c.name                          AS 분야,
       SUM(s.minutes)                  AS 총분,
       ROUND(SUM(s.minutes) / 60.0, 1) AS 시간,
       COUNT(DISTINCT s.member_id)     AS 참여인원
FROM study_log s
INNER JOIN category c ON s.category_id = c.id
GROUP BY c.id, c.name
ORDER BY 총분 DESC
LIMIT 5;
```

**실행 결과**

```
분야        총분  시간  참여인원
----------  ----  ----  --------
JavaScript  670   11.2  4       
Python      595   9.9   5       
DB          475   7.9   4       
HTML/CSS    425   7.1   4       
Algorithm   340   5.7   2
```
