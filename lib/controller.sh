#!/bin/bash

source "$CS_CLI_LIB_DIR/config.sh"
source "$CS_CLI_LIB_DIR/utils.sh"

run_list_mode(){
    # TODO, put this in a utils function
local find_cmd="find"
    if command -v fdfind &> /dev/null; then
        find_cmd="fdfind"
    elif command -v fd &> /dev/null; then
        find_cmd="fd"
    fi

    $find_cmd --strip-cwd-prefix --base-directory ~/.local/share/cs-cli/cheatsheets/personal --type f && $find_cmd --strip-cwd-prefix --base-directory ~/.local/share/cs-cli/cheatsheets/community --type f



}

run_edit_mode() {
    local edit_path="$1"
    if [[ -z $edit_path ]]; then
        edit_path=$(get_all_note_paths | fzf)
    fi

    if [[ -z $edit_path ]]; then
        read -p "Enter note >> " edit_path
    fi

    local target_file="$PERSONAL_CHEATSHEETS_DIR/$edit_path"
    if [[ -f $COMMUNITY_CHEATSHEETS_USER_DIR/$edit_path ]]; then
        target_file=$COMMUNITY_CHEATSHEETS_USER_DIR/$edit_path
    fi

    local target_dir
    target_dir=$(dirname "$target_file")
    mkdir -p "$target_dir"

    ${EDITOR:-nvim} "$target_file"
    exit 0
}

get_all_note_paths(){
    local find_cmd="find"
    if command -v fdfind &> /dev/null; then
        find_cmd="fdfind"
    elif command -v fd &> /dev/null; then
        find_cmd="fd"
    fi

    $find_cmd --strip-cwd-prefix --base-directory ~/.local/share/cs-cli/cheatsheets/personal --type f && $find_cmd --strip-cwd-prefix --base-directory ~/.local/share/cs-cli/cheatsheets/community --type f
}

run_fuzzy_find_mode() {
    local find_cmd="find"
    if command -v fdfind &> /dev/null; then
        find_cmd="fdfind"
    elif command -v fd &> /dev/null; then
        find_cmd="fd"
    fi

    local note_path
    note_path=$(get_all_note_paths | \
        fzf --preview 'cs {}')

    if [[ -z "$note_path" ]]; then
        exit 0
    fi

    run_query_mode "$note_path"
}

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
    local note_path_internal="$base_topic/$sub_topic" 

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

main_controller() {

    local fuzzy_find="false"
    local edit_mode="false"
    local edit_path=""
    local list_dirs="false"

    while getopts "flEe:" opt; do
        case $opt in
            f) 
                fuzzy_find="true"
                ;;
            e) 
                edit_mode="true"
                edit_path="$OPTARG"
                ;;
            E) 
                edit_mode="true"
                ;;
            l) 
                list_dirs="true"
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
    elif [[ "$list_dirs" == "true" ]]; then
        run_list_mode
    elif [[ "$fuzzy_find" == "true" ]]; then
        run_fuzzy_find_mode
    else
        run_query_mode "$1"
    fi
}
