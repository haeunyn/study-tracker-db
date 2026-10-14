#!/bin/bash
# run.sh — DB를 처음부터 다시 만들고 쿼리 결과까지 생성한다.
#
#   ./run.sh
#
# 하는 일
#   1) 기존 DB 삭제 (재현 가능하게)
#   2) 스키마 생성
#   3) 샘플 데이터 입력
#   4) 쿼리 20개 실행 → results/query_results.md

set -e
cd "$(dirname "$0")"

echo "① 기존 DB 삭제"
rm -f study_tracker.db

echo "② 스키마 생성 (sql/01_schema.sql)"
sqlite3 study_tracker.db < sql/01_schema.sql

echo "③ 샘플 데이터 입력 (sql/02_sample_data.sql)"
sqlite3 study_tracker.db < sql/02_sample_data.sql

echo "④ 행 수 확인"
sqlite3 -header -column study_tracker.db "
SELECT 'member' AS 테이블, COUNT(*) AS 행수 FROM member
UNION ALL SELECT 'category', COUNT(*) FROM category
UNION ALL SELECT 'mission', COUNT(*) FROM mission
UNION ALL SELECT 'study_log', COUNT(*) FROM study_log
UNION ALL SELECT 'evaluation', COUNT(*) FROM evaluation;"

echo "⑤ 쿼리 실행 → results/query_results.md"
python3 tools/run_queries.py

echo ""
echo "완료! sqlite3 study_tracker.db 로 직접 들어가 볼 수 있습니다."
