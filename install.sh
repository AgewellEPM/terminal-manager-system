#!/bin/bash

set -e

INSTALL_DIR="$HOME/.terminal_creator"
BIN_DIR="$HOME/.local/bin"

# Create directories
mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"

# Copy files
echo "Installing Terminal Creator..."
cp TerminalCreator "$INSTALL_DIR/"
cp TerminalCreatorMenuBar "$INSTALL_DIR/"
cp create_mapped_terminal.sh "$INSTALL_DIR/"
cp launch_terminal_creator.sh "$INSTALL_DIR/"
cp launch_menu_bar.sh "$INSTALL_DIR/"

# Create symlinks in bin directory
ln -sf "$INSTALL_DIR/create_mapped_terminal.sh" "$BIN_DIR/create-terminal"
ln -sf "$INSTALL_DIR/launch_terminal_creator.sh" "$BIN_DIR/terminal-creator"
ln -sf "$INSTALL_DIR/launch_menu_bar.sh" "$BIN_DIR/terminal-menu"

# Add to PATH if not already there
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
    echo "Added ~/.local/bin to PATH in ~/.zshrc"
    echo "Please run: source ~/.zshrc"
fi

echo "✅ Terminal Creator installed successfully!"
echo
echo "Usage:"
echo "  create-terminal           # Interactive terminal creator"
echo "  terminal-creator          # Full GUI application" 
echo "  terminal-menu             # Menu bar application"
echo
echo "Or run directly from install directory:"
echo "  $INSTALL_DIR/create_mapped_terminal.sh -h"
