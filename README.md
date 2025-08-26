# Terminal Manager System with Hoodrobot Integration

A comprehensive macOS terminal management system with dynamic naming, folder mapping, and Hoodrobot integration.

## 🚀 Features

- **🖥️ Menu Bar Application**: Persistent menu bar interface for quick access
- **📁 Dynamic Terminal Creation**: Create named terminals mapped to specific folders
- **✏️ Batch Renaming**: Rename terminals individually or in batch with patterns
- **🤖 Hoodrobot Integration**: Seamless integration with the Hoodrobot assistive system
- **💾 JSON Persistence**: Maintains terminal mappings and names across sessions
- **🔧 Multiple Interfaces**: GUI app, menu bar app, and command-line tools

## 📦 Components

### 1. Menu Bar Application (`TerminalManagerMenuBar`)
- Quick Actions for creating terminals (Home, Desktop, Documents, Downloads)
- Terminal management interface
- Dynamic rename capabilities
- Hoodrobot integration when available
- GitHub repository link

### 2. Terminal Creator GUI (`TerminalWindowCreator`)
- SwiftUI interface for terminal creation
- Visual folder browser
- Recent folders tracking
- Project name suggestions

### 3. Command-Line Tools
- `create-terminal`: Create terminals from command line
- `rename-terminal`: Dynamic terminal renaming with interactive menu
- `create_mapped_terminal.sh`: Shell script interface

## 🛠️ Installation

```bash
cd terminal_creator_build
./install.sh
```

This will:
- Build all components
- Install to `~/.terminal_creator/`
- Set up LaunchAgent for auto-start
- Add commands to PATH

## 📖 Usage

### Menu Bar Interface
Click the terminal icon (⌨️) in the menu bar to access:
- Quick Actions (create terminals in common folders)
- Terminal Windows (manage existing terminals)
- Rename Terminals (batch or individual renaming)
- Hoodrobot Integration (when available)

### Command Line Interface

```bash
# Create a new terminal
create-terminal "Project Name" /path/to/folder
create-terminal -i  # Interactive mode

# Rename terminals
rename-terminal                # Interactive mode
rename-terminal "New Name"      # Rename current terminal
rename-terminal -l             # List all terminals
rename-terminal -c             # Rename current window
rename-terminal -a             # Batch rename all windows

# List terminal mappings
create-terminal -l
```

### GUI Application
```bash
terminal-creator  # Launch full GUI app
```

## 🤖 Hoodrobot Integration

When Hoodrobot is running, additional features become available:
- Send terminal content to Hoodrobot
- Quick capture integration
- Synchronized terminal management
- Screenshot and analysis features

## 📁 File Structure

Terminal mappings and configurations are stored in:
- `~/.tinkybink_terminal_mappings.json`: Window ID to name mappings
- `~/.tinkybink_terminal_names.json`: Named terminals with metadata
- `~/Library/Application Support/TerminalCreator/`: Application data
- `~/.terminal_creator/`: Installed binaries

## 🎨 Dynamic Naming Features

The rename system supports:
- **Individual renaming**: Rename specific terminal windows
- **Batch renaming**: Apply patterns to all windows (e.g., "Project-{n}")
- **Current window**: Quick rename of active terminal
- **Persistent names**: Names survive terminal restarts via JSON storage

## ⚙️ System Requirements

- macOS 12.0 or later
- Terminal.app
- jq (for JSON processing - auto-installed if needed)
- Optional: Hoodrobot for advanced integration

## 🔗 Integration Points

### TinkyBink Terminal Management
- Updates `.tinkybink_terminal_mappings.json`
- Maintains `.tinkybink_terminal_names.json`
- Compatible with existing TinkyBink workflows

### Hoodrobot System
- Process communication via signals
- Shared JSON data structures
- Menu bar integration when both systems active

## 📝 Examples

### Quick Project Setup
```bash
# Create development environment
create-terminal "Frontend" ~/Projects/webapp/frontend
create-terminal "Backend" ~/Projects/webapp/backend
create-terminal "Database" ~/Projects/webapp/db

# Rename for clarity
rename-terminal -a "WebApp-{n}"
```

### Interactive Workflow
```bash
# Launch interactive creator
create-terminal -i

# Launch interactive renamer
rename-terminal

# View all terminals
rename-terminal -l
```

## 🐛 Troubleshooting

### Menu bar app not appearing
```bash
launchctl load ~/Library/LaunchAgents/com.terminal.creator.menubar.plist
```

### Commands not found
```bash
source ~/.zshrc
# or
export PATH="$HOME/.terminal_creator:$PATH"
```

### Reset mappings
```bash
rm ~/.tinkybink_terminal_*.json
```

## 📄 License

MIT License

## 👥 Contributors

Terminal Manager System - Part of the TinkyBink and Hoodrobot ecosystem

---

For issues or feature requests, please open an issue on GitHub.