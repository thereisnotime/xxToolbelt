# xxToolbelt

A Bash-based system for managing scripts across 20+ languages via symlinks in `~/.local/bin`. Scripts work everywhere — interactive shells, AI tools, cron jobs — because they are symlinks, not aliases.

## Core Files

- `xxtoolbelt.sh` — the entire system. Sourced from `.bashrc`/`.zshrc`. Contains all functions, the TUI menu, the CLI parser, and the sync engine.
- `tests/smoke.sh` — end-to-end smoke test in a throwaway HOME. Run by CI on Linux and macOS.
- `.belts` — belt registry, one `name|source` per line. Lines prefixed with `#` are disabled.
- `.debug` — presence of this file enables debug logging. Never commit it.
- `scripts/` — core scripts organized by language folder (`bash/`, `python/`, etc.). Belt symlinks also land here as `<belt>-<folder>/` directory symlinks.
- `belts/` — cloned git repos or registered local paths. Never edit files inside here; they are managed by their own repos.

## Architecture in One Paragraph

`xxtb-sync` is the heart of the system. It (1) removes stale symlinks in `~/.local/bin` that point to deleted scripts, (2) scans `scripts/` language folders and symlinks executables into `~/.local/bin`, skipping scripts whose `xxtb-os:` marker excludes the current OS, (3) writes the `xxtb` wrapper script to `~/.local/bin`, then (4) calls `xxtb-sync-belts` which symlinks belt language folders into `scripts/` and then symlinks individual belt scripts into `~/.local/bin` (same OS filter). The final `echo "$_belt_count $_belt_scripts $_belt_skipped"` in `xxtb-sync-belts` is parsed by the caller — **any stdout pollution inside that function corrupts the return value and breaks the `[[ "$_belt_count" -gt 0 ]]` check downstream**.

## Function Map

| Function | Purpose |
|---|---|
| `xxtb()` | Master entry point — CLI parser + TUI loop |
| `xxtb-sync()` | Full sync: cleanup → core scripts → xxtb wrapper → belts |
| `xxtb-sync-belts()` | Belt sync; returns `"<belt_count> <script_count> <skipped_count>"` on stdout |
| `xxtb-os-allowed()` | True unless the script's `xxtb-os:` marker (or folder `.xxtb-os`) excludes `$XXTOOLBELT_OS` |
| `xxtb-add-belt()` | Clone (git) or register (local), then sync |
| `xxtb-remove-belt()` | Remove symlinks, delete dir, unregister |
| `xxtb-disable-belt()` | Prefix `#` in `.belts`, sync |
| `xxtb-enable-belt()` | Remove `#` prefix, sync |
| `xxtb-list-belts()` | Print registry with types and subfolders |
| `xxtb-update()` | curl/wget latest `xxtoolbelt.sh`, pull all belts, reload, sync |
| `xxtb-update-belts()` | `git pull --rebase` each git belt; fallback: checkout+clean+retry |
| `xxtb-export()` | Base64-encode a script into a shareable one-liner |
| `xxtb-toggle-debug()` | Touch/delete `.debug` file |
| `xxtb-list-scripts()` | Scan and print all synced scripts |
| `xxtb-log()` | Prefixed logging — INFO/WARN/ERR/DEBUG with timestamps and color |
| `xxtb-failure()` | ERR trap handler |

## Key Gotchas

**zsh never runs the bash code.** Near the top of `xxtoolbelt.sh` there's a zsh shim: if `$ZSH_VERSION` is set it adds `~/.local/bin` to PATH, defines `xxtb` as a function that runs `bash -c 'source xxtoolbelt.sh; xxtb ...'`, and returns. Keep it above everything else, and keep it calling `bash` directly (not the `~/.local/bin/xxtb` wrapper) so the first sync on a fresh machine works.

**Stay bash 3.2 compatible.** macOS `/bin/bash` is 3.2. No `declare -A`, `${x,,}`, `mapfile`, `declare -n`, `|&`, `&>>`, and no `local -`. No GNU-only flags either: no `sed -i` (write to a tmp file and `mv`), no `grep -P`, no `readlink -f`. `tests/smoke.sh` runs under `/bin/bash` on macOS in CI.

**Don't shadow common command names.** The logger is `xxtb-log`, not `log` (macOS has `/usr/bin/log`, and users' rc files often define their own). A `log` alias is only defined when nothing called `log` exists yet.

**`xxtb-sync-belts` stdout is load-bearing.** It is captured with `$()` so the caller can parse `"<count> <count>"`. Any `echo`, `print`, or command that writes to stdout inside this function (or anything it calls) will corrupt the return value. All diagnostic output must go to stderr (`>&2`). This is what caused the venv bug (v2.3.3 fix): `python3 -m venv` prints its "ensurepip not available" message to stdout on systems missing `python3-venv`; the fix was `&>/dev/null` instead of `2>/dev/null`.

**Symlink safety guards.** The stale-cleanup phase only removes symlinks whose `readlink` target starts with `XXTOOLBELT_SCRIPTS_FOLDER` or `XXTOOLBELT_BELTS_FOLDER`. Never change this check — it prevents accidental deletion of non-xxToolbelt symlinks in `~/.local/bin`.

