#!/bin/bash

# Terminal Window Creator with Folder Mapping
# Integrates with existing TinkyBink terminal management system

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAPPINGS_FILE="$HOME/.tinkybink_terminal_mappings.json"
TERMINAL_NAMES_FILE="$HOME/.tinkybink_terminal_names.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to get user input
get_input() {
    local prompt="$1"
    local var_name="$2"
    local default_value="$3"
    
    if [[ -n "$default_value" ]]; then
        read -p "$prompt [$default_value]: " input
        if [[ -z "$input" ]]; then
            eval "$var_name='$default_value'"
        else
            eval "$var_name='$input'"
        fi
    else
        read -p "$prompt: " input
        eval "$var_name='$input'"
    fi
}

# Function to validate directory
validate_directory() {
    local dir="$1"
    
    if [[ ! -d "$dir" ]]; then
        print_error "Directory does not exist: $dir"
        return 1
    fi
    
    if [[ ! -r "$dir" ]]; then
        print_error "Directory is not readable: $dir"
        return 1
    fi
    
    return 0
}

# Function to load existing mappings
load_mappings() {
    if [[ -f "$MAPPINGS_FILE" ]]; then
        cat "$MAPPINGS_FILE"
    else
        echo "{}"
    fi
}

# Function to save mappings
save_mappings() {
    local mappings="$1"
    echo "$mappings" > "$MAPPINGS_FILE"
    print_status "Mappings saved to $MAPPINGS_FILE"
}

# Function to load terminal names
load_terminal_names() {
    if [[ -f "$TERMINAL_NAMES_FILE" ]]; then
        cat "$TERMINAL_NAMES_FILE"
    else
        echo "{}"
    fi
}

# Function to save terminal names
save_terminal_names() {
    local names="$1"
    echo "$names" > "$TERMINAL_NAMES_FILE"
    print_status "Terminal names saved to $TERMINAL_NAMES_FILE"
}

# Function to create new terminal window with mapping
create_terminal_window() {
    local window_name="$1"
    local folder_path="$2"
    
    print_status "Creating terminal window: $window_name"
    print_status "Mapping to folder: $folder_path"
    
    # Validate directory first
    if ! validate_directory "$folder_path"; then
        return 1
    fi
    
    # Create AppleScript to open new terminal window
    local applescript="
    tell application \"Terminal\"
        activate
        
        -- Create new window and change directory
        do script \"cd '$folder_path'\"
        
        -- Get the ID of the new window
        set newWindowID to id of front window
        
        -- Set the window name
        set custom title of front window to \"$window_name\"
        
        -- Return window ID for mapping
        return newWindowID as string
    end tell
    "
    
    # Execute AppleScript and get window ID
    local window_id
    window_id=$(osascript -e "$applescript" 2>/dev/null)
    
    if [[ $? -ne 0 || -z "$window_id" ]]; then
        print_error "Failed to create terminal window"
        return 1
    fi
    
    print_status "Terminal window created with ID: $window_id"
    
    # Update mappings
    local mappings
    mappings=$(load_mappings)
    
    # Add new mapping using jq (install if needed)
    if ! command -v jq &> /dev/null; then
        print_warning "jq not found, installing..."
        brew install jq 2>/dev/null || {
            print_error "Failed to install jq. Please install it manually: brew install jq"
            return 1
        }
    fi
    
    # Add mapping
    mappings=$(echo "$mappings" | jq ". + {\"$window_id\": \"$window_name\"}")
    save_mappings "$mappings"
    
    # Add terminal name mapping
    local names
    names=$(load_terminal_names)
    names=$(echo "$names" | jq ". + {\"$window_name\": {\"path\": \"$folder_path\", \"window_id\": \"$window_id\", \"created\": \"$(date -Iseconds)\"}}")
    save_terminal_names "$names"
    
    print_status "✅ Terminal window '$window_name' created and mapped to '$folder_path'"
    
    # Update terminal title with project indicator
    update_terminal_title "$window_id" "$window_name" "$folder_path"
    
    return 0
}

# Function to update terminal title
update_terminal_title() {
    local window_id="$1"
    local window_name="$2"
    local folder_path="$3"
    
    local folder_name
    folder_name=$(basename "$folder_path")
    
    local applescript="
    tell application \"Terminal\"
        set custom title of window id $window_id to \"[$window_name] $folder_name\"
    end tell
    "
    
    osascript -e "$applescript" 2>/dev/null || true
}

