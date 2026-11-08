"""Refresh only the static folder index; explanations stay in folder READMEs."""
import json
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
EXTENSIONS = {'.py', '.ps1', '.sh', '.pl', '.js', '.html', '.go', '.php', '.sql',
              '.groovy', '.cob', '.yml', '.yaml', '.txt'}
SKIP = {'website', 'site', 'assets', 'node_modules', 'venv', '__pycache__'}


def folder_index():
    result = {}
    for directory, names, filenames in os.walk(ROOT):
        names[:] = sorted(name for name in names if not name.startswith('.')
                          and name not in SKIP and not (Path(directory) / name).is_symlink())
        folder = Path(directory).relative_to(ROOT).as_posix()
        if folder == '.':
            folder = ''
        files = [name for name in sorted(filenames) if not name.startswith('.')
                 and not (Path(directory) / name).is_symlink()]
        tools = [name for name in files if Path(name).suffix.lower() in EXTENSIONS
                 and name not in {'index.html', 'guide.html', 'mkdocs.yml', 'requirements-docs.txt'}]
        readmes = [name for name in files if name.lower() == 'readme.md']
        if len(readmes) > 1:
            raise ValueError(f'Multiple READMEs in {folder}')
        if tools:
            result[folder] = {
                'readme': (Path(folder) / readmes[0]).as_posix() if readmes else None,
                'files': [(Path(folder) / name).as_posix() for name in tools],
            }
    return result


if __name__ == '__main__':
    target = ROOT / 'assets' / 'folders.json'
    target.write_text(json.dumps(folder_index(), indent=2) + '\n', encoding='utf-8')
