# 코디세이 학습 관리 DB (디지털 서랍장)

> Codyssey AI 올인원 2기 · 본과정 AI·SW 기초 · **데이터베이스와 백엔드** 미션 (B6-1)
> 백엔드 프레임워크 없이 **SQL만으로** 스키마 설계 → 데이터 입력 → 요구사항 해결까지 완성합니다.

교육생이 **무엇을 얼마나 공부했는지**(학습 기록)와 **어떤 미션을 누구에게 평가받았는지**(동료평가)를 추적하는 데이터베이스입니다.

## 실행 방법

```bash
cd study-tracker-db
./run.sh
```

이 한 줄이 아래를 순서대로 수행합니다.

1. 기존 DB 삭제 (재현 가능하도록)
2. 스키마 생성 — `sql/01_schema.sql`
3. 샘플 데이터 입력 — `sql/02_sample_data.sql`
4. 행 수 확인
5. 쿼리 20개 실행 → `results/query_results.md` 생성

### 직접 들여다보기

```bash
sqlite3 study_tracker.db

sqlite> .tables                      -- 테이블 목록
sqlite> .schema member               -- 특정 테이블 구조
sqlite> PRAGMA foreign_keys = ON;    -- ⚠️ 접속할 때마다 켜야 한다
sqlite> SELECT * FROM member LIMIT 5;
sqlite> .quit
```

> **DB**: SQLite 3.51 — 설치가 필요 없고 파일 하나로 끝나서 선택했습니다. macOS/Linux 에 기본 탑재되어 있습니다.
> **도구**: CLI(`sqlite3`). GUI 를 쓰려면 DB Browser for SQLite 로 `study_tracker.db` 를 열면 됩니다.

## 제출물

| 제출물 | 파일 |
| --- | --- |
| 스키마 생성 SQL | [`sql/01_schema.sql`](sql/01_schema.sql) |
| 샘플 데이터 INSERT SQL | [`sql/02_sample_data.sql`](sql/02_sample_data.sql) |
| 쿼리 20개 SQL | [`sql/03_queries.sql`](sql/03_queries.sql) |
| 실행 결과 | [`results/query_results.md`](results/query_results.md) · [`results/constraint_tests_output.txt`](results/constraint_tests_output.txt) |
| ERD | [`docs/ERD.md`](docs/ERD.md) |
| (보너스) 제약조건 테스트 | [`sql/04_constraint_tests.sql`](sql/04_constraint_tests.sql) |

## 데이터 모델

테이블 **5개**, 1:N 관계 **4개**. 자세한 그림과 설명은 [docs/ERD.md](docs/ERD.md).

| 테이블 | 내용 | 행 수 |
| --- | --- | --- |
| `member` | 교육생 | 10 |
| `category` | 학습 분야 | 10 |
| `mission` | 과제(미션) | 12 |
| `study_log` | 학습 기록 (member 1:N, category 1:N) | 32 |
| `evaluation` | 동료평가 (mission 1:N, member 1:N ×2) | 22 |

```
member   1 ──< N  study_log  >── N ── 1   category
member   1 ──< N  evaluation >── N ── 1   mission
         (evaluatee_id / evaluator_id 로 두 번 참조)
```

### 제약조건

| 종류 | 적용 위치 |
| --- | --- |
| `PRIMARY KEY` | 모든 테이블의 `id` |
| `NOT NULL` | `member.name`, `study_log.title`, `evaluation.result` 등 |
| `UNIQUE` | `member.email`, `category.name`, `mission.code` |
| `FOREIGN KEY` | `study_log` 2개, `evaluation` 3개 |
| `CHECK` | `minutes > 0 AND <= 1440`, `result IN ('PASS','FAIL')`, `evaluatee_id <> evaluator_id` |

### 삭제 동작을 다르게 준 이유

```sql
FOREIGN KEY (member_id)   REFERENCES member(id)   ON DELETE CASCADE   -- 회원 삭제 → 기록도 삭제
FOREIGN KEY (category_id) REFERENCES category(id) ON DELETE RESTRICT  -- 사용 중 분야 → 삭제 거부
```

회원이 사라지면 그 사람의 기록은 **주인이 없어 의미가 없으므로** 함께 지웁니다.
반대로 기록이 남아 있는데 분야를 지우면 **그 기록이 어디에 속하는지 알 수 없으므로** 삭제를 막습니다.

## 쿼리 20개

[`results/query_results.md`](results/query_results.md) 에 **쿼리 + 실행 결과**가 함께 들어 있습니다.

| 범주 | 과제 요구 | 작성 | 번호 |
| --- | --- | --- | --- |
| 기본 조회 (WHERE/ORDER BY/LIMIT) | 4개 이상 | **5개** | Q01~Q05 |
| 조인 (INNER 2+, LEFT 1+) | 4개 이상 | **5개** (INNER 3, LEFT 2) | Q06~Q10 |
| 집계 (COUNT/SUM/AVG + GROUP BY) | 3개 이상 | **4개** | Q11~Q14 |
| 서브쿼리 | 1개 이상 | **2개** | Q15~Q16 |
| 수정·삭제 (UPDATE/DELETE) | 2개 이상 | **2개** | Q17~Q18 |
| 인덱스 (CREATE INDEX + 이유) | 1개 이상 | **4개** | Q19 + 스키마 3개 |

### 인덱스를 건 컬럼과 이유

