#!/bin/bash

set -e

echo "==> Atualizando o sistema..."
sudo pacman -Syu --noconfirm

echo "==> Instalando dependências de compilação e bibliotecas..."
sudo pacman -S --noconfirm base-devel git curl zlib libffi openssl readline libyaml

echo "==> Instalando rbenv..."
if [ ! -d "$HOME/.rbenv" ]; then
  git clone https://github.com/rbenv/rbenv.git ~/.rbenv
  cd ~/.rbenv && src/configure && make -C src
fi

echo "==> Instalando ruby-build como plugin do rbenv..."
mkdir -p ~/.rbenv/plugins
if [ ! -d "$HOME/.rbenv/plugins/ruby-build" ]; then
  git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
fi

# Define rbenv PATH e init para múltiplos shells
add_to_shell_rc() {
  local shell_rc=$1
  if ! grep -q 'rbenv init' "$shell_rc" 2>/dev/null; then
    echo -e '\n# Configuração do rbenv' >>"$shell_rc"
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >>"$shell_rc"
    echo 'eval "$(rbenv init - bash)"' >>"$shell_rc"
    echo "[INFO] rbenv adicionado a $shell_rc"
  fi
}

echo "==> Adicionando rbenv ao PATH e init..."
add_to_shell_rc "$HOME/.bashrc"
add_to_shell_rc "$HOME/.zshrc"
add_to_shell_rc "$HOME/.profile"

# Também exporta no script atual
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init - bash)"

echo "==> Instalando última versão estável do Ruby..."
LATEST_RUBY=$(rbenv install -l | grep -v - | tail -1 | xargs)
rbenv install -s "$LATEST_RUBY"
rbenv global "$LATEST_RUBY"
rbenv rehash

echo "==> Ruby $(ruby -v) instalado com sucesso!"

echo "==> Instalando Bundler e Rails..."
gem install bundler
gem install rails

echo "✅ Ambiente Ruby configurado com sucesso!"
echo "ℹ️ Reinicie seu terminal ou rode: source ~/.bashrc (ou ~/.zshrc)"
