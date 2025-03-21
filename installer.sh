#!/usr/bin/env bash

# This script provides an easy way to install my preferred packages along with my configurations.
# Author: Tsakiris Tryfon

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
start_underline=$(tput smul)
end_underline=$(tput rmul)
red_fg=$(tput setaf 1)
white_fg=$(tput setaf 7)
black_bg=$(tput setab 0)
reset=$(tput sgr0)

# ---------------------------------------------------- Symbols ---------------------------------------------------------

thunder="\u2301"
bullet="\u2022"

# ---------------------------------------------------- Functions -------------------------------------------------------

function _check_ppa() {
    for i in "$@"; do
        if ! grep -Rq "^deb.*$i" /etc/apt/sources.list.d/*.list; then
            sudo add-apt-repository -y ppa:"$i" > /dev/null
            sudo apt-get -qq update
        fi
    done
}

function _check_file() {
    if [ ! -f "$1" ]; then
        echo "${bold}${red_fg}Error${reset}: cannot find ${1} in this directory."
        echo "You should run the installer from within the github repository."
        echo "(git clone https://github.com/tsakirist/configurations.git)"
        exit 1
    fi
}

function _check_dir() {
    if [ ! -d "$1" ]; then
        echo "${bold}${red_fg}Error${reset}: cannot find ${1} in this directory."
        echo "You should run the installer from within the github repository."
        echo "(git clone https://github.com/tsakirist/configurations.git)"
        exit 1
    fi
}

function _create_dir_if_not_exists() {
    [ ! -d "$1" ] && mkdir -p "$1"
}

function _print_cmd_version() {
    "$1" --version | grep -m1 -Po "(\d+\.)?(\d+\.)(\d+)?( ?\(\w+\))?"
}

# Function that takes as argument the author/repo and installs the latest deb
function _install_latest_deb() {
    local repo="https://api.github.com/repos/$1/releases/latest"
    local url=$(curl -s "$repo" | grep -E 'browser_download_url.*amd64.*\.deb' | grep -vE 'musl|sha256' | cut -d '"' -f 4)
    local filename=$(basename "$url")
    wget -qO /tmp/"$filename" "$url" && sudo dpkg -i /tmp/"$filename" > /dev/null
}

# Installs latest deb and also prints the current and new installed version
# Takes two arguments:
#   - The repository URL as a first argument
#   - An optional name for the executable command that might differ and can't be deduced from the URL
function _install_latest_deb_with_version() {
    local repo="$1"
    local cmd
    if [ "$#" -eq 1 ]; then
        cmd=$(echo "$repo" | cut -d/ -f2)
    elif [ "$#" -eq 2 ]; then
        cmd="$2"
    fi
    if command -v "$cmd" > /dev/null 2>&1; then
        echo -e "    ${bullet} Old version: ${red_fg}$(_print_cmd_version "$cmd")${reset}"
    fi
    _install_latest_deb "$repo"
    echo -e "    ${bullet} New version: ${red_fg}$(_print_cmd_version "$cmd")${reset}"
}

function _install() {
    sudo apt-get -qq install "$@" > /dev/null
}

function _update() {
    sudo apt-get -qq update
}

# Checks whether the provided command exists or not
function _check_command() {
    command -v "$1" > /dev/null 2>&1
}

# Checks whether the command is present and if not will try to install it
# Takes an optional second argument that specifies a different name for the package
function _need_command() {
    if ! _check_command "$1"; then
        local cmd
        if [ "$#" -eq 1 ]; then
            cmd="$1"
        elif [ "$#" -eq 2 ]; then
            cmd="$2"
        fi
        echo -e "    ${black_bg}${thunder} Installing required package ${bold}${red_fg}${cmd}${reset} ..."
        _install "$cmd"
    fi
}

# Checks whether the command is present and if not will try to install it via the passed arguments.
# $2: Expected to be a function responsible for the installation
# $3...$n: Expected arguments possibly required for the installation function
function _need_command_fn() {
    if [[ $# -lt 2 ]]; then
        echo "Expected at least two arguments. Provided $# argument(s)."
        return
    fi

    if ! _check_command "$1"; then
        echo -e "    ${black_bg}${bullet} Command ${bold}${red_fg}${1}${reset} doesn't exist." \
            "Installing it via ${bold}${red_fg}${2}${reset} function ..."
        "$2" "${@:3}"
    fi
}

# Checks whether the package is installed and if not will try to install it
# TODO: Think whether this can totally replace @_check_command
function _need_package() {
    local installed=$(dpkg-query -W -f='${Status}' "$1" 2> /dev/null | grep -c "ok installed")
    if [ "$installed" -eq 0 ]; then
        echo -e "${black_bg}${thunder} Installing required package ${bold}${red_fg}${1}${reset} ..."
        _install "$1"
    fi
}

function _backup() {
    echo "Backing up $1 ..."
    cp "$1" "$1" -v --force --backup=numbered
}

function _reboot() {
    echo "${black_bg}${bold}It is recommended to ${red_fg}reboot${white_fg} after a fresh installation" \
        "of the packages and configurations.${reset}"
    read -n 1 -r -p "Would you like to reboot? [Y/n] " input
    if [[ "$input" =~ ^([yY])$ ]]; then
        sudo reboot
    fi
}

function _prompt() {
    local exec=false
    echo -e "${bullet} Do you want to download/install ${bold}${red_fg}${1}${reset} [Y/n] "
    read -n 1 -r -s input
    if [[ "$input" =~ ^([yY])$ ]]; then
        exec=true
    fi
    if [[ $exec == "true" ]]; then
        $1
    fi
}

function _print() {
    local action
    if [ $# -gt 1 ]; then
        case "$1" in
            "s") action="Setting" ;;
            "i") action="Installing" ;;
            "c") action="Changing" ;;
        esac
        echo -en "${black_bg}${thunder} ${action} ${bold}${red_fg}${*:2:1}${reset}"
        echo -e "${black_bg}${*:3} ...${reset}"
    fi
}

function _change_shell() {
    if [ $# -eq 0 ]; then
        echo "Cannot change shell to empty argument. You must provide the ${bold}${red_fg}shell name${reset}."
        return
    fi
    local shell
    case "$1" in
        "bash") shell="bash" ;;
        "zsh") shell="zsh" ;;
    esac
    local msg="Do you want to change the default shell to ${shell}?\nThis will issue 'chsh -s $(command -v ${shell})' command."
    if [ "$INSTALLATION_MODE" == "unattended" ] || (whiptail --title "Change shell" --yesno "${msg}" 8 78); then
        sudo chsh -s "$(command -v "${shell}")"
        _print c "shell to $(command -v "${shell}")"
        echo "In order for the ${start_underline}change${end_underline} to take effect you need to" \
            "${bold}${red_fg}re-login${reset}."
    fi
}

function _git_config() {
    _check_file git/gitconfig
    _print s ".gitconfig"
    ln -sv --backup=numbered "${SCRIPT_DIR}/git/gitconfig" "$HOME"/.gitconfig
}

function _git_pre_commit_hooks() {
    _chekc_dir hooks
    _check_file hooks/pre-commit-config.yaml
    _check_file hooks/check-added-files-nvim.sh
    _print s "git pre-commit hooks"

    # Make sure to install the required `pre-commit` package (https://pre-commit.com/)
    _need_command pipx
    pipx ensurepath > /dev/null 2>&1
    pipx install pre-commit > /dev/null 2>&1

    # Copy pre-commit hook files
    cp -v hooks/pre-commit-config.yaml .pre-commit-config.yaml
    cp -v hooks/check-added-files-nvim.sh .git/hooks
}

function _bashrc() {
    _check_file bash/bashrc
    _print s ".bashrc"
    ln -sv --backup=numbered "${SCRIPT_DIR}/bash/bashrc" "$HOME"/.bashrc
}

function _bash_aliases() {
    _check_file bash/bash_aliases
    _print s ".bash_aliases"
    ln -sv --backup=numbered "${SCRIPT_DIR}/bash/bash_aliases" "$HOME"/.bash_aliases
}

function _bash_functions() {
    _check_file bash/bash_functions
    _print s ".bash_functions"
    ln -sv --backup=numbered "${SCRIPT_DIR}/bash/bash_functions" "$HOME"/.bash_functions
}

function _bash_config() {
    _bashrc && _bash_aliases && _bash_functions
}

function _zsh() {
    _print i "zsh"
    _install zsh
    _change_shell zsh
}

function _zshrc() {
    _check_file zsh/zshrc
    _print s ".zshrc"
    ln -sv --backup=numbered "${SCRIPT_DIR}/zsh/zshrc" "$HOME"/.zshrc
}

function _zsh_aliases() {
    _check_file zsh/zsh_aliases
    _print s ".zsh_aliases"
    ln -sv --backup=numbered "${SCRIPT_DIR}/zsh/zsh_aliases" "$HOME"/.zsh_aliases
}

function _zsh_functions() {
    _check_file zsh/zsh_functions
    _print s ".zsh_functions"
    ln -sv --backup=numbered "${SCRIPT_DIR}/zsh/zsh_functions" "$HOME"/.zsh_functions
}

function _zsh_p10k() {
    _check_file zsh/p10k.zsh
    _print s ".p10k.zsh"
    cp -v --backup=numbered zsh/p10k.zsh ~/.p10k.zsh
}

function _zsh_forgit() {
    _check_file zsh/forgit.zsh
    _print s ".forgit.zsh"
    ln -sv --backup=numbered "${SCRIPT_DIR}/zsh/forgit.zsh" "$HOME"/.forgit.zsh
}

function _zsh_config() {
    _zshrc && _zsh_aliases && _zsh_functions && _zsh_p10k && _zsh_forgit
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

function _build_essential() {
    _print i "build-essential"
    _install build-essential
}

function _mise_config() {
    _check_file mise/config.toml
    _print s "mise configuration"
    ln -sv --backup=numbered "${SCRIPT_DIR}/mise/config.toml" "$HOME"/.config/mise/config.toml
}

function _mise() {
    _print i "mise" ": a manager for dev tools"
    sudo install -dm 755 /etc/apt/keyrings
    wget -qO - https://mise.jdx.dev/gpg-key.pub | gpg --dearmor | sudo tee /etc/apt/keyrings/mise-archive-keyring.gpg 1> /dev/null
    echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=amd64] https://mise.jdx.dev/deb stable main" \
        | sudo tee /etc/apt/sources.list.d/mise.list > /dev/null 2>&1
    _update
    _install mise \
        && echo "Make sure to ${red_fg}restart${reset} your shell session or ${red_fg}source${reset} the rc file to be able use mise tools."
    _mise_config
    mise install --silent --yes > /dev/null 2>&1
}

function _node() {
    _print i "node" ": asynchronous event-driven javascript runtime"
    _need_command_fn mise _mise
    mise use --global node@lts > /dev/null
}

function _nvim_nightly() {
    _print i "neovim nightly" ": a superior vim fork focused on extensiblity and usability"
    local nvim_tar="nvim-linux64.tar.gz"
    local nvim_tar_dir="${nvim_tar%%.*}"
    pushd "$(mktemp -d)" > /dev/null || return
    curl -sSLO "https://github.com/neovim/neovim/releases/download/nightly/${nvim_tar}"
    [ -f "$nvim_tar" ] \
        && tar xzf "$nvim_tar" \
        && [ -d "$nvim_tar_dir" ] \
        && sudo mv "$nvim_tar_dir/bin/nvim" /usr/local/bin/nvim \
        && echo "Installed NVIM version: $(
            /usr/local/bin/nvim --version | grep -m 1 NVIM | awk -v COLOR="$red_fg" -v RESET="$reset" '{print COLOR $2 RESET}'
        )"
    popd > /dev/null || return
}

function _check_nvim_config_requirements() {
    _need_command make build-essential
    _need_command luarocks
    _need_command_fn node _node
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
    ln -sf "${SCRIPT_DIR}/nvim" "$config_path"

    # Make sure to install Lazy and update the plugins
    # TODO: Perhaps I should use the lazy-lock file here and restore?
    echo -e "    ${bullet} Syncing neovim plugins ..."
    /usr/bin/env nvim --headless -c "Lazy! sync" -c "quitall" > /dev/null
}

function _neofetch() {
    _print i "neofetch" ": a command-line system information tool"
    _install neofetch
}

function _xclip() {
    _print i "xclip" ": command line interface to X selections (clipboard)"
    _install xclip
}

function _dconf() {
    _check_file dconf/settings.dconf
    _print s "dconf settings"
    dconf load / < dconf/settings.dconf
}

function _preload() {
    _print i "preload"
    _install preload
}

function _cmake() {
    _print i "cmake"
    _install cmake
}

function _tree() {
    _print i "tree" ": list contents of directories in a tree-like format"
    _install tree
}

function _htop() {
    _print i "htop" ": an interactive process viewer"
    _install htop
}

function _gotop() {
    _print i "gotop" ": a terminal UI system monitoring tool"
    sudo snap install gotop-cjbassi
    sudo snap connect gotop-cjbassi:hardware-observe
    sudo snap connect gotop-cjbassi:mount-observe
    sudo snap connect gotop-cjbassi:system-observe
}

function _btop() {
    _print i "btop" ": interactive resource monitor written in C++"
    local repo="https://api.github.com/repos/aristocratos/btop/releases/latest"
    local url=$(curl -s "$repo" | grep "browser_download_url" | grep "linux" | grep "x86_64" | cut -d '"' -f 4)
    local filename=$(basename "$url")
    pushd "$(mktemp -d)" > /dev/null || return
    curl -sSLO "$url" \
        && [ -f "$filename" ] \
        && tar -xf "$filename" \
        && cd btop || return \
        && sudo make install
    popd > /dev/null || return
}

function _ncdu() {
    _print i "ncdu" ": a terminal UI disk usage monitoring tool"
    _install ncdu
}

function _monitoring_tools() {
    _htop
    _gotop
    _btop
    _ncdu
}

function _gnome_tweaks() {
    _print i "gnome-tweaks"
    _install gnome-tweaks
}

function _gnome_shell_extensions() {
    _print i "gnome-shell-extensions"
    _install gnome-shell-extensions gnome-shell-extension-dashtodock gnome-shell-extension-arc-menu
}

function _gnome_sushi() {
    _print i "gnome-sushi" ": file previewer"
    _install gnome-sushi
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
    ln -sv --backup=numbered "${SCRIPT_DIR}/rg/config" "${destination}/config"
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
    ln -sv --backup=numbered "${SCRIPT_DIR}/kitty/kitty.conf" "$destination/kitty.conf"
    cp -v kitty/*.png "$destination/"
    _kitty_themes
}

function _kitty_themes() {
    _check_dir kitty/themes/
    local destination="$HOME/.config/kitty/themes"
    _create_dir_if_not_exists "$destination/"
    ln -sv --backup=numbered "${SCRIPT_DIR}/kitty/themes/carbonfox.conf" "$destination"
}

function _wezterm() {
    _print i "wezterm" ": cross platform terminal emulator in Rust"
    curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg
    echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' \
        | sudo tee /etc/apt/sources.list.d/wezterm.list > /dev/null 2>&1
    _update
    _install wezterm
    _wezterm_config
}

function _wezterm_config() {
    _check_dir wezterm
    _print s "wezterm configuration"

    local destination="$HOME/.config/wezterm/"
    _create_dir_if_not_exists "$destination"

    cp -avsfT "${SCRIPT_DIR}/wezterm/" "$destination"
}

function _x_profile() {
    _check_file x/xprofile
    _print s "xprofile"
    ln -sv --backup=numbered "${SCRIPT_DIR}/x/xprofile" "$HOME"/.xprofile
}

function _set_wallpaper() {
    local wlp="wallpapers/abstract_cube.jpg"
    _check_file "$wlp"
    local path="$(readlink -e $wlp)"
    local uri="'file://$path'"
    _print s "wallpaper" ": $path"
    gsettings set org.gnome.desktop.background picture-uri "$uri"
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
    curl -sSLO "$asset" && mkdir $directory && tar xf "$font" -C "$directory" --wildcards "**/codicon.ttf"
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
    cp -r fonts "$HOME"/.local/share
    _need_command fc-cache fontconfig
    fc-cache -f

    popd > /dev/null || return
}

