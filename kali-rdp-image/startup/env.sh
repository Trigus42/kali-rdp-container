#!/usr/bin/env bash

# Propagate selected container env vars to all zsh sessions.
# Written to a dedicated file sourced by ~/.zshrc so it can't be
# overridden by the system /etc/zsh/zshrc from kali-defaults.

ENV_FILE="/etc/kali-rdp-env"

: > "$ENV_FILE"  # truncate to avoid duplicates on restart

if [ -n "$HISTFILE" ]; then
    echo "export HISTFILE=\"$HISTFILE\"" >> "$ENV_FILE"
fi
