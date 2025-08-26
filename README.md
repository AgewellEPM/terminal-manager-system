# Terminal Manager System with Hoodrobot Integration

A comprehensive macOS terminal management system with dynamic naming, folder mapping, and Hoodrobot integration.

## 🚀 Features

- **🖥️ Menu Bar Application**: Persistent menu bar interface for quick access
- **📁 Dynamic Terminal Creation**: Create named terminals mapped to specific folders
- **✏️ Batch Renaming**: Rename terminals individually or in batch with patterns
- **🤖 Hoodrobot Integration**: Seamless integration with the Hoodrobot assistive system
- **💾 JSON Persistence**: Maintains terminal mappings and names across sessions
- **🔧 Multiple Interfaces**: GUI app, menu bar app, and command-line tools
- **⚡ Claude Terminal Bridge**: Full interactive terminal control with inter-terminal communication
- **💬 Chat Mode**: Real-time messaging between terminals
- **🎯 Full Terminal Access**: Complete control while maintaining normal shell functionality

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

### 3. Claude Terminal Bridge (`terminal_bridge.sh`)
- **Full interactive terminal control** with `claude` command
- **Inter-terminal messaging** and real-time chat
- **Dynamic terminal naming** and folder mapping
- **Persistent communication** between terminal sessions
- **Chat mode** for real-time collaboration

### 4. Command-Line Tools
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

### Claude Terminal Bridge (NEW!)

```bash
# Enter full terminal control mode
claude

# Direct commands
terminal_bridge.sh name "MyTerminal"    # Name current terminal
terminal_bridge.sh list                 # List all terminals
terminal_bridge.sh send "Target" "Hi!"  # Send message
terminal_bridge.sh check                # Check messages
terminal_bridge.sh chat                 # Enter chat mode
terminal_bridge.sh map                  # Map to folder
```

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

## ⚡ Claude Terminal Bridge - Full Control Mode

The Claude Terminal Bridge gives you **complete terminal control** with inter-terminal communication:

### Entering Claude Mode
```bash
# Type in any terminal to enter full control mode
claude
```

### Interactive Features
- **Press 1**: Name your terminal anything you want
- **Press 2**: List all active terminals with their names and PIDs
- **Press 3**: Send messages to specific terminals
- **Press 4**: Check incoming messages from other terminals
- **Press 5**: Broadcast messages to ALL terminals
- **Press 6**: Quick map terminal to any folder
- **Press 7**: Enter real-time chat mode between terminals

### Chat Mode Commands
- **Normal typing**: Broadcasts to all terminals
- **@TerminalName message**: Send to specific terminal
- **/name NewName**: Rename current terminal on the fly
- **/list**: Show all active terminals
- **/exit**: Leave chat mode

### Example Workflow
```bash
# Terminal 1
claude
# Press 1, name it "Frontend"
# Press 6, map to ~/Projects/frontend

# Terminal 2  
claude
# Press 1, name it "Backend"
# Press 6, map to ~/Projects/backend

# Now they can communicate:
# In Frontend: Press 3, send to "Backend": "Ready to deploy?"
# In Backend: Press 4 to see message and respond
```

## 📝 Examples

### Development Team Setup with Claude Bridge
```bash
# Terminal 1: Setup frontend
claude
# Press 1: Name "Frontend-Dev"
# Press 6: Map to ~/Projects/webapp/frontend
# Press 7: Enter chat mode

# Terminal 2: Setup backend
claude  
# Press 1: Name "Backend-Dev"
# Press 6: Map to ~/Projects/webapp/backend
# Press 7: Enter chat mode

# Now both terminals can chat in real-time while working!
# Type: "Frontend ready for API testing"
# Other terminal sees: "[Frontend-Dev]: Frontend ready for API testing"
```

### Quick Project Setup (Legacy)
```bash
# Create development environment
create-terminal "Frontend" ~/Projects/webapp/frontend
create-terminal "Backend" ~/Projects/webapp/backend
create-terminal "Database" ~/Projects/webapp/db

# Rename for clarity
rename-terminal -a "WebApp-{n}"
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