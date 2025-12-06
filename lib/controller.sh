#!/bin/bash

# This file contains the main controller logic for the cs-cli tool.

source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/utils.sh"

# Handles the -e option to edit a personal cheatsheet.
run_edit_mode() {
    local edit_path="$1"
    local target_file="$PERSONAL_CHEATSHEETS_DIR/$edit_path"

    local target_dir
    target_dir=$(dirname "$target_file")
    mkdir -p "$target_dir"

    ${EDITOR:-nvim} "$target_file"
    exit 0
}

# Handles the -f option for fuzzy finding cheatsheets.
run_fuzzy_find_mode() {
    local find_cmd="find"
    if command -v fdfind &> /dev/null; then
        find_cmd="fdfind"
    elif command -v fd &> /dev/null; then
        find_cmd="fd"
    fi

    local note_path
    note_path=$($find_cmd . "$USER_CHEATSHEETS_DIR" "$SYSTEM_CHEATSHEETS_DIR" -type f | \
        sed -E 's#^.*/(personal|community)/?(.*)$#\2#' | \
        grep -v 'README.md' | \
        grep '/' | \
        fzf --preview 'base_name=$(echo {} | cut -d "/" -f 1); \
        lang_name=$(get_language {}); \
        local found_file=$(find_cheatsheet_file "{}"); \
        if [[ -n "$found_file" ]]; then cat "$found_file" | batcat --color=always -l "${lang_name:-bash}"; fi')

    if [[ -z "$note_path" ]]; then
        exit 0
    fi

    run_query_mode "$note_path"
}

# Handles a direct query for a cheatsheet.
run_query_mode() {
    local query
    if [[ -n "$1" ]]; then
      query="$1"
    else
      query=$(read_input)
    fi

    local base_topic
    local sub_topic
    IFS=' ' read -r base_topic sub_topic <<< $(get_parts $query)
    local note_path_internal="$base_topic/$sub_topic" # Renamed to avoid confusion

    local tmp
    tmp=$(mktemp)
    trap 'rm -f "$tmp"' EXIT

    local cheat_sheet_file
    if ! cheat_sheet_file=$(find_cheatsheet_file "$note_path_internal"); then

        if ! curl -s "cht.sh/$query" -o "$tmp"; then
            echo "failed to fetch data" >&2
            exit 1
        fi
        # clean ANSI escape codes
        sed -i 's/\x1b\[[0-9;]*m//g' "$tmp"

        local is_ok
        is_ok=$(is_response_ok "$tmp")
        case "$is_ok" in
            "invalid") echo "not a valid cheat sheet" >&2; exit 0 ;;
            "unknown") cat "$tmp"; exit 0 ;;
        esac


        local dir="$NOTE_DIR/$base_topic"
        local abs_file_path="$dir/$sub_topic"
        mkdir -p "$dir"
        if [[ ! -f "$abs_file_path" ]]; then
            mv "$tmp" "$abs_file_path"
            echo "saved to dir: $note_path_internal"
        fi
        cheat_sheet_file=$abs_file_path
    fi

    display_sheet "$cheat_sheet_file" "$note_path_internal"
}

# Main entry point for the controller. Parses options and calls the appropriate function.
main_controller() {
    # Removed export CHEAT_PATH as the external 'cheat' tool is no longer used directly.

    local fuzzy_find="false"
    local edit_mode="false"
    local edit_path=""

    while getopts "fe:" opt; do
        case $opt in
            f) 
                fuzzy_find="true"
                ;;
            e) 
                edit_mode="true"
                edit_path="$OPTARG"
                ;;
            \?) 
                echo "Invalid option" >&2
                exit 1
                ;;
        esac
done

    shift $((OPTIND - 1))

    if [[ "$edit_mode" == "true" ]]; then
        run_edit_mode "$edit_path"
    elif [[ "$fuzzy_find" == "true" ]]; then
        run_fuzzy_find_mode
    else
        run_query_mode "$1"
    fi
}
