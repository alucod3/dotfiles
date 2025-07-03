#!/bin/bash

# =============================================================================
# Script de Instalação e Configuração de Dotfiles para Arch Linux
# Versão: 2.0
# Autor: Sistema de Configuração Automatizada
# =============================================================================

set -euo pipefail  # Modo strict: para na primeira falha

# =============================================================================
# CONFIGURAÇÕES E CONSTANTES
# =============================================================================

readonly SCRIPT_NAME="$(basename "$0")"
readonly LOG_FILE="/tmp/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
readonly BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
readonly DOTFILES_REPO="https://github.com/alucod3/dotfiles.git"  # Ajuste conforme necessário

# Cores para output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly NC='\033[0m' # No Color

# Listas de pacotes organizadas
readonly ESSENTIAL_PACKAGES=(
    "git" "curl" "wget" "base-devel"
    "bat" "btop" "fastfetch" "tree"
)

readonly TERMINAL_UTILITIES=(
    "ranger" "fzf" "lsd" "ripgrep" 
    "fd" "httpie" "whois" "duf" 
    "lazygit" "zoxide"
)

readonly I3_CONFIG=(
    "i3"
    "redshift" "feh" "flameshot"
)

readonly DEVELOPMENT_PACKAGES=(
    "docker" "docker-compose"
    "vim" "neovim" 
    "nodejs" "npm" "python-pip"
)

readonly FONT_PACKAGES=(
    "ttf-jetbrains-mono-nerd"
    "ttf-firacode-nerd"
)

readonly GUI_APPLICATIONS=(
    "bitwarden" "kitty"
)

# =============================================================================
# FUNÇÕES UTILITÁRIAS
# =============================================================================

# Função de logging
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "INFO")  echo -e "${GREEN}[INFO]${NC} $message" | tee -a "$LOG_FILE" ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC} $message" | tee -a "$LOG_FILE" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} $message" | tee -a "$LOG_FILE" ;;
        "DEBUG") echo -e "${BLUE}[DEBUG]${NC} $message" | tee -a "$LOG_FILE" ;;
        *)       echo -e "${PURPLE}[$level]${NC} $message" | tee -a "$LOG_FILE" ;;
    esac
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# Função para confirmar ação do usuário
confirm() {
    local prompt="$1"
    local response
    
    while true; do
        read -rp "$(echo -e "${YELLOW}$prompt${NC} [y/N]: ")" response
        case "$response" in
            [Yy]|[Yy][Ee][Ss]) return 0 ;;
            [Nn]|[Nn][Oo]|"") return 1 ;;
            *) echo "Por favor, responda com 'y' ou 'n'." ;;
        esac
    done
}

# Função para verificar se um comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Função para verificar se um pacote está instalado
is_package_installed() {
    pacman -Qi "$1" >/dev/null 2>&1
}

# Função para backup de arquivos
backup_file() {
    local file="$1"
    if [[ -e "$file" ]]; then
        local backup_path="$BACKUP_DIR/$(basename "$file")"
        mkdir -p "$BACKUP_DIR"
        cp -r "$file" "$backup_path"
        log "INFO" "Backup criado: $file -> $backup_path"
    fi
}

