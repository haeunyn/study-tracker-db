"""쿼리 하나만 골라서 SQL 과 실행 결과를 보여준다.

평가장에서 긴 SQL 을 손으로 칠 필요가 없게 하려고 만들었다.
03_queries.sql 안의 `-- Q14.` 같은 머리말을 기준으로 블록을 찾는다.

실행: ./show.sh 14     (= python3 tools/show_query.py 14)
      ./show.sh        (번호 없이 → 목록만 보여준다)
"""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
DB = BASE / "study_tracker.db"
QUERY_FILE = BASE / "sql" / "03_queries.sql"

HEADER = re.compile(r"^--\s*(Q\d+\.|지표\s*[①②③]|\(가\)|\(나\))\s*(.*)$")


def load_blocks() -> list[dict]:
    blocks: list[dict] = []
    current: dict | None = None
    for line in QUERY_FILE.read_text(encoding="utf-8").splitlines():
        head = HEADER.match(line)
        if head:
            if current:
                blocks.append(current)
            current = {"id": head.group(1).rstrip("."), "desc": head.group(2).strip(), "sql": []}
            continue
        if current is not None:
            current["sql"].append(line)
    if current:
        blocks.append(current)

    # 블록 끝에 붙은 다음 구획 제목(-- ===== / -- [집계] 등)은 떼어낸다.
    for b in blocks:
        while b["sql"] and (not b["sql"][-1].strip() or b["sql"][-1].lstrip().startswith("--")):
            b["sql"].pop()

    return [b for b in blocks if "\n".join(b["sql"]).strip()]


def main() -> int:
    blocks = load_blocks()

    # 번호를 안 줬으면 목록만 보여준다.
    if len(sys.argv) < 2:
        print("쿼리 목록 —  ./show.sh <번호>  로 하나만 실행합니다\n")
        for b in blocks:
            print(f"  {b['id']:<8} {b['desc']}")
        return 0

    want = sys.argv[1].strip().upper()
    if want.isdigit():                      # 14 -> Q14
        want = f"Q{int(want):02d}"

    for b in blocks:
        if b["id"].upper() == want:
            sql_text = "\n".join(b["sql"]).strip()
            print(f"\n── {b['id']}. {b['desc']}\n", flush=True)
            print(sql_text)
            print("\n── 실행 결과\n", flush=True)   # 결과가 뒤에 오도록 먼저 내보낸다
            subprocess.run(
                ["sqlite3", "-header", "-column", str(DB)],
                input="PRAGMA foreign_keys = ON;\n" + sql_text,
                text=True,
            )
            print()
            return 0

    print(f"'{sys.argv[1]}' 에 해당하는 쿼리가 없습니다. 번호 없이 실행하면 목록이 나옵니다.", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
