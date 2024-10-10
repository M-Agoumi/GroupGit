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

CONFIG_FILE="repos.txt"

# Print error message and exit
error_exit() {
    echo "${RED}Error:${RESET} $1" >&2
    exit 1
}

# Print warning message
warn() {
    echo "${YELLOW}Warning:${RESET} $1" >&2
}

# Print success message
success() {
    echo "${GREEN}Success:${RESET} $1"
}

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

# Parse configuration file and return repository information
parse_config() {
    local group_filter="$1"
    local callback="$2"
    shift 2  # Remove first two arguments
    local callback_args="$*"  # Collect remaining arguments
    local current_group=""
    local in_group=0

    [ ! -f "$CONFIG_FILE" ] && error_exit "Configuration file '$CONFIG_FILE' not found. Please run 'init' first."

    # Check if the group exists when filter is provided
    if [ -n "$group_filter" ] && ! grep -q "^\[$group_filter\]" "$CONFIG_FILE"; then
        local suggestion
        suggestion=$(suggest_group "$group_filter")
        error_exit "Group '${YELLOW}$group_filter${RESET}' does not exist.\n${CYAN}Did you mean '${GREEN}$suggestion${CYAN}'?${RESET}"
    fi

    while IFS= read -r line; do
        # Skip comments and empty lines
        case "$line" in
            \#* | "") continue ;;
        esac

        # Handle group declarations
        if echo "$line" | grep -q "^\["; then
            current_group=$(echo "$line" | tr -d '[]')
            if [ "$group_filter" = "$current_group" ]; then
                in_group=1
            else
                in_group=0
            fi
            continue
        fi

        # Process repository if in correct group or no group filter
        if [ "$in_group" -eq 1 ] || [ -z "$group_filter" ]; then
            local repo_name repo_url
            repo_name=$(echo "$line" | awk '{print $1}')
            repo_url=$(echo "$line" | awk '{print $2}')
            $callback "$repo_name" "$repo_url" "$current_group" $callback_args
        fi
    done < "$CONFIG_FILE"
}

# String distance calculation for suggestions
string_distance() {
    local s1="$1" s2="$2" dist=0
    local len1=${#s1} len2=${#s2}
    local max_len=$((len1 > len2 ? len1 : len2))

    for i in $(seq 1 "$max_len"); do
        [ "$(echo "$s1" | cut -c"$i")" != "$(echo "$s2" | cut -c"$i")" ] && dist=$((dist + 1))
    done
    echo "$dist"
}

# Find closest matching group name
suggest_group() {
    local input_group="$1"
    local closest_group="" closest_distance=999
    local group_list
    group_list=$(grep "^\[" "$CONFIG_FILE" | sed 's/^\[\(.*\)\]$/\1/')

    for group_name in $group_list; do
        local distance
        distance=$(string_distance "$input_group" "$group_name")
        if [ "$distance" -lt "$closest_distance" ]; then
            closest_distance="$distance"
            closest_group="$group_name"
        fi
    done
    echo "$closest_group"
}

# Initialize repository configuration
init() {
    [ -f "$CONFIG_FILE" ] && error_exit "Configuration file '${YELLOW}$CONFIG_FILE${RESET}' already exists."

    # Create configuration file
    cat > "$CONFIG_FILE" << EOF
# List your repositories here in the format: <name> <repo_url>
# Add [groupName] to group a set of repos
[backend]
SampleRepo https://github.com/user/sample-repo.git
[frontend]
SampleRepoB https://github.com/user/sample-repo-b.git
EOF

    # Initialize Git repository
    if [ ! -d ".git" ]; then
        git init > /dev/null 2>&1
        success "Initialized Git repository."
    fi

    # Create .gitignore
    cat > .gitignore << EOF
# Ignore everything except the configuration file
*
!$CONFIG_FILE
!.gitignore
EOF

    # Initial commit
    git add "$CONFIG_FILE" .gitignore
    git commit -m "Initial commit: Add configuration file and .gitignore" > /dev/null 2>&1
    success "Initialized configuration in '${YELLOW}$CONFIG_FILE${GREEN}'."
}

# Clone callback for parse_config
clone_repo() {
    local repo_name="$1"
    local repo_url="$2"

    if [ -d "$repo_name" ]; then
        warn "Repository '$repo_name' already exists. Skipping clone."
    else
        echo "Cloning '$repo_name' from '$repo_url'..."
        git clone "$repo_url" "$repo_name"
    fi
}

# Update callback for parse_config
update_repo() {
    local repo_name="$1"

    if [ -d "$repo_name" ]; then
        echo "Updating repository '$repo_name'..."
        (cd "$repo_name" && git pull)
    else
        warn "Repository '$repo_name' does not exist. Skipping update."
    fi
}

# Stash callback for parse_config
stash_repo() {
    local repo_name="$1"
    local repo_url="$2"
    local group="$3"
    local stash_command="$4"

    if [ ! -d "$repo_name" ]; then
        warn "Repository '$repo_name' does not exist. Skipping stash."
        return
    fi

    case "$stash_command" in
        view)
            (cd "$repo_name" &&
             if git stash list | grep -q "stash@{"; then
                 echo " - $repo_name has active changes."
             fi)
            ;;
        all)
            echo "Stashing changes in '$repo_name'..."
            (cd "$repo_name" && git stash)
            ;;
        *)
            error_exit "Invalid stash command. Use 'view' or 'all'."
            ;;
    esac
}

# Main command handler
# @todo: upgrade (version using github tags)
main() {
    case "$1" in
        init)
            init
            ;;
        clone)
            parse_config "$2" clone_repo
            ;;
        update)
            parse_config "$2" update_repo
            ;;
        stash)
            local command="${2:-all}"
            [ "$command" = "view" ] || command="all"
            parse_config "$3" stash_repo "$command"
            ;;
        *)
            header
            echo "Usage: groupgit {init|clone|update|stash [view|all]} [group]"
            ;;
    esac
}

main "$@"