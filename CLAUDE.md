# xxToolbelt

A Bash-based system for organizing scripts and tools across multiple languages. Scripts are managed via symlinks in `~/.local/bin` (not shell aliases), so they work everywhere: interactive shells, AI tools, cron jobs, and any process with PATH.

## Project Structure

- `xxtoolbelt.sh` - Main script (sourced from shell rc file). Contains all core logic: TUI menu, CLI parser, sync engine, belt management, export/import.
- `scripts/` - Core scripts organized by language (e.g., `scripts/bash/`, `scripts/python/`). Each language folder has a template and README.
- `belts/` - External toolbelts (git repos or local folders registered via `xxtb -a`). Belt registration is stored in `.belts` file.
- `.belts` - Belt registry file. Format: `name|source` per line. Disabled belts are prefixed with `#`.
- `.debug` - Presence of this file enables debug mode.

## How It Works

1. `xxtoolbelt.sh` is sourced from `.bashrc`/`.zshrc` on shell startup (lightweight - no script scanning on startup).
2. `xxtb --sync` (or `xxtb -s`) creates/updates symlinks in `~/.local/bin` for all scripts in `scripts/` and registered belts.
3. Scripts are discovered by file extension using `XXTOOLBELT_SCRIPTS_WHITELIST` (supports 20+ languages).
4. Files starting with `_` are treated as library files and skipped during sync (not symlinked).
5. The `.private` keyword in filenames (e.g., `xxfoo.private.sh`) is stripped from the symlink name and gitignored.

## Key Commands

```
xxtb              # Launch TUI menu
xxtb -s / --sync  # Sync scripts to ~/.local/bin (create/update/clean symlinks)
xxtb -ls / --list # List all synced scripts
xxtb -u / --update # Update xxToolbelt core + all git belts, then re-sync
xxtb -e COMMAND   # Export a script as a shareable import string
xxtb -h / --help  # Show CLI help
xxtb -d / --debug # Toggle debug mode
```

### Belt Management

```
xxtb -a NAME URL|PATH   # Add a belt (git repo or local path)
xxtb -r / --belts        # List registered belts
xxtb --remove-belt NAME  # Remove a belt
xxtb --disable-belt NAME # Disable without removing
xxtb --enable-belt NAME  # Re-enable a disabled belt
```

## Script Conventions

- All script filenames should start with `xx` (e.g., `xxmy-tool.sh`).
- Scripts must have a proper shebang line (e.g., `#!/bin/bash`, `#!/usr/bin/env python3`).
- Scripts are made executable automatically during sync.
- Scanning depth is 3 levels by default (`XXTOOLBELT_SCANNING_DEPTH`).

## Belt Structure

A belt repo should contain language folders with scripts:

```
my-belt/
  bash/
    xxmy-script.sh
  python/
    xxtool.py
```

Belt folders are symlinked into `scripts/` as `<belt-name>-<folder>` during sync. Python belt folders with a `requirements.txt` get an auto-created venv.

## Development Notes

- The project uses shellcheck for linting (CI via GitHub Actions). Several shellcheck directives are disabled at the top of `xxtoolbelt.sh`.
- The `xxtb` wrapper in `~/.local/bin` sources `xxtoolbelt.sh` and forwards args, enabling `xxtb` usage outside sourced shells.
- Stale symlinks (pointing to deleted scripts) are cleaned up automatically during sync.
- When editing `xxtoolbelt.sh`, preserve the existing code style: function-based organization, `log()` for output, color variables for formatting.
- Do not modify files inside `belts/` - those are managed by their own git repos.
