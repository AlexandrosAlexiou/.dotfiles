#!/usr/bin/env bash

# This script provides an easy way to install my preferred packages along with my configurations.
# Author: Tsakiris Tryfon
# Modified: Alexandros Alexiou

# --------------------------------------------- Disable Shellcheck Rules -----------------------------------------------
# shellcheck disable=SC2155
# SC2155: Declare and assign separately to avoid masking return values.

# -------------------------------------------- Generic Script Variables ------------------------------------------------

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# --------------------------------------------- Whiptail Size variables ------------------------------------------------

SIZE=$(stty size)
ROWS=$(stty size | cut -d ' ' -f 1)

# -------------------------------------------------- Font Commands -----------------------------------------------------

bold=$(tput bold)
red_fg=$(tput setaf 1)
white_fg=$(tput setaf 7)
black_bg=$(tput setab 0)
reset=$(tput sgr0)
# ---------------------------------------------------- Symbols ---------------------------------------------------------

thunder="⚡"
bullet="•"

# ---------------------------------------------------- Functions -------------------------------------------------------

function _check_file() {
    if [ ! -f "$1" ]; then
        echo "${bold}${red_fg}Error${reset}: cannot find ${1} in this directory."
        echo "You should run the installer from within the github repository."
        exit 1
    fi
}

function _check_dir() {
    if [ ! -d "$1" ]; then
        echo "${bold}${red_fg}Error${reset}: cannot find ${1} in this directory."
        echo "You should run the installer from within the github repository."
        exit 1
    fi
}

function _create_dir_if_not_exists() {
    [ ! -d "$1" ] && mkdir -p "$1"
}

function _print_cmd_version() {
    "$1" --version | grep -m1 -Po "(\d+\.)?(\d+\.)(\d+)?( ?\(\w+\))?"
}

function _install() {
    brew install "$@" > /dev/null
}

function _update() {
    sudo apt-get -qq update
}

# Checks whether the provided command exists or not
function _check_command() {
    command -v "$1" > /dev/null 2>&1
}

# Checks whether one or more packages are present and if not install them
function _ensure_installed() {
    local missing_packages=()

    for cmd in "$@"; do
        if ! brew ls --versions "$cmd" > /dev/null 2>&1; then
            missing_packages+=("$cmd")
        fi
    done

    if [ ${#missing_packages[@]} -eq 0 ]; then
        return
    fi

    for package in "${missing_packages[@]}"; do
        echo "${black_bg}${thunder} Installing ${bold}${red_fg}$package${reset} ..."
        if _install "$package"; then
            echo "${black_bg}${thunder} Installation of ${bold}${red_fg}$package${reset} successful!"
        else
            echo "${bold}${red_fg} Failed to install $package.${reset}"
        fi
    done
}

function _reboot() {
    echo "${black_bg}${bold}It is recommended to ${red_fg}reboot${white_fg} after a fresh installation" \
        "of the packages and configurations.${reset}"
    read -n 1 -r -p "Would you like to reboot? [Y/n] " input
    if [[ "$input" =~ ^([yY])$ ]]; then
        sudo shutdown -r now
    fi
}

function _print() {
    local action
    if [ $# -gt 1 ]; then
        case "$1" in
            "s") action="Setting" ;;
            "i") action="Installing" ;;
            "c") action="Changing" ;;
            "u") action="Updating" ;;
            "info") action="Info:" ;;
        esac
        echo -en "${black_bg}⚡ ${action} ${bold}${red_fg}${*:2:1}${reset}"
        echo -e "${black_bg}${*:3} ...${reset}"
    fi
}

function _git_config() {
    _check_file git/gitconfig
    _print s ".gitconfig"
}

function _zshrc() {
    _check_file zsh/zshrc
    _print s ".zshrc"
    /opt/homebrew/bin/gln -sv --backup=numbered "${SCRIPT_DIR}/zsh/zshrc" "$HOME"/.zshrc
}

