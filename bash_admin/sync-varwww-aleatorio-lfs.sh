#!/bin/bash
# sync-varwww-aleatorio-lfs.sh - Com suporte ao Git LFS

SOURCE_DIR="/var/www/"
PROJECT_DIR="$HOME/aleatorio"
BACKUP_SUBDIR="$PROJECT_DIR/var-www"
LOG_FILE="$PROJECT_DIR/var-www-sync.log"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

echo -e "${BLUE}🔄 Sincronização /var/www com Git LFS${NC}"
log "Iniciando sincronização com LFS"

cd "$PROJECT_DIR"
mkdir -p "$BACKUP_SUBDIR"

# 1. Verificar se Git LFS está configurado
if ! git lfs version >/dev/null 2>&1; then
    echo -e "${RED}❌ Git LFS não instalado. Instalando...${NC}"
    sudo apt update && sudo apt install git-lfs
    git lfs install
fi

# 2. Configurar tracking para arquivos grandes se não existir
if [ ! -f .gitattributes ]; then
    echo -e "${YELLOW}📝 Configurando Git LFS tracking...${NC}"
    
    cat > .gitattributes << 'EOF'
# Git LFS tracking para arquivos grandes
*.AppImage filter=lfs diff=lfs merge=lfs -text
*.iso filter=lfs diff=lfs merge=lfs -text
*.zip filter=lfs diff=lfs merge=lfs -text
*.tar.gz filter=lfs diff=lfs merge=lfs -text
*.deb filter=lfs diff=lfs merge=lfs -text
*.rpm filter=lfs diff=lfs merge=lfs -text
*.dmg filter=lfs diff=lfs merge=lfs -text
*.exe filter=lfs diff=lfs merge=lfs -text
*.msi filter=lfs diff=lfs merge=lfs -text

# Arquivos específicos do Nextcloud
var-www/nextcloud/apps/*/collabora/*.AppImage filter=lfs diff=lfs merge=lfs -text
var-www/*/data/*/files/* filter=lfs diff=lfs merge=lfs -text
var-www/*/backup/* filter=lfs diff=lfs merge=lfs -text

# Arquivos de mídia grandes
*.mp4 filter=lfs diff=lfs merge=lfs -text
*.avi filter=lfs diff=lfs merge=lfs -text
*.mov filter=lfs diff=lfs merge=lfs -text
*.mkv filter=lfs diff=lfs merge=lfs -text
*.pdf filter=lfs diff=lfs merge=lfs -text
EOF

    git add .gitattributes
    git commit -m "feat: configurar Git LFS para arquivos grandes"
fi

# 3. Verificar arquivos grandes antes do rsync
echo -e "${YELLOW}🔍 Verificando arquivos grandes existentes...${NC}"
find var-www/ -type f -size +50M 2>/dev/null | head -10

# 4. Rsync
echo -e "${YELLOW}📂 Executando rsync...${NC}"
sudo rsync -av --delete --stats \
    --exclude='.git' \
    --exclude='*.tmp' \
    --exclude='*.log' \
    --exclude='.DS_Store' \
    --exclude='nextcloud/data/*/files/*' \
    --exclude='nextcloud_data_backup/*/files/*' \
    --exclude='html/nextcloud/data' \
    --exclude='*/cache' \
    --exclude='*/sessions' \
    --exclude='*/tmp' \
    "$SOURCE_DIR" "$BACKUP_SUBDIR/" 2>&1 | \
    tee -a "$LOG_FILE"

# Ajustar permissões
sudo chown -R $(whoami):$(whoami) "$BACKUP_SUBDIR" 2>/dev/null

# 5. Verificar e migrar arquivos grandes para LFS
echo -e "${YELLOW}🔄 Verificando arquivos que precisam ir para LFS...${NC}"

# Encontrar arquivos grandes que não estão no LFS
LARGE_FILES=$(find var-www/ -type f -size +50M ! -path "*/.git/*" 2>/dev/null || true)

