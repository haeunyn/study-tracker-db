-- ============================================================
-- 01_schema.sql — 코디세이 학습 관리 DB 스키마
-- ============================================================
-- 실행:  sqlite3 study_tracker.db < sql/01_schema.sql
--
-- ■ 주제
--   교육생이 무엇을 얼마나 공부했고(study_log), 어떤 미션을 누구에게
--   평가받았는지(evaluation)를 추적하는 DB.
--
-- ■ 테이블 5개와 1:N 관계 4개
--     member    1 ──< N  study_log      한 사람이 여러 학습 기록을 남긴다
--     category  1 ──< N  study_log      한 분야에 여러 학습 기록이 속한다
--     mission   1 ──< N  evaluation     한 미션에 여러 평가가 달린다
--     member    1 ──< N  evaluation     한 사람이 여러 번 평가를 받고/하고
--                                        (evaluatee_id, evaluator_id 로 두 번 참조)
--
-- ■ 왜 테이블을 나누나? (엑셀과의 차이)
--   엑셀이었다면 한 시트에 "이름, 이메일, 분야, 제목, 시간"을 전부 적었을 것이다.
--   그러면 같은 사람이 10번 공부할 때 이름과 이메일이 10번 반복된다.
--   이메일을 고치려면 10줄을 다 고쳐야 하고, 한 줄만 빠뜨리면 데이터가 어긋난다.
--   테이블을 나누면 사람은 member 에 한 번만 저장하고, 학습 기록은 그 사람의 id 만 가리킨다.
--   → 고칠 곳이 한 군데가 되고, 이것이 관계형 DB 의 핵심이다.
-- ============================================================

-- ⚠️ SQLite 전용: FK 제약은 기본으로 꺼져 있다. 연결할 때마다 켜야 한다.
--    이 줄이 없으면 없는 member_id 를 넣어도 그냥 들어간다(= FK 가 무의미해진다).
--    MySQL/PostgreSQL 은 기본으로 켜져 있다.
PRAGMA foreign_keys = ON;

-- 재실행 가능하도록 기존 테이블을 지운다.
-- 자식 → 부모 순서로 지워야 한다. 반대로 하면 FK 제약에 걸린다.
DROP TABLE IF EXISTS evaluation;
DROP TABLE IF EXISTS study_log;
DROP TABLE IF EXISTS mission;
DROP TABLE IF EXISTS category;
DROP TABLE IF EXISTS member;

-- ------------------------------------------------------------
-- member — 교육생
-- ------------------------------------------------------------
CREATE TABLE member (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    name        TEXT    NOT NULL,                 -- 제약조건: NOT NULL
    email       TEXT    NOT NULL UNIQUE,          -- 제약조건: UNIQUE (같은 이메일로 두 명 등록 불가)
    github_id   TEXT,                             -- 선택 입력
    joined_on   DATE    NOT NULL,
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------
-- category — 학습 분야
-- ------------------------------------------------------------
CREATE TABLE category (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    name        TEXT    NOT NULL UNIQUE,          -- 분야 이름은 중복될 수 없다
    description TEXT
);

-- ------------------------------------------------------------
-- mission — 과제(미션)
-- ------------------------------------------------------------
CREATE TABLE mission (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    code        TEXT    NOT NULL UNIQUE,          -- 'B1-1' 처럼 과정에서 쓰는 코드
    title       TEXT    NOT NULL,
    is_required INTEGER NOT NULL DEFAULT 1,       -- 1=필수, 0=선택  (SQLite 에는 BOOLEAN 이 없어 INTEGER 사용)
    est_hours   INTEGER NOT NULL DEFAULT 0,       -- 예상 학습 시간
    CHECK (is_required IN (0, 1)),                -- 0/1 외의 값을 막는다
    CHECK (est_hours >= 0)
);

-- ------------------------------------------------------------
-- study_log — 학습 기록  (member 1:N, category 1:N)
-- ------------------------------------------------------------
CREATE TABLE study_log (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    member_id   INTEGER NOT NULL,                 -- FK → member.id
    category_id INTEGER NOT NULL,                 -- FK → category.id
    title       TEXT    NOT NULL,
    studied_on  DATE    NOT NULL,
    minutes     INTEGER NOT NULL,
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CHECK (minutes > 0 AND minutes <= 1440),      -- 하루는 1440분을 넘을 수 없다

    -- ON DELETE CASCADE: 회원이 삭제되면 그 사람의 학습 기록도 함께 삭제한다.
    --   주인이 사라진 기록은 의미가 없기 때문.
    FOREIGN KEY (member_id)   REFERENCES member(id)   ON DELETE CASCADE,

    -- ON DELETE RESTRICT: 사용 중인 분야는 삭제를 막는다.
    --   기록이 남아 있는데 분야를 지우면 그 기록이 어디에 속하는지 알 수 없게 된다.
    FOREIGN KEY (category_id) REFERENCES category(id) ON DELETE RESTRICT
);

-- ------------------------------------------------------------
-- evaluation — 동료평가  (mission 1:N, member 1:N ×2)
-- ------------------------------------------------------------
CREATE TABLE evaluation (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    mission_id   INTEGER NOT NULL,                -- FK → mission.id   어떤 미션에 대한 평가인가
    evaluatee_id INTEGER NOT NULL,                -- FK → member.id    평가를 '받은' 사람
    evaluator_id INTEGER NOT NULL,                -- FK → member.id    평가를 '한' 사람
    evaluated_on DATE    NOT NULL,
    result       TEXT    NOT NULL,                -- 'PASS' 또는 'FAIL'
    comment      TEXT,

    CHECK (result IN ('PASS', 'FAIL')),
    CHECK (evaluatee_id <> evaluator_id),         -- 자기 자신을 평가할 수 없다

    FOREIGN KEY (mission_id)   REFERENCES mission(id) ON DELETE CASCADE,
    FOREIGN KEY (evaluatee_id) REFERENCES member(id)  ON DELETE CASCADE,
    FOREIGN KEY (evaluator_id) REFERENCES member(id)  ON DELETE CASCADE
);

-- ============================================================
-- 인덱스 (과제 요구: 최소 1개 + 적용 이유)
-- ============================================================
-- 인덱스는 '책 뒤의 찾아보기'와 같다. 없으면 처음부터 끝까지 훑어야(Full Scan) 하고,
-- 있으면 바로 해당 위치로 간다. 대신 INSERT/UPDATE 때 색인도 갱신해야 해서 쓰기는 조금 느려진다.
-- → 그래서 '자주 검색/정렬/조인하는 컬럼'에만 건다.

-- 이유: 월별 학습시간 집계와 기간 조회에서 studied_on 으로 매번 걸러낸다.
CREATE INDEX idx_study_log_studied_on ON study_log(studied_on);

-- 이유: "이 회원의 기록" 조회가 가장 빈번하다. member_id 로 join/where 가 계속 일어난다.
CREATE INDEX idx_study_log_member ON study_log(member_id);

-- 이유: 동료평가 현황을 '받은 사람 기준'으로 집계하는 쿼리가 많다. (장학금 요건 확인)
CREATE INDEX idx_evaluation_evaluatee ON evaluation(evaluatee_id, evaluated_on);

-- 참고: PK(id)와 UNIQUE(email, name, code) 컬럼에는 인덱스가 자동으로 만들어진다.
--       그래서 이메일로 회원을 찾는 쿼리는 따로 인덱스를 걸지 않아도 빠르다.
