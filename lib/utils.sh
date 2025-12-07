#!/bin/bash

read_input(){
    local raw_input
    if [ -p /dev/stdin ]; then
        raw_input=$(cat)
    else
        raw_input="$1"
    fi

    if [ -z "$raw_input" ]; then
        read -p "Enter note >> " raw_input
    fi
    echo "$raw_input" | tr " " "+"
}

is_response_ok(){
    local input_file="$1"
    local result=""

    if grep -q -e "Invalid permissions string" -e "404 NOT FOUND" -e "Unknown topic" "$input_file"; then
        if grep -q "Unknown topic" "$input_file"; then
            result="unknown"
        else
            result="invalid"
        fi
    fi
    echo "$result"
}

get_parts() {
    local query="$1"
    local base=""
    local sub=""

    if [[ "$query" == */* ]]; then


        IFS='/' read -r base sub <<< "$query"
    elif [[ "$query" == *~* ]]; then
        IFS='~' read -r base sub <<< "$query"
    else
        base="$query"
        sub=":root"
    fi
    
    printf "%s %s" $base $sub
}

get_language(){
    local note_path="$1"
    local base_topic
    local sub_topic
    IFS=' ' read -r base_topic sub_topic <<< $(get_parts $note_path)
    local lang=$(batcat --list-languages | awk -F ':' '{print $1}' | grep -ix "$base_topic")
    echo "${lang:-bash}"
}


display_sheet() {
    local file_path="$1"
    local note_path="$2"
    
    local base_topic
    local sub_topic

    IFS=' ' read -r base_topic sub_topic <<< $(get_parts $note_path)
    batcat --color=always -l "$(get_language $note_path)" --paging always --file-name "$note_path" "$file_path"
}

find_cheatsheet_file() {
    local note_path="$1"
    local full_path=""

    # First search in PERSONAL_CHEATSHEETS_DIR
    if [[ -f "$PERSONAL_CHEATSHEETS_DIR/$note_path" ]]; then
        full_path="$PERSONAL_CHEATSHEETS_DIR/$note_path"
    # Then search in COMMUNITY_CHEATSHEETS_USER_DIR
    elif [[ -f "$COMMUNITY_CHEATSHEETS_USER_DIR/$note_path" ]]; then
        full_path="$COMMUNITY_CHEATSHEETS_USER_DIR/$note_path"
    fi

    if [[ -n "$full_path" ]]; then
        echo "$full_path"
        return 0
    else
        return 1
    fi
}

