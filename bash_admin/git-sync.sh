#!/bin/bash
# git-sync-safe.sh

echo "1. Buscando atualizações do repositório remoto..."
git fetch origin

# Verifica se há atualizações remotas
if [ $(git rev-list HEAD...origin/main --count) -ne 0 ]; then
    echo "📥 Há atualizações remotas disponíveis"
    echo "Mudanças remotas:"
    git log HEAD..origin/main --oneline
    
    echo "Aplicando atualizações remotas..."
    git pull origin main
else
    echo "✅ Repositório local já está atualizado"
fi

# Verifica se há mudanças locais
if ! git diff-index --quiet HEAD --; then
    echo "2. Adicionando arquivos modificados..."
    git add .
    
    echo "Digite a mensagem do commit:"
    read commit_message
    
    git commit -m "$commit_message"
    
    echo "3. Enviando mudanças para o repositório remoto..."
    git push origin main
else
    echo "✅ Não há mudanças locais para enviar"
fi

echo "🎉 Sincronização completa!"
