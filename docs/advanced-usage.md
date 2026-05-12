# Advanced Usage

## Debug Mode

Toggle a verbose debug log for every sync operation:

```bash
xxtb --debug       # enable
xxtb --debug       # toggle off
```

While debug mode is on, sync prints every symlink created, every belt script registered, and every stale link removed. The state is stored in `~/.xxtoolbelt/.debug` — deleting that file disables it.

---

## Private Scripts

Any script whose filename contains `.private` before the extension is gitignored but still synced and callable by its clean name.

```
scripts/bash/xxmy-tokens.private.sh   →  callable as: xxmy-tokens
scripts/python/xxwork-api.private.py  →  callable as: xxwork-api
```

Use this for scripts that contain credentials, internal hostnames, or anything you don't want in a public repo.

---

## Library Files

Files whose name starts with `_` are treated as shared libraries and are never symlinked into `~/.local/bin`. Use them for shared helpers sourced by other scripts.

```
scripts/bash/_colors.sh       # sourced by other scripts, not callable directly
scripts/python/_api_client.py # imported by other scripts
```

---

## Script Scanning Depth

The default scan depth is 3 levels inside each language folder. Increase it if your scripts are nested deeper (e.g. you organise by project inside a language folder):

```bash
# in ~/.bashrc / ~/.zshrc, after sourcing xxtoolbelt.sh
XXTOOLBELT_SCANNING_DEPTH=4
```

---

## Export and Import Scripts

Share a script as a self-contained one-liner (base64-encoded):

```bash
xxtb -e xxmy-script
```

This prints an `XXTBIMPORT=...` line. The recipient pastes it in their terminal and the script is placed into the correct language folder and synced automatically.

---

## Changing the Scripts Editor

`xxtb -o` opens the scripts folder in your editor. Change the editor:

```bash
XXTOOLBELT_SCRIPTS_EDITOR="nvim"   # in your rc file
```

---

## Overriding the Scripts Folder

Move your scripts to a different path (e.g. inside a synced folder like Dropbox or a dotfiles repo):

```bash
XXTOOLBELT_SCRIPTS_FOLDER="$HOME/Dropbox/scripts"
```

Set this before sourcing `xxtoolbelt.sh`.

---

## Keeping `~/.local/bin` Safe

The stale-symlink cleanup only removes symlinks whose target starts with `XXTOOLBELT_SCRIPTS_FOLDER` or `XXTOOLBELT_BELTS_FOLDER`. Symlinks placed there by other tools are never touched.

---

## Adding a New Language

1. Create `scripts/<lang>/` with a template script and a `README.md`.
2. Add the extension to `XXTOOLBELT_SCRIPTS_WHITELIST` in your rc file:

```bash
XXTOOLBELT_SCRIPTS_WHITELIST+=("nim")
```

3. Verify the shebang runs standalone: `bash ./scripts/nim/template.nim`
4. Reload and sync: `source ~/.bashrc && xxtb -s`

---

## Cron and Systemd

Scripts are plain symlinks in `~/.local/bin`, so they work anywhere PATH is set:

```bash
# crontab
PATH=/home/user/.local/bin:/usr/bin:/bin
*/5 * * * * xxmy-monitor

# systemd unit
[Service]
Environment="PATH=/home/user/.local/bin:/usr/bin:/bin"
ExecStart=/home/user/.local/bin/xxmy-service
```

---

## Forcing a Full Resync

To rebuild all symlinks from scratch (useful after moving the scripts folder):

```bash
xxtb -s
```

This re-scans everything, prunes stale links, and recreates the `xxtb` wrapper.

---

## Self-Update

```bash
xxtb -u
```

Downloads the latest `xxtoolbelt.sh`, pulls all git-based belts, reloads, and re-syncs. The changelog for both core and each belt is printed before the pull.