# Função para instalar pacotes com verificação
install_packages() {
    local package_list=("$@")
    local to_install=()
    
    log "INFO" "Verificando pacotes a serem instalados..."
    
    for package in "${package_list[@]}"; do
        if ! is_package_installed "$package"; then
            to_install+=("$package")
        else
            log "DEBUG" "Pacote já instalado: $package"
        fi
    done
    
    if [[ ${#to_install[@]} -gt 0 ]]; then
        log "INFO" "Instalando pacotes: ${to_install[*]}"
        if sudo pacman -S --noconfirm "${to_install[@]}"; then
            log "INFO" "Pacotes instalados com sucesso: ${to_install[*]}"
        else
            log "ERROR" "Falha ao instalar alguns pacotes"
            return 1
        fi
    else
        log "INFO" "Todos os pacotes já estão instalados"
    fi
}

# =============================================================================
# FUNÇÕES DE INSTALAÇÃO
# =============================================================================

update_system() {
    log "INFO" "Atualizando sistema..."
    if sudo pacman -Syu --noconfirm; then
        log "INFO" "Sistema atualizado com sucesso"
    else
        log "ERROR" "Falha ao atualizar sistema"
        return 1
    fi
}

install_essential_packages() {
    log "INFO" "Instalando pacotes essenciais..."
    install_packages "${ESSENTIAL_PACKAGES[@]}"
}

install_terminal_utilities() {
    if confirm "Deseja instalar utilitários de terminal (ranger, fzf, lsd, etc.)?"; then
        log "INFO" "Instalando utilitários de terminal..."
        install_packages "${TERMINAL_UTILITIES[@]}"
    fi
}

install_development_packages() {
    if confirm "Deseja instalar pacotes de desenvolvimento (Docker, Neovim, etc.)?"; then
        log "INFO" "Instalando pacotes de desenvolvimento..."
        install_packages "${DEVELOPMENT_PACKAGES[@]}"
        
        # Configurar Docker
        if is_package_installed "docker"; then
            log "INFO" "Configurando Docker..."
            if ! groups "$USER" | grep -q docker; then
                sudo usermod -aG docker "$USER"
                log "INFO" "Usuário adicionado ao grupo docker"
            fi
            
            sudo systemctl enable docker.service
            sudo systemctl start docker.service
            log "INFO" "Serviço Docker configurado"
        fi
    fi
}

install_i3() {
    if confirm "Deseja instalar i3?"; then
        log "INFO" "Instalando i3 e auxiliares..."
        install_packages "${I3_CONFIG[@]}"
    fi
}

install_fonts() {
    if confirm "Deseja instalar fontes Nerd Fonts?"; then
        log "INFO" "Instalando fontes..."
        install_packages "${FONT_PACKAGES[@]}"
    fi
}

install_gui_applications() {
    if confirm "Deseja instalar aplicações GUI (Kitty, Bitwarden...)?"; then
        log "INFO" "Instalando aplicações GUI..."
        install_packages "${GUI_APPLICATIONS[@]}"
    fi
}

setup_zsh() {
    if ! confirm "Deseja instalar e configurar Zsh com Oh My Zsh?"; then
        return 0
    fi
    
    log "INFO" "Configurando Zsh..."
    
    # Instalar Zsh se necessário
    if ! is_package_installed "zsh"; then
        install_packages "zsh"
    fi
    
    # Instalar Oh My Zsh se não existir
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        log "INFO" "Instalando Oh My Zsh..."
        backup_file "$HOME/.zshrc"
        
        export RUNZSH=no
        export CHSH=no
        
        if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"; then
            log "INFO" "Oh My Zsh instalado com sucesso"
        else
            log "ERROR" "Falha ao instalar Oh My Zsh"
            return 1
        fi
    else
        log "DEBUG" "Oh My Zsh já instalado"
    fi
    
    # Configurar Zsh como shell padrão
    if [[ "$SHELL" != "/usr/bin/zsh" ]]; then
        if confirm "Deseja definir Zsh como shell padrão?"; then
            chsh -s /usr/bin/zsh
            log "INFO" "Zsh definido como shell padrão"
        fi
    fi
}

setup_neovim() {
    if ! is_package_installed "neovim"; then
        return 0
    fi
    
    if ! confirm "Deseja configurar Neovim com LazyVim?"; then
        return 0
    fi
    
    log "INFO" "Configurando Neovim com LazyVim..."
    
    # Backup das configurações existentes
    local nvim_configs=(
        "$HOME/.config/nvim"
        "$HOME/.local/share/nvim"
        "$HOME/.local/state/nvim"
        "$HOME/.cache/nvim"
    )
    
    for config in "${nvim_configs[@]}"; do
        backup_file "$config"
        [[ -d "$config" ]] && rm -rf "$config"
    done
    
    # Clonar LazyVim starter
    if git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"; then
        rm -rf "$HOME/.config/nvim/.git"
        log "INFO" "LazyVim configurado com sucesso"
    else
        log "ERROR" "Falha ao configurar LazyVim"
        return 1
    fi
}

setup_git_config() {
    if ! command_exists "git"; then
        return 0
    fi
    
    log "INFO" "Configurando Git..."
    
    local git_name git_email
    
    # Verificar se já está configurado
    if git config --global user.name >/dev/null 2>&1 && git config --global user.email >/dev/null 2>&1; then
        log "INFO" "Git já está configurado"
        git_name=$(git config --global user.name)
        git_email=$(git config --global user.email)
        log "INFO" "Nome: $git_name, Email: $git_email"
        
        if ! confirm "Deseja reconfigurar?"; then
            return 0
        fi
    fi
    
    read -rp "Nome para commits do Git: " git_name
    if [[ -n "$git_name" ]]; then
        read -rp "Email para commits do Git: " git_email
        
        if [[ -n "$git_email" ]]; then
            git config --global user.name "$git_name"
            git config --global user.email "$git_email"
            git config --global init.defaultBranch main
            git config --global pull.rebase false
            
            log "INFO" "Git configurado: $git_name <$git_email>"
        fi
    fi
}

# =============================================================================
# TRANSFERINDO .CONFIG
# =============================================================================

setup_dotfiles() {
    log "INFO" "Configurando dotfiles..."

    # Diretório onde está o script (pasta atual)
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local config_source="$script_dir/config"
    
    # Verificar se o diretório config existe no diretório do script
    if [[ -d "$config_source" ]]; then
        log "INFO" "Diretório config encontrado em: $config_source"
        moving_dotfiles "$config_source"
    else
        log "ERROR" "Diretório config não encontrado em: $config_source"
        log "ERROR" "Certifique-se de que a pasta 'config' está no mesmo diretório do script"
        handle_error "setup_dotfiles" "Pasta config não encontrada"
    fi

        local config_dir="$1"
    
    log "INFO" "Movendo arquivos de configuração..."
    
    # Criar diretório .config se não existir
    mkdir -p "$HOME/.config"
    
    # Mover arquivos de configuração
    if [[ -d "$config_dir" ]]; then
        for item in "$config_dir"/*; do
            if [[ -e "$item" ]]; then
                local basename_item=$(basename "$item")
                local target="$HOME/.config/$basename_item"
                
                # Fazer backup se já existir
                backup_file "$target"
                
                if cp -r "$item" "$target"; then
                    log "INFO" "Copiado: $basename_item -> ~/.config/"
                else
                    log "WARN" "Falha ao copiar: $basename_item"
                fi
            fi
        done
        log "INFO" "Arquivos de configuração movidos com sucesso"
    else
        log "ERROR" "Diretório de configuração não encontrado: $config_dir"
    fi
}

# =============================================================================
# FUNÇÃO PRINCIPAL
# =============================================================================

cleanup() {
    log "INFO" "Executando limpeza..."
    
    # Limpar pacman cache
    sudo pacman -Scc --noconfirm
    log "INFO" "Cache do pacman limpo"  
    log "INFO" "Log salvo em: $LOG_FILE"
    
    if [[ -d "$BACKUP_DIR" ]]; then
        log "INFO" "Backups salvos em: $BACKUP_DIR"
    fi
}

show_summary() {
    log "INFO" "=== RESUMO DA INSTALAÇÃO ==="
    log "INFO" "Script executado com sucesso!"
    log "INFO" "Log completo: $LOG_FILE"
    
    if [[ -d "$BACKUP_DIR" ]]; then
        log "INFO" "Backups: $BACKUP_DIR"
    fi
    
    log "WARN" "IMPORTANTE: Reinicie o terminal ou execute 'source ~/.zshrc' para aplicar as mudanças"
    
    if is_package_installed "docker" && ! groups "$USER" | grep -q docker; then
        log "WARN" "Para usar Docker sem sudo, faça logout e login novamente"
    fi
}

main() {
    log "INFO" "=== INICIANDO CONFIGURAÇÃO DE DOTFILES ==="
    log "INFO" "Arch Linux Dotfiles Installer v2.0"
    log "INFO" "Log: $LOG_FILE"
    
    # Configurar trap para limpeza
    trap cleanup EXIT
    
    # Verificar se está rodando no Arch Linux
    if ! grep -q "Arch Linux" /etc/os-release 2>/dev/null; then
        log "WARN" "Este script foi projetado para Arch Linux"
        if ! confirm "Continuar mesmo assim?"; then
            exit 1
        fi
    fi
    
    # Executar funções de instalação
    update_system
    install_essential_packages
    install_terminal_utilities
    install_development_packages
    install_fonts
    install_gui_applications
    setup_zsh
    setup_neovim
    setup_git_config
    setup_dotfiles
    
    show_summary
    
    log "INFO" "=== CONFIGURAÇÃO CONCLUÍDA ==="
}

# =============================================================================
# EXECUÇÃO
# =============================================================================

# Verificar se está sendo executado como root
if [[ $EUID -eq 0 ]]; then
    log "ERROR" "Este script não deve ser executado como root"
    exit 1
fi

# Executar função principal
main "$@"