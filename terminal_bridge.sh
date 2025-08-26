#!/bin/bash

# Terminal Bridge - Full Interactive Terminal Manager
# Allows naming terminals and inter-terminal communication

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Files for communication
BRIDGE_DIR="$HOME/.terminal_bridge"
TERMINAL_REGISTRY="$BRIDGE_DIR/terminals.json"
MESSAGE_QUEUE="$BRIDGE_DIR/messages"
CURRENT_TERMINAL="$BRIDGE_DIR/current_$$"

# Create bridge directory
mkdir -p "$BRIDGE_DIR"
mkdir -p "$MESSAGE_QUEUE"

# Get or set terminal name
get_terminal_name() {
    if [[ -f "$CURRENT_TERMINAL" ]]; then
        cat "$CURRENT_TERMINAL"
    else
        echo "Terminal_$$"
    fi
}

# Set terminal name
set_terminal_name() {
    local name="$1"
    echo "$name" > "$CURRENT_TERMINAL"
    
    # Update Terminal.app title
    if [[ -n "$TERM_SESSION_ID" ]]; then
        printf "\033]0;%s\007" "$name"
    fi
    
    # Register in JSON
    if command -v jq &> /dev/null; then
        local registry="{}"
        [[ -f "$TERMINAL_REGISTRY" ]] && registry=$(cat "$TERMINAL_REGISTRY")
        registry=$(echo "$registry" | jq ". + {\"$name\": {\"pid\": $$, \"created\": \"$(date -Iseconds)\", \"active\": true}}")
        echo "$registry" > "$TERMINAL_REGISTRY"
    fi
    
    echo -e "${GREEN}✓${NC} Terminal renamed to: ${CYAN}$name${NC}"
}

# List all active terminals
list_terminals() {
    echo -e "\n${CYAN}Active Terminals:${NC}"
    echo "────────────────────────────"
    
    if [[ -f "$TERMINAL_REGISTRY" ]] && command -v jq &> /dev/null; then
        jq -r 'to_entries[] | "\(.key) (PID: \(.value.pid))"' "$TERMINAL_REGISTRY" 2>/dev/null | while read line; do
            echo -e "  ${GREEN}►${NC} $line"
        done
    else
        echo "  No terminals registered"
    fi
    echo
}

# Send message to another terminal
send_to_terminal() {
    local target="$1"
    local message="$2"
    
    if [[ -z "$target" ]] || [[ -z "$message" ]]; then
        echo -e "${RED}Usage:${NC} send <terminal_name> <message>"
        return 1
    fi
    
    local sender=$(get_terminal_name)
    local msg_file="$MESSAGE_QUEUE/${target}_$(date +%s%N)"
    
    echo "{\"from\": \"$sender\", \"to\": \"$target\", \"message\": \"$message\", \"time\": \"$(date -Iseconds)\"}" > "$msg_file"
    
    echo -e "${GREEN}✓${NC} Message sent to ${CYAN}$target${NC}"
}

# Check for messages
check_messages() {
    local my_name=$(get_terminal_name)
    local found=0
    
    for msg_file in "$MESSAGE_QUEUE"/${my_name}_*; do
        if [[ -f "$msg_file" ]]; then
            if command -v jq &> /dev/null; then
                local from=$(jq -r '.from' "$msg_file" 2>/dev/null)
                local message=$(jq -r '.message' "$msg_file" 2>/dev/null)
                local time=$(jq -r '.time' "$msg_file" 2>/dev/null | cut -d'T' -f2 | cut -d'-' -f1)
                
                echo -e "\n${YELLOW}📬 Message from ${CYAN}$from${NC} ${YELLOW}at $time:${NC}"
                echo -e "   ${message}"
                found=1
            fi
            rm "$msg_file"
        fi
    done
    
    if [[ $found -eq 0 ]]; then
        echo -e "${BLUE}No new messages${NC}"
    fi
}

# Broadcast to all terminals
broadcast() {
    local message="$1"
    local sender=$(get_terminal_name)
    
    if [[ -z "$message" ]]; then
        echo -e "${RED}Usage:${NC} broadcast <message>"
        return 1
    fi
    
    if [[ -f "$TERMINAL_REGISTRY" ]] && command -v jq &> /dev/null; then
        jq -r 'keys[]' "$TERMINAL_REGISTRY" 2>/dev/null | while read terminal; do
            if [[ "$terminal" != "$sender" ]]; then
                send_to_terminal "$terminal" "$message" &>/dev/null
            fi
        done
        echo -e "${GREEN}✓${NC} Broadcast sent to all terminals"
    fi
}

