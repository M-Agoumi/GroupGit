#!/bin/sh

# ANSI color codes for gradient effect
RED='\033[0;31m'
ORANGE='\033[0;33m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
RESET='\033[0m'

# GroupGit Header
header() {
echo "${RED}   ______                _____ _ _"
echo "${ORANGE}  /   __/___ ___ _ _ ___/   __/_/ /_"
echo "${YELLOW} /  /  /  _/ . / / / . /  /  / /  _/"
echo "${GREEN}/_____/_/ /___/___/  _/_____/_/_/"
echo "${CYAN}                 /_/"
echo "${MAGENTA}        Manage Your Repositories with Ease"
echo "${BLUE}"
}

CONFIG_FILE="repos.txt"  # Configuration file to store repository information

# Function to initialize the configuration file, Git setup, and create an initial commit
init() {
    # Check if the configuration file already exists
    if [ -f "$CONFIG_FILE" ]; then
        echo "${RED}Error:${RESET} Configuration file '${YELLOW}$CONFIG_FILE${RESET}' already exists."
        exit 1
    fi

    # Create the configuration file with a sample repository entry
    echo "# List your repositories here in the format: <name> <repo_url>" > "$CONFIG_FILE"
    echo "SampleRepo https://github.com/user/sample-repo.git" >> "$CONFIG_FILE"
    echo "${GREEN}Initialized configuration file '${YELLOW}$CONFIG_FILE${GREEN}'.${RESET}"
    echo "${CYAN}You can edit this file to add your repositories.${RESET}"

    # Initialize Git if it's not already initialized
    if [ ! -d ".git" ]; then
        git init > /dev/null 2>&1
        echo "${MAGENTA}Initialized Git repository.${RESET}"
    fi

    # Create .gitignore file to ignore everything except the configuration file
    echo "# Ignore everything except the configuration file" > .gitignore
    echo "*" >> .gitignore
    echo "!$CONFIG_FILE" >> .gitignore
    echo "!.gitignore" >> .gitignore
    echo "${BLUE}Created .gitignore to prevent accidental commits of other files.${RESET}"

    # Add the configuration file and .gitignore to the repository
    git add "$CONFIG_FILE" .gitignore

    # Commit the changes with an initial commit message
    git commit -m "Initial commit: Add configuration file and .gitignore" > /dev/null 2>&1
    echo "${GREEN}Initial commit created with '${YELLOW}$CONFIG_FILE${GREEN}' and '.gitignore'.${RESET}"
}

# Function to clone repositories listed in the configuration file
clone() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Configuration file '$CONFIG_FILE' not found. Please run 'init' first."
        exit 1
    fi

    while IFS= read -r line; do
        # Skip lines starting with '#' (comments) or empty lines
        case "$line" in
            \#* | "") continue ;;
        esac

        # Read repository name and URL
        repo_name=$(echo "$line" | awk '{print $1}')
        repo_url=$(echo "$line" | awk '{print $2}')

        if [ -d "$repo_name" ]; then
            echo "Repository '$repo_name' already exists. Skipping clone."
        else
            echo "Cloning '$repo_name' from '$repo_url'..."
            git clone "$repo_url" "$repo_name"
        fi
    done < "$CONFIG_FILE"
}

# Main function to handle user commands
case "$1" in
    init)
        init
        ;;
    clone)
        clone
        ;;
    *)
        header
        echo "Usage: $0 {init|clone}"
        ;;
esac
