"""One-shot (service index-import): load the project's registers into ediarum.index, once.

The workshop project is app-led: its registers are kept in the index, and the watcher never
reads them from XML. This is the migration such a project starts from: the register XML in the
repository (data/Register, on the shared volume once fileservice has cloned it) is ingested a
single time, with `ediarum-index ingest --of-project <project>`. Afterwards the entries are
edited in the Index app only.

Skipped when the project already has entries, so a restart doesn't re-ingest (the ingest would
not delete or overwrite entries made in the app anyway, but it takes a few minutes).

    python import_registers.py PROJECT
"""

import os
import subprocess
import sys
import time
from pathlib import Path

from sqlmodel import Session, func, select

from ediarum_index.db import engine
from ediarum_index.models import Entry

WAIT_SECONDS = 600


def main() -> None:
    project = sys.argv[1]
    with Session(engine) as session:
        count = session.exec(select(func.count()).select_from(Entry).where(Entry.project_name == project)).one()
    if count:
        print(f"index-import: {project} has {count} entries already, nothing to do")
        return

    # fileservice clones the project in the background after it starts
    registers = Path(os.environ["XML_MOUNT_ROOT"]) / project / "data" / "Register"
    for _ in range(WAIT_SECONDS // 5):
        if registers.is_dir():
            break
        print(f"index-import: waiting for {registers} …", flush=True)
        time.sleep(5)
    else:
        sys.exit(f"index-import: {registers} did not appear (docker compose logs fileservice)")

    print(f"index-import: ingesting the registers of {project} (a few minutes) …", flush=True)
    code = subprocess.run(["ediarum-index", "ingest", "--of-project", project]).returncode
    with Session(engine) as session:
        count = session.exec(select(func.count()).select_from(Entry).where(Entry.project_name == project)).one()
    if not count:
        sys.exit(f"index-import: no entries after the ingest (exit {code}, log above)")
    # exit 1 also means "a record failed or conflicted": worth a look, not worth stopping the stack
    print(f"index-import: {count} entries" + (f" (ingest exit {code}: see the report above)" if code else ""))


if __name__ == "__main__":
    main()
