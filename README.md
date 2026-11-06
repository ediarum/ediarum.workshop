# ediarum workshop

The whole ediarum stack on your own computer, started with one command: the platform with the
Index and IDs apps, ediarum.webdav for oXygen, and the services behind them. The data comes
from *edition humboldt digital*: its registers and the letters between Alexander von Humboldt
and Johann Moritz Rugendas (see [Data and licence](#data-and-licence)). Everything runs
locally; nothing you change leaves your computer.

The project is **app-led**: persons, places and institutions are kept and edited in the
**Index app**. The texts stay TEI files that you edit in **oXygen**, and they point at register
entries by id (`<persName key="H0012069">`). A new entry gets its id from **ediarum.id** the
moment it's saved in the Index app, so you can tag it in a letter right away.

```
                     http://localhost:1769
                              │
                            proxy
   ┌──────────┬───────────┬───┴─────────┬─────────────┬──────────────┐
platform   webdav       index          id         fileservice     (gitserver,
 (apps)  (login, WebDAV) (registers)  (new ids)   (shared XML)     MariaDB)
              ▲
         oXygen XML Editor
```

## What you need

- **Docker**: Docker Desktop (Windows with the WSL 2 backend, macOS) or Docker Engine with the
  Compose plugin (Linux). Give Docker at least 6 GB of memory (Docker Desktop → Settings →
  Resources) and keep about 5 GB of disk space free.
- **git**. On Windows install [Git for Windows](https://git-scm.com/download/win): it brings
  **Git Bash**, the terminal all workshop scripts run in.
- **oXygen XML Editor** or **oXygen XML Author**, version 24 or newer (the Developer edition has
  no Author view).
- Internet access for the first start (Docker downloads the base images).

## Start

Open a terminal in this folder. On Windows that is **Git Bash**: right-click the folder in
Explorer → *Open Git Bash here* (Windows 11: *Show more options* first), not PowerShell or the
command prompt. Then run:

```bash
./start.sh
```

The first start builds the images and takes a while (10–20 minutes, depending on the computer
and the connection). Later starts take under a minute. The script waits until the registers
are loaded into the index, then prints:

```
ediarum workshop is running.

  Platform (Index, IDs, WebDAV)   http://localhost:1769/
  Login                           workshop@example.org / workshop
  WebDAV for oXygen               http://localhost:1769/webdav/connection/avhr/
  oXygen project file             …/oxygen/workshop.xpr
```

## Set up oXygen

The workshop comes with an oXygen project file. It brings ediarum.BASE.edit, the framework for
the letters (Author view, toolbar, tagging of persons, places and institutions), and points it
at your local services. The stack has to be running (see [Start](#start)).

### 1. Open the workshop project

1. *Project → Open Project…* and choose `oxygen/workshop.xpr` in
   this folder (`start.sh` prints the full path).
2. Restart oXygen if it asks you to: the project switches the frameworks directory to its own
   folder, and oXygen loads frameworks on start. Open the project again if it isn't open
   anymore.
3. Check that it took effect, in *Options → Preferences* (macOS: *oXygen → Settings*):
   - *Editor Variables → Custom Editor Variables* shows `ediarum_project_domain` =
     `http://localhost:1769` and `ediarum_project_name` = `avhr`. The selector at the bottom of
     the dialog must say **Project Options**.
   - *Document Type Association* lists `ediarum.BASE.edit`.

Keep the project file where it is: it finds the framework next to itself.

### 2. Connect to WebDAV

Quick: *File → Open URL…*, enter `http://localhost:1769/webdav/connection/avhr/`,
user `workshop@example.org`, password `workshop`, then *Browse*.

To browse the files all the time (recommended):

1. *Window → Show View → Data Source Explorer*.
2. *Configure Database Sources…* → *Data Sources → New*: type **WebDAV**, any name (e.g.
   `workshop`).
3. *Connections → New*: choose that data source and enter
   - WebDAV URL: `http://localhost:1769/webdav/connection/avhr/`
   - User: `workshop@example.org`, password: `workshop`
4. The connection appears in the Data Source Explorer. The letters are in
   `Briefe/Rugendas/`, named by the date they were sent.

## The exercise: a new person, from the Index app into a letter

### 1. Add the person in the Index app

1. Open http://localhost:1769/ and log in (`workshop@example.org` / `workshop`).
2. Open **Index**, choose the project *edition humboldt digital (Workshop)* and the entry type
   **person**. Search for a name to see how the existing 9,400 persons look.
3. **New entry.** Fill in at least *Nachname* and *Vorname* (or *Ungegliederter Name*), and
   the label as it should appear in lists (`Nachname, Vorname`). Leave **Project ID empty**.
4. Save. The entry opens; its **Project ID** is now filled in: `H` and seven digits, e.g.
   `H4821937`.

Changes to an entry (dates, notes, authority URIs, relations) are made the same way: *Edit* in
the entry view. In this project the Index app is the register: the register files in oXygen
(`Register/`) are not connected to it. A change in the Index app doesn't show up in them, and a
change to them in oXygen doesn't reach the Index app.

### 2. Where the id comes from

The Index app didn't make that id up. When an entry is saved without a Project ID, ediarum.index
asks **ediarum.id** for a new one in the project's scheme (prefix `H`, seven random digits),
which checks it against every id already in use in the project's files, reserves it, and marks
it as used straight away.

To check, ask ediarum.id about the id: open this address in the browser, with your id at the end of the path:

    http://localhost:1769/api/id/avhr/ids/H4821937?key=UoGsSo5JrihjZW57AGMOaGl1mUnYSM4_l70226Do028

The answer lists the id as `"status": "used"`, `"reserved_by": "index"` and the note
`ediarum.index person: <your label>`. An id nobody has handed out answers `"status": "free"`.
(The **IDs** app in the platform manages the API keys only; it has no list of ids. The key in
the address is the workshop's oXygen key from `workshop.env`.) oXygen gets its ids from the same
service, so an id is never handed out twice, whoever asks.

### 3. Tag the person in a letter

1. In oXygen, open a letter from `Briefe/Rugendas/`. It opens in the Author view with the
   ediarum toolbar.
2. Select a name in the text, then click the **person** button in the toolbar
   (*Personenname*).
3. The list comes straight from the Index app. Type part of your new person's name, choose it,
   *OK*.
4. Switch to the *Text* view: the selection is now
   `<persName key="H4821937">…</persName>`, with your person's id.
5. Save (Ctrl+S / Cmd+S). webdav commits the letter to the project's repository. The letter now
   points at the Index entry by its id; the person's data stays in the Index app.

Places and institutions work the same way (the place and organisation buttons; entry types
*place* and *organisation* in the Index app).

### 4. Add a comment to a register entry

1. In the Index app, open your new person: click the entry in the list, not *Edit*.
2. Below the fields, under **Comments**, choose **Add comment**.
3. Under *Field*, choose what the comment is about: *General* for the whole entry, or one field,
   e.g. the date of birth. Write the comment and click **Add**.
4. The comment is listed under *Comments*, with the field it belongs to. Open an existing entry
   too: comments from the original registers (oXygen comments in the XML) show there the same
   way.

### 5. Relations between persons

1. In the Index app, open your new person in the entry view (not *Edit*).
2. Under **Relations**, choose **Add relation**. Keep *This entry → target*, type a predicate,
   e.g. `corresponds_with` (the list only suggests `member_of` and `part_of`, but any word
   works), keep the target type **person** and choose any existing person as the target entry
   (type a few letters of a name). **Add**.
3. Open that person's entry: the relation shows there too, in the other direction, next to any
   `mentions` that come from the notes of the original registers.
4. A person can also be linked to an institution: predicate `member_of`, target type
   **organisation**. Institutions are a register of their own (entry type *organisation* in the
   Index app): you can add and edit them the same way as persons and places.

### 6. Who is editing what: WebDAV locks

1. Open a letter in oXygen through WebDAV and leave it open.
2. Open http://localhost:1769/ and go to the **WebDAV** admin, then to the project
   *edition humboldt digital (Workshop)*.
3. Under the WebDAV locks you see the letter, who locked it and since when. This is how webdav
   keeps two people from overwriting each other's work.
4. Close the letter in oXygen and reload the page: the lock is gone.

### 7. A second editor: a new WebDAV user

1. Open http://localhost:1769/, go to the **WebDAV** admin and open **Manage Users**. Create a user
   with a name, an email address (e.g. `editor@example.org`) and a password of at least 8
   characters Leave *Make the user an Admin?* unticked and click **Register New User**.
2. Open the project *edition humboldt digital (Workshop)*, choose the new user under the
   project's users and click **Add User**. Without this, the user can't open the project.
3. In oXygen, add a second WebDAV connection in the Data Source Explorer (as in
   [Connect to WebDAV](#2-connect-to-webdav)), with the same URL but the new user's email and
   password.
4. Through the new connection, open a letter and leave it open. In the WebDAV admin (task 6),
   the lock now names the new user.
5. Through your first connection (`workshop@example.org`), open the same letter: oXygen tells
   you it is locked by someone else, and you can't save over the other editor's work.
6. Close the letter in the new user's connection. Then remove the new user from the project in
   the WebDAV admin and try the new connection again: the project is no longer open to them.

### 8. Reserve an id and watch it become used

ediarum.id knows every id in the project's files: `"used"` (found in a file), `"reserved"`
(handed out, not yet in a file) or `"free"`.

1. Ask ediarum.id for a new id, with a note on what it is for:

       http://localhost:1769/api/id/avhr/new-id?note=my+test&key=UoGsSo5JrihjZW57AGMOaGl1mUnYSM4_l70226Do028
       
   Change only the text after `note=` (up to the `&`) to your own note, with `+` for spaces,
   e.g. `note=footnote+in+letter+1826`. Leave the rest of the address as it is.
   The answer is the id, e.g. `H5550123`. Reload the page and you get another one: every
   request reserves a new id.
2. Check it:

       http://localhost:1769/api/id/avhr/ids/H5550123?key=UoGsSo5JrihjZW57AGMOaGl1mUnYSM4_l70226Do028

   Replace `H5550123` (between `ids/` and `?`) with the id you got in step 1. Leave the rest of
   the address as it is.
   It is `"reserved"`, with your note and an `expires_at`: a reservation that is never used is
   released after 14 days.
3. In oXygen, open a letter and switch to the *Text* view. Replace the value in the root element `<TEI … xml:id="H0017851">` with your id, e.g. `xml:id="H5550123"`, and save.
4. About 30 seconds later, check the id again: it is `"used"`, and `source_file` names your
   letter. ediarum.id found it in the saved file.

### Next: a project of your own

Start an empty edition next to avhr, created in the WebDAV app the way an admin does on the
platform: see **[NEW-PROJECT.md](NEW-PROJECT.md)**.

### Back to your usual setup

*Project → Close Project*, or open your usual project file. The workshop's settings only apply
while its project is open.

## Stop, continue, start over

In the same terminal as for the start (Windows: Git Bash):

| | Command |
|---|---|
| Stop (everything is kept) | `./stop.sh` |
| Continue | `./start.sh` |
| Start over with the original data | `./reset.sh`, then `./start.sh` |

## Troubleshooting

- **"Docker is not running"**: start Docker Desktop and wait until it says it's running.
- **Windows: `./start.sh` isn't found or opens in another program**: the terminal isn't Git Bash.
  Open Git Bash in this folder (see [Start](#start)) and run it there.
- **"Port 1769 is already in use"**: another program uses the port. Stop it, or set another
  `PORT` in `workshop.env` and run `scripts/prepare.sh` (it rewrites the oXygen project file).
- **A service doesn't come up**: see which, and why:

  ```bash
  docker compose --env-file workshop.env --env-file sources.env ps -a
  docker compose --env-file workshop.env --env-file sources.env logs <service>
  ```
- **The lookup in oXygen shows an error or stays empty**:
  - Is the stack running? http://localhost:1769/ must open in the browser.
  - Does oXygen use a proxy? *Preferences → Network Connection Settings → Proxy*: exclude
    `localhost`.
  - Are the project's editor variables active? [Step 1.3](#1-open-the-workshop-project): if the
    selector says *Global Options*, oXygen uses your usual servers instead of the local ones.
  - Right after a reset the registers are still loading: the `logs` command above, for the
    service `index-import`, shows how far.
  - **A person you just created isn't in the list**: check that it has a *Project ID* in the
    Index app (without one, it's left out of oXygen's lists). Then run the person action
    again: the list is fetched anew each time.
- **Documents open in the Text view only**: the framework isn't loaded. Check
  [step 1.3](#1-open-the-workshop-project) and restart oXygen.
- **No person or place buttons, icons missing**: ediarum.BASE.edit isn't loaded.
  *Document Type Association* must list `ediarum.BASE.edit`; if not, check step 1.3 and restart
  oXygen.
- **A framework is there twice**: you also have ediarum.BASE.edit (or the AVHR framework) as an
  add-on installed. Disable the extra copy in *Document Type Association* while you work with
  the workshop, or use a separate oXygen installation.
- **"New entry" fails with an error about ediarum.id**: the index couldn't reach ediarum.id and
  doesn't create an entry without an id. The `ps -a` command above must list `id-api` as
  *healthy*.
- **The register files in `Register/` don't show my new person**: expected. They are the
  register XML the Index app was loaded from once, at the first start; the Index app keeps the
  registers since then and doesn't write these files.
- **Slow on Apple Silicon or with little memory**: give Docker more memory; close other programs.

---

## For trainers

### Where the parts come from: `sources.env`

`sources.env` names every part of the workshop. Each entry is either a path (relative to this
folder) or a git URL with a tag, branch or commit:

| Setting | What | Used by |
|---|---|---|
| `PLATFORM_BUILD` | ediarum-platform (app shell) | Docker build |
| `WEBDAV_BUILD` | ediarum.webdav (login, project registry, WebDAV) | Docker build |
| `FILESERVICE_BUILD` | ediarum.fileservice (shared XML checkout) | Docker build |
| `ID_BUILD`, `ID_FRONTEND_BUILD` | ediarum.id and its app | Docker build |
| `INDEX_BUILD`, `INDEX_FRONTEND_BUILD` | ediarum.index and its app | Docker build |
| `BASE_EDIT_SOURCE` | ediarum.BASE.edit, the oXygen framework | `scripts/prepare.sh` |
| `DATA_SOURCE`, `DATA_LETTERS` | the edition humboldt digital dataset, and which letters to include (a regular expression on the letters' titles) | `scripts/prepare.sh` |

A git URL for an image built from a sub-folder takes the folder after a colon:
`https://github.com/ediarum/ediarum.index.git#v0.2.0:frontend`. The start scripts fetch the
services' git URLs with your own git, and its login, into `.sources/<repo>/`
(`scripts/fetch-services.sh`), and Docker builds from there; `scripts/prepare.sh` fetches its two
the same way. So private repositories work for whoever can `git clone` them. A path is built as
it is, uncommitted changes included, which is the way to try out changes to a service.

### Generated folders

`scripts/prepare.sh` builds them from the sources above (needs git and Python 3.9 or newer;
on Windows `python` or `py` will do). `start.sh` downloads them from `GENERATED_URL`
(`sources.env`) if one of them is missing, and runs `prepare.sh` if that is empty or fails.

| Folder | Script | What |
|---|---|---|
| `dataset/avhr/` | `scripts/make-dataset.py` | the registers and the selected letters, in the layout the edition is edited in |
| `oxygen/` | `scripts/make-oxygen.py` | `ediarum.BASE.edit/` and `workshop.xpr` with every editor variable pointed at `localhost` |

The published dataset holds one file per register entry and references entries as
`ref="https://edition-humboldt.de/H…"`. `make-dataset.py` collects the entries into register
files (`Register/Personen/A.xml`, …, `Orte/…`, `Einrichtungen.xml`), turns the references into
`key="H…"`, and marks the letters as `telota:doctype="letter avhr"`. That's the form
ediarum.index's avhr profile reads and ediarum.BASE.edit's letter rules and tagging actions
expect.

After a change to `sources.env`'s data or framework entries, or to `PORT`: run
`scripts/prepare.sh`, then `./reset.sh` and `./start.sh` (the git server is filled from
`dataset/` on its first start only).

### Releases

A release is published to https://github.com/ediarum/ediarum.workshop as one snapshot commit
(no development history), and GitHub Actions builds `workshop-generated.tar.gz` for it:

```
scripts/release.sh patch|minor|major
```

It sets `GENERATED_URL` in `sources.env` to the new tag's GitHub release file, commits, tags and
pushes, then hands over to `scripts/publish.sh`. That script refuses a snapshot that still holds
internal hosts or tokens, so every `*_BUILD` and `*_SOURCE` has to point at a public repository
first. Pushing the tag starts `.github/workflows/workshop.yml`, which creates the release with
the file. `scripts/publish.sh --check X.Y.Z` runs the checks without changing anything.

### App-led, and what that takes

webdav registers the project with *Index app is source of truth* (`seed/seed-webdav.php`), so
the registry says `index_source_of_truth: app`. Then:

- ediarum.index keeps the registers. The one-shot `index-import` loads `data/Register` once
  (`ediarum-index ingest --of-project avhr`), as a project does when it moves its registers into
  the app, and is skipped once the project has entries. The index watcher ingests XML-led
  projects only, so the stack doesn't run it.
- index-api has `ID_URL`/`ID_KEY`: an entry created without a `source_id` gets one from
  ediarum.id (reserved and confirmed at once). If ediarum.id is down, creating fails (503).
- fileservice and ediarum.id treat the project like any other: the texts are files.
  `data/Register` stays in the repository, so ediarum.id knows the ids already in use and never
  hands one out again.
- oXygen gets only ediarum.BASE.edit, with no register framework, so there's no XML way to
  edit an entry.

### How it differs from the instance (`ediarum-platform/deploy`)

- One local MariaDB for webdav and index instead of the hosted database.
- `gitserver` (git daemon) instead of GitLab: webdav clones and pushes there, fileservice clones
  from there. It's created from `dataset/` on the first start.
- webdav's services are copied into `compose.yaml` rather than included (its compose only builds,
  needs a host directory, and has its own database).
- webdav reports changes to fileservice only (it has a single services URL); ediarum.id follows
  through its watcher every `RECONCILE_INTERVAL` (30 s).
- Fixed, public keys and passwords in `workshop.env`; the proxy listens on `127.0.0.1` only.
- The webdav project is created by `seed/seed-webdav.php` (webdav has no CLI for projects); the
  fixed index and fileservice keys are stored by `seed/seed_keys.py`, ediarum.id's keys (oXygen,
  index) are written into its `keys.toml` on start.
- The registers are loaded by the `index-import` one-shot.
- The fixed keys are valid for every project, so projects added at runtime work with them
  ([NEW-PROJECT.md](NEW-PROJECT.md)). Such a project gets its repository from the git server's
  `new-repo`, or uses the participant's own one (`--repo`, with a token that the fileservice
  reads from `secrets/git_token`), and its id prefix in `config/id/projects.toml`
  (`scripts/new-project.sh`); the fileservice, ediarum.id and ediarum.index learn of it on a
  restart.

**Start order:** db and gitserver → webdav migrations → webdav → project seed → fileservice
(clones the project once, on start) → keys → id-api → index-api → register import → id watcher
→ proxy.

## Data and licence

The data is a selection from the TEI dataset of *edition humboldt digital*
(https://github.com/telota/edition-humboldt-digital), © Berlin-Brandenburgische Akademie der
Wissenschaften, licensed under
[CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/). The workshop copy is modified
(see [Generated folders](#generated-folders)) and shared under the same licence;
`dataset/avhr/README.md` names the exact version and the citation.

> TEI-XML-Datenset der Tagebücher, Briefe, Dokumente, Forschungsbeiträge, Chronologieeinträge
> und Register der edition humboldt digital (Version 12.0.0). Herausgegeben von Ottmar Ette,
> Stefan Dumont, Carmen Götz, Tobias Kraft, Ulrich Päßler, Florian Schnee, Christian Thomas und
> Jan Wierzoch. Berlin-Brandenburgische Akademie der Wissenschaften 2026.
