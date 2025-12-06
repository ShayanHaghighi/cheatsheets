#!/bin/bash

# This file contains configuration variables for the cs-cli tool.

# The base directory for user-specific cs-cli files.
# Using XDG_DATA_HOME if set, otherwise ~/.local/share
CS_USER_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/cs-cli"

# The base directory for system-wide cs-cli files.
CS_SYSTEM_DATA_DIR="/usr/local/share/cs-cli"

# Cheatsheet directories
USER_CHEATSHEETS_DIR="$CS_USER_DATA_DIR/cheatsheets"
SYSTEM_CHEATSHEETS_DIR="$CS_SYSTEM_DATA_DIR/cheatsheets"

# Personal cheatsheets are stored in the user's data directory.
PERSONAL_CHEATSHEETS_DIR="$USER_CHEATSHEETS_DIR/personal"

# Community cheatsheets can be in both system and user directories.
# User-downloaded sheets go into the user directory.
COMMUNITY_CHEATSHEETS_USER_DIR="$USER_CHEATSHEETS_DIR/community"
COMMUNITY_CHEATSHEETS_SYSTEM_DIR="$SYSTEM_CHEATSHEETS_DIR/community"

# For saving new cheatsheets downloaded from cht.sh
# New community sheets are saved to the user's data directory.
NOTE_DIR="$COMMUNITY_CHEATSHEETS_USER_DIR"

# Ensure user directories exist for storing personal and downloaded cheatsheets.
mkdir -p "$PERSONAL_CHEATSHEETS_DIR"
mkdir -p "$COMMUNITY_CHEATSHEETS_USER_DIR"
