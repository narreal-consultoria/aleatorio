#!/bin/bash
# setup-hub-portfolio-sync.sh - Configuração inicial

echo "🚀 Configuração Hub & Portfolio Sync"
echo "===================================="

cd ~/aleatorio

# 1. Verificar estrutura do projeto
if [ ! -d ".git" ]; then
    echo "❌ Não está em um repositório Git"
    exit 1
fi

# 2. Criar .gitignore se não existir
if [ ! -f ".gitignore" ]; then
    echo "📝 Criando .gitignore..."
    cat > .gitignore << 'EOF'
# Logs
*.log
sync-*.log

# Temporários
*.tmp
*.temp
.DS_Store

# Node modules
node_modules/

# Cache
cache/
tmp/
EOF
fi

# 3. Configurar estrutura
echo "📁 Configurando estrutura..."
mkdir -p var-www/hub
mkdir -p var-www/portfolio

# 4. Primeira sincronização
echo "🔄 Executando primeira sincronização..."
~/sync-hub-portfolio.sh

# 5. Configurar cron (opcional)
echo -e "\n❓ Deseja configurar sincronização automática? (y/n)"
read -p "Resposta: " auto_sync

if [ "$auto_sync" = "y" ]; then
    echo "⏰ Configurando cron job..."
    (crontab -l 2>/dev/null; echo "0 */2 * * * /home/fred/sync-hub-portfolio.sh >> /home/fred/aleatorio/sync-cron.log 2>&1") | crontab -
    echo "✅ Sincronização automática configurada (a cada 2 horas)"
fi

echo -e "\n✅ Configuração concluída!"
echo "📋 Comandos disponíveis:"
echo "  ~/sync-hub-portfolio.sh     - Sincronizar manualmente"
echo "  ~/check-hub-portfolio.sh    - Verificar status"
echo "  crontab -l                  - Ver agendamentos"
