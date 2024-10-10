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
    echo "# Add [groupName] to group a set of repos" >> "$CONFIG_FILE"
    echo "[backend]" >> "$CONFIG_FILE"
    echo "SampleRepo https://github.com/user/sample-repo.git" >> "$CONFIG_FILE"
    echo "[frontend]" >> "$CONFIG_FILE"
    echo "SampleRepoB https://github.com/user/sample-repo-b.git" >> "$CONFIG_FILE"
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

# Function to calculate a basic string distance (alternative to Levenshtein)
string_distance() {
    s1="$1"
    s2="$2"
    dist=0
    len1=${#s1}
    len2=${#s2}

    max_len=$((len1 > len2 ? len1 : len2))

    for i in $(seq 1 "$max_len"); do
        char1=$(echo "$s1" | cut -c"$i")
        char2=$(echo "$s2" | cut -c"$i")

        if [ "$char1" != "$char2" ]; then
            dist=$((dist + 1))
        fi
    done

    echo "$dist"
}

# Function to find close group suggestions
suggest_group() {
    input_group="$1"
    closest_group=""
    closest_distance=999
    group_list=$(grep "^\[" "$CONFIG_FILE" | sed 's/^\[\(.*\)\]$/\1/')  # Extract groups using sed

    for group_name in $group_list; do
        distance=$(string_distance "$input_group" "$group_name")
        if [ "$distance" -lt "$closest_distance" ]; then
            closest_distance="$distance"
            closest_group="$group_name"
        fi
    done

    echo "$closest_group"
}

# Function to check if a group exists
group_exists() {
    group="$1"
    grep -q "^\[$group\]" "$CONFIG_FILE"
}

# Function to clone repositories listed in the configuration file, optionally filtered by group
clone() {
    group_filter="$1"
    in_group=0

    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Configuration file '$CONFIG_FILE' not found. Please run 'init' first."
        exit 1
    fi

    # Check if the group exists
    if [ -n "$group_filter" ] && ! group_exists "$group_filter"; then
        echo "${RED}Error:${RESET} Group '${YELLOW}$group_filter${RESET}' does not exist."
        suggestion=$(suggest_group "$group_filter")
        if [ -n "$suggestion" ]; then
            echo "${CYAN}Did you mean '${GREEN}$suggestion${CYAN}'?${RESET}"
        fi
        exit 1
    fi

    while IFS= read -r line; do
        # Skip lines starting with '#' (comments) or empty lines
        case "$line" in
            \#* | "") continue ;;
        esac

        # Check if this line is a group declaration (e.g., [groupName])
        if echo "$line" | grep -q "^\["; then
            current_group=$(echo "$line" | tr -d '[]')
            if [ "$group_filter" = "$current_group" ]; then
                in_group=1
            else
                in_group=0
            fi
            continue
        fi

        # If in a group and group matches (or no group filter is set), clone the repo
        if [ "$in_group" -eq 1 ] || [ -z "$group_filter" ]; then
            repo_name=$(echo "$line" | awk '{print $1}')
            repo_url=$(echo "$line" | awk '{print $2}')

            if [ -d "$repo_name" ]; then
                echo "Repository '$repo_name' already exists. Skipping clone."
            else
                echo "Cloning '$repo_name' from '$repo_url'..."
                git clone "$repo_url" "$repo_name"
            fi
        fi
    done < "$CONFIG_FILE"
}

# Function to update repositories by pulling the latest changes, optionally filtered by group
update() {
    group_filter="$1"
    in_group=0

    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Configuration file '$CONFIG_FILE' not found. Please run 'init' first."
        exit 1
    fi

    # Check if the group exists
    if [ -n "$group_filter" ] && ! group_exists "$group_filter"; then
        echo "${RED}Error:${RESET} Group '${YELLOW}$group_filter${RESET}' does not exist."
        suggestion=$(suggest_group "$group_filter")
        if [ -n "$suggestion" ]; then
            echo "${CYAN}Did you mean '${GREEN}$suggestion${CYAN}'?${RESET}"
        fi
        exit 1
    fi

    while IFS= read -r line; do
        # Skip lines starting with '#' (comments) or empty lines
        case "$line" in
            \#* | "") continue ;;
        esac

        # Check if this line is a group declaration (e.g., [groupName])
        if echo "$line" | grep -q "^\["; then
            current_group=$(echo "$line" | tr -d '[]')
            if [ "$group_filter" = "$current_group" ]; then
                in_group=1
            else
                in_group=0
            fi
            continue
        fi

        # If in a group and group matches (or no group filter is set), update the repo
        if [ "$in_group" -eq 1 ] || [ -z "$group_filter" ]; then
            repo_name=$(echo "$line" | awk '{print $1}')

            if [ -d "$repo_name" ]; then
                echo "Updating repository '$repo_name'..."
                cd "$repo_name" || exit
                git pull
                cd ..
            else
                echo "Repository '$repo_name' does not exist. Skipping update."
            fi
        fi
    done < "$CONFIG_FILE"
}

# Function to stash changes in repositories, optionally filtered by group
stash() {
    command="$1"       # The second argument to specify the command
    group_filter="$2"  # The first argument for the group filter
    in_group=0

    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Configuration file '$CONFIG_FILE' not found. Please run 'init' first."
        exit 1
    fi

    # If no command is specified, default to 'all'
    if [ "$command" != "view" ]; then
        command="all"
    fi

    # Check if the group exists, but only if a group filter is provided
    if [ -n "$group_filter" ] && ! group_exists "$group_filter"; then
        echo "${RED}Error:${RESET} Group '${YELLOW}$group_filter${RESET}' does not exist."
        suggestion=$(suggest_group "$group_filter")
        if [ -n "$suggestion" ]; then
            echo "${CYAN}Did you mean '${GREEN}$suggestion${CYAN}'?${RESET}"
        fi
        exit 1
    fi

    case "$command" in
        view)
            echo "Repositories with active stashes:"
            while IFS= read -r line; do
                # Skip lines starting with '#' (comments) or empty lines
                case "$line" in
                    \#* | "") continue ;;
                esac

                # Check if this line is a group declaration (e.g., [groupName])
                if echo "$line" | grep -q "^\["; then
                    current_group=$(echo "$line" | tr -d '[]')
                    if [ "$group_filter" = "$current_group" ]; then
                        in_group=1
                    else
                        in_group=0
                    fi
                    continue
                fi

                # If group is specified, check if the repo is in that group
                if [ -n "$group_filter" ] && [ "$in_group" -eq 0 ]; then
                    continue
                fi

                # Check for active stash in the repo
                repo_name=$(echo "$line" | awk '{print $1}')
                if [ -d "$repo_name" ]; then
                    cd "$repo_name" || continue
                    if git stash list | grep -q "stash@{"; then
                        echo " - $repo_name has active changes."
                    fi
                    cd ..
                else
                    echo "Repository '$repo_name' does not exist. Skipping check."
                fi
            done < "$CONFIG_FILE"
            ;;

        all)
            while IFS= read -r line; do
                # Skip lines starting with '#' (comments) or empty lines
                case "$line" in
                    \#* | "") continue ;;
                esac

                # Check if this line is a group declaration (e.g., [groupName])
                if echo "$line" | grep -q "^\["; then
                    current_group=$(echo "$line" | tr -d '[]')
                    if [ "$group_filter" = "$current_group" ]; then
                        in_group=1
                    else
                        in_group=0
                    fi
                    continue
                fi

                # If in a group and group matches (or no group filter is set), stash the changes
                if [ "$in_group" -eq 1 ] || [ -z "$group_filter" ]; then
                    repo_name=$(echo "$line" | awk '{print $1}')
                    if [ -d "$repo_name" ]; then
                        echo "Stashing changes in '$repo_name'..."
                        cd "$repo_name" || exit
                        git stash
                        cd ..
                    else
                        echo "Repository '$repo_name' does not exist. Skipping stash."
                    fi
                fi
            done < "$CONFIG_FILE"
            ;;

        *)
            echo "Invalid stash command. Use 'view' to see stashed repos or 'all' to stash all changes."
            ;;
    esac
}



# Main function to handle user commands
# @todo: upgrade (version using github tags)
case "$1" in
    init)
        init
        ;;
    clone)
        clone "$2"  # Pass the second argument as the group filter
        ;;
    update)
        update "$2"
        ;;
    stash)
        stash "$2" "$3"  # Pass group and subcommand
        ;;
    *)
        header
        echo "Usage: groupgit {init|clone|update|stash [view|all]} [group]"
        ;;
esac

