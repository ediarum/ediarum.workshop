# A new, empty project

Besides *edition humboldt digital* (`avhr`), you can add projects of your own to the running
workshop, starting empty: the way a new edition starts on the platform. You create the project in
the **WebDAV app**, as an admin does on a real instance; a script does the parts that the
workshop's stand-ins (local git server, fixed configuration) need around it.

What you get, for a project `demo` with the id prefix `D`:

- a WebDAV folder for oXygen: `http://localhost:1769/webdav/connection/demo/`, empty, every save
  committed to the project's own repository;
- its own registers in the **Index app** (app-led, like avhr), starting empty;
- its own ids from **ediarum.id**: `D` and seven digits, for register entries and for new
  documents.

The repository is either one on the workshop's own git server (the default; nothing leaves your
computer) or **your own** on GitLab, GitHub or another git host, with an access token you give: see
[With your own repository](#with-your-own-repository-gitlab-github).

The stack has to be running (`./start.sh`, see [README.md](README.md#start)).

> **Set up before this guide existed?** The workshop's keys used to be limited to avhr. Run
> `./reset.sh` and `./start.sh` once (this deletes your edits), otherwise saving an entry in the
> new project fails (see [Troubleshooting](#troubleshooting)).

## The steps

```
 terminal                     WebDAV app (browser)                 terminal
 ────────                     ────────────────────                 ────────
 1 new-project.sh demo D  →   2 Create New Project, Initialize  →  3 Enter: restart
   git repo + id prefix         Edit: two checkboxes                 fileservice, id, index
                                Users: add Workshop
                                                        ↓
                              4 Index app: new person  →  5 oXygen: new letter, tag the person
```

### 1. Terminal: prepare

In the workshop folder (Windows: in Git Bash, as for `./start.sh`):

```bash
scripts/new-project.sh demo D "Demo edition"
```

The arguments: the **slug** (lowercase letters and digits, words joined by `-`; it's in every URL
and can't be changed later), the **id prefix** (a letter or two; distinct from `H`, avhr's) and the
project's **name**. The script

- creates the repository `git://gitserver/demo.git` on the workshop's git server, with a `main`
  branch and an empty `data/` folder: webdav only initializes a project whose branch exists and
  has a `data/` folder;
- adds the prefix to `config/id/projects.toml`: ediarum.id hands out ids only for projects listed
  there;
- prints the values for the next step and waits. Leave the terminal open.

With your own repository, add `--repo https://…`; the script then checks that
repository instead of creating one: see [With your own repository](#with-your-own-repository-gitlab-github).

### 2. WebDAV app: create the project

Open http://localhost:1769/, log in (`workshop@example.org` / `workshop`), open **WebDAV**.

1. **Manage Projects → Create New Project**:

   | Field | Value |
   |---|---|
   | Project Name | `Demo edition` |
   | Slug | `demo` |
   | Git Remote URL | `git://gitserver/demo.git` |
   | Git Username | `workshop` |
   | Git Personal Access Token | `workshop` (the form requires one; the local git server takes none) |
   | Tracked Git Branch | `main` |

   With your own repository: its address, your user name and token, and its branch, as the
   script printed them.

2. **Initialize Project.** The log shows the clone; *OK* when it's done. The project page opens.
3. **Edit**, tick both, save:
   - **Push to ediarum services?** Every save in oXygen goes on to the fileservice, and from there
     to ediarum.id (which then knows the ids used in the texts).
   - **Index app is the source of truth?** The registers are kept in the Index app, as in avhr.
4. **Users**: choose *Workshop*, **Add User**. The login is an admin and could open the WebDAV
   folder anyway, but the apps list a user's projects from this membership.

### 3. Terminal: let the services pick it up

Press Enter. The script checks that webdav lists the project as app-led, then restarts

- the **fileservice**, which clones a new project only when it starts;
- **ediarum.id** (API and watcher), which reads `projects.toml` only when it starts;
- **ediarum.index**, so the project appears in the Index app's project list.

It ends with the addresses for the next steps.

### 4. Index app: the first register entry

**Index** → project *Demo edition* → entry type **person** → **New entry**. Fill in a name, leave
*Project ID* empty, save. The Project ID is filled in: `D` and seven digits. Check it with
ediarum.id, as in [the main exercise](README.md#2-where-the-id-comes-from):

    http://localhost:1769/api/id/demo/ids/D1234567?key=UoGsSo5JrihjZW57AGMOaGl1mUnYSM4_l70226Do028

### 5. oXygen: the first text

The workshop project file points oXygen at avhr. Switch it to the new project:

1. Open `oxygen/workshop.xpr` (see [README.md](README.md#1-open-the-workshop-project)).
2. *Options → Preferences → Editor Variables → Custom Editor Variables*, with **Project Options**
   selected at the bottom, *Edit* two variables:
   - `ediarum_project_name`: `avhr` → `demo` (the register lookups);
   - `ediarum_id`: in the address, `/api/id/avhr/` → `/api/id/demo/` (new ids).
3. Connect to `http://localhost:1769/webdav/connection/demo/` (user `workshop@example.org`,
   password `workshop`), as in [README.md](README.md#2-connect-to-webdav). The folder is empty.
4. *File → New → Framework templates → ediarum.BASE.edit → **Brief*** (a letter; *Dokument* for
   other texts). Its `xml:id` comes from ediarum.id, with the `D` prefix.
5. *File → Save to URL…*: `http://localhost:1769/webdav/connection/demo/1820-01-01_Brief.xml`
   (or a sub-folder you like). webdav commits it to the project's `data/` folder.
6. Tag a name with the **person** button: the list shows your new person from step 4.

To go back to avhr, set the two variables back. (The project file keeps what you change:
`scripts/prepare.sh` writes it anew, as does unpacking the workshop download again.)

## With your own repository (GitLab, GitHub)

The project's texts can live in a repository of yours instead: webdav clones it at *Initialize*
and pushes every save there, as on a real instance.

**What you need**

- An **https** address of the repository, e.g. `https://gitlab.com/me/demo.git`. It may be
  empty: webdav needs a branch with a top-level `data/` folder, and the script offers to push them.
- An **access token** that can read and write it:

  | Host | Token | User name (`--user`) |
  |---|---|---|
  | GitLab | personal or project access token with `read_repository` and `write_repository` (project tokens: role *Developer* or higher) | `oauth2` (the default) or your own |
  | GitLab | deploy token with `read_repository` and `write_repository` | the deploy token's user name |
  | GitHub | fine-grained token for the repository with *Contents: Read and write* | your GitHub user name |

  If the branch is protected, the token's user must be allowed to push to it.

**Step 1 with your repository**

```bash
scripts/new-project.sh demo D "Demo edition" --repo https://gitlab.com/me/demo.git
```

Add `--user NAME` for GitHub or a deploy token, and `--branch NAME` for a branch other than
`main`. The script asks for the token (hidden; or set `GIT_TOKEN` beforehand), and

- checks with your own git that the token can read the repository, and whether the branch with
  `data/` exists; if not, it asks, then pushes a commit with `data/.gitkeep`;
- stores the token for the **fileservice** in `secrets/git_token`, its user name in
  `secrets/git.env`. webdav hands the other services the address *without* credentials, so the
  fileservice needs its own copy to clone the repository;
- prints the form values. In step 2 enter **your** address, user name and token (the same token)
  instead of the workshop's; everything else stays as described.

**Keep in mind**

- Every save in oXygen is pushed to your repository. `reset.sh` deletes the workshop's copy and
  the stored token, not what was pushed.
- The token is stored in plain text, twice: in `secrets/git_token` (git-ignored, on your computer)
  and in webdav's database. Use a token for this repository only, with a short expiry, and revoke
  it after the workshop.
- The fileservice has **one** token for every repository: a second project with a different token
  replaces the first (the script says so), and the first can't be cloned anew after that.

## Tokens and keys

Nothing to generate in the workshop, except the git token for [your own
repository](#with-your-own-repository-gitlab-github): all keys are fixed in `workshop.env` and valid
for **every** project, so a new project works with them. On a real instance each one is created per project or
client instead; this is where:

| Key (`workshop.env`) | From → to | What for | On an instance |
|---|---|---|---|
| `PLATFORM_SERVICE_TOKEN` | fileservice, id, index → webdav | read the project registry | webdav's `SERVICE_TOKEN`, set once |
| `FILESERVICE_WEBDAV_KEY` | webdav → fileservice | every save | `ediarum-fileservice-create-key` (CLI; `*` or per project) |
| `FILESERVICE_ADMIN_KEY` | id, index → fileservice | read the files, status | `ediarum-fileservice-create-key --admin` |
| `ID_OXYGEN_KEY` | oXygen → ediarum.id | new ids in templates and actions | IDs app → Keys (per project, after its `projects.toml` entry) or `ediarum-id keys add` |
| `INDEX_ID_KEY` | ediarum.index → ediarum.id | the id of a new register entry | `ediarum-id keys add index` (all projects) |
| `INDEX_OXYGEN_KEY` | oXygen → ediarum.index | the register lookups | Index app → Keys (per project or *All projects*) |
| — | webdav → git server | clone and push | the project's *Git Username* / *Personal Access Token* in the WebDAV app (a GitLab token with `write_repository`) |
| `secrets/git_token` | fileservice → git server | clone (own repository only) | a token with `read_repository` for all project repositories, `/run/secrets/git_token` |

On an instance the repository is a new GitLab project with a `main` branch and a `data/` folder,
and the id prefix is added to ediarum.id's `projects.toml` by whoever runs it; the steps in the
WebDAV app are the same.

## Removing projects

`./reset.sh` removes the added projects together with everything else: their
repositories on the workshop's git server, files, ids and register entries, their prefixes in
`config/id/projects.toml` and the stored git token. Your own repositories keep what was pushed.
There is no way to remove a single added project; it does no harm to leave it.

## Troubleshooting

- **Initialize fails with "Branch 'main' does not exist" or a missing `data` folder**: the
  repository wasn't created, or (own repository) the branch or `data/` is missing because you
  declined the push, or the branch in the form differs from the script's. Run step 1 again (it's
  safe to), then *Try Again* in the dialog.
- **"Can't read … with that token"** (own repository): the address, the user name (GitHub and
  deploy tokens need theirs, `--user`) or the token's rights. Try `git ls-remote <address>` with
  the same user and token.
- **Initialize fails with "Authentication failed"** (own repository): the *Git Username* or *Git
  Personal Access Token* in the form. *Try Again* lets you correct them.
- **The script says the Git Remote URL differs**: the address in the form must be exactly the one
  given to the script (same spelling, with or without `.git`). Correct it under *Edit*.
- **The script says webdav doesn't list the project, or it isn't app-led**: check the slug, and
  the checkbox *Index app is the source of truth?* under *Edit*. Then run the script again with
  the same arguments; it skips what's done.
- **"fileservice didn't clone"**: was the project initialized (no *Not Initialized* in the
  project list)? With your own repository: can the token in `secrets/git_token` read it? Then `docker compose --env-file workshop.env --env-file sources.env logs fileservice`.
- **The project isn't in the Index app's list**: was the user *Workshop* added (step 2.4)? Reload
  the page.
- **Saving an entry in the Index app fails with an error about ediarum.id**: ediarum.id doesn't
  serve the project, or the keys are still limited to avhr from an older setup. Check
  http://localhost:1769/api/id/projects lists `demo`; if it does, `./reset.sh` once (see the note
  at the top) and repeat the steps.
- **The person lookup in oXygen shows avhr's persons**: `ediarum_project_name` still says `avhr`
  (step 5.2), or the variables were changed under *Global Options* instead of *Project Options*.
