#!/bin/bash


clear 


cat << 'BANNER'
  ______     __               
 /_  __/____/ /_  ____  __  __
  / / / ___/ __ \/ __ \/ / / /
 / / / /__/ / / / /_/ / /_/ / 
/_/  \___/_/ /_/\____/\__,_/  
                               
        M A G I C   I N S T A L L E R
BANNER
echo ""

read -rp "Quel nom veux-tu afficher dans zsh/tmux ? [Tchou] " term_name
term_name="${term_name:-Tchou}"
printf "\n\n"

echo "Bon choix, je commence l'installation"
printf "\n"
echo "Don't go to far I will some autorization"


printf "\n\n\n"

sleep 2

# ==========================================================
# magicinstall.sh
# Neovim, Docker, zsh/oh-my-zsh, tmux, Starship
# Compatible with Debian, Ubuntu and Kali
# ==========================================================

# --- 1. NEOVIM (custom build via GitHub releases) ---
echo "--- Removing old Neovim and installing the latest AppImage build ---"
sudo apt remove --purge -y neovim neovim-runtime || true
sudo rm -f /usr/local/bin/nvim
sudo rm -rf /opt/nvim
rm -rf ~/.config/nvim ~/.local/share/nvim ~/.cache/nvim
sudo apt autoremove -y

curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage
chmod u+x nvim-linux-x86_64.appimage
sudo mkdir -p /opt/nvim
sudo mv nvim-linux-x86_64.appimage /opt/nvim/nvim
sudo ln -sf /opt/nvim/nvim /usr/local/bin/nvim

# --- 2. SYSTEM UPDATES & DEPENDENCIES ---
echo "--- Installing fresh dependencies ---"
sudo apt update
sudo apt install -y zsh tmux fzf zoxide xclip python3-venv git curl nmap
sudo apt install -y libfuse2t64 || sudo apt install -y libfuse2

# --- 3. DOCKER (official repo - works on Debian, Ubuntu and Kali) ---
echo "--- Installing Docker Engine from Docker's official repo ---"

sudo apt remove -y $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc 2>/dev/null | cut -f1)

. /etc/os-release
case "$ID" in
  ubuntu)
    DOCKER_OS="ubuntu"
    DOCKER_CODENAME="${UBUNTU_CODENAME:-$VERSION_CODENAME}"
    ;;
  kali)
    DOCKER_OS="debian"
    DOCKER_CODENAME="trixie"   # Kali's own codename isn't recognized by Docker; pins to current Debian stable
    ;;
  *)
    DOCKER_OS="debian"
    DOCKER_CODENAME="$VERSION_CODENAME"
    ;;
esac

sudo apt install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/$DOCKER_OS/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/$DOCKER_OS
Suites: $DOCKER_CODENAME
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo systemctl enable docker --now
sudo usermod -aG docker $USER

# --- 4. DIRECTORIES ---
echo "--- Creating Directories ---"
mkdir -p ~/.config/nvim ~/journal/Journal/

# --- 5. OH-MY-ZSH & PLUGINS ---
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "--- Installing Oh-My-Zsh ---"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Refreshing Zsh Plugins
rm -rf ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
rm -rf ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
rm -rf ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-completions
rm -rf ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fzf-tab
rm -rf ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/you-should-use

git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-completions
git clone https://github.com/Aloxaf/fzf-tab ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fzf-tab
git clone https://github.com/MichaelAquilina/zsh-you-should-use.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/you-should-use

# Starship prompt (replaces powerlevel10k)
curl -sS https://starship.rs/install.sh | sh -s -- -y

# --- 6. CONFIG FILE INJECTION ---

# .zshrc
cat << 'EOF' > ~/.zshrc
export MY_TERM_NAME="Tchou"
export ZSH="$HOME/.oh-my-zsh"

# Désactive bracketed-paste côté zsh : contourne un bug confirmé de Windows
# Terminal qui envoie un marqueur de fin corrompu à tmux pendant un collage,
# bloquant la session (cf. github.com/microsoft/terminal issues #19316 et #19418).
# Contrepartie : un collage multi-lignes s'exécute ligne par ligne au lieu
# d'être inséré tel quel (donc attention si tu colles plusieurs commandes).
unset zle_bracketed_paste