function _fzf_config() {
    _check_file fzf/fzf.config
    _check_file fzf/fzf.zsh
    _print s "fzf configuration"
    ln -sv --backup=numbered "${SCRIPT_DIR}/fzf/fzf.config" "$HOME"/.fzf.config
    ln -sv --backup=numbered "${SCRIPT_DIR}/fzf/fzf.zsh" "$HOME"/.fzf.zsh
}

function _fzf() {
    _print i "fzf" ": a command line fuzzy finder"
    if [ -d "$HOME"/.fzf ]; then
        echo -e "    ${bullet} Old version: ${red_fg}$(_print_cmd_version fzf)${reset}"
        pushd "$HOME"/.fzf > /dev/null || return \
            && git pull --quiet origin \
            && popd > /dev/null || return
    else
        git clone --quiet --depth=1 https://github.com/junegunn/fzf.git "$HOME"/.fzf
    fi
    "$HOME"/.fzf/install --key-bindings --completion --no-update-rc > /dev/null 2>&1
    echo -e "    ${bullet} New version: ${red_fg}$(_print_cmd_version fzf)${reset}"
}

function _fd() {
    _print i "fd" ": an improved version of find"
    _install_latest_deb_with_version sharkdp/fd
}

function _bat() {
    _print i "bat" ": a clone of cat with syntax highlighting"
    _install_latest_deb_with_version sharkdp/bat
}

