#!/bin/bash

# ==========================================================
# magicuninstall.sh
# Reverts everything magicinstall.sh sets up
# ==========================================================

echo "--- Removing Docker ---"
sudo systemctl disable docker --now 2>/dev/null || true
sudo apt purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras 2>/dev/null || true
sudo rm -rf /var/lib/docker /var/lib/containerd
sudo rm -f /etc/apt/sources.list.d/docker.sources
sudo rm -f /etc/apt/keyrings/docker.asc
sudo deluser "$USER" docker 2>/dev/null || true

echo "--- Removing Neovim ---"
sudo rm -f /usr/local/bin/nvim
sudo rm -rf /opt/nvim
rm -rf ~/.config/nvim ~/.local/share/nvim ~/.cache/nvim

echo "--- Removing Oh-My-Zsh, plugins and Starship ---"
rm -rf ~/.oh-my-zsh
rm -f ~/.zshrc
sudo rm -f /usr/local/bin/starship
rm -f ~/.config/starship.toml

echo "--- Removing tmux config ---"
rm -f ~/.tmux.conf

echo "--- Removing Python venv ---"
rm -rf ~/.venv

echo "--- Removing apt packages installed by magicinstall.sh ---"
echo "(git, curl and python3-venv are left alone since other tools may depend on them)"
sudo apt remove -y zsh tmux fzf zoxide xclip nmap libfuse2t64 libfuse2 2>/dev/null || true
sudo apt autoremove -y

echo "--- DONE ---"
echo "Note: ~/.zshrc.pre-oh-my-zsh (your original zshrc backup, if it exists) was left untouched."
echo "Your default shell wasn't changed by magicinstall.sh, so nothing to revert there either."
