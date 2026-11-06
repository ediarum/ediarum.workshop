"""One-shot (services index-keys, fileservice-keys): store the fixed workshop API keys.

Both apps keep keys in ediarum_sdk's `sdk_api_key` table (SHA-256 hashes only) and their CLIs
only hand out random keys. This writes the hash of a key given in the environment instead, so
the oXygen project file and webdav's settings can name the key in advance. Idempotent: an
existing row of the same name gets the hash of the given key.

    python seed_keys.py NAME=ENVVAR:PROJECTS[:admin] ...

DATABASE_URL is the app's own. The app must have created its tables already.
"""

import os
import sys

from sqlmodel import Session, create_engine

from ediarum_sdk.auth import ApiKey, hash_key


def main() -> None:
    engine = create_engine(os.environ["DATABASE_URL"])
    with Session(engine) as session:
        for spec in sys.argv[1:]:
            name, rest = spec.split("=", 1)
            env, projects, *flags = rest.split(":")
            key = os.environ[env]
            row = session.get(ApiKey, name) or ApiKey(name=name, key_hash="")
            row.key_hash = hash_key(key)
            row.projects = projects
            row.is_admin = "admin" in flags
            row.is_active = True
            row.created_by = "workshop"
            session.add(row)
            print(f"key {name}: {projects}{' (admin)' if row.is_admin else ''}")
        session.commit()


if __name__ == "__main__":
    main()
