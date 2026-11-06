#!/usr/bin/env python3
"""Build dataset/avhr/: the workshop's copy of edition humboldt digital, in the layout the
edition is edited in.

The source is the published TEI dataset (github.com/telota/edition-humboldt-digital,
CC BY-SA 4.0). It holds one file per register entry and the texts in their published form.
ediarum.index's avhr profile and ediarum.BASE.edit expect the editing layout instead, so this
script

- collects the register entries into register files under data/Register/:
      person       → Personen/<A–Z>.xml      (read by the index's person profile)
      place        → Orte/<A–Z>.xml          (place profile)
      institution  → Einrichtungen.xml       (organisation profile)
      glossary, measure, plant, bibliographical-abbrevation → Glossar.xml, Masse.xml,
                     Pflanzen.xml, Verweissiglen.xml (not loaded into the index; ediarum.id
                     scans them like every file, so their ids are never handed out again)
  Each entry is copied as it is; the files are sorted by the entries' titles.
- copies the letters whose <title> matches --letters into data/Briefe/<folder>/, named
  <date sent>_<id>.xml, and marks them as AVHR letters (telota:doctype="letter avhr"), which is
  what ediarum.BASE.edit's letter rules match.
- turns references to register entries back into keys, in every file: the published
  ref="https://edition-humboldt.de/H0001123 http://d-nb.info/gnd/…" becomes key="H0001123",
  the form the index reads and oXygen's tagging writes. References to anything else stay.

Text in, text out (regular expressions, no XML rewriting), so the entries keep their
formatting.

    scripts/make-dataset.py SOURCE [--letters REGEX] [--source LABEL] [--out DIR]

SOURCE is a checkout of the dataset (scripts/prepare.sh fetches the one named in sources.env).
"""

import argparse
import re
import shutil
import sys
import unicodedata
from collections import defaultdict
from pathlib import Path

HERE = Path(__file__).resolve().parent.parent

# published folder → (register file or folder, list element, entry type label)
REGISTERS = {
    "person": ("Personen/", "listPerson", "Personen"),
    "place": ("Orte/", "listPlace", "Orte"),
    "institution": ("Einrichtungen.xml", "listOrg", "Einrichtungen"),
    "glossary": ("Glossar.xml", "list", "Glossar"),
    "measure": ("Masse.xml", "list", "Maße"),
    "plant": ("Pflanzen.xml", "list", "Pflanzen"),
    "bibliographical-abbrevation": ("Verweissiglen.xml", "list", "Verweissiglen"),
}

ENTRY_REF = re.compile(r'\bref="(https://edition-humboldt\.de/H\d+(?:\s[^"]*)?)"')
ENTRY_URI = re.compile(r"^https://edition-humboldt\.de/(H\d+)$")


def keys(text: str) -> str:
    "ref=\"https://edition-humboldt.de/H… other URIs\" → key=\"H…\" (several entries: several keys)."

    def to_key(m: re.Match) -> str:
        ids = [u.group(1) for u in map(ENTRY_URI.match, m.group(1).split()) if u]
        return f'key="{" ".join(ids)}"'

    return ENTRY_REF.sub(to_key, text)


def title(text: str) -> str:
    m = re.search(r"<title[^>]*>(.*?)</title>", text, re.S)
    return " ".join(re.sub(r"<[^>]+>", "", m.group(1)).split()) if m else ""


def initial(label: str) -> str:
    "The register file an entry goes into: its title's first letter, without diacritics."
    for ch in unicodedata.normalize("NFKD", label):
        if ch.isalpha() and ch.isascii():
            return ch.upper()
    return "Andere"


def register_file(heading: str, list_element: str, entries: list[str]) -> str:
    body = "\n".join(entries)
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<TEI xmlns="http://www.tei-c.org/ns/1.0" xmlns:telota="http://www.telota.de" telota:doctype="register">
    <teiHeader>
        <fileDesc>
            <titleStmt>
                <title>{heading}</title>
            </titleStmt>
            <publicationStmt>
                <p>edition humboldt digital, Registerdatei des ediarum-Workshops (siehe README.md).</p>
            </publicationStmt>
            <sourceDesc>
                <p>Zusammengestellt aus den Registereinträgen des veröffentlichten Datensets.</p>
            </sourceDesc>
        </fileDesc>
    </teiHeader>
    <text>
        <body>
            <{list_element}>
{body}
            </{list_element}>
        </body>
    </text>
