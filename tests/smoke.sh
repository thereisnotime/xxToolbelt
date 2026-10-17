#!/usr/bin/env bash
# shellcheck disable=SC2016 # single-quoted snippets are expanded by the shell under test, on purpose
# Smoke test for xxtoolbelt.sh. Runs in a throwaway HOME, never touches yours.
#
# Usage: tests/smoke.sh [shell]
#   shell  the shell that sources xxtoolbelt.sh (default: bash). Use 'zsh' to
#          test the zsh shim, or a path like /bin/bash to test bash 3.2 on macOS.
#
# Set XXTOOLBELT_OS=darwin|linux to fake the OS for the 'xxtb-os:' filter.
_shell="${1:-bash}"
_repo="$(cd "$(dirname "$0")/.." && pwd)"
_failed=0

_tmp="$(mktemp -d "${TMPDIR:-/tmp}/xxtb-smoke.XXXXXX")"
trap 'rm -rf "$_tmp"' EXIT
export HOME="$_tmp/home"
mkdir -p "$HOME"
# Copy, not symlink: sync writes .belts and scripts/<belt>-* links into the install.
cp -R "$_repo" "$HOME/.xxtoolbelt"
rm -rf "$HOME/.xxtoolbelt/.git" "$HOME/.xxtoolbelt/belts" "$HOME/.xxtoolbelt/.belts"

function pass () { echo "ok   - $1"; }
function fail () { echo "FAIL - $1"; _failed=1; }
function check () {
	# check <description> <command...>
	local _desc="$1"; shift
	if "$@"; then pass "$_desc"; else fail "$_desc"; fi
}
function xxtb_run () {
	# Source xxtoolbelt.sh in the shell under test and run xxtb with the given args.
	"$_shell" -c 'source "$HOME/.xxtoolbelt/xxtoolbelt.sh"; xxtb "$@"' xxtb "$@"
}

# Fixture belt: one portable script, one per OS, a library, and a folder
# that is linux-only through a .xxtb-os file.
_belt="$_tmp/fixture-belt"
mkdir -p "$_belt/bash" "$_belt/linuxonly"
printf '#!/usr/bin/env bash\necho any\n' > "$_belt/bash/xxfx-any.sh"
printf '#!/usr/bin/env bash\n# xxtb-os: linux\necho linux\n' > "$_belt/bash/xxfx-linux.sh"
printf '#!/usr/bin/env bash\n// xxtb-os: darwin,freebsd\necho darwin\n' > "$_belt/bash/xxfx-mac.sh"
printf '#!/usr/bin/env bash\n-- xxtb-os: macos\necho macos\n' > "$_belt/bash/xxfx-macos-alias.sh"
printf '#!/usr/bin/env bash\necho lib\n' > "$_belt/bash/_fxlib.sh"
printf '#!/usr/bin/env bash\necho folder\n' > "$_belt/linuxonly/xxfx-folder.sh"
printf 'linux\n' > "$_belt/linuxonly/.xxtb-os"

_os="${XXTOOLBELT_OS:-}"
if [[ -z "$_os" ]]; then
	case "$OSTYPE" in darwin*) _os="darwin" ;; *) _os="linux" ;; esac
fi
export XXTOOLBELT_OS="$_os"
_bin="$HOME/.local/bin"

echo "# shell: $_shell ($("$_shell" -c 'echo ${BASH_VERSION:-zsh $ZSH_VERSION}')), os: $_os"

# 1. First sync on a fresh HOME (empty ~/.local/bin, no xxtb wrapper yet).
check "first sync succeeds" xxtb_run -s
check "xxtb wrapper written" test -x "$_bin/xxtb"
check "core template synced" test -L "$_bin/xxtemplate-bash"
if [[ "$_os" == "linux" ]]; then
	check "linux-only core script synced on linux" test -L "$_bin/xxnet-iptables-ls"
else
	check "linux-only core script skipped on $_os" test ! -e "$_bin/xxnet-iptables-ls"
fi

# 2. Wrapper works without sourcing anything.
check "wrapper runs" "$_bin/xxtb" --version

# 3. Add a local belt, OS filter applies.
check "add local belt" xxtb_run -a fx "$_belt"
check "portable belt script synced" test -L "$_bin/xxfx-any"
check "library not synced" test ! -e "$_bin/_fxlib"
if [[ "$_os" == "linux" ]]; then
	check "linux script synced" test -L "$_bin/xxfx-linux"
	check "linux folder synced" test -L "$_bin/xxfx-folder"
	check "darwin script skipped" test ! -e "$_bin/xxfx-mac"
	check "macos alias script skipped" test ! -e "$_bin/xxfx-macos-alias"
else
	check "linux script skipped" test ! -e "$_bin/xxfx-linux"
	check "linux folder skipped" test ! -e "$_bin/xxfx-folder"
	check "darwin script synced" test -L "$_bin/xxfx-mac"
	check "macos alias script synced" test -L "$_bin/xxfx-macos-alias"
fi

# 4. Switching OS drops links that no longer apply.
_other="darwin"; [[ "$_os" == "darwin" ]] && _other="linux"
XXTOOLBELT_OS="$_other" xxtb_run -s >/dev/null
check "switching to $_other keeps portable script" test -L "$_bin/xxfx-any"
if [[ "$_other" == "darwin" ]]; then
	check "switching to darwin drops linux link" test ! -e "$_bin/xxfx-linux"
	check "switching to darwin adds darwin link" test -L "$_bin/xxfx-mac"
else
	check "switching to linux drops darwin link" test ! -e "$_bin/xxfx-mac"
	check "switching to linux adds linux link" test -L "$_bin/xxfx-linux"
fi
xxtb_run -s >/dev/null

# 5. Belt registry edits (no sed -i).
check "disable belt" xxtb_run --disable-belt fx
check "belt marked disabled" grep -q '^#fx|' "$HOME/.xxtoolbelt/.belts"
check "enable belt" xxtb_run --enable-belt fx
check "belt marked enabled" grep -q '^fx|' "$HOME/.xxtoolbelt/.belts"

# 6. Listing.
_list="$(xxtb_run --list 2>&1)"
if echo "$_list" | grep -q 'xxfx-any'; then pass "list shows belt script"; else fail "list shows belt script"; fi
_belts="$(xxtb_run -r 2>&1)"
if echo "$_belts" | grep -q 'fx'; then pass "belts list shows fx"; else fail "belts list shows fx"; fi

# 7. Remove belt cleans its links.
check "remove belt" xxtb_run --remove-belt fx
check "belt links removed" test ! -e "$_bin/xxfx-any"

# 8. Sourcing must not shadow an existing 'log' (macOS has /usr/bin/log).
_log_type="$("$_shell" -c 'function log () { echo mine; }; source "$HOME/.xxtoolbelt/xxtoolbelt.sh"; log' 2>&1)"
if [[ "$_log_type" == "mine" ]]; then pass "existing log() kept"; else fail "existing log() kept (got: $_log_type)"; fi

if [[ "$_failed" -ne 0 ]]; then
	echo "# smoke test FAILED"
	exit 1
fi
echo "# smoke test passed"
