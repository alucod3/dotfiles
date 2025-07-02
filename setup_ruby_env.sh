#!/bin/bash

# =============================================================================
# Script de Instalação e Configuração do Ruby via rbenv para Arch Linux
# Versão: 2.0
# Descrição: Instala Ruby de forma otimizada usando rbenv com detecção inteligente
# =============================================================================

set -euo pipefail  # Modo strict: para na primeira falha

# =============================================================================
# CONFIGURAÇÕES E CONSTANTES
# =============================================================================

readonly SCRIPT_NAME="$(basename "$0")"
readonly LOG_FILE="/tmp/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
readonly BACKUP_DIR="$HOME/.ruby_backup_$(date +%Y%m%d_%H%M%S)"

# Cores para output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# URLs e diretórios
readonly RBENV_REPO="https://github.com/rbenv/rbenv.git"
readonly RUBY_BUILD_REPO="https://github.com/rbenv/ruby-build.git"
readonly RBENV_DIR="$HOME/.rbenv"
readonly RUBY_BUILD_DIR="$HOME/.rbenv/plugins/ruby-build"

# Dependências do Ruby por categoria
readonly BUILD_DEPENDENCIES=(
    "base-devel" "git" "curl" "wget"
)

readonly RUBY_DEPENDENCIES=(
    "zlib" "libffi" "openssl" "readline" 
    "libyaml" "gdbm" "ncurses" "libxml2" 
    "libxslt" "sqlite"
)

readonly OPTIONAL_DEPENDENCIES=(
    "imagemagick" "postgresql-libs" "mysql"
)

# Configurações de shell
readonly SHELL_CONFIGS=(
    "$HOME/.bashrc"
    "$HOME/.zshrc" 
    "$HOME/.profile"
    "$HOME/.bash_profile"
)

# Gems essenciais
readonly ESSENTIAL_GEMS=(
    "bundler"
    "rake"
    "irb"
    "reline"
)

readonly POPULAR_GEMS=(
    "rails"
    "puma"
    "pg"
    "redis"
    "sidekiq"
    "rspec"
    "rubocop"
)

# =============================================================================
# FUNÇÕES UTILITÁRIAS
# =============================================================================

# Função de logging melhorada
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "INFO")    echo -e "${GREEN}[INFO]${NC} $message" | tee -a "$LOG_FILE" ;;
        "WARN")    echo -e "${YELLOW}[WARN]${NC} $message" | tee -a "$LOG_FILE" ;;
        "ERROR")   echo -e "${RED}[ERROR]${NC} $message" | tee -a "$LOG_FILE" ;;
        "DEBUG")   echo -e "${BLUE}[DEBUG]${NC} $message" | tee -a "$LOG_FILE" ;;
        "SUCCESS") echo -e "${CYAN}[SUCCESS]${NC} $message" | tee -a "$LOG_FILE" ;;
        *)         echo -e "${PURPLE}[$level]${NC} $message" | tee -a "$LOG_FILE" ;;
    esac
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# Função para spinner/loading
show_spinner() {
    local pid=$1
    local message="$2"
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        printf "\r${BLUE}[%c]${NC} %s" "${spin:i++%${#spin}:1}" "$message"
        sleep 0.1
    done
    printf "\r"
}

# Função para confirmar ação do usuário
confirm() {
    local prompt="$1"
    local default="${2:-n}"
    local response
    
    while true; do
        if [[ "$default" == "y" ]]; then
            read -rp "$(echo -e "${YELLOW}$prompt${NC} [Y/n]: ")" response
            response=${response:-y}
        else
            read -rp "$(echo -e "${YELLOW}$prompt${NC} [y/N]: ")" response
            response=${response:-n}
        fi
        
        case "$response" in
            [Yy]|[Yy][Ee][Ss]) return 0 ;;
            [Nn]|[Nn][Oo]) return 1 ;;
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
    if [[ -f "$file" ]]; then
        mkdir -p "$BACKUP_DIR"
        local backup_path="$BACKUP_DIR/$(basename "$file").$(date +%s)"
        cp "$file" "$backup_path"
        log "DEBUG" "Backup criado: $file -> $backup_path"
    fi
}

# Função para detectar shell atual
detect_shell() {
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        echo "zsh"
    elif [[ -n "${BASH_VERSION:-}" ]]; then
        echo "bash"
    else
        echo "$(basename "$SHELL")"
    fi
}

# Função para obter versão mais recente do Ruby
get_latest_ruby_version() {
    local versions
    if ! versions=$(rbenv install -l 2>/dev/null | grep -E '^\s*[0-9]+\.[0-9]+\.[0-9]+$' | tail -1 | xargs); then
        log "WARN" "Não foi possível obter versões do Ruby via rbenv, usando fallback"
        echo "3.3.0"  # Fallback para uma versão conhecida
        return 1
    fi
    echo "$versions"
}

