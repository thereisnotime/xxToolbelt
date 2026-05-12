# Python Venv Management

xxToolbelt manages Python virtual environments automatically during sync. Two modes are supported: per-belt isolated venvs (default) and a single shared venv that all opted-in belts use.

---

## How It Works

When `xxtb -s` runs, it scans each belt's language folders. If a `python/requirements.txt` is found it calls `xxtb-ensure-venv`, which:

1. Checks if `uv` is available — uses it if so, falls back to `python3 -m venv` + `pip`.
2. Creates the venv if it doesn't exist.
3. Installs/syncs requirements (re-runs if `requirements.txt` is newer than the venv directory).

All output is silenced — sync stdout is load-bearing for belt count parsing.

---

## Per-Belt Venv (Default)

Each belt folder gets its own `.venv`:

```
belts/mybelt/python/.venv/
```

**When to use:** When your belt has unique or conflicting dependencies, or you want complete isolation.

**Shebang:**
```python
#!/usr/bin/env -S bash -c 'exec "$(dirname "$(realpath "$0")")"/.venv/bin/python3 "$0" "$@"'
```

This resolves the symlink to the real script file and executes the `.venv` sitting next to it.

---

## Shared Venv (Opt-in)

A single venv at `~/.xxtoolbelt/.venv` shared by all belts that opt in.

**When to use:** When multiple belts have the same deps (saves disk and RAM), especially on resource-constrained devices like Termux.

**How to opt in:** Add an empty `.shared-venv` marker file to the belt's language folder:

```bash
touch python/.shared-venv
git add python/.shared-venv
git commit -m "feat: opt into xxtoolbelt shared venv"
git push
```

**Shebang:**
```python
#!/usr/bin/env -S bash -c 'exec "$HOME/.xxtoolbelt/.venv/bin/python3" "$0" "$@"'
```

**Conflict warning:** Every install into the shared venv logs a line to stderr so you can spot version conflicts:

```
[INFO] Belt 'mybelt' uses shared venv (/home/user/.xxtoolbelt/.venv)
```

If two belts require incompatible versions of the same package, the last belt synced wins silently. Switch back to per-belt venvs if that's a problem.

---

## Using uv (Recommended)

[uv](https://github.com/astral-sh/uv) is a fast Python package manager that replaces `pip` and `python3 -m venv`. xxToolbelt uses it automatically if it's on PATH.

**Install:**

```bash
# Official installer (works on Linux, macOS, Termux)
curl -LsSf https://astral.sh/uv/install.sh | sh

# asdf
asdf plugin add uv https://github.com/asdf-community/asdf-uv.git
asdf install uv latest

# mise
mise use -g uv
```

**What changes:** `uv venv` instead of `python3 -m venv`, `uv pip install` instead of `pip install`. Noticeably faster on first sync with many packages.

If `uv` is not found, xxToolbelt falls back to `python3` + `pip` automatically and logs a one-time warning per folder.

---

## Migrating from Per-Belt to Shared

1. Add `.shared-venv` to the belt's python folder and push.
2. Update the shebang in all Python scripts to use `$HOME/.xxtoolbelt/.venv/bin/python3`.
3. Run `xxtb -s` to build the shared venv and install deps.
4. Delete the old per-belt venv:

```bash
rm -rf ~/.xxtoolbelt/belts/mybelt/python/.venv
```

---

## Troubleshooting

**Sync says "uv venv creation failed" or "pip install failed"**
Check stderr output with `xxtb -s 2>&1 | grep -E 'ERR|WARN'`. Usually a missing `python3` binary or a broken `requirements.txt`.

**Script imports fail at runtime even though sync succeeded**
Verify the shebang points to the right interpreter:
```bash
head -1 ~/.xxtoolbelt/belts/mybelt/python/xxmy-script.py
~/.xxtoolbelt/.venv/bin/python3 -c "import mypackage"
```

**Shared venv is missing a package after adding a new belt**
Run `xxtb -s` — it re-installs requirements whenever `requirements.txt` is newer than the venv directory.