</TEI>
"""


def entries_of(text: str, list_element: str) -> str:
    "The children of the file's register list: everything between <listX> and </listX>."
    m = re.search(rf"<body>\s*<{list_element}>(.*)</{list_element}>\s*</body>", text, re.S)
    if not m:
        raise ValueError(f"no <body><{list_element}>")
    return m.group(1).strip("\n")


def build_registers(src: Path, out: Path) -> dict[str, int]:
    counts = {}
    for folder, (target, list_element, heading) in REGISTERS.items():
        files = sorted((src / "data" / "index" / folder).glob("*.xml"))
        if not files:
            sys.exit(f"make-dataset: {src}/data/index/{folder}: no files")
        groups: dict[str, list[tuple[str, str]]] = defaultdict(list)
        for f in files:
            text = f.read_text(encoding="utf-8")
            label = title(text)
            try:
                entry = entries_of(text, list_element)
            except ValueError as e:
                sys.exit(f"make-dataset: {f}: {e}")
            group = initial(label) if target.endswith("/") else ""
            groups[group].append((label.casefold(), keys(entry)))
        for group, items in sorted(groups.items()):
            items.sort()
            path = out / "data" / "Register" / (f"{target}{group}.xml" if group else target)
            path.parent.mkdir(parents=True, exist_ok=True)
            name = f"{heading} {group}".strip()
            path.write_text(register_file(name, list_element, [e for _, e in items]), encoding="utf-8")
        counts[folder] = len(files)
    return counts


def sent_date(text: str) -> str:
    m = re.search(r'<correspAction type="sent">(.*?)</correspAction>', text, re.S)
    d = m and re.search(r'<date\b[^>]*?\b(?:when|notBefore|from)="([^"]+)"', m.group(1))
    return d.group(1) if d else "undatiert"


def build_letters(src: Path, out: Path, pattern: str, folder: str) -> int:
    matcher = re.compile(pattern)
    target = out / "data" / "Briefe" / folder
    n = 0
    for f in sorted((src / "data" / "letter").glob("*.xml")):
        text = f.read_text(encoding="utf-8")
        if not matcher.search(title(text)):
            continue
        root = re.search(r"<TEI\b[^>]*>", text)
        if root is None:
            sys.exit(f"make-dataset: {f}: no <TEI> element")
        tag = root.group(0)
        if "telota:doctype" not in tag:
            tag = tag[:-1] + ' xmlns:telota="http://www.telota.de" telota:doctype="letter avhr">'
        text = text[: root.start()] + tag + text[root.end() :]
        target.mkdir(parents=True, exist_ok=True)
        (target / f"{sent_date(text)}_{f.stem}.xml").write_text(keys(text), encoding="utf-8")
        n += 1
    return n


def readme(src: Path, source: str, letters_folder: str, counts: dict[str, int], letters: int) -> str:
    citation = ""
    src_readme = src / "README.md"
    if src_readme.is_file():
        m = re.search(r"## Zitierempfehlung\s+(.*?)\n\s*\n", src_readme.read_text(encoding="utf-8"), re.S)
        citation = m.group(1).strip() if m else ""
    return f"""# edition humboldt digital: workshop copy

A selection of the TEI dataset of *edition humboldt digital* for the ediarum workshop,
built by `scripts/make-dataset.py` from

    {source}

- `data/Register/`: every register entry ({counts['person']} persons, {counts['place']} places,
  {counts['institution']} institutions, plus glossary, measures, plants and abbreviations),
  collected into register files.
- `data/Briefe/{letters_folder}/`: {letters} letters.

Changes against the published files: register entries are grouped into register files; letters
carry `telota:doctype="letter avhr"`; references to register entries are written as
`key="H…"` instead of `ref="https://edition-humboldt.de/H… …"`. Nothing else is changed.

## Citation

{citation or "edition humboldt digital, ed. by Ottmar Ette. Berlin-Brandenburgische Akademie der Wissenschaften. https://edition-humboldt.de"}

## Licence

© Berlin-Brandenburgische Akademie der Wissenschaften. Licensed under Creative Commons
Attribution-ShareAlike 4.0 International (CC BY-SA 4.0),
https://creativecommons.org/licenses/by-sa/4.0/. This copy is a modified version (see above)
and is shared under the same licence.
"""


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("src", type=Path, help="checkout of telota/edition-humboldt-digital")
    parser.add_argument("--letters", default="Rugendas", help="regular expression on the letters' <title>")
    parser.add_argument("--folder", help="folder below data/Briefe/ (default: from --letters)")
    parser.add_argument("--source", help="where the checkout came from, for the README")
    parser.add_argument("--out", type=Path, default=HERE / "dataset" / "avhr")
    args = parser.parse_args()

    src: Path = args.src.resolve()
    if not (src / "data" / "index" / "person").is_dir():
        sys.exit(f"make-dataset: {src}: no data/index/person (not the edition humboldt digital dataset?)")
    folder = args.folder or re.sub(r"\W+", "_", args.letters).strip("_") or "Auswahl"

    out: Path = args.out
    if out.exists():
        shutil.rmtree(out)
    out.mkdir(parents=True)
    counts = build_registers(src, out)
    letters = build_letters(src, out, args.letters, folder)
    if not letters:
        sys.exit(f"make-dataset: no letter title matches {args.letters!r}")

    left = [
        str(p.relative_to(out))
        for p in out.rglob("*.xml")
        if re.search(r'<(?:persName|placeName|orgName|settlement)\b[^>]*\bref="https://edition-humboldt\.de/H', p.read_text(encoding="utf-8"))
    ]
    if left:
        sys.exit(f"make-dataset: references left unconverted in {', '.join(left[:5])}")

    (out / "README.md").write_text(readme(src, args.source or str(src), folder, counts, letters), encoding="utf-8")
    print(
        f"dataset: {counts['person']} persons, {counts['place']} places, {counts['institution']} institutions, "
        f"{letters} letters in data/Briefe/{folder}/ → {out.relative_to(HERE) if out.is_relative_to(HERE) else out}"
    )


if __name__ == "__main__":
    main()