**Belt directory deletion guard.** `xxtb-remove-belt` uses `${variable:?}` guards before `rm -rf`. Keep them. An empty variable expanding to `rm -rf /` is not a theoretical risk.

**Library files are excluded from sync.** Any file whose name starts with `_` (e.g. `_log.sh`, `_colors.sh`) is treated as a shared library and not symlinked into `~/.local/bin`. This is intentional.

**`.private` keyword.** Files named `xx*.private.*` are gitignored but still synced. The `.private` segment is stripped from the symlink name so the script is accessible by its clean name.

## Code Style

- **Indentation:** tabs, not spaces.
- **Functions:** `function xxtb-operation() { ... }` — always `function` keyword, kebab-case.
- **Global constants:** `XXTOOLBELT_UPPER_SNAKE_CASE`.
- **Local variables inside functions:** `local _var` — underscore prefix.
- **All user output through `xxtb-log()`** — never raw `echo` for user-facing messages. Diagnostic output in `xxtb-sync-belts` must use `xxtb-log ... >&2`.
- **ShellCheck directives** are set at the top of the file. Add to the existing `# shellcheck disable=` line; don't add new per-line disables unless necessary.

## Common Operations

### Adding a new CLI flag
Add a `case` entry in `xxtb()` (around line 237). Follow the existing pattern — single-letter short form + long form + `=` variant where applicable. Return immediately after handling.

### Adding a language to the whitelist
Extend `XXTOOLBELT_SCRIPTS_WHITELIST` (around line 38). Add both the extension to the array and a matching `scripts/<lang>/` folder with a template and README.

### Changing sync behavior
Touch `xxtb-sync()` for core scripts or `xxtb-sync-belts()` for belt scripts. Be vigilant about stdout in `xxtb-sync-belts`.

### Switching a belt between local folder and git repo

The distinction is purely in the source stored in `.belts`: a source starting with `/` or `~` is local (no clone); anything else is a git URL (cloned into `belts/<name>/`). `xxtb-remove-belt` **deletes** `belts/<name>/` only for git-registered belts, so the safe paths differ by direction.

**Registered local path → git repo** (folder not yet in `belts/`):
```bash
xxtb --remove-belt <name>          # removes symlinks, unregisters; folder is NOT deleted
xxtb -a <name> <git-url>           # clones into belts/<name>/, registers, syncs
```

**Registered git belt → local folder** (keep the cloned folder, just re-register):
```bash
# Don't use --remove-belt — it would delete belts/<name>/
sed -i "s|^${name}|.*|${name}|/absolute/path|" .belts   # rewrite source in registry
xxtb -s                                                   # re-sync
```
Or edit `.belts` manually: change the line from `name|https://...` to `name|/absolute/path`.

**Manually cloned into `belts/<name>/` and want to register as a git belt** (most common bootstrap case — `xxtb -a` would fail because the directory already exists):
```bash
echo "name|https://git-url" >> .belts
xxtb -s
```

### Bumping the version
`_SCRIPT_VERSION` near the top of `xxtoolbelt.sh`. Bump after any meaningful change — minor for fixes, minor+1 for new features. Push right after.

## Testing

CI runs ShellCheck (`.github/workflows/lint.yaml`) and `tests/smoke.sh` on ubuntu-latest and macos-latest under bash and zsh (`.github/workflows/test.yaml`). The smoke test uses a throwaway HOME. When making changes:

1. Run `shellcheck xxtoolbelt.sh tests/smoke.sh` and `tests/smoke.sh bash` (plus `tests/smoke.sh zsh` if you have zsh, and `XXTOOLBELT_OS=darwin tests/smoke.sh bash` to exercise the OS filter) before committing.
2. Source the file and test the affected commands manually: `source xxtoolbelt.sh && xxtb -s`.
3. Test on a clean shell (not one that already has the old version sourced) when changing sync or update logic.
4. If touching `xxtb-sync-belts`, verify the belt count is still parsed correctly: after `xxtb -s`, check that the summary line "Synced X core + Y scripts from Z belt(s)" shows correct numbers.

## Belt Conventions

A belt repo should have language subfolders (`bash/`, `python/`, etc.) directly at the root. Scripts must start with `xx`. Files starting with `_` are library files (not synced). If a folder has `requirements.txt`, a `.venv` is auto-created on first sync — output is silenced with `&>/dev/null`.

## What Not to Do

- Do not add `set -e` or `set -o pipefail` — the codebase intentionally avoids strict exit behavior.
- Do not add user-facing `echo` inside `xxtb-sync-belts` or any function it calls — stdout is captured.
- Do not edit files under `belts/` — they are managed by external repos.
- Do not use `--no-verify` when committing — fix the ShellCheck issues instead.
- Do not add new top-level ShellCheck `disable` directives without justifying them in a comment.
- Do not read `.belts` with anything other than `while IFS='|' read -r name source` — the format is `name|source` per line and must stay that way.
