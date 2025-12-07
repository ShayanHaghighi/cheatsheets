#!/bin/bash

CS_USER_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/cs-cli"

CS_SYSTEM_DATA_DIR="/usr/local/share/cs-cli"

# Cheatsheet directories
USER_CHEATSHEETS_DIR="$CS_USER_DATA_DIR/cheatsheets"

PERSONAL_CHEATSHEETS_DIR="$USER_CHEATSHEETS_DIR/personal"
COMMUNITY_CHEATSHEETS_USER_DIR="$USER_CHEATSHEETS_DIR/community"

# This is where user written notes will be stored
NOTE_DIR="$COMMUNITY_CHEATSHEETS_USER_DIR"

mkdir -p "$PERSONAL_CHEATSHEETS_DIR"
mkdir -p "$COMMUNITY_CHEATSHEETS_USER_DIR"
