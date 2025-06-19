#!/bin/bash
# close-terminals.sh - Fechar terminais de forma controlada

echo "🖥️ Terminais Ativos"
echo "=================="

# Listar terminais ativos
echo "Usuários e terminais:"
who -u

echo -e "\nShells rodando:"
ps aux | grep -v grep | grep -E "(bash|zsh|fish)" | awk '{print "PID:", $2, "TTY:", $7, "User:", $1, "Command:", $11}'

echo -e "\n🔧 Opções:"
echo "1) Fechar terminal específico por TTY"
echo "2) Fechar todos os shells de um usuário"
echo "3) Fechar todos os shells exceto o atual"
echo "4) Fechar shells órfãos/abandonados"
echo "5) Apenas mostrar informações"

read -p "Escolha uma opção (1-5): " choice

case $choice in
    1)
        echo "TTYs disponíveis:"
        who | awk '{print $2}'
        read -p "Digite o TTY para fechar (ex: pts/1): " tty_target
        if [ -n "$tty_target" ]; then
            echo "Fechando TTY $tty_target..."
            sudo pkill -t "$tty_target"
            echo "✅ Comando enviado"
        fi
        ;;
    2)
        read -p "Digite o nome do usuário: " username
        if [ -n "$username" ]; then
            echo "Fechando shells do usuário $username..."
            sudo pkill -u "$username" -t pts/
            echo "✅ Comando enviado"
        fi
        ;;
    3)
        CURRENT_TTY=$(tty | sed 's|/dev/||')
        echo "TTY atual: $CURRENT_TTY (será preservado)"
        echo "Fechando outros terminais..."
        
        for tty in $(who | awk '{print $2}' | grep -v "^$CURRENT_TTY$"); do
            echo "Fechando $tty..."
            sudo pkill -t "$tty"
        done
        echo "✅ Outros terminais fechados"
        ;;
    4)
        echo "Procurando shells órfãos..."
        # Shells sem TTY ou com PPID 1
        ps aux | grep -E "(bash|zsh|fish)" | awk '$7 == "?" || $3 == "1" {print $2}' | while read pid; do
            if [ -n "$pid" ]; then
                echo "Fechando processo órfão PID: $pid"
                sudo kill -TERM "$pid"
            fi
        done
        echo "✅ Limpeza concluída"
        ;;
    5)
        echo "ℹ️ Apenas exibindo informações (nenhuma ação tomada)"
        ;;
esac

echo -e "\n📊 Estado final:"
echo "Terminais ativos: $(who | wc -l)"
echo "Shells rodando: $(ps aux | grep -v grep | grep -E '(bash|zsh|fish)' | wc -l)"
