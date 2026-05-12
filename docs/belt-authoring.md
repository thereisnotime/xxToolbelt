# Belt Authoring Guide

A belt is a git repository (or local folder) that xxToolbelt clones and syncs alongside your core scripts. This guide covers everything needed to publish a belt others can add with a single `xxtb -a` command.

---

## Minimal Structure

```
my-toolbelt/
├── bash/
│   └── xxhello.sh
└── python/
    ├── xxfetch.py
    └── requirements.txt
```

Rules:
- Language folders sit at the repo root — no nesting.
- Every script must start with `xx` to avoid clashing with system commands.
- Files starting with `_` are libraries — not synced to `~/.local/bin`.
- Only executables are synced — `chmod +x` your scripts.

---

## Supported Languages

Any language in `XXTOOLBELT_SCRIPTS_WHITELIST` works. The whitelist contains:

`py sh erl hrl exs java rs ps1 pwsh rb lua cpp c pl groovy d go js php r cs ts janet zig v`

The shebang is what actually matters — if your runtime can be invoked from a shebang, it works.

---

## Shebang Patterns

### Bash
```bash
#!/usr/bin/env bash
```

### Python (system interpreter)
```python
#!/usr/bin/env python3
```

### Python with per-belt venv
```python
#!/usr/bin/env -S bash -c 'exec "$(dirname "$(realpath "$0")")"/.venv/bin/python3 "$0" "$@"'
```
Resolves the real script path (following symlinks) and uses the `.venv` next to it.

### Python with shared xxToolbelt venv
```python
#!/usr/bin/env -S bash -c 'exec "$HOME/.xxtoolbelt/.venv/bin/python3" "$0" "$@"'
```
See [python-venv.md](python-venv.md) for when to choose shared vs per-belt.

### Node.js
```javascript
#!/usr/bin/env node
```

### Ruby
```ruby
#!/usr/bin/env ruby
```

### Go (interpreted via `gorun` or compiled ahead of time)
```go
#!/usr/bin/env gorun
```

---

## Python Dependencies

Drop a `requirements.txt` in your `python/` folder. xxToolbelt creates a venv and installs it automatically on first sync.

**Default (per-belt, isolated):**
No extra files needed — a `.venv` is created inside `python/`.

**Opt-in shared venv:**
Add an empty `.shared-venv` marker file:

```bash
touch python/.shared-venv
```

All belts that opt in share `~/.xxtoolbelt/.venv`. Use this when your deps overlap with other belts and you want to save disk/RAM. See [python-venv.md](python-venv.md) for the full tradeoff.

---

## Private Scripts in Belts

Same rule as core scripts — name the file `xxscript.private.ext` and it is gitignored but synced with the clean name `xxscript`.

---

## Registering a Belt

```bash
xxtb -a mybelt git@github.com:you/my-toolbelt.git
```

Or a local folder (no cloning, changes reflect immediately):

```bash
xxtb -a mybelt /path/to/my-toolbelt
```

---

## Switching a Belt from Local to Git

```bash
xxtb --remove-belt mybelt          # removes symlinks, unregisters; folder NOT deleted
xxtb -a mybelt git@github.com:...  # clone and register
```

## Switching from Git to Local

Edit `.belts` directly — change the URL to an absolute path and re-sync:

```bash
# ~/.xxtoolbelt/.belts
mybelt|/absolute/path/to/my-toolbelt
```

```bash
xxtb -s
```

---

## Belt Conventions Checklist

- [ ] Language folders at repo root
- [ ] All scripts named `xx*`
- [ ] All scripts are executable (`chmod +x`)
- [ ] Library files named `_*`
- [ ] `requirements.txt` present if Python deps are needed
- [ ] `.shared-venv` marker added if opting into shared venv
- [ ] Shebangs tested standalone before registering
