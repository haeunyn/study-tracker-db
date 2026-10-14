"""03_queries.sql 을 쿼리 단위로 쪼개 실행하고, 결과를 마크다운으로 남긴다.

과제 요구: "쿼리마다 실행 결과를 확인할 수 있어야 하고,
            각 쿼리에 무엇을 확인하는 쿼리인지 한 줄 설명을 붙인다"

통째로 실행한 출력은 어떤 결과가 어떤 쿼리의 것인지 알기 어려워서,
`-- Q01.` 같은 머리말을 기준으로 블록을 나눠 하나씩 실행한다.

실행: python tools/run_queries.py
"""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
DB = BASE / "study_tracker.db"
QUERY_FILE = BASE / "sql" / "03_queries.sql"
OUT = BASE / "results" / "query_results.md"

# 블록 시작을 알리는 머리말: "-- Q01. 설명" / "-- 지표 ① ..." / "-- (가) ..."
HEADER = re.compile(r"^--\s*(Q\d+\.|지표\s*[①②③]|\(가\)|\(나\))\s*(.*)$")
# 큰 구획 제목: "-- [기본 조회]"
SECTION = re.compile(r"^--\s*\[([^\]]+)\]")


def run_sql(sql: str) -> str:
    """sqlite3 CLI 로 SQL 을 실행하고 표 형태 출력을 돌려준다."""
    proc = subprocess.run(
        ["sqlite3", "-header", "-column", str(DB)],
        input=sql,
        capture_output=True,
        text=True,
    )
    out = (proc.stdout or "").rstrip()
    err = (proc.stderr or "").strip()
    if err:
        out = f"{out}\n[stderr] {err}".strip()
    return out or "(결과 행 없음)"


def main() -> int:
    if not DB.exists():
        print(f"DB 가 없습니다: {DB}\n먼저 ./run.sh 를 실행하세요.", file=sys.stderr)
        return 1

    lines = QUERY_FILE.read_text(encoding="utf-8").splitlines()

    blocks: list[dict] = []
    current: dict | None = None
    section = ""

    for line in lines:
        sec = SECTION.match(line)
        if sec:
            section = sec.group(1)
            continue

        head = HEADER.match(line)
        if head:
            if current:
                blocks.append(current)
            current = {
                "id": head.group(1).rstrip("."),
                "desc": head.group(2).strip(),
                "section": section,
                "sql": [],
            }
            continue

        if current is not None:
            current["sql"].append(line)

    if current:
        blocks.append(current)

    out_lines = [
        "# 쿼리 실행 결과",
        "",
        "> `tools/run_queries.py` 가 `sql/03_queries.sql` 을 쿼리 단위로 실행한 결과입니다.",
        "> 재생성: `./run.sh`",
        "",
        f"- 총 {len(blocks)}개 블록",
        f"- DB: `study_tracker.db` (SQLite {subprocess.run(['sqlite3', '--version'], capture_output=True, text=True).stdout.split()[0]})",
        "",
        "---",
        "",
    ]

    for block in blocks:
        sql_text = "\n".join(block["sql"]).strip()
        if not sql_text:
            continue
        label = f"{block['id']}. {block['desc']}" if block["desc"] else block["id"]
        tag = f" · {block['section']}" if block["section"] else ""
        out_lines += [
            f"## {label}{tag}",
            "",
            "```sql",
            sql_text,
            "```",
            "",
            "**실행 결과**",
            "",
            "```",
            run_sql(sql_text),
            "```",
            "",
        ]

    OUT.write_text("\n".join(out_lines), encoding="utf-8")
    print(f"✅ {OUT.relative_to(BASE)} 생성 ({len(blocks)}개 블록)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
