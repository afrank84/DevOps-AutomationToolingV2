# Artifactory storage and upload tools

These examples use settings assigned inside each script, not environment-variable
or CLI overrides. Configure a local working copy and keep credentials out of Git.
Uploads change remote artifacts; examples below were not executed.

## [List-FilesAndSizeInFolder.ps1](List-FilesAndSizeInFolder.ps1)

Uses Artifactory's `/api/storage/<repository>/<folder>` endpoint to list immediate
children, skips folders, then requests each file's metadata to print its name
and size rounded to two decimals in PowerShell MB units. It does not recurse.

**Setup:** PowerShell, network access, and an API key permitted to read that
repository. Set `$artifactoryUrl`, `$repositoryPath`, and `$apiKey` at the top.

```powershell
.\Artifactory\List-FilesAndSizeInFolder.ps1
```

The script sends `X-JFrog-Art-Api` and prints results to the terminal. It catches
request exceptions and writes an error; it does not create a report file.

## [Upload-SingleFileToArtifactory.py](Upload-SingleFileToArtifactory.py)

Opens one local file in binary mode and PUTs its contents to the assembled
Artifactory URL using HTTP basic authentication. Requires Python, `requests`,
and deploy permissions on the destination repository.

Set `artifactory_url`, `repo_path`, `file_path`, `username`, and `password` in a
local copy, then run:

```bash
python Artifactory/Upload-SingleFileToArtifactory.py
```

It prints success only for HTTP 201; other statuses print the response body.
There is no overwrite prompt, retry, timeout, or exception wrapper. Check the
destination path: it can replace an existing artifact if server policy permits.

## [Upload-FilesRecusiveWithFolderStructure.py](Upload-FilesRecusiveWithFolderStructure.py)

Walks `local_path` recursively and PUTs every file into `repo_path`, preserving
its relative path. It uses the `X-JFrog-Art-Api` header and binary request bodies.
Requires Python, `requests`, and repository deploy permissions.

Set the four example assignments at the bottom (`local_path`, `artifactory_url`,
`repo_path`, `api_key`) in a local copy, then run:

```bash
python Artifactory/Upload-FilesRecusiveWithFolderStructure.py
```

It prints a per-file status, treating only 201 as success. HTTP failures continue
to the next file, but file-access or network exceptions can stop the run. There
is no transaction or rollback, and existing remote paths may be overwritten.
Relative paths come from `os.path.relpath`; review separators when using Windows.
