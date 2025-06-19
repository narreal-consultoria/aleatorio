#!/bin/bash
# check-hub-portfolio.sh - Verificação rápida

echo "📊 Status Hub & Portfolio"
echo "========================"

cd ~/aleatorio

echo "🔍 Estrutura atual:"
ls -la var-www/ 2>/dev/null || echo "Pasta var-www não existe"

if [ -d "var-www/hub" ]; then
    echo "Hub: $(find var-www/hub -type f | wc -l) arquivos ($(du -sh var-www/hub | cut -f1))"
else
    echo "Hub: ❌ Não encontrado"
fi

if [ -d "var-www/portfolio" ]; then
    echo "Portfolio: $(find var-www/portfolio -type f | wc -l) arquivos ($(du -sh var-www/portfolio | cut -f1))"
else
    echo "Portfolio: ❌ Não encontrado"
fi

echo -e "\n📅 Última sincronização:"
if [ -f "sync-hub-portfolio.log" ]; then
    tail -1 sync-hub-portfolio.log
else
    echo "Nenhum log encontrado"
fi

echo -e "\n🔄 Status Git:"
git status --short | head -5
