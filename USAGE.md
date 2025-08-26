# Terminal Creator Usage Guide

## Command Line Tool

The `create_mapped_terminal.sh` script provides a command-line interface for creating mapped terminal windows.

### Basic Usage

```bash
./create_mapped_terminal.sh [OPTIONS]
```

### Options

- `-h, --help` - Show help message
- `-i, --interactive` - Interactive mode with menu
- `-l, --list` - List current terminal mappings  
- `-n, --name NAME` - Specify terminal window name
- `-p, --path PATH` - Specify folder path to map

### Interactive Mode

Run with `-i` flag to see quick options:

1. **Home Directory** - Create terminal in home folder
2. **Desktop** - Create terminal on desktop
3. **Documents** - Create terminal in documents
4. **Downloads** - Create terminal in downloads  
5. **Current Directory** - Create terminal in current working directory
6. **Custom Path** - Browse and select any folder
7. **Create New Project** - Create new project structure

### Examples

```bash
# Interactive mode
./create_mapped_terminal.sh -i

# Create specific terminal
./create_mapped_terminal.sh -n "MyApp" -p "/Users/john/Projects/myapp"

# Quick desktop terminal
./create_mapped_terminal.sh -n "Desktop Work" -p "$HOME/Desktop"

# List all mappings
./create_mapped_terminal.sh -l
```

## GUI Applications

### Main Terminal Creator App

- Full-featured GUI with folder browser
- Recent projects list
- Quick action buttons
- Project creation wizard

### Menu Bar App  

- Lives in menu bar for quick access
- Quick action buttons for common folders
- Recent projects dropdown
- Minimal interface for fast terminal creation

## Integration Features

### TinkyBink System Integration

- Automatically updates `~/.tinkybink_terminal_mappings.json`
- Compatible with existing terminal management tools
- Maintains terminal ID to name mappings

### Terminal Window Management

- Sets custom window titles with project indicators
- Format: `[ProjectName] FolderName`
- Preserves terminal session state
- Automatic directory switching

### Project Memory

- Remembers recent projects and folders
- Stores creation timestamps  
- Quick access to frequently used locations
- Persistent across application restarts
