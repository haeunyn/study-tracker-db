#!/bin/bash
# show.sh — 쿼리 하나만 골라서 SQL 과 결과를 한 번에 보여준다.
#
#   ./show.sh        쿼리 목록
#   ./show.sh 14     Q14 의 SQL + 실행 결과
#
# 평가장에서 긴 SQL 을 손으로 치지 않으려고 만든 도우미다.

set -e
cd "$(dirname "$0")"
python3 tools/show_query.py "$@"