# Function to list existing mappings
list_mappings() {
    print_status "Current Terminal Mappings:"
    echo
    
    if [[ -f "$TERMINAL_NAMES_FILE" ]]; then
        local names
        names=$(load_terminal_names)
        
        echo "$names" | jq -r 'to_entries[] | "  \(.key): \(.value.path) (ID: \(.value.window_id))"' 2>/dev/null || {
            print_warning "No valid mappings found or jq not available"
        }
    else
        print_warning "No terminal mappings found"
    fi
}

# Function to show quick project options
show_quick_options() {
    echo
    print_status "Quick Start Options:"
    echo "  1. Home Directory (~)"
    echo "  2. Desktop"
    echo "  3. Documents"
    echo "  4. Downloads"
    echo "  5. Current Directory"
    echo "  6. Custom Path"
    echo "  7. Create New Project"
    echo
}

# Function to handle quick options
handle_quick_option() {
    local option="$1"
    local folder_path
    local window_name
    
    case "$option" in
        1)
            folder_path="$HOME"
            window_name="Home"
            ;;
        2)
            folder_path="$HOME/Desktop"
            window_name="Desktop"
            ;;
        3)
            folder_path="$HOME/Documents"
            window_name="Documents"
            ;;
        4)
            folder_path="$HOME/Downloads"
            window_name="Downloads"
            ;;
        5)
            folder_path="$(pwd)"
            window_name="$(basename "$(pwd)")"
            ;;
        6)
            get_input "Enter folder path" folder_path
            get_input "Enter window name" window_name "$(basename "$folder_path")"
            ;;
        7)
            create_new_project
            return $?
            ;;
        *)
            print_error "Invalid option"
            return 1
            ;;
    esac
    
    create_terminal_window "$window_name" "$folder_path"
}

# Function to create new project
create_new_project() {
    local base_dir="$HOME/Desktop/Projects"
    local project_name
    local project_path
    
    get_input "Enter project name" project_name
    
    if [[ -z "$project_name" ]]; then
        print_error "Project name cannot be empty"
        return 1
    fi
    
    # Clean project name
    project_name=$(echo "$project_name" | sed 's/[^a-zA-Z0-9_-]/_/g')
    
    get_input "Enter project base directory" base_dir "$base_dir"
    project_path="$base_dir/$project_name"
    
    # Create directory structure
    print_status "Creating project directory: $project_path"
    mkdir -p "$project_path"
    mkdir -p "$project_path/docs"
    mkdir -p "$project_path/src"
    mkdir -p "$project_path/tests"
    
    # Create basic files
    echo "# $project_name" > "$project_path/README.md"
    echo "node_modules/
*.log
.DS_Store" > "$project_path/.gitignore"
    
    print_status "✅ Project created: $project_path"
    
    create_terminal_window "$project_name" "$project_path"
}

# Function to show usage
show_usage() {
    echo "Terminal Window Creator with Folder Mapping"
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -l, --list          List current mappings"
    echo "  -i, --interactive   Interactive mode"
    echo "  -n, --name NAME     Terminal window name"
    echo "  -p, --path PATH     Folder path to map"
    echo
    echo "Examples:"
    echo "  $0 -i                                    # Interactive mode"
    echo "  $0 -n \"MyProject\" -p \"/path/to/project\"   # Direct creation"
    echo "  $0 -l                                    # List mappings"
}

# Interactive mode
interactive_mode() {
    echo
    print_status "🚀 Terminal Window Creator"
    echo
    
    show_quick_options
    
    local choice
    get_input "Select an option (1-7)" choice
    
    handle_quick_option "$choice"
}

# Main function
main() {
    local window_name=""
    local folder_path=""
    local interactive_mode=false
    local list_mode=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -l|--list)
                list_mode=true
                shift
                ;;
            -i|--interactive)
                interactive_mode=true
                shift
                ;;
            -n|--name)
                window_name="$2"
                shift 2
                ;;
            -p|--path)
                folder_path="$2"
                shift 2
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Handle different modes
    if [[ "$list_mode" == true ]]; then
        list_mappings
        exit 0
    fi
    
    if [[ "$interactive_mode" == true ]]; then
        interactive_mode
        exit $?
    fi
    
    # Direct mode - both name and path required
    if [[ -n "$window_name" && -n "$folder_path" ]]; then
        create_terminal_window "$window_name" "$folder_path"
        exit $?
    fi
    
    # If no arguments provided, show usage and enter interactive mode
    if [[ $# -eq 0 ]]; then
        show_usage
        echo
        read -p "Would you like to enter interactive mode? (y/N): " answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            interactive_mode
        fi
    else
        print_error "Both window name and folder path are required for direct mode"
        show_usage
        exit 1
    fi
}

# Run main function
main "$@"