"""Build-only discovery: READMEs stay beside scripts; no generated source docs."""

import html
import json
import logging
import os
import posixpath
import re
import shutil
from collections import defaultdict
from pathlib import Path, PurePosixPath
from urllib.parse import quote, unquote, urlsplit

from mkdocs.structure.files import File, Files

LOG = logging.getLogger("mkdocs.pkb")
FOLDER_READMES = {}
ROOT = Path(__file__).resolve().parent.parent
LANGUAGES = {
    ".py": "Python", ".ps1": "PowerShell", ".sh": "Bash",
    ".pl": "Perl", ".js": "JavaScript", ".html": "HTML / JavaScript",
    ".go": "Go", ".php": "PHP", ".sql": "SQL", ".groovy": "Groovy",
    ".cob": "COBOL", ".yml": "YAML", ".yaml": "YAML",
}
SKIP_DIRS = {"website", "site", "assets", "node_modules", "__pycache__", "venv"}
# Normal inline Markdown links are also the documentation coverage convention.
LINK = re.compile(r'(?<!!)\[((?:[^\[\]\n]|\[[^\]\n]*\])+)\]\(([^\s)]+)(\s+"[^"]*")?\)')


def map_prose(text, transform):
    """Leave fenced examples and inline code literal when adapting Markdown links."""
    result = []
    fence = None
    for line in text.splitlines(keepends=True):
        marker = re.match(r"^\s*(`{3,}|~{3,})", line)
        if marker:
            token = marker.group(1)
            if fence is None:
                fence = token
            elif token[0] == fence[0] and len(token) >= len(fence):
                fence = None
            result.append(line)
        elif fence:
            result.append(line)
        else:
            chunks = re.split(r"(`+[^`\n]*`+)", line)
            result.append("".join(chunk if i % 2 else transform(chunk)
                                  for i, chunk in enumerate(chunks)))
    return "".join(result)


def discover():
    """Include new files, but never traverse hidden directories, caches or symlinks."""
    paths = []
    for directory, names, filenames in os.walk(ROOT):
        names[:] = sorted(
            name for name in names
            if not name.startswith(".") and name not in SKIP_DIRS
            and not (Path(directory) / name).is_symlink()
        )
        for name in sorted(filenames):
            path = Path(directory) / name
            if not name.startswith(".") and not path.is_symlink():
                paths.append(path.relative_to(ROOT).as_posix())
    # Preserve the pre-existing notes without creating a new docs hierarchy.
    paths.extend(
        path.relative_to(ROOT).as_posix()
        for path in sorted((ROOT / ".docs").rglob("*.md"))
        if not path.is_symlink() and path.resolve().is_relative_to(ROOT)
    )
    return sorted(paths)


def resolve_link(source, target):
    parsed = urlsplit(target)
    if parsed.scheme or parsed.netloc or not parsed.path:
        return None
    path = unquote(parsed.path)
    if path.startswith("/"):
        return None
    return posixpath.normpath(posixpath.join(posixpath.dirname(source), path))


def prose_links(text):
    links = []

    def collect(prose):
        links.extend(LINK.finditer(prose))
        return prose

    map_prose(text, collect)
    return links