# Função para instalar pacotes com verificação
install_packages() {
    local package_list=("$@")
    local to_install=()
    
    log "INFO" "Verificando dependências..."
    
    for package in "${package_list[@]}"; do
        if ! is_package_installed "$package"; then
            to_install+=("$package")
        else
            log "DEBUG" "Já instalado: $package"
        fi
    done
    
    if [[ ${#to_install[@]} -gt 0 ]]; then
        log "INFO" "Instalando: ${to_install[*]}"
        if sudo pacman -S --noconfirm "${to_install[@]}"; then
            log "SUCCESS" "Pacotes instalados: ${to_install[*]}"
        else
            log "ERROR" "Falha ao instalar dependências"
            return 1
        fi
    else
        log "INFO" "Todas as dependências já estão instaladas"
    fi
}

# =============================================================================
# FUNÇÕES DE INSTALAÇÃO
# =============================================================================

update_system() {
    log "INFO" "Atualizando sistema..."
    
    if sudo pacman -Syu --noconfirm >/dev/null 2>&1; then
        log "SUCCESS" "Sistema atualizado"
    else
        log "ERROR" "Falha ao atualizar sistema"
        return 1
    fi
}

install_dependencies() {
    log "INFO" "Instalando dependências de compilação..."
    install_packages "${BUILD_DEPENDENCIES[@]}"
    
    log "INFO" "Instalando dependências do Ruby..."
    install_packages "${RUBY_DEPENDENCIES[@]}"
    
    if confirm "Deseja instalar dependências opcionais (ImageMagick, PostgreSQL, MySQL)?"; then
        log "INFO" "Instalando dependências opcionais..."
        install_packages "${OPTIONAL_DEPENDENCIES[@]}"
    fi
}

install_rbenv() {
    log "INFO" "Configurando rbenv..."
    
    if [[ -d "$RBENV_DIR" ]]; then
        log "INFO" "rbenv já existe, atualizando..."
        cd "$RBENV_DIR"
        git pull origin master >/dev/null 2>&1 || {
            log "WARN" "Falha ao atualizar rbenv, continuando..."
        }
    else
        log "INFO" "Clonando rbenv..."
        if git clone "$RBENV_REPO" "$RBENV_DIR" >/dev/null 2>&1; then
            log "SUCCESS" "rbenv clonado"
        else
            log "ERROR" "Falha ao clonar rbenv"
            return 1
        fi
    fi
    
    # Compilar rbenv para melhor performance
    log "INFO" "Compilando rbenv..."
    cd "$RBENV_DIR"
    if src/configure && make -C src >/dev/null 2>&1; then
        log "SUCCESS" "rbenv compilado"
    else
        log "WARN" "Falha ao compilar rbenv, mas continuando..."
    fi
}

install_ruby_build() {
    log "INFO" "Configurando ruby-build..."
    
    mkdir -p "$(dirname "$RUBY_BUILD_DIR")"
    
    if [[ -d "$RUBY_BUILD_DIR" ]]; then
        log "INFO" "ruby-build já existe, atualizando..."
        cd "$RUBY_BUILD_DIR"
        git pull origin master >/dev/null 2>&1 || {
            log "WARN" "Falha ao atualizar ruby-build, continuando..."
        }
    else
        log "INFO" "Clonando ruby-build..."
        if git clone "$RUBY_BUILD_REPO" "$RUBY_BUILD_DIR" >/dev/null 2>&1; then
            log "SUCCESS" "ruby-build instalado"
        else
            log "ERROR" "Falha ao instalar ruby-build"
            return 1
        fi
    fi
}

configure_shell() {
    log "INFO" "Configurando shells..."
    
    local rbenv_config='
# Configuração do rbenv - Adicionado automaticamente
export PATH="$HOME/.rbenv/bin:$PATH"
if command -v rbenv >/dev/null 2>&1; then
    eval "$(rbenv init -)"
fi'
    
    local current_shell=$(detect_shell)
    local configured_shells=()
    
    for shell_config in "${SHELL_CONFIGS[@]}"; do
        if [[ -f "$shell_config" ]]; then
            backup_file "$shell_config"
            
            if ! grep -q "rbenv init" "$shell_config" 2>/dev/null; then
                echo "$rbenv_config" >> "$shell_config"
                configured_shells+=("$(basename "$shell_config")")
                log "DEBUG" "rbenv configurado em $shell_config"
            else
                log "DEBUG" "rbenv já configurado em $shell_config"
            fi
        fi
    done
    
    if [[ ${#configured_shells[@]} -gt 0 ]]; then
        log "SUCCESS" "rbenv configurado em: ${configured_shells[*]}"
    fi
    
    # Configurar rbenv no shell atual
    export PATH="$HOME/.rbenv/bin:$PATH"
    if command_exists rbenv; then
        eval "$(rbenv init -)"
        log "DEBUG" "rbenv inicializado no shell atual"
    fi
}

install_ruby() {
    log "INFO" "Instalando Ruby..."
    
    if ! command_exists rbenv; then
        log "ERROR" "rbenv não encontrado no PATH"
        return 1
    fi
    
    local ruby_version
    ruby_version=$(get_latest_ruby_version)
    
    if [[ -z "$ruby_version" ]]; then
        log "ERROR" "Não foi possível determinar versão do Ruby"
        return 1
    fi
    
    log "INFO" "Versão selecionada: Ruby $ruby_version"
    
    # Verificar se já está instalada
    if rbenv versions | grep -q "$ruby_version"; then
        log "INFO" "Ruby $ruby_version já está instalado"
        rbenv global "$ruby_version"
        rbenv rehash
        return 0
    fi
    
    # Configurar otimizações de compilação
    export RUBY_CONFIGURE_OPTS="--enable-shared --disable-install-doc"
    export CPPFLAGS="-I/usr/include/openssl-1.0"
    export PKG_CONFIG_PATH="/usr/lib/openssl-1.0/pkgconfig"
    
    log "INFO" "Compilando Ruby $ruby_version (isso pode demorar)..."
    
    # Instalar com feedback visual
    if rbenv install -s "$ruby_version" > /tmp/ruby_install.log 2>&1 & then
        local install_pid=$!
        show_spinner $install_pid "Compilando Ruby $ruby_version..."
        wait $install_pid
        
        if [[ $? -eq 0 ]]; then
            log "SUCCESS" "Ruby $ruby_version instalado"
            rbenv global "$ruby_version"
            rbenv rehash
        else
            log "ERROR" "Falha ao instalar Ruby $ruby_version"
            log "ERROR" "Log de instalação em /tmp/ruby_install.log"
            return 1
        fi
    else
        log "ERROR" "Falha ao iniciar instalação do Ruby"
        return 1
    fi
}

install_essential_gems() {
    log "INFO" "Instalando gems essenciais..."
    
    if ! command_exists gem; then
        log "ERROR" "Comando 'gem' não encontrado"
        return 1
    fi
    
    # Configurar gem para não instalar documentação por padrão
    local gemrc="$HOME/.gemrc"
    if [[ ! -f "$gemrc" ]] || ! grep -q "no-document" "$gemrc"; then
        echo "gem: --no-document" >> "$gemrc"
        log "DEBUG" "Configuração .gemrc criada"
    fi
    
    local failed_gems=()
    
    for gem in "${ESSENTIAL_GEMS[@]}"; do
        if gem list -i "^${gem}$" >/dev/null 2>&1; then
            log "DEBUG" "Gem já instalada: $gem"
        else
            log "INFO" "Instalando gem: $gem"
            if gem install "$gem" >/dev/null 2>&1; then
                log "SUCCESS" "Gem instalada: $gem"
            else
                log "WARN" "Falha ao instalar gem: $gem"
                failed_gems+=("$gem")
            fi
        fi
    done
    
    if [[ ${#failed_gems[@]} -gt 0 ]]; then
        log "WARN" "Gems que falharam: ${failed_gems[*]}"
    fi
    
    rbenv rehash
}

install_popular_gems() {
    if ! confirm "Deseja instalar gems populares (Rails, RSpec, Rubocop, etc.)?"; then
        return 0
    fi
    
    log "INFO" "Instalando gems populares..."
    
    local failed_gems=()
    
    for gem in "${POPULAR_GEMS[@]}"; do
        if gem list -i "^${gem}$" >/dev/null 2>&1; then
            log "DEBUG" "Gem já instalada: $gem"
        else
            log "INFO" "Instalando gem: $gem"
            if gem install "$gem" --no-document >/dev/null 2>&1; then
                log "SUCCESS" "Gem instalada: $gem"
            else
                log "WARN" "Falha ao instalar gem: $gem"
                failed_gems+=("$gem")
            fi
        fi
    done
    
    if [[ ${#failed_gems[@]} -gt 0 ]]; then
        log "WARN" "Algumas gems falharam na instalação: ${failed_gems[*]}"
        log "INFO" "Você pode tentar instalá-las manualmente depois"
    fi
    
    rbenv rehash
}

# =============================================================================
# FUNÇÕES DE VERIFICAÇÃO E LIMPEZA
# =============================================================================

verify_installation() {
    log "INFO" "Verificando instalação..."
    
    local errors=0
    
    # Verificar rbenv
    if ! command_exists rbenv; then
        log "ERROR" "rbenv não está no PATH"
        ((errors++))
    else
        log "SUCCESS" "rbenv: $(rbenv --version)"
    fi
    
    # Verificar Ruby
    if ! command_exists ruby; then
        log "ERROR" "Ruby não está disponível"
        ((errors++))
    else
        local ruby_version=$(ruby --version)
        log "SUCCESS" "Ruby: $ruby_version"
    fi
    
    # Verificar gems
    if ! command_exists gem; then
        log "ERROR" "RubyGems não está disponível"
        ((errors++))
    else
        local gem_version=$(gem --version)
        log "SUCCESS" "RubyGems: $gem_version"
    fi
    
    # Verificar Bundler
    if ! command_exists bundle; then
        log "WARN" "Bundler não está disponível"
    else
        local bundler_version=$(bundle --version)
        log "SUCCESS" "Bundler: $bundler_version"
    fi
    
    return $errors
}

show_summary() {
    local current_shell=$(detect_shell)
    
    echo
    log "INFO" "=== RESUMO DA INSTALAÇÃO ==="
    
    if command_exists ruby; then
        log "SUCCESS" "✅ Ruby instalado: $(ruby --version)"
    fi
    
    if command_exists rbenv; then
        log "SUCCESS" "✅ rbenv instalado: $(rbenv --version)"
        log "INFO" "   Versões disponíveis: $(rbenv versions --bare | tr '\n' ' ')"
    fi
    
    if command_exists gem; then
        local gem_count=$(gem list --local | wc -l)
        log "SUCCESS" "✅ RubyGems: $gem_count gems instaladas"
    fi
    
    if command_exists bundle; then
        log "SUCCESS" "✅ Bundler instalado: $(bundle --version)"
    fi
    
    echo
    log "INFO" "📁 Log detalhado: $LOG_FILE"
    
    if [[ -d "$BACKUP_DIR" ]]; then
        log "INFO" "📁 Backups: $BACKUP_DIR"
    fi
    
    echo
    log "WARN" "⚠️  IMPORTANTE:"
    log "WARN" "   • Reinicie seu terminal ou execute:"
    log "WARN" "     source ~/.${current_shell}rc"
    log "WARN" "   • Para verificar: ruby --version"
    log "WARN" "   • Para listar versões: rbenv versions"
    log "WARN" "   • Para trocar versão: rbenv global <versão>"
    
    echo
    log "SUCCESS" "🎉 Ambiente Ruby configurado com sucesso!"
}

cleanup() {
    log "DEBUG" "Executando limpeza..."
    
    # Limpar arquivos temporários
    rm -f /tmp/ruby_install.log
    
    # Remover variáveis de ambiente temporárias
    unset RUBY_CONFIGURE_OPTS CPPFLAGS PKG_CONFIG_PATH
}

# =============================================================================
# FUNÇÃO PRINCIPAL
# =============================================================================

main() {
    log "INFO" "=== INSTALAÇÃO DO RUBY VIA RBENV ==="
    log "INFO" "Ruby Environment Installer v2.0"
    log "INFO" "Log: $LOG_FILE"
    
    # Configurar trap para limpeza
    trap cleanup EXIT
    
    # Verificar sistema operacional
    if ! grep -q "Arch Linux" /etc/os-release 2>/dev/null; then
        log "WARN" "Este script foi otimizado para Arch Linux"
        if ! confirm "Continuar mesmo assim?"; then
            exit 1
        fi
    fi
    
    # Verificar se não está rodando como root
    if [[ $EUID -eq 0 ]]; then
        log "ERROR" "Este script não deve ser executado como root"
        exit 1
    fi
    
    # Executar instalação
    update_system || exit 1
    install_dependencies || exit 1
    install_rbenv || exit 1
    install_ruby_build || exit 1
    configure_shell || exit 1
    install_ruby || exit 1
    install_essential_gems || exit 1
    install_popular_gems
    
    # Verificar e mostrar resumo
    if verify_installation; then
        show_summary
        log "SUCCESS" "=== INSTALAÇÃO CONCLUÍDA COM SUCESSO ==="
    else
        log "ERROR" "=== INSTALAÇÃO CONCLUÍDA COM ERROS ==="
        log "ERROR" "Verifique o log para mais detalhes: $LOG_FILE"
        exit 1
    fi
}

# =============================================================================
# EXECUÇÃO
# =============================================================================

main "$@"