function _zsh_aliases() {
    _check_file zsh/zsh_aliases
    _print s ".zsh_aliases"
    /opt/homebrew/bin/gln -sv --backup=numbered "${SCRIPT_DIR}/zsh/zsh_aliases" "$HOME"/.zsh_aliases
}

function _zsh_functions() {
    _check_file zsh/zsh_functions
    _print s ".zsh_functions"
    /opt/homebrew/bin/gln -sv --backup=numbered "${SCRIPT_DIR}/zsh/zsh_functions" "$HOME"/.zsh_functions
}

function _zsh_forgit() {
    _check_file zsh/forgit.zsh
    _print s ".forgit.zsh"
    /opt/homebrew/bin/gln -sv --backup=numbered "${SCRIPT_DIR}/zsh/forgit.zsh" "$HOME"/.forgit.zsh
}

function _zsh_plugins() {
    _print i "zsh plugins"

    local zsh_custom="$HOME/.oh-my-zsh/custom"

    function _install_zsh_plugin() {
        if [ $# -ne 2 ]; then
            echo "Expected two arguments. Provided $# argument(s)."
            return
        fi

        local repo=$1
        local target_dir=$zsh_custom/$2
        [ ! -d "$target_dir" ] && git clone --quiet --depth=1 "$repo" "$target_dir"
    }

    _install_zsh_plugin https://github.com/romkatv/powerlevel10k.git themes/powerlevel10k
    _install_zsh_plugin https://github.com/zsh-users/zsh-autosuggestions plugins/zsh-autosuggestions
    _install_zsh_plugin https://github.com/zdharma-continuum/fast-syntax-highlighting plugins/fast-syntax-highlighting
    _install_zsh_plugin https://github.com/wfxr/forgit.git plugins/forgit
    _install_zsh_plugin https://github.com/tamcore/autoupdate-oh-my-zsh-plugins plugins/autoupdate
    _install_zsh_plugin https://github.com/reegnz/jq-zsh-plugin.git plugins/jq
}

function _oh_my_zsh() {
    _print i "oh-my-zsh" ": framework for managing zsh configuration"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended > /dev/null 2>&1
    _zsh_plugins
    _zshrc
}

function set_homebrew_launchctl() {
    # add homebrew to launchctl path for Finder-launched applications
    path=$(launchctl getenv PATH)
    launchctl setenv PATH "/opt/homebrew/bin":"$path"
}

function _set_repo_hooks() {
    _ensure_installed pre-commit

    _print i "Installing hooks"

    local hooks_destination=".git/hooks"
    cp "hooks/check-added-files-nvim.sh" "$hooks_destination"

    pushd hooks > /dev/null || return
    pre-commit install
    popd > /dev/null || return
}

function _set_preferences() {
    # Set key repeat speed
    defaults write -g InitialKeyRepeat -int 15             # normal minimum is 15 (225 ms)
    defaults write -g KeyRepeat -int 2                     # normal minimum is 2 (30 ms)
    defaults write -g ApplePressAndHoldEnabled -bool false # Disable press-and-hold for keys in favor of key repeat
    _print info "System Preferences are set" ": the changes aren't applied until you log out and back in"
}

function _install_from_brewfile() {
    _print info "Installing using Brewfile"
    brew bundle install
}

function _install_from_app_store() {
    _ensure_installed mas

    apps=(
        Amphetamine
        Xcode
    )

    for i in "${apps[@]}"; do
        _print i "$i"
        mas lucky "$i"
    done
}

function _check_nvim_config_requirements() {
    _ensure_installed make
    _ensure_installed luarocks
    _ensure_installed node
}

function _nvim_config() {
    _print s "neovim configuration"
    _check_dir nvim

    local config_path="$HOME/.config"

    # Check nvim requirements
    echo -e "    ${bullet} Checking LSP server requirements ..."
    _check_nvim_config_requirements

    # Make symbolic links to the whole nvim directory in the target directory
    echo -e "    ${bullet} Creating symbolic link to '$config_path/nvim' ..."
    gln -sf "${SCRIPT_DIR}/nvim" "$config_path"

    # Make sure to install Lazy and update the plugins
    # TODO: Perhaps I should use the lazy-lock file here and restore?
    echo -e "    ${bullet} Syncing neovim plugins ..."
    /usr/bin/env nvim --headless -c "Lazy! sync" -c "quitall" > /dev/null
}

function _neovide() {
    _print i "neovide" ": No Nonsense Neovim Client in Rust"
    # install Neovide but ignore the neovim dependency
    # Neovide will use the one installed from _nvim_from_source
    brew install neovide --cask --ignore-dependencies neovim
}

function _neovide_config() {
    local file="neovide/config.toml"
    _check_file "$file"
    _print s "Neovide config"
    local destination="$HOME/.config/neovide/"
    _create_dir_if_not_exists "$destination"
    gln -sv --backup=numbered "${SCRIPT_DIR}/$file" "$destination/$(basename $file)"
}

function _luacheck() {
    _print i "luacheck" ": Static analysis tool and linter for Lua"
    _ensure_installed luarocks
    luarocks install luacheck
}

function _stylua() {
    _print i "stylua" ": An opiniated Lua formatter"
    # Check dependencies
    _ensure_installed unzip
    # TODO: Since this logic is repeating extract only the url logic to a function?
    # Download latest zip from GitHub releases
    local repo="https://api.github.com/repos/JohnnyMorganz/StyLua/releases/latest"
    local url=$(curl -s "$repo" | grep "browser_download_url" | grep "macos" | cut -d '"' -f 4)
    local download_dir=$(mktemp -d)
    local filename=$(basename "$url")
    local file="$download_dir/stylua"
    wget -qO "$download_dir/$filename" "$url" && unzip -q "$download_dir/$filename" -d "$download_dir"
    [ -f "$file" ] && chmod u+x "$file" && sudo mv "$file" /usr/local/bin
}

function _bat_config() {
    _check_file bat/config
    _print s "bat config"
    local destination="$HOME/.config/bat"
    _create_dir_if_not_exists "$destination"
    ln -sv --backup=numbered "${SCRIPT_DIR}/bat/config" "${destination}/config"
}

function _rg_config() {
    _check_file rg/config
    _print s "ripgrep config"
    local destination="$HOME/.config/rg"
    _create_dir_if_not_exists "$destination"
    /opt/homebrew/bin/gln -sv --backup=numbered "${SCRIPT_DIR}/rg/config" "${destination}/config"
}

function _kitty() {
    _print i "kitty" ": the fast, featureful, GPU based terminal emulator"

    curl -sSL https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin launch=n > /dev/null 2>&1
    sudo ln -svf "$HOME"/.local/kitty.app/bin/kitty /usr/local/bin/

    # Place the kitty.desktop file somewhere it can be found
    cp -v ~/.local/kitty.app/share/applications/kitty.desktop ~/.local/share/applications/

    # Update the path to the kitty icon in the kitty.desktop file
    sed -i "s|Icon=kitty|Icon=/home/$USER/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|g" \
        ~/.local/share/applications/kitty.desktop

    # ImageMagick is required by kitty in order to use `icat`
    _install imagemagick
}

function _kitty_config() {
    _check_file kitty/kitty.conf
    _check_file kitty/kitty.png
    _print s "kitty.conf"
    local destination="$HOME/.config/kitty"
    _create_dir_if_not_exists "$destination"
    /opt/homebrew/bin/gln -sv --backup=numbered "${SCRIPT_DIR}/kitty/kitty.conf" "$destination/kitty.conf"
    cp -v kitty/*.png "$destination/"
    _kitty_themes
}

function _kitty_themes() {
    _check_dir kitty/themes/
    local destination="$HOME/.config/kitty/themes"
    _create_dir_if_not_exists "$destination"
    /opt/homebrew/bin/gln -sv --backup=numbered "${SCRIPT_DIR}/kitty/themes/carbonfox.conf" "$destination/"
}

function _wezterm_config() {
    _check_dir wezterm
    _print s "wezterm configuration"

    local destination="$HOME/.config/wezterm/"
    _create_dir_if_not_exists "$destination"

    gcp -avsfT "${SCRIPT_DIR}/wezterm/" "$destination"
}

function _ghostty_config() {
    _check_command ghostty

    _check_dir ghostty
    _print s "Ghostty configuration"

    local destination="$HOME/Library/Application Support/com.mitchellh.ghostty/config"
    _create_dir_if_not_exists "$(dirname "$destination")"

    gcp -avsfT "${SCRIPT_DIR}/ghostty/config" "$destination"
}

function _ghostty_themes() {
    check_command ghostty
    _check_dir ghostty/themes/
    local destination="/Applications/Ghostty.app/Contents/Resources/ghostty/themes"

    /opt/homebrew/bin/gln -sv --backup=numbered "${SCRIPT_DIR}/ghostty/themes/Carbonfox" "$destination/"
}

function _download_nerd_fonts() {
    local fonts=("CascadiaMono" "JetBrainsMono")
    local fonts_pattern=$(
        IFS='|'
        echo "${fonts[*]}"
    )
    local repo="https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest"
    local assets=$(curl -sSL "$repo" | grep -E "browser_download_url.*\.tar\.xz" | grep -E "$fonts_pattern" | cut -d '"' -f 4)

    # Takes care of downloading, and properly extracting the fonts contents
    while IFS= read -r asset; do
        local font=$(basename "$asset")
        local directory="fonts/${font%%.*}" # Remove '.' extensions from font name
        curl -sSLO "$asset" && mkdir "$directory" && tar xf "$font" -C "$directory"
    done <<< "$assets"
}

function _download_codicons() {
    local repo="https://api.github.com/repos/microsoft/vscode-codicons/releases/latest"
    local asset=$(curl -sSL "$repo" | grep -E "tarball_url" | cut -d '"' -f 4)
    local font=$(basename "$asset")
    local directory="fonts/Codicons"
    curl -sSLO "$asset" && mkdir $directory && tar xf "$font" -C "$directory" "**/codicon.ttf"
}

function _install_fonts() {
    _print i "fonts"

    pushd "$(mktemp -d)" > /dev/null || return

    # Create the directory to store fonts
    mkdir fonts

    # Download required fonts
    _download_nerd_fonts
    _download_codicons

    # Copy and install all fonts
    cp -r fonts "$HOME/Library/Fonts"

    popd > /dev/null || return
}

function _install_tinkertool() {
    _ensure_installed curl pup awk
    echo "${black_bg}${thunder} Installing ${bold}${red_fg}TinkerTool: application that gives you access to additional preference settings Apple has built into macOS.${reset} ..."
    download_page_html=$(curl -s 'https://www.bresink.com/osx/0TinkerTool/download.php')
    post_url=$(echo "$download_page_html" | pup -p 'form attr{action}')
    form_attributes=$(echo "$download_page_html" | pup 'input attr{value}')

    # Use sed to capture each attribute into separate variables
    download=$(echo "$form_attributes" | sed -n '1p')
    key1=$(echo "$form_attributes" | sed -n '2p')
    key2=$(echo "$form_attributes" | sed -n '3p')
    key3=$(echo "$form_attributes" | sed -n '4p')

    # Authenticate ourselves to the webserver and receive the cookies
    authenticate_command="curl -s '${post_url}' -c /tmp/cookies.txt -X POST -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:109.0) Gecko/20100101 Firefox/112.0' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8' -H 'Accept-Language: en-GB,en;q=0.5' -H 'Accept-Encoding: gzip, deflate, br' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Origin: https://www.bresink.com' -H 'Connection: keep-alive' -H 'Referer: https://www.bresink.com/' -H 'Upgrade-Insecure-Requests: 1' -H 'Sec-Fetch-Dest: document' -H 'Sec-Fetch-Mode: navigate' -H 'Sec-Fetch-Site: cross-site' -H 'Sec-Fetch-User: ?1' --data-raw 'Download=${download}&key1=${key1}&key2=${key2}&key3=${key3}'"
    eval "$authenticate_command" > /dev/null
    PHPSESSID=$(awk -F'\t' '/PHPSESSID/ {print $7}' /tmp/cookies.txt)

    # Create the download command interpolating the PHPSESSID that we got from the cookies and download the dmg file.
    download_command="curl 'https://www.bresink.biz/download3.php?PHPSESSID=${PHPSESSID}' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:109.0) Gecko/20100101 Firefox/112.0' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8' -H 'Accept-Language: en-GB,en;q=0.5' -H 'Accept-Encoding: gzip, deflate, br' -H 'Connection: keep-alive' -H 'Cookie: PHPSESSID=${PHPSESSID}' -H 'Upgrade-Insecure-Requests: 1' -H 'Sec-Fetch-Dest: document' -H 'Sec-Fetch-Mode: navigate' -H 'Sec-Fetch-Site: same-origin' -H 'TE: trailers' --output /tmp/TinkerTool.dmg"
    echo "$download_command"
    eval "$download_command"

    open /tmp/TinkerTool.dmg
}

function _ideavim_config() {
    _check_file ideavim/ideavimrc
    _print s "Setting ideavimrc to ~/.ideavimrc"
    local destination="$HOME/.ideavimrc"
    gln -sv --backup=numbered "${SCRIPT_DIR}/ideavim/ideavimrc" "$destination"
}

function _fzf_config() {
    _check_file fzf/fzf.config
    _check_file fzf/fzf.zsh
    _print s "fzf configuration"
    gln -sv --backup=numbered "${SCRIPT_DIR}/fzf/fzf.config" "$HOME"/.fzf.config
}

function _lazygit_config() {
    local file="lazygit/config.yml"
    _check_file "$file"
    _print s "lazygit config"
    local destination="$HOME/Library/Application Support/lazygit/"
    _create_dir_if_not_exists "$destination"
    gln -sv --backup=numbered "${SCRIPT_DIR}/$file" "$destination/$(basename $file)"
}

function _check_root() {
    local msg="$(printf '%s\n' \
        "Would you like to have a completely unattended installation?" \
        "This will execute the installer with sudo to elevate privileges.")"
    if [ "$EUID" -ne 0 ]; then
        if (whiptail --title "Installer Privileges" --yesno "$msg" 8 78); then
            echo -e "${thunder} Trying to get ${bold}${red_fg}root${reset} access rights... "
            sudo -s "$0" "$@"
            exit $?
        fi
    fi
    gln -sv --backup=numbered "${SCRIPT_DIR}/$file" "$destination/$(basename "$file")"
}

function _validate_root() {
    # This function will validate user's timestamp without running any command
    # It will prompt for password and keep it in cache, which is 15 mins by default
    sudo -v
}

function _check_for_dependencies_and_install_if_not_installed() {
    # Check if xcode command line tools are installed and install them if not
    if [[ $(
        xcode-select -p 1> /dev/null
        echo $?
    ) == "2" ]]; then
        _print i "xcode" ": command line tools"
        xcode-select --install
    else
        _print info "xcode command line tools" ": already installed"
    fi

    # Install brew
    if ! command -v "brew" > /dev/null 2>&1; then
        _print i "Homebrew" ": The Missing Package Manager for macOS"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        _print u "Homebrew" ": Updating repositories"
        brew update
    else
        _print info "Homebrew The Missing Package Manager for macOS" ": already installed"
    fi

    # Install wget
    _ensure_installed wget
}

# ------------------------------------------------------ Packages ------------------------------------------------------

pkgs=(
    "    Set repo hooks"
    "    Set System Preferences"
    "    Install from Brewfile"
    "    install App Store apps"
    "    zshrc"
    "    zsh_aliases"
    "    zsh_functions"
    "    zsh_forgit"
    "    oh-my-zsh"
    "    set path for launchctl"
    "    nvim from source"
    "    nvim config"
    "    neovide"
    "    neovide config"
    "    kitty config"
    "    wezterm config"
    "    ghostty config"
    "    git config"
    "    bat config"
    "    fzf config"
    "    rg config"
    "    lazygit config"
    "    stylua: an opiniated Lua formatter"
    "    luacheck: lua static analysis tool"
    "    install fonts"
    "    install TinkerTool"
    "    ideavim config"
)

pkgs_functions=(
    _set_repo_hooks
    _set_preferences
    _install_from_brewfile
    _install_from_app_store
    _zshrc
    _zsh_aliases
    _zsh_functions
    _zsh_forgit
    _oh_my_zsh
    _set_path_launchctl
    _nvim_from_source
    _nvim_config
    _neovide
    _neovide_config
    _kitty_config
    _wezterm_config
    _ghostty_config
    _git_config
    _bat_config
    _fzf_config
    _rg_config
    _lazygit_config
    _stylua
    _luacheck
    _install_fonts
    _install_tinkertool
    _ideavim_config
)

dotfiles_functions=(
    _zshrc
    _zsh_aliases
    _zsh_functions
    _zsh_forgit
    _fzf_config
    _nvim_config
)

# -------------------------------------------------------- Menus -------------------------------------------------------

function _show_main_menu() {
    _ensure_installed dialog
    local INFO="---------------------- System Information -----------------------\n"
    INFO+="$(uname -a)"
    INPUT=$(dialog --title "This script provides an easy way to install my preferred packages and configurations." \
        --menu "\nScript is executed from '$(pwd)'\n\n${INFO}" ${SIZE} 4 \
        "1" "    Fresh installation of everything" \
        "2" "    Selective installation" \
        "3" "    Dotfiles installation" \
        "Q" "    Quit" \
        3>&1 1>&2 2>&3)
}

function _create_selective_menu() {
    # Dynamically populate the GUI menu from the pkgs array
    menu_options=()
    for ((i = 0; i < "${#pkgs[@]}"; i++)); do
        menu_options+=("$((i + 1))")
        menu_options+=("${pkgs[$i]}")
    done
    # Manually add the Quit option
    menu_options+=("Q")
    menu_options+=("    Quit")
}

function _show_selective_menu() {
    OPT=$(dialog --title "Selectively install packages/configurations" \
        --menu "\nSelect the packages and the configurations that you want to install/set." ${SIZE} $((ROWS - 10)) \
        "${menu_options[@]}" \
        3>&1 1>&2 2>&3)
}

# ----------------------------------------------------- Installers -----------------------------------------------------

function _fresh_install() {
    _ensure_installed curl git coreutils
    for ((i = 1; i < "${#pkgs_functions[@]}"; i++)); do
        ${pkgs_functions[$i]}
    done
    # Ask for reboot
    _reboot
}

function _selective_install() {
    _ensure_installed curl git coreutils
    _create_selective_menu
    local exit_status=0
    while [ $exit_status -eq 0 ]; do
        _show_selective_menu
        case $OPT in
            Q) exit_status=1 ;;
            *) ${pkgs_functions[(($OPT - 1))]} ;;
        esac
        # Sleep only when user hasn't selected Quit
        [ $exit_status -eq 0 ] && sleep 2
    done
    clear
}

function _dotfiles_install() {
    for ((i = 0; i < "${#dotfiles_functions[@]}"; i++)); do
        ${dotfiles_functions[$i]}
    done
}

# ------------------------------------------------------- Main ---------------------------------------------------------

_validate_root
_check_for_dependencies_and_install_if_not_installed
_show_main_menu

if [[ $INPUT -eq 1 ]]; then
    _fresh_install
elif [[ $INPUT -eq 2 ]]; then
    _selective_install
elif [[ $INPUT -eq 3 ]]; then
    _dotfiles_install
else
    clear
    exit 0
fi