def on_files(files, config):
    FOLDER_READMES.clear()
    paths = discover()
    scripts = [p for p in paths if PurePosixPath(p).suffix.lower() in LANGUAGES
               and p not in {"index.html", "guide.html", "mkdocs.yml"}]
    markdown = [p for p in paths if p.lower().endswith(".md")]
    # The build guide is itself a single canonical folder README.
    markdown.append("website/README.md")
    readmes = {}
    for path in markdown:
        if PurePosixPath(path).name.lower() == "readme.md":
            folder = posixpath.dirname(path)
            if folder in readmes:
                raise ValueError(f"Multiple folder READMEs: {readmes[folder]}, {path}")
            readmes[folder] = path

    folders = {posixpath.dirname(p) for p in scripts + markdown}
    for folder in list(folders):
        while folder:
            folder = posixpath.dirname(folder)
            folders.add(folder)
    def page_path(path):
        # MkDocs excludes dot-prefixed output paths; the source notes stay put.
        return "legacy-notes" + path[len(".docs"):] if path == ".docs" or path.startswith(".docs/") else path

    pages = {folder: posixpath.join(page_path(folder), "index.md") for folder in folders}
    mapping = {path: pages[posixpath.dirname(path)]
               if PurePosixPath(path).name.lower() == "readme.md" else page_path(path)
               for path in markdown}
    by_folder = defaultdict(list)
    notes = defaultdict(list)
    for path in scripts:
        by_folder[posixpath.dirname(path)].append(path)
    for path in markdown:
        if PurePosixPath(path).name.lower() != "readme.md":
            notes[posixpath.dirname(path)].append(path)

    ref = (os.environ.get("PKB_SOURCE_REF") or os.environ.get("CF_PAGES_COMMIT_SHA")
           or os.environ.get("CF_PAGES_BRANCH") or "main")
    source_base = f"{config.repo_url}/blob/{quote(ref, safe='')}/"

    def source_url(path):
        return source_base + quote(path, safe="/")

    def rewrite(content, source, destination):
        def replace(match):
            label, target, title = match.groups()
            resolved = resolve_link(source, target)
            if resolved is None:
                return match.group(0)
            parsed = urlsplit(target)
            if resolved in mapping:
                href = posixpath.relpath(mapping[resolved], posixpath.dirname(destination) or ".")
                if parsed.fragment:
                    href += "#" + parsed.fragment
            elif resolved in pages:
                href = posixpath.relpath(pages[resolved], posixpath.dirname(destination) or ".")
            elif resolved in scripts or (ROOT / resolved).is_file():
                # Link to source rather than accidentally execute a tool.
                href = source_url(resolved)
                if parsed.fragment:
                    href += "#" + parsed.fragment
            else:
                # Preserve old notes without letting their existing broken links
                # abort a strict build or silently send readers to a local 404.
                LOG.info("Unresolved legacy link in %s: %s", source, target)
                return f"{label} *(unavailable repository target: `{target}`)*"
            return f"[{label}]({href}{title or ''})"
        return map_prose(content, lambda prose: LINK.sub(replace, prose))

    # Count only explicit source links in the owning folder's README.
    covered = set()
    for folder, readme in readmes.items():
        text = (ROOT / readme).read_text(encoding="utf-8")
        for match in prose_links(text):
            resolved = resolve_link(readme, match.group(2))
            if resolved in by_folder[folder]:
                covered.add(resolved)
    missing = [path for path in scripts if path not in covered]
    # Non-fatal even under mkdocs --strict; coverage gaps are expected in this pilot.
    if missing:
        LOG.info("PKB documentation gaps (%d/%d tools; source links measure coverage, not quality):\n%s",
                 len(missing), len(scripts), "\n".join(f"  - {p}" for p in missing))

    # Keep theme/plugin assets (CSS, JavaScript, search worker); replace only
    # docs_dir inputs with the canonical README projections below.
    output = Files(file for file in files if file.src_dir != config.docs_dir)

    def add(uri, content):
        output.append(File.generated(config, uri, content=content))

    add("guide.html", (ROOT / "guide.html").read_text(encoding="utf-8"))

    for asset in ("folder-views.js", "folder-views.css"):
        add("assets/" + asset, (ROOT / "website" / asset).read_text(encoding="utf-8"))

    def relative(target, destination):
        return posixpath.relpath(target, posixpath.dirname(destination) or ".")

    for folder in sorted(folders):
        destination = pages[folder]
        readme = readmes.get(folder)
        FOLDER_READMES[destination] = (readme, (ROOT / readme).read_text(encoding="utf-8") if readme else None)
        if readme:
            body = rewrite((ROOT / readme).read_text(encoding="utf-8"), readme, destination)
            body += f"\n\n[View this README on GitHub]({source_url(readme)})\n"
        else:
            body = (f"# {PurePosixPath(folder).name or 'Tools'}\n\n"
                    "No folder README is available yet. This inventory is generated from filenames; "
                    "functionality, setup, and safety have not been documented here. "
                    "Review source before running a tool.\n")
        children = [child for child in sorted(folders)
                    if child and posixpath.dirname(child) == folder]
        if children:
            body += "\n## Browse folders\n\n" + "\n".join(
                f"- [{'Existing notes' if child == '.docs' else PurePosixPath(child).name}]({relative(pages[child], destination)})"
                for child in children) + "\n"
        if by_folder[folder]:
            body += "\n## Script inventory\n\n"
            body += "Source links keep every implementation individually accessible.\n\n"
            for path in by_folder[folder]:
                name = PurePosixPath(path).name
                status = "Linked in folder README" if path in covered else "Missing folder documentation"
                body += f"### {name}\n\n{LANGUAGES[PurePosixPath(path).suffix.lower()]} · {status}\n\n"
                reader = relative("guide.html", destination) + "?file=" + quote(path, safe="")
                body += f"[Read how this file works]({reader}) · [View source on GitHub]({source_url(path)})"
                if path.endswith(".html"):
                    body += f" · [Open interactive tool]({relative(path, destination)})"
                body += "\n\n"
        if notes[folder]:
            body += "\n## Existing notes\n\nPreserved existing documents; not newly reviewed in this pilot.\n\n"
            body += "\n".join(f"- [{PurePosixPath(p).stem}]({relative(mapping[p], destination)})"
                              for p in notes[folder]) + "\n"
        if not folder:
            body += ("\n## Documentation coverage\n\n"
                     f"{len(scripts) - len(missing)} of {len(scripts)} tools have source links in their folder README. "
                     "A link is a coverage signal, not a correctness review. "
                     "Missing documentation is reported at build time without failing the build.\n\n"
                     "[Download coverage report](documentation-coverage.json) · "
                     "[Open the preserved original catalog](catalog.html)\n")
        add(destination, body)

    for source in markdown:
        if PurePosixPath(source).name.lower() != "readme.md":
            destination = mapping[source]
            body = rewrite((ROOT / source).read_text(encoding="utf-8"), source, destination)
            add(destination, body + f"\n\n[View original on GitHub]({source_url(source)})\n")

    # Keep the original catalog and standalone HTML/JS tools working at their paths.
    catalog = (ROOT / "index.html").read_text(encoding="utf-8")
    catalog = catalog.replace("<body>", '<body><aside style="padding:1rem;text-align:center">'
                              '<a href="./">Browse the searchable knowledge base</a>'
                              ' · Preserved original catalog</aside>', 1)
    add("catalog.html", catalog)
    for path in scripts:
        output.append(File.generated(config, path, abs_src_path=str(ROOT / path)))
    add("documentation-coverage.json", json.dumps({
        "total": len(scripts), "linked_in_folder_readme": len(covered), "missing": missing,
    }, indent=2) + "\n")

    def navigation(folder):
        items = [{"Overview": pages[folder]}]
        for child in sorted(folders):
            if child and posixpath.dirname(child) == folder:
                items.append({"Existing notes" if child == ".docs" else PurePosixPath(child).name: navigation(child)})
        items.extend({PurePosixPath(path).stem: mapping[path]} for path in notes[folder])
        return items

    config.nav = navigation("") + [{"Original catalog": "catalog.html"}]
    return output


