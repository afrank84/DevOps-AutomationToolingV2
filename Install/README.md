# Workstation installation templates

These files change the host system. Use a local reviewed copy on the intended
platform; they were not executed during documentation work. Run Bash examples
with `bash Install/<filename>` and Windows examples in PowerShell after reviewing
their assigned paths and installer versions.

## [Docker-Install.sh](Docker-Install.sh)

For Ubuntu hosts with sudo: installs prerequisites, downloads Docker's repository
signing key, adds the Docker apt source for the host codename/architecture, and
installs Docker Engine, CLI, containerd, buildx, and Compose. Adds the current
`$USER` to the docker group, then invokes `docker run --rm hello-world` through
`newgrp`. Needs apt and Docker download/registry access. Group membership grants
substantial host control; an existing login may need renewal. Repository/key files
are system changes, and rerunning can conflict with an existing key file.

## [Install-SetupEnviormentForCobolOnLinux.sh](Install-SetupEnviormentForCobolOnLinux.sh)

Upgrades apt packages, installs build-essential/wget, downloads GnuCOBOL 3.1.2,
builds and installs it system-wide, removes its downloaded build tree, then writes,
compiles, and runs a local `hello.cob`. Needs sudo, build tools, and GNU download
access. The source archive is not checksum-verified by this script; review a
trusted package-manager alternative before using it. It has no strict error mode,
so later steps can proceed after failures, and local sample filenames can overwrite
existing files. No COBOL program in this repository is automatically validated.

## [InstallCustomFonts.sh](InstallCustomFonts.sh)

Installs a configured list of Google font families under
`~/.local/share/fonts`. Optionally tries apt font packages, downloads family ZIPs
with wget, extracts TTF/OTF files, copies them with overwrite enabled, refreshes
fontconfig, and prints matching installed families. Needs Bash, wget, unzip,
fontconfig, and Google Fonts access; apt steps use sudo when apt exists.
The download endpoint must return an actual ZIP or extraction fails. Temporary
files are cleaned via a trap. Restart applications to discover new fonts.

## [Python3-Install.ps1](Python3-Install.ps1)

Checks `python --version`; if any Python responds it skips installation. Otherwise
downloads the pinned Windows x64 Python 3.11.4 installer into the current directory,
runs a quiet all-users install with PATH modification, checks `python` again,
and removes the installer. Requires Windows, administrator capability for the
all-users install, and python.org access. It does not enforce a minimum version
when Python already exists or refresh PATH in the current shell. Installer success
is not checked via its exit code. Review the old pinned version before use.

## [VisualStudio2019-DownloadWithOutEmail.ps1](VisualStudio2019-DownloadWithOutEmail.ps1)

Downloads the Community, Professional, and Enterprise VS 2019 bootstrapper EXEs
from `aka.ms` into `C:/VS2019/`. It does not create that directory, run installers,
select workloads, bypass licensing, or grant a license. Create the directory and
ensure it is writable before running. Network/HTTP failures are not handled.

## [VisualStudioCode-Install.sh](VisualStudioCode-Install.sh)

Downloads the x64 VS Code Debian package into Downloads, installs it with
`sudo dpkg -i`, runs `sudo apt-get install -f` to resolve dependencies, and reports
whether `code` is on PATH. Needs Debian/Ubuntu amd64, wget, sudo, dpkg, and apt.
It changes installed packages and leaves the DEB on disk. There is no strict
error mode or independent artifact verification; the final PATH check does not
prove all installation steps succeeded.

## [WindowsAgentHardening.ps1](WindowsAgentHardening.ps1)

Requires administrator rights on Windows 11. Writes machine/user registry policy
values to reduce consumer suggestions/activity features, disables OneDrive sync
policy and startup entries/tasks, removes Windows Backup Appx packages for the
current user and provisioning, and writes `C:\AgentPolicy\AGENT_POLICY.txt`.
Run in an elevated PowerShell session and reboot after reviewing the results.
It acts on the current user's profile as well as the machine. There is no backup
of prior registry values or automatic rollback. OneDrive uninstall is defined as
an optional function but is **not** called by default. This is a targeted agent
configuration template, not a comprehensive security baseline.