| 인덱스 | 이유 |
| --- | --- |
| `study_log(studied_on)` | 월별 집계·기간 조회에서 매번 이 컬럼으로 거른다 |
| `study_log(member_id)` | "이 회원의 기록" 조회가 가장 빈번하다 |
| `evaluation(evaluatee_id, evaluated_on)` | 동료평가 현황을 받은 사람 기준으로 집계한다 |
| `study_log(category_id)` | 분야별 집계(Q11)가 반복된다 |

> 인덱스는 **책 뒤의 찾아보기**와 같습니다. 없으면 처음부터 끝까지 훑어야 하고(Full Scan),
> 있으면 바로 해당 위치로 갑니다. 대신 INSERT/UPDATE 때 색인도 갱신해야 해서 **쓰기는 조금 느려집니다.**
> 그래서 자주 **검색·정렬·조인**하는 컬럼에만 겁니다.
> PK 와 UNIQUE 컬럼에는 인덱스가 **자동으로** 만들어집니다.

## 보너스 과제 (3/3)

### 1. 같은 요구를 JOIN 과 서브쿼리 두 방식으로

"학습 기록이 하나도 없는 회원"을 두 가지로 풀었습니다. (`03_queries.sql` 하단)

```sql
-- (가) 서브쿼리
SELECT name FROM member WHERE id NOT IN (SELECT DISTINCT member_id FROM study_log);

-- (나) LEFT JOIN
SELECT m.name FROM member m
LEFT JOIN study_log s ON m.id = s.member_id
WHERE s.id IS NULL;
```

**차이**: 결과는 같습니다. 다만 `NOT IN` 은 서브쿼리 결과에 `NULL` 이 섞이면
**전체가 비어버리는 함정**이 있습니다(NULL 과의 비교는 참도 거짓도 아니기 때문).
`LEFT JOIN` 방식은 그 함정이 없고 대용량에서 보통 더 빠릅니다. 읽기 쉬운 쪽은 서브쿼리입니다.

### 2. 데이터 정합성 깨뜨려 보기

```bash
sqlite3 study_tracker.db < sql/04_constraint_tests.sql
```

**10가지를 일부러 실패시키고** 결과를 [`results/constraint_tests_output.txt`](results/constraint_tests_output.txt) 에 남겼습니다.

| # | 시도 | 결과 |
| --- | --- | --- |
| 1~2 | 없는 `member_id` / `category_id` 로 INSERT | `FOREIGN KEY constraint failed` |
| 3 | 중복 이메일 | `UNIQUE constraint failed: member.email` |
| 4 | 이름 없이 INSERT | `NOT NULL constraint failed: member.name` |
| 5~7 | 0분 학습 / 자기 평가 / `result='MAYBE'` | `CHECK constraint failed` |
| 8 | 사용 중인 분야 삭제 | `FOREIGN KEY constraint failed` (RESTRICT) |
| 9 | 회원 삭제 | 학습 기록도 **함께 삭제됨** (CASCADE 동작 확인) |
| 10 | `PRAGMA foreign_keys = OFF` 후 같은 INSERT | **에러 없이 들어감** ⚠️ |

**테스트 10이 핵심입니다.** SQLite 는 FK 제약이 **기본으로 꺼져 있습니다.**
연결할 때마다 `PRAGMA foreign_keys = ON;` 을 실행해야 하고, 빠뜨리면 FK 를 선언해도 아무 효과가 없습니다.
(MySQL/PostgreSQL 은 기본으로 켜져 있습니다.)

### 3. 미니 리포트 — 핵심 지표 3개

| 지표 | 질문 | 위치 |
| --- | --- | --- |
| ① 이수 현황 | 미션별로 PASS 를 3명에게 받았는가? | `03_queries.sql` 하단 |
| ② **장학금 요건 체크** | 이번 달 동료평가 참여 2회·받기 2회·합계 4회를 채웠는가? | 〃 |
| ③ 분야별 집중도 | 어느 분야에 시간을 가장 많이 썼는가 (TOP 5) | 〃 |

지표 ②는 학칙 제13조의 장학금 지급 기준(본과정 AI·SW 기초: **월 4회 이상, 참여 2회·받기 2회 必**)을
그대로 SQL 로 옮긴 것입니다. 실행 결과 예시:

```
회원  받기  참여  합계  장학금요건
----  ----  ----  ----  ----------
도윤  3     4     7     충족
서연  3     2     5     충족
하은  2     3     5     충족
민준  4     0     4     미달      ← 합계는 4지만 '참여'가 0이라 미달
```

## 폴더 구조

```
study-tracker-db/
├── run.sh                        # 처음부터 다시 만드는 스크립트
├── sql/
│   ├── 01_schema.sql             # CREATE TABLE + 제약조건 + 인덱스
│   ├── 02_sample_data.sql        # INSERT (각 테이블 10행 이상)
│   ├── 03_queries.sql            # 쿼리 20개
│   └── 04_constraint_tests.sql   # (보너스) 제약조건 깨뜨리기
├── results/
│   ├── query_results.md          # 쿼리 + 실행 결과
│   └── constraint_tests_output.txt
├── docs/ERD.md                   # 관계도와 설계 근거
├── tools/run_queries.py          # 쿼리별로 쪼개 실행하는 도구
└── study_tracker.db              # 실행하면 생성됨 (.gitignore 로 제외)
```

## 제약 사항 준수

- 백엔드 프레임워크 **미사용** (Spring/Django/Express 없음)
- 로컬에서 실행 가능한 DB (SQLite)
- 뷰·프로시저·트리거 **미사용**
- 테이블 5개 (요구 4개 이상), 1:N 관계 4개 (요구 2개 이상)
- 각 테이블 10행 이상
- DB 고유 문법(`strftime`, `PRAGMA`)은 해당 쿼리에 **주석으로 명시**