function _rg() {
    _print i "rg" ": ripgrep recursive search for a pattern in files"
    _install_latest_deb_with_version BurntSushi/ripgrep rg
}

function _glow() {
    _print i "glow" ": markdown renderer for the terminal"
    _install_latest_deb_with_version charmbracelet/glow
}

function _delta() {
    _print i "delta" ": a better viewer for git and diff output"
    _install_latest_deb_with_version dandavison/delta
}

function _difftastic() {
    _print i "difftastic" ": structural diff viewer"

    pushd "$(mktemp -d)" > /dev/null || return

    local repo="https://api.github.com/repos/Wilfred/difftastic/releases/latest"
    local asset_url=$(curl -sSL $repo | grep -E "browser_download_url.*x86_64.*linux.*\.tar\.gz" | cut -d '"' -f 4)
    local asset=$(basename "$asset_url")

    curl -sSLO "$asset_url" && tar xf "$asset" && [ -f difft ] && sudo mv difft /usr/local/bin

    popd > /dev/null || return
}

function _lazygit() {
    _print i "lazygit" ": a terminal UI for git commands"
    pushd "$(mktemp -d)" > /dev/null || return
    local LAZYGIT_VERSION=$(curl -sS "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -sSLo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit /usr/local/bin
    popd > /dev/null || return
}

function _lazygit_config() {
    local file="lazygit/config.yml"
    _check_file "$file"
    _print s "lazygit config"
    local destination="$HOME/.config/lazygit"
    _create_dir_if_not_exists "$destination"
    ln -sv --backup=numbered "${SCRIPT_DIR}/$file" "$destination/$(basename $file)"
}

function _rustup() {
    _print i "rustup" ": rust toolchain installer"
    curl -sSf https://sh.rustup.rs | sh -s -- -y -- > /dev/null 2>&1
}

function _sd() {
    _print i "sd" ": intuitive find & replace CLI (sed alternative)"
    _need_command cargo
    cargo -q install sd
}

function _tldr() {
    _print i "tldr" ": cheatsheet for console commands"
    _need_command cargo
    cargo -q install tealdeer
}

function _yazi() {
    _print i "yazi" ": terminal file manager"
    _need_command cargo
    cargo -q install --locked yazi-fm yazi-cli
}

function _fx() {
    _print i "fx" ": terminal JSON viewer & processor "
    sudo snap install fx > /dev/null
}

function _jq() {
    _print i "jq" ": command-line json processor"
    _install jq
}

function _vm_swappiness() {
    local value=10
    local file="/etc/sysctl.conf"
    _print c "vm.swappiness" " to $value"
    if grep -q "^vm.swappiness" $file; then
        sudo sed -i "s/\(^vm.swappiness=\).*/\1$value/" $file
    else
        echo "vm.swappiness=${value}" | sudo tee -a $file > /dev/null 2>&1
    fi
    sudo sysctl -q -p
    echo "Swappiness value:" "$(cat /proc/sys/vm/swappiness)"
}

function _check_root() {
    local msg="$(printf '%s\n' \
        "Would you like to have a completely unattended installation?" \
        "This will execute the installer with sudo to elevate privileges.")"
    if [ "$EUID" -ne 0 ]; then
        if (whiptail --title "Installer Privileges" --yesno "$msg" 8 78); then
            echo -e "${thunder} Trying to get ${start_underline}${bold}${red_fg}root${reset} access rights... "
            sudo -s "$0" "$@"
            exit $?
        fi
    fi
}

function _validate_root() {
    # This function will validate user's timestamp without running any command
    # It will prompt for password and keep it in cache, which is 15 mins by default
    sudo -v
}

function _disable_automatic_apt_updates() {
    _print s "non automatic updates for apt"
    local file="/etc/apt/apt.conf.d/20auto-upgrades"
    local contents=$(
        cat << EOF
APT::Periodic::Update-Package-Lists "0";
APT::Periodic::Download-Upgradeable-Packages "0";
APT::Periodic::AutocleanInterval "0";
APT::Periodic::Unattended-Upgrade "0";
EOF
    )
    echo "$contents" | sudo tee "$file" > /dev/null 2>&1
}

# ------------------------------------------------------ Packages ------------------------------------------------------

pkgs=(
    "    dconf settings"
    "    build-essential"
    "    zsh"
    "    zshrc, zsh_aliases, zsh_functions, zsh_p10k, zsh_forgit"
    "    oh-my-zsh"
    "    bashrc, bash_aliases, bash_functions"
    "    nvim nightly"
    "    nvim configuration"
    "    kitty: the fast, featureful, GPU based terminal emulator"
    "    kitty configuration"
    "    wezterm: cross platform terminal emulator in Rust"
    "    wezterm configuration"
    "    fzf: fuzzy finder"
    "    fzf configuration"
    "    fd: improved version of find"
    "    rg: ripgrep recursive search for a pattern in files"
    "    rg configuration"
    "    bat: a cat clone with syntax highlighting"
    "    bat configuration"
    "    delta: a better viewer for git and diff output"
    "    difftastic: a structural diff viewer"
    "    lazygit: a simple terminal UI for git commands"
    "    lazygit configuration"
    "    git configuration"
    "    git pre-commit hooks"
    "    glow: markdown renderer for the terminal"
    "    mise: a manager for dev tools"
    "    mise configuration"
    "    node: asyncrhonous event-driven JavaScript runtime"
    "    rustup: rust toolchain installer"
    "    sd: intuitive find & replace CLI (sed alternative)"
    "    tldr: cheatsheet for console commands"
    "    yazi: terminal file manager"
    "    fx: terminal JSON viewer & processor"
    "    jq: command-line json processor"
    "    xprofile"
    "    xclip"
    "    neofetch"
    "    htop + gotop + btop + ncdu: monitoring tools"
    "    tree"
    "    cmake"
    "    gnome-tweaks"
    "    gnome-shell-extensions"
    "    gnome-sushi"
    "    preload"
    "    vmswappiness"
    "    wallpaper"
    "    fonts"
    "    disable automatic apt updates"
)

pkgs_functions=(
    _dconf
    _build_essential
    _zsh
    _zsh_config
    _oh_my_zsh
    _bash_config
    _nvim_nightly
    _nvim_config
    _kitty
    _kitty_config
    _wezterm
    _wezterm_config
    _fzf
    _fzf_config
    _fd
    _rg
    _rg_config
    _bat
    _bat_config
    _delta
    _difftastic
    _lazygit
    _lazygit_config
    _git_config
    _git_pre_commit_hooks
    _glow
    _mise
    _mise_config
    _node
    _rustup
    _sd
    _tldr
    _yazi
    _fx
    _jq
    _x_profile
    _xclip
    _neofetch
    _monitoring_tools
    _tree
    _cmake
    _gnome_tweaks
    _gnome_shell_extensions
    _gnome_sushi
    _preload
    _vm_swappiness
    _set_wallpaper
    _install_fonts
    _disable_automatic_apt_updates
)

dotfiles_functions=(
    _zsh_config
    _bash_config
    _kitty_config
    _nvim_config
    _fzf_config
    _bat_config
    _rg_config
    _lazygit_config
    _git_config
    _x_profile
)

# -------------------------------------------------------- Menus -------------------------------------------------------

function _show_main_menu() {
    _need_command whiptail
    local INFO="---------------------- System Information -----------------------\n"
    INFO+="$(hostnamectl | grep -E "Operating|Kernel|Architecture")"
    INPUT=$(whiptail --title "This script provides an easy way to install my preferred packages and configurations." \
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
    OPT=$(whiptail --title "Selectively install packages/configurations" \
        --menu "\nSelect the packages and the configurations that you want to install/set." ${SIZE} $((ROWS - 10)) \
        "${menu_options[@]}" \
        3>&1 1>&2 2>&3)
}

# ----------------------------------------------------- Installers -----------------------------------------------------

function _fresh_install() {
    INSTALLATION_MODE="unattended"
    _need_command curl && _need_command git
    for ((i = 1; i < "${#pkgs_functions[@]}"; i++)); do
        ${pkgs_functions[$i]}
    done
    _dconf
    _reboot
}

function _selective_install() {
    _need_command curl && _need_command git
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
}

function _dotfiles_install() {
    for ((i = 0; i < "${#dotfiles_functions[@]}"; i++)); do
        ${dotfiles_functions[$i]}
    done
}

# ------------------------------------------------------- Main ---------------------------------------------------------

_validate_root
_show_main_menu

if [[ $INPUT -eq 1 ]]; then
    _fresh_install
elif [[ $INPUT -eq 2 ]]; then
    _selective_install
elif [[ $INPUT -eq 3 ]]; then
    _dotfiles_install
else
    exit 0
fi
