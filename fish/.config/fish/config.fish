## Source from conf.d before our fish config
source $HOME/.config/fish/done.fish
source $HOME/.config/fish/shorts.fish
source $HOME/.config/fish/aliasesrc.fish
source $HOME/.config/fish/globle_variables.fish

## Set values
## Run fastfetch as welcome message
function fish_greeting
    fastfetch
end

## Environment setup
# Apply .profile: use this to put fish compatible .profile stuff in
if test -f ~/.fish_profile
    source ~/.fish_profile
end

# Add ~/.local/bin to PATH
if test -d ~/.local/bin
    if not contains -- ~/.local/bin $PATH
        set -p PATH ~/.local/bin
    end
end

# Add depot_tools to PATH
if test -d ~/Applications/depot_tools
    if not contains -- ~/Applications/depot_tools $PATH
        set -p PATH ~/Applications/depot_tools
    end
end

## Functions
# Functions needed for !! and !$ https://github.com/oh-my-fish/plugin-bang-bang
function __history_previous_command
    switch (commandline -t)
        case "!"
            commandline -t $history[1]; commandline -f repaint
        case "*"
            commandline -i !
    end
end

function __history_previous_command_arguments
    switch (commandline -t)
        case "!"
            commandline -t ""
            commandline -f history-token-search-backward
        case "*"
            commandline -i '$'
    end
end

if [ "$fish_key_bindings" = fish_vi_key_bindings ]
    bind -Minsert ! __history_previous_command
    bind -Minsert '$' __history_previous_command_arguments
else
    bind ! __history_previous_command
    bind '$' __history_previous_command_arguments
end

# Fish command history
function history
    builtin history --show-time='%F %T '
end

function bak --argument filename
    cp $filename $filename.bak
end

# Copy DIR1 DIR2
function copy
    set count (count $argv | tr -d \n)
    if test "$count" = 2; and test -d "$argv[1]"
        set from (string trim -r -c / -- $argv[1])
        set to (echo $argv[2])
        command cp -r $from $to
    else
        command cp $argv
    end
end

function ssh
    env TERM=xterm-256color ssh $argv
end

## gallery-dl Reddit setup
# Load environment variables from .env file (called only when needed)
function __load_env_file
    if test -f ~/.env
        for line in (cat ~/.env | grep -v '^#' | grep -v '^\s*$')
            # Handle simple KEY=VALUE pairs (no quotes handling for security)
            set -l parts (string split -m 1 '=' -- $line)
            if test (count $parts) -eq 2
                # Remove leading/trailing whitespace and quotes
                set -l key (string trim -- $parts[1])
                set -l value (string trim -- $parts[2])
                set value (string trim -c '\'"' -- $value)
                set -gx $key $value
            end
        end
    end
end

# Helper function to create Reddit config
function __gallery_dl_create_reddit_config
    # Load .env only when needed
    __load_env_file
    
    # Check if required environment variables are set
    if not set -q REDDIT_ID; or not set -q REDDIT_APP
        echo "Error: REDDIT_ID and REDDIT_APP environment variables must be set in ~/.env" >&2
        return 1
    end
    
    # Create secure temporary file
    set -l temp_config (mktemp)
    chmod 600 $temp_config
    
    # Write config
    echo "{
  \"extractor\": {
    \"reddit\": {
      \"client-id\": \"$REDDIT_ID\",
      \"client-secret\": \"$REDDIT_APP\"
    }
  }
}" > $temp_config
    
    echo $temp_config
end

# Function to run gallery-dl with Reddit credentials from .env
function gallery-dl-reddit
    set -l temp_config (__gallery_dl_create_reddit_config)
    or return 1
    
    gallery-dl --config $temp_config $argv
    set -l exit_code $status
    
    # Cleanup
    rm -f $temp_config
    
    return $exit_code
end

# Function for Reddit OAuth setup
function gallery-dl-reddit-oauth
    set -l temp_config (__gallery_dl_create_reddit_config)
    or return 1
    
    gallery-dl --config $temp_config oauth:reddit
    set -l exit_code $status
    
    # Cleanup
    rm -f $temp_config
    
    return $exit_code
end


# ~/.config/fish/config.fish
if test -f $HOME/.config/fish/starship.toml
    set -x STARSHIP_CONFIG $HOME/.config/fish/starship.toml
else
    set -x STARSHIP_CONFIG $HOME/.config/fish/starship.base.toml
end

## Initialize Starship prompt
zoxide init fish | source
starship init fish | source