# Interactive mode
interactive_mode() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}    Terminal Bridge - Interactive Mode    ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
    
    local current_name=$(get_terminal_name)
    echo -e "\n${GREEN}Current Terminal:${NC} $current_name"
    
    while true; do
        echo -e "\n${YELLOW}Commands:${NC}"
        echo "  1) Name this terminal"
        echo "  2) List all terminals"
        echo "  3) Send message to terminal"
        echo "  4) Check messages"
        echo "  5) Broadcast to all"
        echo "  6) Quick terminal mapper"
        echo "  7) Terminal chat mode"
        echo "  8) Exit"
        
        read -p "$(echo -e ${CYAN}Choose [1-8]: ${NC})" choice
        
        case $choice in
            1)
                read -p "Enter new name: " new_name
                set_terminal_name "$new_name"
                ;;
            2)
                list_terminals
                ;;
            3)
                list_terminals
                read -p "Send to terminal: " target
                read -p "Message: " msg
                send_to_terminal "$target" "$msg"
                ;;
            4)
                check_messages
                ;;
            5)
                read -p "Broadcast message: " msg
                broadcast "$msg"
                ;;
            6)
                quick_mapper
                ;;
            7)
                chat_mode
                ;;
            8)
                echo -e "${GREEN}Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option${NC}"
                ;;
        esac
    done
}

# Quick terminal mapper
quick_mapper() {
    echo -e "\n${CYAN}Quick Terminal Mapper${NC}"
    echo "──────────────────────"
    
    read -p "Terminal name: " name
    read -p "Map to folder (or press Enter for current): " folder
    
    if [[ -z "$folder" ]]; then
        folder=$(pwd)
    fi
    
    set_terminal_name "$name"
    cd "$folder"
    
    echo -e "${GREEN}✓${NC} Terminal '${CYAN}$name${NC}' mapped to: $folder"
}

# Chat mode - continuous messaging
chat_mode() {
    echo -e "\n${CYAN}Terminal Chat Mode${NC}"
    echo "──────────────────"
    echo "Commands: /list, /name <name>, /exit"
    echo
    
    local my_name=$(get_terminal_name)
    echo -e "Chatting as: ${GREEN}$my_name${NC}"
    
    # Background message checker
    (
        while true; do
            sleep 2
            for msg_file in "$MESSAGE_QUEUE"/${my_name}_*; do
                if [[ -f "$msg_file" ]]; then
                    if command -v jq &> /dev/null; then
                        local from=$(jq -r '.from' "$msg_file" 2>/dev/null)
                        local message=$(jq -r '.message' "$msg_file" 2>/dev/null)
                        echo -e "\r\033[K${YELLOW}[$from]:${NC} $message"
                        echo -n "> "
                    fi
                    rm "$msg_file"
                fi
            done
        done
    ) &
    local checker_pid=$!
    
    while true; do
        read -p "> " input
        
        if [[ "$input" == "/exit" ]]; then
            kill $checker_pid 2>/dev/null
            break
        elif [[ "$input" == "/list" ]]; then
            list_terminals
        elif [[ "$input" =~ ^/name ]]; then
            local new_name="${input#/name }"
            set_terminal_name "$new_name"
            my_name="$new_name"
        elif [[ "$input" =~ ^@.* ]]; then
            # Direct message format: @terminal message
            local target=$(echo "$input" | cut -d' ' -f1 | tr -d '@')
            local msg=$(echo "$input" | cut -d' ' -f2-)
            send_to_terminal "$target" "$msg" &>/dev/null
        else
            # Broadcast to all
            broadcast "$input" &>/dev/null
        fi
    done
}

# Main command handler
case "${1:-}" in
    name)
        set_terminal_name "$2"
        ;;
    list)
        list_terminals
        ;;
    send)
        send_to_terminal "$2" "$3"
        ;;
    check)
        check_messages
        ;;
    broadcast)
        broadcast "$2"
        ;;
    chat)
        chat_mode
        ;;
    map)
        quick_mapper
        ;;
    claude)
        # Special Claude mode - enhanced terminal management
        echo -e "${MAGENTA}Claude Terminal Mode Activated${NC}"
        interactive_mode
        ;;
    *)
        # Default to interactive mode
        interactive_mode
        ;;
esac

# Cleanup on exit
trap "rm -f $CURRENT_TERMINAL" EXIT