if [ -n "$LARGE_FILES" ]; then
    echo -e "${YELLOW}📦 Arquivos grandes encontrados:${NC}"
    echo "$LARGE_FILES" | head -5
    
    # Adicionar ao LFS tracking se necessário
    echo "$LARGE_FILES" | while read file; do
        if [ -f "$file" ]; then
            # Obter extensão
            ext="${file##*.}"
            
            # Verificar se já está sendo rastreado
            if ! grep -q "\\*\\.$ext.*filter=lfs" .gitattributes 2>/dev/null; then
                echo "Adicionando *.$ext ao LFS tracking"
                echo "*.$ext filter=lfs diff=lfs merge=lfs -text" >> .gitattributes
            fi
        fi
    done
fi

# 6. Git operations com LFS
git add .

# Verificar mudanças
if ! git diff-index --quiet --cached HEAD -- 2>/dev/null; then
    echo -e "${YELLOW}📝 Criando commit...${NC}"
    
    # Estatísticas
    MODIFIED=$(git diff --cached --name-only | wc -l)
    LFS_FILES=$(git lfs ls-files | wc -l)
    
    COMMIT_MSG="sync: var-www com LFS $(date '+%Y-%m-%d %H:%M:%S')

📊 Estatísticas:
- Arquivos modificados: $MODIFIED
- Arquivos no LFS: $LFS_FILES
- Tamanho var-www/: $(du -sh var-www/ 2>/dev/null | cut -f1)

🔧 Git LFS:
- Configuração: Ativa
- Tracking: Arquivos grandes automático
- Status: $(git lfs status | head -3 | tail -1 || echo "OK")

Detalhes:
$(git diff --cached --name-status | head -10)
$([ $(git diff --cached --name-status | wc -l) -gt 10 ] && echo "... e mais arquivos")"

    if git commit -m "$COMMIT_MSG"; then
        echo -e "${GREEN}✅ Commit criado${NC}"
        
        # Push com LFS
        echo -e "${YELLOW}⬆️ Fazendo push com Git LFS...${NC}"
        echo -e "${BLUE}💡 Isso pode demorar devido aos arquivos grandes...${NC}"
        
        if git push origin main; then
            echo -e "${GREEN}✅ Push concluído com sucesso!${NC}"
            log "Sincronização com LFS concluída"
        else
            echo -e "${RED}❌ Erro no push${NC}"
            log "ERRO: Falha no push com LFS"
            
            # Diagnóstico LFS
            echo -e "${YELLOW}🔍 Diagnóstico Git LFS:${NC}"
            git lfs status
            git lfs ls-files | head -5
        fi
    fi
else
    echo -e "${GREEN}✅ Nenhuma mudança detectada${NC}"
    log "Nenhuma mudança detectada"
fi

# 7. Relatório LFS
echo -e "${BLUE}📊 Relatório Git LFS:${NC}"
echo "═══════════════════════════════════════"
echo "Arquivos no LFS: $(git lfs ls-files | wc -l)"
echo "Tamanho LFS: $(git lfs ls-files -s | awk '{sum+=$2} END {printf "%.1f MB", sum/1024/1024}')"
echo "Tracking configurado: $(grep -c "filter=lfs" .gitattributes 2>/dev/null || echo "0") tipos"
echo "─────────────────────────────────────"
echo "Total arquivos: $(find var-www/ -type f 2>/dev/null | wc -l)"
echo "Tamanho total: $(du -sh var-www/ 2>/dev/null | cut -f1)"
echo "═══════════════════════════════════════"

# 8. Mostrar arquivos LFS (primeiros 5)
if [ $(git lfs ls-files | wc -l) -gt 0 ]; then
    echo -e "${BLUE}📁 Arquivos no Git LFS (primeiros 5):${NC}"
    git lfs ls-files | head -5
fi
