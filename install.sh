#!/bin/sh

# ANSI color codes for colorful output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Define variables
INSTALL_DIR="$HOME/.local/bin"     # Directory to install the script, commonly in PATH for user executables
SCRIPT_NAME="groupgit.sh"          # Name of the script file
LINK_NAME="groupgit"               # Command name you want to use

# Create the install directory if it doesn't exist
mkdir -p "$INSTALL_DIR"

# Check if the script exists in the current directory
if [ ! -f "$SCRIPT_NAME" ]; then
    echo "${RED}Error: ${SCRIPT_NAME} not found in the current directory. Please make sure the script is here.${RESET}"
    exit 1
fi

# Copy the script to the install directory with the desired command name
cp "$SCRIPT_NAME" "$INSTALL_DIR/$LINK_NAME"

# Make the script executable
chmod +x "$INSTALL_DIR/$LINK_NAME"

# Ensure that ~/.local/bin is in the PATH
if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
    # Determine which shell configuration file to update
    if [ -n "$ZSH_VERSION" ]; then
        SHELL_RC="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        SHELL_RC="$HOME/.bashrc"
    else
        SHELL_RC="$HOME/.profile"
    fi

    # Add the directory to the PATH in the shell configuration file
    echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$SHELL_RC"
    echo "${YELLOW}Added $INSTALL_DIR to PATH in $SHELL_RC.${RESET}"
    echo "${CYAN}Restart your terminal or run 'source $SHELL_RC' to update your PATH.${RESET}"
fi

echo "${GREEN}GroupGit installed successfully!${RESET}"
echo "${BLUE}You can now run '${LINK_NAME}' from anywhere in your terminal.${RESET}"