plugins=(git docker sudo command-not-found extract zsh-completions fzf-tab you-should-use zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

alias zconfig="nvim ~/.zshrc"
alias zreload="source ~/.zshrc"
alias treload="tmux source-file ~/.tmux.conf"
alias tconfig="nvim ~/.tmux.conf"
alias pypy="source ~/.venv/bin/activate"
alias d="cd ~/Desktop"


tname() {
  if [[ -z "$1" ]]; then
    echo "Usage: tname <name>"
    return 1
  fi
  export MY_TERM_NAME="$1"
  sed -i "s/^export MY_TERM_NAME=.*/export MY_TERM_NAME=\"$1\"/" ~/.zshrc
  if [[ -n "$TMUX" ]]; then
    tmux set-option -g status-right "#[fg=#afd7ff]| %H:%M #[fg=#080808,bg=#87afff,bold] $1 "
  fi
  echo "Nom changé pour : $1"
}

export tip="10.10.10.10"
export turl="domaine.com"

bindkey '^[[A' up-line-or-search
bindkey '^[[B' down-line-or-search

# Ctrl+V colle depuis le presse-papier système si X11 est dispo (xclip),
# ne fait rien sinon (machine sans environnement graphique)
paste-clipboard() {
  if [[ -n "$DISPLAY" ]]; then
    LBUFFER+="$(xclip -selection clipboard -o 2>/dev/null)"
  fi
}
zle -N paste-clipboard
bindkey '^V' paste-clipboard

eval "$(zoxide init zsh)"
source <(fzf --zsh)
export PATH="$HOME/.venv/bin:$PATH"
eval "$(starship init zsh)"
EOF
sed -i "s/^export MY_TERM_NAME=.*/export MY_TERM_NAME=\"$term_name\"/" ~/.zshrc

# .tmux.conf
MY_TERM_NAME="$term_name"   # baked into the file below; tmux doesn't expand $VARS inside quoted strings
cat << EOF > ~/.tmux.conf
set -g status-position top
set -g status-bg "#005f87"
set -g status-fg "#afd7ff"
set -g status-left ""
set -g status-right "#[fg=#afd7ff]| %H:%M #[fg=#080808,bg=#87afff,bold] $MY_TERM_NAME "
set -g mouse on
set -g window-status-current-format " #[fg=#080808,bg=#87afff,bold] #I:#W "
set-option -g default-shell /usr/bin/zsh
set -g prefix C-a
unbind C-b
bind C-a send-prefix

# Mouse selection -> system clipboard via xclip (besoin de X11 ; ne fait
# rien sur une machine sans environnement graphique), and auto-exit copy-mode
bind-key -T copy-mode MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "xclip -selection clipboard -in 2>/dev/null"
bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "xclip -selection clipboard -in 2>/dev/null"
EOF

# init.lua
cat << 'EOF' > ~/.config/nvim/init.lua
-- Laisse nvim auto-détecter xclip si X11 est dispo (sinon ne fait rien,
-- juste un avertissement au premier yank, sans planter)
vim.opt.clipboard = "unnamedplus"
vim.keymap.set({'n', 'v'}, 'p', '"+p', { noremap = true, silent = true })
vim.keymap.set({'n', 'v'}, 'y', '"+y', { noremap = true, silent = true })
-- Mouse selection copies straight to the system clipboard
vim.keymap.set('v', '<LeftRelease>', '"+y<Esc>', { noremap = true, silent = true })
-- Ctrl+V pastes while typing (normal-mode Ctrl+V is left alone, it's Visual Block)
vim.keymap.set('i', '<C-v>', '<C-r>+', { noremap = true, silent = true })

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  { "catppuccin/nvim", name = "catppuccin", priority = 1000 },
  "neovim/nvim-lspconfig",
  "hrsh7th/nvim-cmp",
  "hrsh7th/cmp-nvim-lsp",
  "L3MON4D3/LuaSnip",
})

vim.opt.termguicolors = true
vim.cmd.colorscheme "catppuccin-mocha"

local cmp = require('cmp')
cmp.setup({
  snippet = { expand = function(args) require('luasnip').lsp_expand(args.body) end },
  mapping = cmp.mapping.preset.insert({ ['<Tab>'] = cmp.mapping.confirm({ select = true }), ['<CR>'] = cmp.mapping.confirm({ select = true }) }),
  sources = cmp.config.sources({ { name = 'nvim_lsp' } })
})

local capabilities = require('cmp_nvim_lsp').default_capabilities()
if vim.lsp.enable then
  vim.lsp.config('pyright', { capabilities = capabilities })
  vim.lsp.enable('pyright')
else
  require('lspconfig').pyright.setup({ capabilities = capabilities })
end

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.cursorline = true
vim.opt.mouse = 'a'
EOF

# starship.toml
mkdir -p ~/.config
cat << 'EOF' > ~/.config/starship.toml
add_newline = false

format = """${env_var.MY_TERM_NAME}$directory$git_branch$git_status$character"""
right_format = """$cmd_duration$status$python"""

[env_var.MY_TERM_NAME]
variable = "MY_TERM_NAME"
format = "[$env_value]($style) "
style = "fg:153"

[directory]
style = "fg:111"
truncation_length = 3
format = "[$path]($style) "

[git_branch]
style = "fg:117"
format = "[$branch]($style) "

[git_status]
style = "fg:117"

[character]
success_symbol = "[>](bold fg:117)"
error_symbol = "[>](bold red)"

[cmd_duration]
style = "fg:221"
format = "[$duration]($style) "

[status]
disabled = false
style = "fg:red"
format = "[$symbol$status]($style) "

[python]
style = "fg:221"
format = "[$virtualenv]($style) "
EOF

# --- 7. PYTHON VIRTUAL ENV ---
echo "--- Creating Python Virtual Environment ---"
rm -rf ~/.venv
python3 -m venv ~/.venv
source ~/.venv/bin/activate
pip install pyright black ruff
echo "--- Priming pyright (first run downloads Node.js + the real pyright package) ---"
~/.venv/bin/pyright --version

clear

cat << 'BANNER'
 _____           _        _ _    _____                      _      _       _ 
|_   _|         | |      | | |  / ____|                    | |    | |     | |
  | |  _ __  ___| |_ __ _| | | | |     ___  _ __ ___  _ __ | | ___| |_ ___| |
  | | | '_ \/ __| __/ _` | | | | |    / _ \| '_ ` _ \| '_ \| |/ _ \ __/ _ \ |
 _| |_| | | \__ \ || (_| | | | | |___| (_) | | | | | | |_) | |  __/ ||  __/_|
|_____|_| |_|___/\__\__,_|_|_|  \_____\___/|_| |_| |_| .__/|_|\___|\__\___(_)
                                                     | |                     
                                                     |_|                     
BANNER





echo "You will now be teleported in tmux" 
echo "To check out your new features go ahead and read the README.md"


sleep 3


tmux
