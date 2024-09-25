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
SCRIPT_NAME="groupgit.sh"          # Name of the script file in GitHub
LINK_NAME="groupgit"               # Command name you want to use
GITHUB_URL="https://raw.githubusercontent.com/M-Agoumi/GroupGit/refs/heads/master/$SCRIPT_NAME"  # URL to download the script

# Create the install directory if it doesn't exist
mkdir -p "$INSTALL_DIR"

# Download the script from GitHub
echo "${CYAN}Downloading $SCRIPT_NAME from GitHub...${RESET}"
curl -sL "$GITHUB_URL" -o "$INSTALL_DIR/$LINK_NAME"

# Check if the download was successful
if [ $? -ne 0 ] || [ ! -f "$INSTALL_DIR/$LINK_NAME" ]; then
    echo "${RED}Error: Failed to download ${SCRIPT_NAME}. Please check your internet connection and the URL.${RESET}"
    exit 1
fi

# Make the script executable
chmod +x "$INSTALL_DIR/$LINK_NAME"

# Detect which shell configuration file to update based on the active shell
if [ -n "$ZSH_VERSION" ] || [ "$(basename "$SHELL")" = "zsh" ]; then
    SHELL_RC="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ] || [ "$(basename "$SHELL")" = "bash" ]; then
    SHELL_RC="$HOME/.bashrc"
else
    SHELL_RC="$HOME/.profile"
fi

# Add the directory to the PATH in the shell configuration file if not already added
if ! grep -qx "export PATH=\"$INSTALL_DIR:\$PATH\"" "$SHELL_RC"; then
    echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$SHELL_RC"
    echo "${YELLOW}Added $INSTALL_DIR to PATH in $SHELL_RC.${RESET}"
    echo "${CYAN}Restart your terminal or run 'source $SHELL_RC' to update your PATH.${RESET}"
else
    echo "${GREEN}$INSTALL_DIR is already in the PATH in $SHELL_RC.${RESET}"
fi

echo "${GREEN}GroupGit installed successfully!${RESET}"
echo "${BLUE}You can now run '${LINK_NAME}' from anywhere in your terminal.${RESET}"
