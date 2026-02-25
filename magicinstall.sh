#!/bin/bash

# --- 1. THE CLEAN SWEEP ---
echo "--- Cleaning house: Removing old configs and conflicts ---"
# Remove old Neovim data/cache to prevent plugin ghosts
rm -rf ~/.local/share/nvim
rm -rf ~/.cache/nvim
# Remove old init.vim if it exists (we use init.lua now)
rm -f ~/.config/nvim/init.vim
# Uninstall existing neovim to ensure a fresh, clean binary
sudo apt remove --purge -y neovim
sudo apt autoremove -y

# --- 2. SYSTEM UPDATES & DEPENDENCIES ---
echo "--- Installing fresh dependencies ---"
sudo apt update
sudo apt install -y zsh tmux neovim fzf zoxide xclip python3-venv git curl

# --- 3. KEYBOARD & DIRECTORIES ---
echo "--- Forcing Keyboard Layout (CA Multix) and Directories ---"
setxkbmap ca multix
mkdir -p ~/.config/nvim ~/journal/Journal/

# --- 4. OH-MY-ZSH & PLUGINS ---
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "--- Installing Oh-My-Zsh ---"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Refreshing Zsh Plugins
rm -rf ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
rm -rf ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
rm -rf ~/powerlevel10k

git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k

# --- 5. CONFIG FILE INJECTION ---

# .zshrc
cat << 'EOF' > ~/.zshrc
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

source ~/powerlevel10k/powerlevel10k.zsh-theme
export MY_TERM_NAME="Tchou"
export ZSH="$HOME/.oh-my-zsh"
# Keyboard Auto-Fix
setxkbmap ca multix

plugins=(git zsh-syntax-highlighting zsh-autosuggestions)
source $ZSH/oh-my-zsh.sh

alias zconfig="nvim ~/.zshrc"
alias zreload="source ~/.zshrc"
alias treload="tmux source-file ~/.tmux.conf"
alias tconfig="nvim ~/.tmux.conf"
alias pypy="source ~/.venv/bin/activate"
alias journal="cd ~/journal/Journal/"
alias p10k="p10k configure"
alias fixkb="setxkbmap ca multix"

bindkey '^[[A' up-line-or-search
bindkey '^[[B' down-line-or-search

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
eval "$(zoxide init zsh)"
source <(fzf --zsh)
EOF

# .tmux.conf
cat << 'EOF' > ~/.tmux.conf
set -g status-position top
set -g status-bg "#005f87"
set -g status-fg "#afd7ff"
set -s set-clipboard on
set -as terminal-features ',xterm-256color:clipboard'
set -g status-left ""
set -g status-right "#[fg=#afd7ff]| %H:%M #[fg=#080808,bg=#87afff,bold] $MY_TERM_NAME "
set -g mouse off
set -g window-status-current-format " #[fg=#080808,bg=#87afff,bold] #I:#W "
set-option -g default-shell /usr/bin/zsh
set -g prefix C-a
unbind C-b
bind C-a send-prefix
EOF

# init.lua
cat << 'EOF' > ~/.config/nvim/init.lua
vim.g.clipboard = {
  name = 'OSC 52',
  copy = { ['+'] = require('vim.ui.clipboard.osc52').copy('+'), ['*'] = require('vim.ui.clipboard.osc52').copy('*') },
  paste = { ['+'] = require('vim.ui.clipboard.osc52').paste('+'), ['*'] = require('vim.ui.clipboard.osc52').paste('*') },
}
vim.opt.clipboard = "unnamedplus"
vim.keymap.set({'n', 'v'}, 'p', '"+p', { noremap = true, silent = true })
vim.keymap.set({'n', 'v'}, 'y', '"+y', { noremap = true, silent = true })

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

if vim.lsp.enable then vim.lsp.enable('pyright') else require('lspconfig').pyright.setup({}) end

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.cursorline = true
vim.opt.mouse = 'a'
EOF

# .p10k.zsh
cat << 'EOF' > ~/.p10k.zsh
'builtin' 'local' '-a' 'p10k_config_opts'
[[ ! -o 'aliases' ]] || p10k_config_opts+=('aliases')
[[ ! -o 'sh_glob' ]] || p10k_config_opts+=('sh_glob')
[[ ! -o 'no_brace_expand' ]] || p10k_config_opts+=('no_brace_expand')
'builtin' 'setopt' 'no_aliases' 'no_sh_glob' 'brace_expand'
() {
  emulate -L zsh -o extended_glob
  unset -m '(POWERLEVEL9K_*|DEFAULT_USER)~POWERLEVEL9K_GITSTATUS_DIR'
  typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(my_identity dir vcs prompt_char)
  typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status command_execution_time virtualenv)
  function prompt_my_identity() { p10k segment -f 153 -t "$MY_TERM_NAME" }
  typeset -g POWERLEVEL9K_MODE=ascii
  typeset -g POWERLEVEL9K_BACKGROUND=235
  typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=false
  typeset -g POWERLEVEL9K_DIR_FOREGROUND=111
  typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGROUND=117
  typeset -g POWERLEVEL9K_DIR_ANCHOR_BOLD=true
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIINS_CONTENT_EXPANSION='>'
  typeset -g POWERLEVEL9K_VIRTUALENV_FOREGROUND=221
  typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=always
}
(( ${#p10k_config_opts} )) && setopt ${p10k_config_opts[@]}
'builtin' 'unset' 'p10k_config_opts'
EOF

# --- 6. PYTHON VIRTUAL ENV ---
echo "--- Creating Python Virtual Environment ---"
rm -rf ~/.venv
python3 -m venv ~/.venv
source ~/.venv/bin/activate
pip install pyright black ruff

echo "--- INSTALL COMPLETE! ---"
echo "Please type: 'zsh' to enter your new shell."
