#!/bin/bash
set -e

# ======== CONFIGURAÇÕES ==========
APP_NAME="fetapijson"
APP_DIR="/var/www/$APP_NAME"
GIT_REPO="https://github.com/Francisco-Fetapi/fetapijson.git"
BRANCH="main"

# ======== CORES ==========
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}🚀 Iniciando deploy de $APP_NAME...${NC}"

# ======== VERIFICA OU INSTALA DEPENDÊNCIAS ==========
if ! command -v git &> /dev/null; then
  echo -e "${RED}❌ Git não está instalado.${NC}"
  echo -e "${YELLOW}➡️ Instalando git...${NC}"
  sudo apt update && sudo apt install git -y
fi

if ! command -v bun &> /dev/null; then
  echo -e "${YELLOW}⚙️ Instalando Bun...${NC}"
  curl -fsSL https://bun.sh/install | bash
  export BUN_INSTALL="$HOME/.bun"
  export PATH="$BUN_INSTALL/bin:$PATH"
fi

if ! command -v pm2 &> /dev/null; then
  echo -e "${YELLOW}⚙️ Instalando PM2...${NC}"
  bun install -g pm2
fi

# ======== CLONA OU ATUALIZA O REPOSITÓRIO ==========
if [ ! -d "$APP_DIR" ]; then
  echo -e "${GREEN}📦 Clonando repositório...${NC}"
  sudo git clone "$GIT_REPO" "$APP_DIR"
else
  echo -e "${GREEN}🔄 Atualizando repositório...${NC}"
  cd "$APP_DIR"
  sudo git fetch origin $BRANCH
  sudo git reset --hard origin/$BRANCH
fi

# ======== INSTALA DEPENDÊNCIAS ==========
cd "$APP_DIR"
echo -e "${GREEN}📦 Instalando dependências com Bun...${NC}"
bun install

# ======== INICIA OU REINICIA O SERVIDOR COM PM2 ==========
echo -e "${GREEN}🚀 Iniciando servidor com PM2 via script 'start:pm2'...${NC}"

# Remove instância antiga se existir
pm2 delete mock-server --silent || true

# Usa o script do package.json
bun run start:pm2

# ======== SALVA CONFIGURAÇÃO DO PM2 ==========
pm2 save
pm2 startup systemd -u $USER --hp $HOME

echo -e "${GREEN}✅ Deploy finalizado com sucesso!${NC}"
echo -e "${YELLOW}🌍 Acesse: http://<SEU_IP>:3001${NC}"
