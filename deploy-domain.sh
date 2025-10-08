#!/bin/bash

set -e

echo "🚀 Iniciando setup automático do mock server + Cloudflare tunnel..."

# ===== Atualização do sistema =====
echo "📦 Atualizando pacotes..."
if command -v dnf >/dev/null 2>&1; then
  dnf -y update
elif command -v yum >/dev/null 2>&1; then
  yum -y update
else
  echo "❌ Nenhum gerenciador de pacotes compatível encontrado (dnf/yum)."
  exit 1
fi

# ===== Instalação do Node.js LTS =====
if ! command -v node >/dev/null 2>&1; then
  echo "🟩 Instalando Node.js LTS..."
  curl -fsSL https://rpm.nodesource.com/setup_lts.x | bash -
  if command -v dnf >/dev/null 2>&1; then
    dnf install -y nodejs
  else
    yum install -y nodejs
  fi
fi

# ===== Instalação do PM2 =====
if ! command -v pm2 >/dev/null 2>&1; then
  echo "⚙️ Instalando PM2..."
  npm install -g pm2
fi

# ===== Instalação do Cloudflared =====
if ! command -v cloudflared >/dev/null 2>&1; then
  echo "☁️ Instalando Cloudflared..."
  curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o /usr/local/bin/cloudflared
  chmod +x /usr/local/bin/cloudflared
fi

# ===== Iniciando túnel =====
echo "🌐 Iniciando túnel Cloudflare (porta 3001)..."
pm2 delete tunnel-mock >/dev/null 2>&1 || true
pm2 start "cloudflared tunnel --url http://localhost:3001" --name tunnel-mock --time

# ===== Salvando e configurando PM2 =====
echo "💾 Salvando configuração PM2..."
pm2 save
pm2 startup -u root --hp /root

# ===== Aguardando e mostrando a URL =====
echo "⏳ Aguardando o Cloudflare gerar a URL..."
sleep 6

echo "🔍 Buscando a URL do túnel..."
pm2 logs tunnel-mock --lines 20 --nostream | grep -o 'https://.*trycloudflare.com' | tail -n 1 > /root/cloudflare-url.txt

if [ -s /root/cloudflare-url.txt ]; then
  echo ""
  echo "✅ Túnel criado com sucesso!"
  echo "🌍 URL pública:"
  cat /root/cloudflare-url.txt
  echo ""
  echo "📄 A URL também foi salva em: /root/cloudflare-url.txt"
else
  echo "⚠️ Não foi possível capturar a URL. Veja os logs com:"
  echo "   pm2 logs tunnel-mock"
fi
