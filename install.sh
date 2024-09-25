#!/bin/sh

# ANSI color codes for colorful output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Define variables
DEFAULT_INSTALL_DIR="$HOME/.local/bin"     # Default directory to install the script
FALLBACK_INSTALL_DIR="$HOME/bin"           # Fallback directory if default is not writable
SCRIPT_NAME="groupgit.sh"                  # Name of the script file in GitHub
LINK_NAME="groupgit"                       # Command name you want to use
GITHUB_URL="https://raw.githubusercontent.com/M-Agoumi/GroupGit/refs/heads/master/$SCRIPT_NAME"  # URL to download the script

# Function to attempt installation in a given directory
install_script() {
    local install_dir="$1"

    # Create the install directory if it doesn't exist
    mkdir -p "$install_dir" 2>/dev/null

    # Check if the directory is writable
    if [ ! -w "$install_dir" ]; then
        echo "${RED}Error: Cannot write to $install_dir.${RESET}"
        return 1
    fi

    # Download the script from GitHub
    echo "${CYAN}Downloading $SCRIPT_NAME from GitHub...${RESET}"
    curl -sL "$GITHUB_URL" -o "$install_dir/$LINK_NAME"

    # Check if the download was successful
    if [ $? -ne 0 ] || [ ! -f "$install_dir/$LINK_NAME" ]; then
        echo "${RED}Error: Failed to download ${SCRIPT_NAME}. Please check your internet connection and the URL.${RESET}"
        return 1
    fi

    # Make the script executable
    chmod +x "$install_dir/$LINK_NAME"

    echo "${GREEN}GroupGit installed successfully in $install_dir!${RESET}"
    echo "${BLUE}You can now run '${LINK_NAME}' from anywhere in your terminal.${RESET}"

    # Ensure that the install directory is in the PATH
    if ! echo "$PATH" | grep -q "$install_dir"; then
        if [ -n "$ZSH_VERSION" ] || [ "$(basename "$SHELL")" = "zsh" ]; then
            SHELL_RC="$HOME/.zshrc"
        elif [ -n "$BASH_VERSION" ] || [ "$(basename "$SHELL")" = "bash" ]; then
            SHELL_RC="$HOME/.bashrc"
        else
            SHELL_RC="$HOME/.profile"
        fi

        # Add the directory to the PATH in the shell configuration file if not already added
        if ! grep -qx "export PATH=\"$install_dir:\$PATH\"" "$SHELL_RC"; then
            echo "export PATH=\"$install_dir:\$PATH\"" >> "$SHELL_RC"
            echo "${YELLOW}Added $install_dir to PATH in $SHELL_RC.${RESET}"
            echo "${CYAN}Restart your terminal or run 'source $SHELL_RC' to update your PATH.${RESET}"
        else
            echo "${GREEN}$install_dir is already in the PATH in $SHELL_RC.${RESET}"
        fi
    fi
    return 0
}

# Try to install in the default directory first
if ! install_script "$DEFAULT_INSTALL_DIR"; then
    # If installation in the default directory fails, try the fallback directory
    if ! install_script "$FALLBACK_INSTALL_DIR"; then
        # If both attempts fail, prompt the user to use sudo to install in the default directory
        echo "${RED}Both user-writable paths failed. Attempting installation with sudo...${RESET}"
        sudo mkdir -p "$DEFAULT_INSTALL_DIR" && sudo curl -sL "$GITHUB_URL" -o "$DEFAULT_INSTALL_DIR/$LINK_NAME" && sudo chmod +x "$DEFAULT_INSTALL_DIR/$LINK_NAME"

        if [ $? -eq 0 ]; then
            echo "${GREEN}GroupGit installed successfully with elevated permissions in $DEFAULT_INSTALL_DIR!${RESET}"
        else
            echo "${RED}Failed to install even with elevated permissions. Please check your system permissions.${RESET}"
            exit 1
        fi
    fi
fi
