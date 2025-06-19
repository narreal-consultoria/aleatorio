#!/bin/bash
# sync-hub-portfolio.sh - Sincronização específica hub e portfolio

# Configurações
SOURCE_BASE="/var/www"
PROJECT_DIR="$HOME/aleatorio"
DEST_BASE="$PROJECT_DIR/var-www"
LOG_FILE="$PROJECT_DIR/sync-hub-portfolio.log"

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Função de log
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

echo -e "${BLUE}🔄 Sincronização Hub & Portfolio${NC}"
echo "=================================="
log "Iniciando sincronização hub e portfolio"

cd "$PROJECT_DIR"

# 1. Verificar se as pastas existem
echo -e "${YELLOW}🔍 Verificando pastas de origem...${NC}"
if [ ! -d "$SOURCE_BASE/hub" ]; then
    echo -e "${RED}❌ Pasta /var/www/hub não encontrada${NC}"
    exit 1
fi

if [ ! -d "$SOURCE_BASE/portfolio" ]; then
    echo -e "${RED}❌ Pasta /var/www/portfolio não encontrada${NC}"
    exit 1
fi

# 2. Criar pastas de destino se não existirem
mkdir -p "$DEST_BASE/hub"
mkdir -p "$DEST_BASE/portfolio"

# 3. Sincronizar HUB
echo -e "${YELLOW}📂 Sincronizando HUB...${NC}"
log "Iniciando sync da pasta hub"

sudo rsync -av --delete \
    --exclude='.git*' \
    --exclude='*.tmp' \
    --exclude='*.log' \
    --exclude='.DS_Store' \
    --exclude='node_modules/' \
    --exclude='cache/' \
    --exclude='tmp/' \
    "$SOURCE_BASE/hub/" "$DEST_BASE/hub/" 2>&1 | tee -a "$LOG_FILE"

HUB_STATUS=${PIPESTATUS[0]}

# 4. Sincronizar PORTFOLIO
echo -e "${YELLOW}📂 Sincronizando PORTFOLIO...${NC}"
log "Iniciando sync da pasta portfolio"

sudo rsync -av --delete \
    --exclude='.git*' \
    --exclude='*.tmp' \
    --exclude='*.log' \
    --exclude='.DS_Store' \
    --exclude='node_modules/' \
    --exclude='cache/' \
    --exclude='tmp/' \
    "$SOURCE_BASE/portfolio/" "$DEST_BASE/portfolio/" 2>&1 | tee -a "$LOG_FILE"

PORTFOLIO_STATUS=${PIPESTATUS[0]}

# 5. Ajustar permissões
echo -e "${YELLOW}🔧 Ajustando permissões...${NC}"
sudo chown -R $(whoami):$(whoami) "$DEST_BASE/hub" "$DEST_BASE/portfolio"

# 6. Verificar mudanças no Git
echo -e "${YELLOW}📝 Verificando mudanças...${NC}"
git add var-www/hub/ var-www/portfolio/ 2>/dev/null

if ! git diff-index --quiet --cached HEAD -- 2>/dev/null; then
    # Há mudanças para commitar
    
    # Estatísticas
    HUB_FILES=$(find var-www/hub -type f 2>/dev/null | wc -l)
    PORTFOLIO_FILES=$(find var-www/portfolio -type f 2>/dev/null | wc -l)
    HUB_SIZE=$(du -sh var-www/hub 2>/dev/null | cut -f1)
    PORTFOLIO_SIZE=$(du -sh var-www/portfolio 2>/dev/null | cut -f1)
    
    COMMIT_MSG="sync: hub e portfolio $(date '+%Y-%m-%d %H:%M:%S')

📊 Estatísticas:
├── Hub: $HUB_FILES arquivos ($HUB_SIZE)
└── Portfolio: $PORTFOLIO_FILES arquivos ($PORTFOLIO_SIZE)

🔧 Status da sincronização:
├── Hub: $([ $HUB_STATUS -eq 0 ] && echo "✅ Sucesso" || echo "❌ Erro")
└── Portfolio: $([ $PORTFOLIO_STATUS -eq 0 ] && echo "✅ Sucesso" || echo "❌ Erro")

⏰ Timestamp: $(date '+%Y-%m-%d %H:%M:%S')
🔄 Método: rsync com exclusões automáticas"

    echo -e "${YELLOW}💾 Criando commit...${NC}"
    if git commit -m "$COMMIT_MSG"; then
        echo -e "${GREEN}✅ Commit criado com sucesso${NC}"
        log "Commit criado com sucesso"
        
        # Push para GitHub
        echo -e "${YELLOW}⬆️ Enviando para GitHub...${NC}"
        if git push origin main; then
            echo -e "${GREEN}✅ Push realizado com sucesso!${NC}"
            log "Push realizado com sucesso"
        else
            echo -e "${RED}❌ Erro no push${NC}"
            log "ERRO: Falha no push"
        fi
    else
        echo -e "${RED}❌ Erro ao criar commit${NC}"
        log "ERRO: Falha ao criar commit"
    fi
else
    echo -e "${GREEN}✅ Nenhuma mudança detectada${NC}"
    log "Nenhuma mudança detectada"
fi

# 7. Relatório final
echo -e "\n${BLUE}📊 Relatório Final${NC}"
echo "=================="
echo "Hub:"
echo "  └── Arquivos: $(find var-www/hub -type f 2>/dev/null | wc -l)"
echo "  └── Tamanho: $(du -sh var-www/hub 2>/dev/null | cut -f1)"
echo "Portfolio:"
echo "  └── Arquivos: $(find var-www/portfolio -type f 2>/dev/null | wc -l)"
echo "  └── Tamanho: $(du -sh var-www/portfolio 2>/dev/null | cut -f1)"
echo "Git:"
echo "  └── Último commit: $(git log -1 --format='%h - %s' 2>/dev/null)"
echo "  └── Status: $(git status --porcelain | wc -l) arquivo(s) não commitado(s)"

log "Sincronização finalizada"

