# Pop!_OS desktop setup examples

These tools change the local desktop/system. Review local copies before running;
none was executed for this documentation.

## [BeeBeepInstall.sh](BeeBeepInstall.sh)

Purges an installed BeeBEEP apt package, recursively removes the current user's
`~/.config/BeeBEEP`, downloads the pinned 5.8.6 amd64 DEB from SourceForge into
Downloads, and installs it with apt. Invoke with Bash on a compatible apt-based
desktop with sudo/wget and an existing Downloads directory. Configuration is
deleted without backup; the download is not the latest release despite its local
filename, and no independent checksum is verified by the script.

## [ChangeDockColor.sh](ChangeDockColor.sh)

Calls `gsettings set` for dash-to-dock's background color (`#002147`) and opacity
(`0.8`). Run with Bash inside the target user's GNOME desktop session, with the
extension's settings schema installed. It changes persistent per-user appearance,
not a system theme. The printed success message is unconditional and there is no
saved previous value or rollback.

## [New-PcSetup.pl](New-PcSetup.pl)

Interactive Perl menu for Git, Brave, VS Code, Obsidian, or all four. Uses sudo/apt,
adds Brave/Microsoft signing keys and repositories as needed, and downloads an
Obsidian DEB. Run with Perl on an apt-based system with sudo and required network
access. It prints commands and stops when a `run_cmd` command fails. Package
detection uses broad `dpkg-query | grep` matches rather than exact installation
state, VS Code's source is amd64-specific, and the assumed latest Obsidian asset
URL may not exist. It changes system packages/repositories and cleans its temporary
Obsidian DEB. It is not a cloud-environment onboarding script.
