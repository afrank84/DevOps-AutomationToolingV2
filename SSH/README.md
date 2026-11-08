# SSH key setup

These two independent scripts create an RSA key pair and print its public key
for registration with GitHub. Use them when preparing a workstation for SSH
authentication. They do not register a key with GitHub or verify a connection.

This pilot documentation was written by reading the source. The scripts were
not executed as part of the PKB work.

## Contents

- [Choose an implementation](#choose-an-implementation)
- [PowerShell: generate and display a key](#powershell-generate-and-display-a-key)
- [Bash: configure a Git workstation](#bash-configure-a-git-workstation)
- [Related tools and alternatives](#related-tools-and-alternatives)

## Choose an implementation

Both implementations use `ssh-keygen -t rsa -b 4096`. Their setup and side effects
differ; they are not interchangeable wrappers.

| Behavior | PowerShell | Bash |
| --- | --- | --- |
| Source | [Get-SshKey.ps1](Get-SshKey.ps1) | [Get-SshKeyLinux.sh](Get-SshKeyLinux.sh) |
| Intended platform | Windows with PowerShell and OpenSSH | Linux with Bash, OpenSSH and Git; also suitable for a configured WSL user environment |
| Key path | `$env:USERPROFILE\.ssh\id_rsa` | `$HOME/.ssh/id_rsa_github` by default |
| Creates `.ssh` directory | No explicit creation | Creates it and sets permissions to `700` |
| Passphrase | Leaves the choice to the interactive `ssh-keygen` prompt | Empty by default; configurable interactive prompt |
| SSH agent | No agent setup | Starts an agent and adds the key |
| Git identity | No Git configuration | Overwrites global `user.name` and `user.email` |
| Result | Prints the public key | Prints the public key and the GitHub registration URL |

### Sensitive operations

- These scripts create a private key. Keep the private file local; only the
  `.pub` file belongs in GitHub's SSH key settings.
- An existing key at the target path can trigger an overwrite prompt. Do not
  approve overwriting a key without checking what still uses it.
- The Bash script defaults to **no passphrase** and changes global Git identity
  for the current user. Review its configuration before running it.
- Neither script stops reliably after every external command failure. Output
  alone does not prove a new key was created: a later step could display or add
  a pre-existing key.

## PowerShell: generate and display a key

Source: [Get-SshKey.ps1](Get-SshKey.ps1)

### When to use it

Use this smaller implementation on Windows when you want to generate a key
and copy the public part, while managing Git configuration and your SSH agent
separately. The use of `USERPROFILE` and Windows path separators makes this
implementation Windows-oriented even though PowerShell itself is cross-platform.

### Dependencies and configuration

- Windows PowerShell or PowerShell on Windows.
- OpenSSH's `ssh-keygen` available on `PATH`.
- A writable `$env:USERPROFILE\.ssh` directory. The script does not explicitly
  create it; ensure it exists first.
- The key comment is the literal `GITHUB_EMAIL`, not a variable or environment
  lookup. If you want a meaningful email comment or a different filename,
  adjust your own local working copy before execution. The script takes no
  command-line parameters.

### Usage and expected result

From the repository root, after reviewing the source and prerequisites:

```powershell
.\SSH\Get-SshKey.ps1
```

`ssh-keygen` may prompt about an existing key and asks for a passphrase. On
success it writes `id_rsa` and `id_rsa.pub` into the configured `.ssh` directory,
then the script prints:

```text
Your public SSH key is:
ssh-rsa <public-key-material> GITHUB_EMAIL
```

The script does not install OpenSSH, start an agent, upload the key, or change
Git's user identity. PowerShell execution policy may also need to permit running
a script according to your workstation's policy.

### How it works

It builds `$sshKeyPath` from `USERPROFILE`, invokes `ssh-keygen`, and reads the
`.pub` file with `Get-Content`. There is no explicit exit-code check before that
read, so inspect `ssh-keygen`'s result if key generation fails.

## Bash: configure a Git workstation

Source: [Get-SshKeyLinux.sh](Get-SshKeyLinux.sh)

### When to use it

Use this version when configuring both an SSH key and Git author identity for
a Linux or WSL user. It does more workstation setup than the PowerShell version.
It uses standard Unix tools and Bash; macOS may also work with those tools, but
has no dedicated Keychain integration in this script.

### Dependencies and configuration

- Bash, `mkdir`, `chmod`, and `cat`.
- OpenSSH commands `ssh-keygen`, `ssh-agent`, and `ssh-add` on `PATH`.
- Git and a writable home directory.
- Review the configuration block at the top of a local working copy:

| Setting | Shipped value | Meaning |
| --- | --- | --- |
| `GITHUB_EMAIL` | `your_email@example.com` | Key comment **and** global Git email |
| `GIT_USERNAME` | `Your Full Name` | Global Git author name |
| `SSH_KEY_FILENAME` | `id_rsa_github` | Filename under `$HOME/.ssh`; comment requests no spaces |
| `USE_PASSPHRASE` | `false` | `true` prompts; `false` passes an empty passphrase with `-N ""` |

These are assignments inside the script, not command-line options. Exporting
environment variables with the same names does not override the assignments.

### Usage and expected result

From the repository root, after configuring a local working copy:

```bash
bash SSH/Get-SshKeyLinux.sh
```

On successful execution, the script creates the key pair, starts an agent,
adds the private key to that agent, sets global Git identity, and prints:

```text
Your public SSH key (add this to GitHub):
------------------------------------------
ssh-rsa <public-key-material> <configured-email>
------------------------------------------

Add your key at: https://github.com/settings/ssh/new
```

**Agent scope:** when launched with `bash`, `eval "$(ssh-agent -s)"` sets the
agent variables in the child shell. They are not exported back to your calling
terminal. The agent process may remain alive after the script exits, but the
parent terminal will not automatically know its socket. Starting an agent here
does not guarantee later Git commands in your terminal can use that key.

### How it works and limitations

The script creates `.ssh`, changes its permissions, invokes `ssh-keygen`, then
starts an agent and calls `ssh-add`. It writes `user.name` and `user.email` with
`git config --global` before printing the public key. There is no `set -e` or
explicit status checking, so later commands can run after earlier failures.

The custom filename `id_rsa_github` is not the default `id_rsa`. In a future
session, you may need to add it to your own agent or configure the appropriate
SSH `IdentityFile`; this script does not write an SSH config file. It also does
not set a Git remote to SSH or test authentication with GitHub.

## Related tools and alternatives

- The [PowerShell implementation](Get-SshKey.ps1) is the smaller key-generation
  alternative; the [Bash implementation](Get-SshKeyLinux.sh) also configures Git
  and starts an agent. Choose based on the side effects you need.
- For manual setup or an Ed25519 key, follow GitHub's
  [SSH key generation guide](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent).
  Neither script currently offers an algorithm selection parameter.
- [GitHub utilities](../Github/) contains other independent repository and API
  tools; configuring a key here does not configure their API credentials.