def on_serve(server, config, builder):
    # README edits and newly added scripts outside docs_dir must trigger discovery.
    for entry in ROOT.iterdir():
        if (entry.name.startswith(".") and entry.name != ".docs") or entry.name in SKIP_DIRS:
            continue
        if not entry.is_symlink():
            server.watch(str(entry), builder)
    return server


def on_post_build(config):
    """The same reader works on the existing static host and MkDocs builds."""
    import importlib.util
    spec = importlib.util.spec_from_file_location("folder_index", ROOT / "website/build_folder_index.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    index = module.folder_index()
    target = Path(config.site_dir)
    shutil.copytree(ROOT / "assets", target / "assets", dirs_exist_ok=True)
    shutil.copy2(ROOT / "guide.html", target / "guide.html")
    (target / "assets/folders.json").write_text(json.dumps(index, indent=2) + "\n", encoding="utf-8")
    for entry in index.values():
        for source in entry["files"] + ([entry["readme"]] if entry["readme"] else []):
            dest = target / source
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / source, dest)


def on_page_content(content, page, config, files):
    """Offer two states of one folder without changing its canonical README."""
    if page.file.src_uri not in FOLDER_READMES:
        return content
    readme, source = FOLDER_READMES[page.file.src_uri]
    if source is None:
        return ('<aside class="folder-notice">This folder needs a README explaining '
                'what its files do, prerequisites, configuration, usage, outputs, '
                'and side effects. The inventory below links to the source.</aside>' + content)
    return (
        '<div class="folder-views" data-folder-views>'
        '<nav class="folder-toolbar" aria-label="Folder presentation">'
        '<span class="folder-label">Folder guide</span>'
        '<button type="button" data-folder-view="rendered" aria-pressed="true">Website</button>'
        '<button type="button" data-folder-view="markdown" aria-pressed="false">Markdown</button>'
        '</nav>'
        '<section data-folder-panel="rendered" aria-label="Rendered folder guide">' + content + '</section>'
        '<section data-folder-panel="markdown" aria-label="Original folder README" hidden>'
        '<p class="folder-source-path">' + html.escape(readme) + '</p>'
        '<p>The original folder README, exactly as stored in the repository.</p>'
        '<div class="folder-source-actions">'
        '<button type="button" data-copy-readme>Copy Markdown</button> '
        '<button type="button" data-download-readme>Download README</button>'
        '<span role="status" data-copy-status></span></div>'
        '<pre class="folder-source"><code>' + html.escape(source) + '</code></pre>'
        '</section></div>'
    )
