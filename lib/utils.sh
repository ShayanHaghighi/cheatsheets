#!/bin/bash

# This file contains utility functions for the cs-cli tool.

# Reads input from stdin or the first argument.
read_input(){
    local raw_input
    if [ -p /dev/stdin ]; then
        # Input is being piped in
        raw_input=$(cat)
    else
        raw_input="$1"
    fi

    # Ensure we actually have input
    if [ -z "$raw_input" ]; then
        read -p "Enter note >> " raw_input
    fi
    echo "$raw_input" | tr " " "+"
}

# Checks if the response from cht.sh is a valid cheatsheet.
is_response_ok(){
    local input_file="$1"
    local result=""

    # Using a single grep for efficiency
    if grep -q -e "Invalid permissions string" -e "404 NOT FOUND" -e "Unknown topic" "$input_file"; then
        if grep -q "Unknown topic" "$input_file"; then
            result="unknown"
        else
            result="invalid"
        fi
    fi
    echo "$result"
}

# Parses a query string into a base topic and a sub-topic.
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
    
    # Return as space-separated string to be used with eval, escaping single quotes
    printf "%s %s" $base $sub
}

# Determines the language for syntax highlighting based on the topic.
get_language(){
    local note_path="$1"
    local base_topic
    local sub_topic
    IFS=' ' read -r base_topic sub_topic <<< $(get_parts $note_path)
    local lang=$(batcat --list-languages | awk -F ':' '{print $1}' | grep -ix "$base_topic")
    echo "${lang:-'bash'}"
}

# Displays the cheatsheet using batcat for syntax highlighting.
display_sheet() {
    local file_path="$1"
    local note_path="$2"
    
    local base_topic
    local sub_topic

    IFS=' ' read -r base_topic sub_topic <<< $(get_parts $note_path)
    batcat -l "$(get_language $note_path)" --paging always --file-name "$note_path" "$file_path"
}

# Function to find a cheatsheet file within the configured directories.
# Searches in personal, then user community, then system community directories.
# Arguments:
#   $1: The full cheatsheet path (e.g., "bash/for")
# Returns:
#   0 if file found, prints the absolute path.
#   1 if file not found.
find_cheatsheet_file() {
    local note_path="$1"
    local full_path=""

    # 1. Search in PERSONAL_CHEATSHEETS_DIR
    if [[ -f "$PERSONAL_CHEATSHEETS_DIR/$note_path" ]]; then
        full_path="$PERSONAL_CHEATSHEETS_DIR/$note_path"
    # 2. Search in COMMUNITY_CHEATSHEETS_USER_DIR
    elif [[ -f "$COMMUNITY_CHEATSHEETS_USER_DIR/$note_path" ]]; then
        full_path="$COMMUNITY_CHEATSHEETS_USER_DIR/$note_path"
    # 3. Search in COMMUNITY_CHEATSHEETS_SYSTEM_DIR
    elif [[ -f "$COMMUNITY_CHEATSHEETS_SYSTEM_DIR/$note_path" ]]; then
        full_path="$COMMUNITY_CHEATSHEETS_SYSTEM_DIR/$note_path"
    fi

    if [[ -n "$full_path" ]]; then
        echo "$full_path"
        return 0
    else
        return 1
    fi
}
