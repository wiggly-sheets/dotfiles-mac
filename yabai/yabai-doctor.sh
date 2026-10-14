#!/bin/bash
# Checks every layer the yabai + karabiner setup depends on, in the order a
# failure propagates. Each of these has silently broken at least once.
set -uo pipefail

fail=0
warned=0
ok()   { printf '  \033[32mok\033[0m   %s\n' "$*"; }
bad()  { printf '  \033[31mFAIL\033[0m %s\n' "$*"; fail=$((fail + 1)); }
warn() { printf '  \033[33mwarn\033[0m %s\n' "$*"; warned=$((warned + 1)); }

echo "SIP and boot-args"
sip=$(csrutil status 2>/dev/null)
for prot in "Filesystem Protections" "Debugging Restrictions" "NVRAM Protections"; do
  if printf '%s' "$sip" | grep -q "$prot: disabled"; then
    ok "$prot disabled"
  else
    bad "$prot must be disabled (csrutil enable --without fs --without debug --without nvram, from recoveryOS)"
  fi
done

if [ "$(uname -m)" = "arm64" ]; then
  if nvram boot-args 2>/dev/null | grep -q -- -arm64e_preview_abi; then
    ok "boot-args has -arm64e_preview_abi"
  else
    bad "Apple Silicon needs: sudo nvram boot-args=-arm64e_preview_abi (then reboot)"
  fi
fi

echo "yabai"
if command -v yabai >/dev/null; then
  ok "yabai $(yabai --version)"
else
  bad "yabai not on PATH"
fi

if pgrep -x yabai >/dev/null; then
  ok "yabai service running"
else
  bad "yabai not running (yabai --start-service)"
fi

# A brew upgrade leaves the old build running until the service restarts, and
# the loaded scripting addition then belongs to a different build. `yabai
# --version` reports the binary on disk, not the live process, so compare the
# binary's mtime against when the process actually started.
yabai_pid=$(pgrep -x yabai | head -1)
if [ -n "$yabai_pid" ]; then
  # Absolute paths on purpose: brew's coreutils shadows date/stat with GNU
  # builds that reject these BSD flags. lstart's field order is locale
  # dependent, so try both. -L follows the Homebrew symlink to the real binary,
  # whose mtime is the build, not the relink.
  started_at=$(/bin/ps -p "$yabai_pid" -o lstart= 2>/dev/null)
  for fmt in "%a %b %e %T %Y" "%a %e %b %T %Y"; do
    started=$(/bin/date -j -f "$fmt" "$started_at" +%s 2>/dev/null) && break
    started=""
  done
  binary_mtime=$(/usr/bin/stat -L -f %m "$(command -v yabai)" 2>/dev/null || true)
  if [ -z "${started##*[!0-9]*}" ] || [ -z "${binary_mtime##*[!0-9]*}" ] \
     || [ -z "$started" ] || [ -z "$binary_mtime" ]; then
    warn "could not compare yabai's build to the running process"
  elif [ "$binary_mtime" -gt "$started" ]; then
    bad "yabai was upgraded after the running process started; run: yabai --restart-service"
  else
    ok "running yabai is the installed build"
  fi
fi

# The scripting addition is what makes space switching work; querying spaces
# fails without it, which is the cheapest end-to-end proof it is loaded.
if yabai -m query --spaces >/dev/null 2>&1; then
  ok "scripting addition responding"
else
  bad "yabai cannot query spaces; SA likely not loaded (see /var/log/com.ianedington.yabai.out)"
fi

# launchctl print needs root to answer; the daemon's own process does not.
if pgrep -f /usr/local/libexec/yabai-load-sa >/dev/null 2>&1; then
  ok "SA loader daemon running"
else
  bad "SA loader daemon not running; re-run macOS/install"
fi

# The installed copy drifts from the repo silently; compare them.
if [ -x /usr/local/libexec/yabai-load-sa ]; then
  if cmp -s ~/.dotfiles/macOS/yabai/yabai-load-sa.sh /usr/local/libexec/yabai-load-sa; then
    ok "installed SA loader matches the repo"
  else
    bad "installed SA loader is stale; re-run macOS/install"
  fi
else
  bad "/usr/local/libexec/yabai-load-sa missing; re-run macOS/install"
fi

# The sudoers entry pins a hash of the yabai binary, so it breaks on upgrade.
# sudoers.d/yabai is 0440 root, so compare against the stamp macOS/install
# writes rather than escalating just to run a check.
if [ -f /private/etc/sudoers.d/yabai ]; then
  want=$(shasum -a 256 "$(command -v yabai)" | cut -d' ' -f1)
  got=$(cat ~/.local/share/dotfiles/yabai-sudoers-hash 2>/dev/null || true)
  if [ "$want" = "$got" ]; then
    ok "sudoers hash matches the yabai binary"
  else
    bad "sudoers hash is stale after a yabai upgrade; re-run macOS/install"
  fi
fi

echo "hotkeys (karabiner)"
# karabiner_console_user_server is the piece that runs shell_command, so it is
# the one whose absence kills hotkeys while remaps keep working.
if pgrep -x karabiner_console_user_server >/dev/null; then
  ok "karabiner_console_user_server running"
else
  bad "karabiner_console_user_server not running; open Karabiner-Elements"
fi

# Karabiner replaces karabiner.json rather than writing through it whenever its
# GUI saves, which silently swaps the symlink for a regular file. Everything
# still works, and the repo quietly stops being the source of truth.
live=~/.config/karabiner/karabiner.json
if [ ! -e "$live" ]; then
  bad "$live missing; re-run macOS/install"
elif [ ! -L "$live" ]; then
  bad "$live is a real file, not a symlink to the repo; save it over macOS/karabiner.json, then re-run macOS/install"
elif cmp -s "$live" ~/.dotfiles/macOS/karabiner.json; then
  ok "karabiner.json symlinked to the repo"
else
  bad "$live points somewhere other than the repo copy; re-run macOS/install"
fi

# The hotkey rules are compiled from macOS/yabai/keybindings, so the committed
# JSON can drift behind the file that is meant to be authoritative.
if ~/.dotfiles/macOS/yabai/gen-karabiner-rules.sh --check 2>/dev/null; then
  ok "generated hotkeys match keybindings"
else
  bad "karabiner.json is stale; run macOS/yabai/gen-karabiner-rules.sh"
fi

echo
if [ "$fail" -gt 0 ]; then
  echo "$fail check(s) failed, $warned inconclusive"
elif [ "$warned" -gt 0 ]; then
  echo "no failures, but $warned check(s) could not be evaluated"
else
  echo "all checks passed"
fi
exit "$fail"
