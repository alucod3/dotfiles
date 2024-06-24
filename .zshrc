# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="/Users/remco/.oh-my-zsh"

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
#ZSH_THEME="robbyrussell"
POWERLEVEL9K_MODE='nerdfont-complete'
ZSH_THEME="powerlevel9k/powerlevel9k"

TERM=xterm-256color

POWERLEVEL9K_CUSTOM_WIFI_SIGNAL="zsh_wifi_signal"
POWERLEVEL9K_CUSTOM_WIFI_SIGNAL_BACKGROUND="black"
POWERLEVEL9K_CUSTOM_WIFI_SIGNAL_FOREGROUND="white"


zsh_wifi_signal(){
        local output=$(/System/Library/PrivateFrameworks/Apple80211.framework/Versions/A/Resources/airport -I)
        local airport=$(echo $output | grep 'AirPort' | awk -F': ' '{print $2}')

        if [ "$airport" = "Off" ]; then
                echo -n "% Wifi Off"
        else
                local speed=$(echo $output | grep 'lastTxRate' | awk -F': ' '{print $2}')
                local color='%F{white}'

                [[ $speed -gt 100 ]] && color='%F{green}'
                [[ $speed -lt 50 ]] && color='%F{red}'

                echo -n "%{$color%} $speed Mb/s%{%f%}" # removed char not in my PowerLine font
        fi
}



POWERLEVEL9K_SHORTEN_DIR_LENGTH=1
POWERLEVEL9K_SHORTEN_STRATEGY="truncate_middle"
POWERLEVEL9K_CONTEXT_DEFAULT_BACKGROUND="000"
POWERLEVEL9K_CONTEXT_DEFAULT_FOREGROUND="007"
POWERLEVEL9K_DIR_HOME_BACKGROUND="001"
POWERLEVEL9K_DIR_HOME_FOREGROUND="000"
POWERLEVEL9K_DIR_HOME_SUBFOLDER_BACKGROUND="001"
POWERLEVEL9K_DIR_HOME_SUBFOLDER_FOREGROUND="000"
POWERLEVEL9K_NODE_VERSION_BACKGROUND="black"
POWERLEVEL9K_NODE_VERSION_FOREGROUND="007"
POWERLEVEL9K_NODE_VERSION_VISUAL_IDENTIFIER_COLOR="002"
POWERLEVEL9K_LOAD_CRITICAL_BACKGROUND="black"
POWERLEVEL9K_LOAD_WARNING_BACKGROUND="black"
POWERLEVEL9K_LOAD_NORMAL_BACKGROUND="black"
POWERLEVEL9K_LOAD_CRITICAL_FOREGROUND="007"
POWERLEVEL9K_LOAD_WARNING_FOREGROUND="007"
POWERLEVEL9K_LOAD_NORMAL_FOREGROUND="007"
POWERLEVEL9K_LOAD_CRITICAL_VISUAL_IDENTIFIER_COLOR="red"
POWERLEVEL9K_LOAD_WARNING_VISUAL_IDENTIFIER_COLOR="yellow"
POWERLEVEL9K_LOAD_NORMAL_VISUAL_IDENTIFIER_COLOR="green"
POWERLEVEL9K_RAM_BACKGROUND="black"
POWERLEVEL9K_RAM_FOREGROUND="007"
POWERLEVEL9K_RAM_VISUAL_IDENTIFIER_COLOR="001"
POWERLEVEL9K_RAM_ELEMENTS=(ram_free)
POWERLEVEL9K_TIME_BACKGROUND="black"
POWERLEVEL9K_TIME_FOREGROUND="007"
POWERLEVEL9K_TIME_FORMAT="%D{%H:%M}"
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=('context' 'dir' 'vcs')
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=('node_version' 'custom_wifi_signal' 'ram' 'time')
POWERLEVEL9K_LEFT_SEGMENT_SEPARATOR=$'\uE0B0'
POWERLEVEL9K_RIGHT_SEGMENT_SEPARATOR=$'\uE0B2'


# Set list of themes to load
# Setting this variable when ZSH_THEME=random
# cause zsh load theme from this variable instead of
# looking in ~/.oh-my-zsh/themes/
# An empty array have no effect
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
export UPDATE_ZSH_DAYS=7

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
    osx
    npm
    git
    web-search
    pip
    zsh-syntax-highlighting
    zsh-autosuggestions
    jsontools
)

source $ZSH/oh-my-zsh.sh

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

 export NVM_DIR=~/.nvm
 [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
