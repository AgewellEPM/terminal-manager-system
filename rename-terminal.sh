#!/bin/bash

# Dynamic Terminal Renamer
# Allows renaming terminal windows on the fly

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

MAPPINGS_FILE="$HOME/.tinkybink_terminal_mappings.json"
NAMES_FILE="$HOME/.tinkybink_terminal_names.json"

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

# Function to get current terminal window ID
get_current_terminal_id() {
    osascript -e 'tell application "Terminal" to id of front window' 2>/dev/null
}

# Function to get all terminal windows
get_all_terminals() {
    osascript -e '
    tell application "Terminal"
        set windowList to {}
        repeat with w in windows
            set windowID to id of w
            try
                set windowName to custom title of w
            on error
                set windowName to "Terminal " & windowID
            end try
            set end of windowList to (windowID as string) & ":" & windowName
        end repeat
        return windowList
    end tell' 2>/dev/null | tr ',' '\n'
}

# Function to rename a terminal window
rename_terminal() {
    local window_id="$1"
    local new_name="$2"
    
    # Set the custom title in Terminal.app
    osascript -e "
    tell application \"Terminal\"
        set custom title of window id $window_id to \"$new_name\"
    end tell" 2>/dev/null
    
    # Update mappings file
    if command -v jq &> /dev/null; then
        # Load existing mappings
        local mappings="{}"
        if [[ -f "$MAPPINGS_FILE" ]]; then
            mappings=$(cat "$MAPPINGS_FILE")
        fi
        
        # Update mapping
        mappings=$(echo "$mappings" | jq ". + {\"$window_id\": \"$new_name\"}")
        echo "$mappings" > "$MAPPINGS_FILE"
        
        # Update names file
        if [[ -f "$NAMES_FILE" ]]; then
            local names=$(cat "$NAMES_FILE")
            # Check if entry exists and update it
            if echo "$names" | jq -e ".\"$new_name\"" > /dev/null 2>&1; then
                names=$(echo "$names" | jq ".\"$new_name\".window_id = \"$window_id\"")
            else
                # Get current directory of the terminal
                local current_dir=$(osascript -e "
                tell application \"Terminal\"
                    do script \"pwd\" in window id $window_id
                    delay 0.5
                    set output to contents of window id $window_id
                    return output
                end tell" 2>/dev/null | tail -1)
                
                names=$(echo "$names" | jq ". + {\"$new_name\": {\"path\": \"$current_dir\", \"window_id\": \"$window_id\", \"renamed\": \"$(date -Iseconds)\"}}")
            fi
            echo "$names" > "$NAMES_FILE"
        fi
    fi
}

# Function to show interactive renaming menu
interactive_rename() {
    echo
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}     Terminal Window Renamer            ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo
    
    print_info "Getting all terminal windows..."
    echo
    
    local windows=($(get_all_terminals))
    
    if [[ ${#windows[@]} -eq 0 ]]; then
        print_error "No terminal windows found"
        exit 1
    fi
    
    echo -e "${YELLOW}Available Terminal Windows:${NC}"
    echo
    
    local count=1
    for window in "${windows[@]}"; do
        local id=$(echo "$window" | cut -d':' -f1)
        local name=$(echo "$window" | cut -d':' -f2-)
        printf "  ${CYAN}%2d)${NC} [ID: %s] %s\n" "$count" "$id" "$name"
        ((count++))
    done
    
    echo
    echo -e "  ${CYAN} c)${NC} Rename current window"
    echo -e "  ${CYAN} a)${NC} Rename all windows"
    echo -e "  ${CYAN} q)${NC} Quit"
    echo
    
    read -p "Select window to rename (1-$((count-1))): " choice
    
    if [[ "$choice" == "q" ]]; then
        exit 0
    elif [[ "$choice" == "c" ]]; then
        rename_current_window
    elif [[ "$choice" == "a" ]]; then
        rename_all_windows
    elif [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -lt "$count" ]]; then
        local selected_window="${windows[$((choice-1))]}"
        local window_id=$(echo "$selected_window" | cut -d':' -f1)
        local current_name=$(echo "$selected_window" | cut -d':' -f2-)
        
        echo
        echo -e "Current name: ${YELLOW}$current_name${NC}"
        read -p "Enter new name: " new_name
        
        if [[ -n "$new_name" ]]; then
            rename_terminal "$window_id" "$new_name"
            print_status "Terminal renamed to '$new_name'"
        else
            print_error "Name cannot be empty"
        fi
    else
        print_error "Invalid choice"
    fi
}

# Function to rename current window
rename_current_window() {
    local window_id=$(get_current_terminal_id)
    
    if [[ -z "$window_id" ]]; then
        print_error "Could not get current terminal window ID"
        exit 1
    fi
    
    echo
    print_info "Current window ID: $window_id"
    read -p "Enter new name for current window: " new_name
    
    if [[ -n "$new_name" ]]; then
        rename_terminal "$window_id" "$new_name"
        print_status "Current terminal renamed to '$new_name'"
    else
        print_error "Name cannot be empty"
    fi
}

# Function to rename all windows with a pattern
rename_all_windows() {
    echo
    print_info "Rename all windows with a pattern"
    echo "Examples:"
    echo "  Project-{n}     → Project-1, Project-2, Project-3..."
    echo "  Dev Terminal {n} → Dev Terminal 1, Dev Terminal 2..."
    echo
    read -p "Enter naming pattern (use {n} for number): " pattern
    
    if [[ -z "$pattern" ]]; then
        print_error "Pattern cannot be empty"
        return
    fi
    
    local windows=($(get_all_terminals))
    local counter=1
    
    for window in "${windows[@]}"; do
        local id=$(echo "$window" | cut -d':' -f1)
        local new_name=${pattern//\{n\}/$counter}
        rename_terminal "$id" "$new_name"
        print_status "Window $id renamed to '$new_name'"
        ((counter++))
    done
}

# Function for quick rename (direct from command line)
quick_rename() {
    local new_name="$1"
    local window_id="$2"
    
    # If no window ID provided, use current window
    if [[ -z "$window_id" ]]; then
        window_id=$(get_current_terminal_id)
    fi
    
    if [[ -z "$window_id" ]]; then
        print_error "Could not get terminal window ID"
        exit 1
    fi
    
    rename_terminal "$window_id" "$new_name"
    print_status "Terminal $window_id renamed to '$new_name'"
}

# Function to list all terminal windows with names
list_terminals() {
    echo
    echo -e "${CYAN}Current Terminal Windows:${NC}"
    echo
    
    local windows=($(get_all_terminals))
    
    if [[ ${#windows[@]} -eq 0 ]]; then
        print_info "No terminal windows found"
        exit 0
    fi
    
    printf "%-10s %-40s\n" "ID" "Name"
    printf "%-10s %-40s\n" "----------" "----------------------------------------"
    
    for window in "${windows[@]}"; do
        local id=$(echo "$window" | cut -d':' -f1)
        local name=$(echo "$window" | cut -d':' -f2-)
        printf "%-10s %-40s\n" "$id" "$name"
    done
    
    echo
}

# Show usage
show_usage() {
    echo "Terminal Window Renamer"
    echo
    echo "Usage: $0 [OPTIONS] [NAME] [WINDOW_ID]"
    echo
    echo "Options:"
    echo "  -h, --help        Show this help message"
    echo "  -l, --list        List all terminal windows"
    echo "  -i, --interactive Interactive renaming mode (default)"
    echo "  -c, --current     Rename current terminal window"
    echo "  -a, --all         Rename all windows with pattern"
    echo
    echo "Examples:"
    echo "  $0                          # Interactive mode"
    echo "  $0 -c                       # Rename current window"
    echo "  $0 \"My Project\"             # Rename current window to 'My Project'"
    echo "  $0 \"My Project\" 12345       # Rename window 12345 to 'My Project'"
    echo "  $0 -l                       # List all terminals"
}

# Main
main() {
    case "${1:-}" in
        -h|--help)
            show_usage
            exit 0
            ;;
        -l|--list)
            list_terminals
            exit 0
            ;;
        -i|--interactive)
            interactive_rename
            ;;
        -c|--current)
            rename_current_window
            ;;
        -a|--all)
            rename_all_windows
            ;;
        "")
            interactive_rename
            ;;
        *)
            # Quick rename mode
            quick_rename "$@"
            ;;
    esac
}

main "$@"