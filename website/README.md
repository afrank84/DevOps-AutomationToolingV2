# Maintaining the personal knowledge base

The repository remains a collection of independent scripts. Folder READMEs are
the canonical explanations, and MkDocs builds the website directly from them.
Only [SSH](../SSH/README.md) has new tool explanations in this pilot. Existing
notes and the original catalog are preserved; undocumented folders show source
inventories instead of invented explanations.

## Contents

- [Generator choice](#generator-choice)
- [Build and preview](#build-and-preview)
- [Discovery, navigation, and search](#discovery-navigation-and-search)
- [Add a script or document a folder](#add-a-script-or-document-a-folder)
- [Folder README template](#folder-readme-template)
- [Cloudflare Pages](#cloudflare-pages)
- [Review and limitations](#review-and-limitations)

## Generator choice

| Option | Fit for this repository |
| --- | --- |
| **MkDocs + Material (selected)** | Python build tooling, full-text client-side search, heading permalinks, syntax highlighting, mobile navigation, and static output. A small hook projects existing READMEs into pages without copying documentation into a second maintained tree. |
| VitePress | Good Markdown navigation and local search, but adds a Node/Vue toolchain and still needs discovery/link adaptation for these distributed READMEs. |
| Docusaurus | Powerful versioning and React customization; more structure and configuration than this single-version script toolbox needs. |
| Existing HTML catalog | Preserved at `catalog.html`; useful tool cards and standalone HTML apps, but the manually maintained descriptions and filename filtering do not replace searchable explanations. |

No database, backend, account system, or new CI workflow is required.

## Build and preview

From the repository root, with Python 3.12:

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements-docs.txt
python -m mkdocs build --strict
python -m mkdocs serve --dev-addr 127.0.0.1:8001
```

On Windows, activate the environment with `.venv\Scripts\Activate.ps1` instead.
Build output goes into ignored `site/`. Source READMEs and scripts are not
modified by a build. `mkdocs serve` watches the existing folders as well as
the build configuration. Restart it after creating a new top-level folder.

To verify this documentation change, build the site and check navigation,
heading links, source links, and a search such as `passphrase` or
`global Git identity`. Do not run workstation setup scripts to test the PKB.

## Discovery, navigation, and search

`website/pkb.py` is website build tooling, not an application script. At each
build it discovers folders, Markdown notes, and these tool extensions:

```text
.py .ps1 .sh .pl .js .html .go .php .sql .groovy .cob .yml .yaml
```

- A folder's `README.md` becomes its overview at `/Folder/`. Existing mixed-case
  `ReadMe.md` / `Readme.md` names are supported in place. Do not add a second
  README with different capitalization in the same folder.
- Folder nesting determines navigation, so `Atlassian/Issues/` appears under
  Atlassian. Every tool remains individually linked to GitHub source, with a
  language label and a shareable inventory heading.
- Each README heading has a stable permalink. For example,
  `/SSH/#bash-configure-a-git-workstation` shares the Bash explanation. Keep
  headings stable after sharing them.
- Standard Markdown links such as `[source](Get-SshKey.ps1)` work in GitHub.
  The hook converts them into GitHub source links on the website. Relative links
  to other READMEs or folders become website links. Standard inline link syntax
  is the supported convention for source links and coverage detection.
- Full-text search is generated from rendered Markdown, including purpose,
  prerequisites, warnings and usage; no descriptions need to be registered in
  `index.html`. Legacy HTML apps keep their own UI and are not indexed internally.
- Missing READMEs produce a neutral inventory. No explanation is generated from
  a filename. Builds report missing folder documentation and write
  `site/documentation-coverage.json`, but these expected gaps do not fail even a
  strict build. Coverage means a local source link exists in the owning README;
  it does not certify explanation quality.
- Non-README Markdown, including existing `.docs/` notes, remains accessible and
  searchable under **Existing notes**. It is not silently deleted or treated as
  reviewed. Existing broken repository links are visibly labeled as unavailable
  in the website; their original Markdown is preserved. New explanations belong
  in the folder README.
- Hidden directories (except the pre-existing `.docs/` notes), symlinks,
  dependency directories, `site/`, and website build tooling are excluded from
  tool discovery. New supported scripts in ordinary folders need no central
  registration. A new language extension needs one entry in `LANGUAGES`.
- The old `index.html` is left unchanged in the repository and served as
  `/catalog.html` in the generated website. Existing script paths and interactive
  HTML/JavaScript tools are retained for compatibility. The catalog is a legacy
  view; its old descriptions are preserved, not endorsed or expanded by this pilot.

Generated page content exists only in the build and output, not in a second
checked-in documentation hierarchy. The hook never calls an AI model or a
remote API to produce or publish explanations.

## Add a script or document a folder

1. Put the script in the appropriate existing folder. Keep its original filename
   and implementation language. Do not consolidate similar implementations just
   to simplify documentation.
2. Read the code, then add a section to that folder's **one** `README.md`. For an
   undocumented folder, start with the template below. Do not add one Markdown
   page per script or create a parallel `docs/` tree.
3. Link every documented source file with a relative inline Markdown link. Group
   equivalent implementations under a common purpose, and describe their actual
   behavior and platform differences. Add headings for individually shareable
   implementations when useful.
4. Update the README's local contents links. The website's navigation and search
   are automatic; the local TOC keeps GitHub rendering useful too.
5. Build, inspect the rendered page and coverage report, and open a PR for human
   review. Do not auto-merge or publish generated explanations. Do not expand
   this pilot into mass documentation until its approach is approved.

## Folder README template

Copy this structure into `<folder>/README.md` and replace the examples with
facts read from the source. Delete placeholders before requesting review.
The template is kept here to avoid adding another Markdown document per folder.

````markdown
# Folder purpose

Explain what problems this folder addresses and what is outside its scope.

## Contents

- [Shared task or purpose](#shared-task-or-purpose)
- [Related tools](#related-tools)

## Shared task or purpose

Explain when and why to use these tools and what the code actually does.

| Implementation | Platform / runtime | Behavior differences |
| --- | --- | --- |
| [tool.py](tool.py) | Python on ... | Actual inputs, outputs, and side effects |
| [tool.ps1](tool.ps1) | PowerShell on ... | Actual differences, including OS-specific APIs |

### Dependencies and configuration

List libraries, CLI tools, services, required permissions, configuration names,
defaults, and whether settings are code assignments, environment variables, or
arguments. Never include real credentials.

### Usage and expected results

```bash
python tool.py <example-input>
```

Explain working directory, expected output files, overwrite behavior, and how
errors are reported. Label examples as illustrative unless actually verified.

### How it works and warnings

Describe the main steps, platform limits, failure handling, destructive actions,
sensitive data, and anything the script does not configure automatically.

## Related tools

Link related folder READMEs, local implementations, and external alternatives.
````

## Cloudflare Pages

Keep the existing Pages project and domain. This PR adds build tooling and
instructions; it does not change the live project's settings or publish it.

After the pilot is reviewed, configure the existing Git-connected project:

| Setting | Value |
| --- | --- |
| Framework preset | None |
| Root directory | Repository root |
| Build command | `pip install -r requirements-docs.txt && python -m mkdocs build --strict` |
| Build output directory | `site` |
| Production branch | `main` |
| Python | `3.12` via `.python-version` (or `PYTHON_VERSION` in Pages settings) |

Use a branch preview for review before switching the production build. If
preview builds are restricted, allow the pilot branch explicitly in Pages
settings. Keep production publication behind human review and merge; no workflow
in this change publishes explanations automatically. The build generates plain
static files and needs no Cloudflare token, script API credentials, or functions.
The build environment needs Python packages from PyPI; Cloudflare hosts the
output, including its search index and syntax-highlighting assets.

Source links use `PKB_SOURCE_REF` when provided, otherwise Pages'
`CF_PAGES_COMMIT_SHA`, then `CF_PAGES_BRANCH`, then `main`. For a local feature
branch preview, set `PKB_SOURCE_REF` to that branch so GitHub links point at the
same version. Cloudflare injects its commit/branch metadata automatically.

For deployment verification, check the Pages build log, then open `/`, `/SSH/`,
a heading permalink, and `/catalog.html` on the preview deployment. Search for
`passphrase`, open both implementation source links, and open a standalone HTML
tool. A successful local build verifies output generation, not a remote Pages
deployment. Actual preview/production deployment requires the project's settings
and access, and must be reported separately.

## Review and limitations

This is a website/documentation pilot, not a review of every tool's correctness.
The SSH explanations are a PR draft for human review; no scripts were executed
to author them. Existing notes may be outdated. Missing documentation remains
visible rather than blocking the rollout.

Search and syntax highlighting are provided by Material's static assets.
GitHub's standard headings, tables, fenced code, and relative links render the
same canonical README; MkDocs-specific markup is not required in tool docs.
Interactive tools that call external APIs retain their original behavior and
credentials requirements. Adding a file to the website does not make it safe
to run or automatically configure it.
