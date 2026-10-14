# ERD — 코디세이 학습 관리 DB

## 관계도

```
┌─────────────────────┐              ┌─────────────────────┐
│      category       │              │       member        │
├─────────────────────┤              ├─────────────────────┤
│ PK id               │              │ PK id               │
│    name   (UNIQUE)  │              │    name   (NOT NULL)│
│    description      │              │    email  (UNIQUE)  │
└──────────┬──────────┘              │    github_id        │
           │                         │    joined_on        │
           │ 1                       │    created_at       │
           │                         └─────┬──────────┬────┘
           │                             1 │        1 │
           │                               │          │
           │ N                           N │          │ N
┌──────────┴───────────────────────────────┴──┐       │
│                 study_log                   │       │
├─────────────────────────────────────────────┤       │
│ PK id                                       │       │
│ FK member_id    → member.id   (CASCADE)     │       │
│ FK category_id  → category.id (RESTRICT)    │       │
│    title, studied_on, minutes, created_at   │       │
└─────────────────────────────────────────────┘       │
                                                      │
┌─────────────────────┐                               │
│      mission        │                               │
├─────────────────────┤                               │
│ PK id               │                               │
│    code   (UNIQUE)  │                               │
│    title, is_required, est_hours                    │
└──────────┬──────────┘                               │
           │ 1                                        │
           │                                          │
           │ N                                        │
┌──────────┴──────────────────────────────────────────┴──┐
│                     evaluation                         │
├────────────────────────────────────────────────────────┤
│ PK id                                                  │
│ FK mission_id   → mission.id (CASCADE)                 │
│ FK evaluatee_id → member.id  (CASCADE)  평가를 받은 사람 │
│ FK evaluator_id → member.id  (CASCADE)  평가를 한 사람   │
│    evaluated_on, result('PASS'|'FAIL'), comment        │
└────────────────────────────────────────────────────────┘
```

## 1:N 관계 4개

| 부모 (1) | 자식 (N) | 읽는 법 | 삭제 동작 |
| --- | --- | --- | --- |
| `member` | `study_log` | 한 사람이 **여러** 학습 기록을 남긴다 | CASCADE |
| `category` | `study_log` | 한 분야에 **여러** 학습 기록이 속한다 | RESTRICT |
| `mission` | `evaluation` | 한 미션에 **여러** 평가가 달린다 | CASCADE |
| `member` | `evaluation` | 한 사람이 **여러 번** 평가를 받고/한다 (2번 참조) | CASCADE |

> **1:N 을 구분하는 법**: FK 가 있는 쪽이 항상 **N(자식)** 이다.
> `study_log.member_id` 가 있으므로 study_log 가 N, member 가 1이다.
> "학습 기록 하나는 회원 한 명에게 속하지만, 회원 한 명은 여러 기록을 가진다."

## member 를 두 번 참조한 이유 ★ 설명 포인트

`evaluation` 은 **같은 테이블(member)을 두 번** 가리킵니다.

```sql
evaluatee_id → member.id   -- 평가를 받은 사람
evaluator_id → member.id   -- 평가를 한 사람
```

- 평가는 **두 사람 사이의 사건**입니다. 한쪽만으로는 기록이 성립하지 않습니다.
- 이름을 `member_id` 로 뭉뚱그리면 "누가 누구를?"을 알 수 없습니다.
- 조회할 때는 **같은 테이블을 별칭 두 개로 조인**합니다.

```sql
FROM evaluation e
INNER JOIN member ee ON e.evaluatee_id = ee.id   -- ee = evaluatee
INNER JOIN member er ON e.evaluator_id = er.id   -- er = evaluator
```

별칭이 없으면 "어느 member 의 name 인지" 구분할 수 없어 SQL 이 오류를 냅니다.

그리고 `CHECK (evaluatee_id <> evaluator_id)` 로 **자기 자신을 평가하는 것**을 막았습니다.
스키마가 업무 규칙을 지켜주는 예입니다.

## 삭제 동작을 다르게 준 이유

| 설정 | 쓴 곳 | 이유 |
| --- | --- | --- |
| `ON DELETE CASCADE` | `study_log.member_id` | 회원이 사라지면 그 사람의 기록은 **주인이 없어 의미가 없다** |
| `ON DELETE RESTRICT` | `study_log.category_id` | 기록이 남아 있는데 분야를 지우면 **그 기록이 어디 속하는지 알 수 없다** → 삭제를 막는다 |

> 같은 FK 라도 "부모가 사라지면 자식은 어떻게 되어야 하는가"의 답이 다릅니다.
> 이걸 정하는 것이 설계이고, 정하지 않으면(기본값 NO ACTION) 나중에 데이터가 꼬입니다.

## 왜 엑셀이 아니라 DB 인가 (과제 목표 1번)

엑셀 한 시트에 전부 적었다면:

| 이름 | 이메일 | 분야 | 제목 | 분 |
| --- | --- | --- | --- | --- |
| 하은 | haeun@… | DB | PK/FK 와 1:N | 100 |
| 하은 | haeun@… | Git | 브랜치 포인터 | 60 |
| 하은 | haeun@… | Python | 제너레이터 | 120 |

- **중복**: 이름과 이메일이 기록 수만큼 반복됩니다
- **수정 위험**: 이메일을 바꾸려면 모든 줄을 고쳐야 하고, 하나라도 빠뜨리면 같은 사람이 두 명이 됩니다
- **오타 방치**: 분야를 'DB', 'db', '디비' 로 제각각 적어도 막아주지 않습니다
- **집계 불안**: 위 상태에서 "분야별 합계"를 내면 'DB'와 'db'가 따로 집계됩니다

테이블을 나누면 사람은 `member` 에 **한 번만** 저장되고, 기록은 그 사람의 `id` 만 가리킵니다.
분야도 `category` 에 등록된 것만 쓸 수 있어(FK) 오타가 원천 차단됩니다.
**"고칠 곳이 한 군데"** 가 되는 것 — 이것이 관계형 DB 의 핵심입니다.
