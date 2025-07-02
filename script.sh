#!/bin/bash

# Script de instalação e configuração de dotfiles para Arch Linux

# Função para verificar erro
check_error() {
  if [ $? -ne 0 ]; then
    echo "Erro: $1"
    exit 1
  fi
}

# Atualizar o sistema
echo "Atualizando o sistema..."
sudo pacman -Syu --noconfirm
check_error "Falha ao atualizar o sistema"

# Instalar pacotes essenciais
echo "Instalando pacotes essenciais..."
sudo pacman -S --noconfirm git docker curl bat btop fastfetch
check_error "Falha ao instalar pacotes essenciais"

###############################
### UTILITÁRIOS DE TERMINAL ###
###############################

if confirm "Deseja instalar utilitários de terminal como ranger, fzf, lsd, etc.?"; then
  echo "==> Instalando utilitários de terminal..."
  sudo pacman -S --noconfirm ranger fzf lsd bat ripgrep fd httpie whois duf

  # LSD alias
  if confirm "Deseja substituir os comandos por comandos aprimorados?"; then
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
      if ! grep -q "alias ls=" "$rc" 2>/dev/null; then
        echo -e "\n# Alias para lsd (ls colorido e moderno)" >>"$rc"
        echo "alias ls='lsd --group-dirs=first'" >>"$rc"
        echo "[INFO] Alias 'ls' adicionado a $rc"
      fi
    done
  fi
fi

# Instalar nerd-fonts
echo "Instalando Nerd Fonts..."
sudo pacman -S --noconfirm ttf-nerd-fonts-symbols
check_error "Falha ao instalar Nerd Fonts"

# Instalar Zsh e Oh My Zsh
echo "Instalando Zsh e Oh My Zsh..."
sudo pacman -S --noconfirm zsh

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  export RUNZSH=no
  export CHSH=no
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  check_error "Falha ao instalar Oh My Zsh"
else
  echo "Oh My Zsh já está instalado, pulando instalação..."
fi

#####################################
# Instalar Vim e Neovim com LazyVim #
#####################################

echo "Instalando Vim e Neovim..."
sudo pacman -S --noconfirm vim neovim

# required
mv ~/.config/nvim{,.bak}

# optional but recommended
mv ~/.local/share/nvim{,.bak}
mv ~/.local/state/nvim{,.bak}
mv ~/.cache/nvim{,.bak}

# Clone the starter
git clone https://github.com/LazyVim/starter ~/.config/nvim

# Remove the .git folder, so you can add it to your own repo later
rm -rf ~/.config/nvim/.git

# Checking error
check_error "Falha ao configurar LazyVim"

# Instalar Ghostty
echo "Instalando Ghostty..."
sudo pacman -S --noconfirm ghostty
check_error "Falha ao instalar Ghostty"

# Instalar Bitwarden
echo "Instalando Bitwarden..."
sudo pacman -S --noconfirm bitwarden
check_error "Falha ao instalar Bitwarden"

###################
# DOTFILES CONFIG #
###################

echo "Configurando dotfiles..."
~/dotfiles
check_error "Falha ao clonar repositório de dotfiles"

# Copiar dotfiles para ~/.config
echo "Copiando dotfiles para ~/.config..."
mkdir -p ~/.config
cp -r ~/dotfiles/.config/* ~/.config/
check_error "Falha ao copiar dotfiles"

# Configurar Zsh como shell padrão
echo "Configurando Zsh como shell padrão..."
chsh -s /usr/bin/zsh
check_error "Falha ao configurar Zsh como shell padrão"

# Habilitar e iniciar o serviço Docker
echo "Habilitando e iniciando o Docker..."
sudo pacman -S --noconfirm docker
sudo systemctl enable docker
sudo systemctl start docker
check_error "Falha ao configurar Docker"

# Limpeza
echo "Limpando arquivos temporários..."
rm -rf ~/dotfiles
check_error "Falha ao remover arquivos temporários"

echo "Configuração concluída com sucesso!"
