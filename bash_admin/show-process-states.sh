#!/bin/bash
echo "📊 Estados de Processos Linux"
echo "============================"

echo -e "\n🔍 Códigos de estado (STAT):"
echo "R = Running (executando)"
echo "S = Sleeping (dormindo/esperando entrada)"
echo "D = Uninterruptible sleep (aguardando I/O)"
echo "T = Stopped (parado por sinal)"
echo "Z = Zombie (morto mas não coletado)"
echo "< = Alta prioridade"
echo "s = Session leader"
echo "+ = Em foreground"

echo -e "\n🐚 Estados atuais dos shells:"
ps aux | head -1  # cabeçalho
ps aux | grep -E "(bash|zsh|fish)" | grep -v grep

echo -e "\n📋 Análise dos shells ativos:"
ps aux | grep -E "(bash|zsh|fish)" | grep -v grep | while read line; do
    pid=$(echo $line | awk '{print $2}')
    stat=$(echo $line | awk '{print $8}')
    cmd=$(echo $line | awk '{print $11}')
    
    case $stat in
        S*) status="✅ Normal (esperando input)" ;;
        R*) status="🏃 Executando algo" ;;
        D*) status="⏳ Aguardando I/O" ;;
        T*) status="⏸️ Parado/Suspenso" ;;
        Z*) status="💀 Zombie (problema!)" ;;
        *) status="❓ Estado: $stat" ;;
    esac
    
    echo "PID $pid ($cmd): $status"
done

echo -e "\n🧟 Verificando zombies:"
ZOMBIES=$(ps aux | grep -c ' Z ')
if [ $ZOMBIES -gt 0 ]; then
    echo "❌ $ZOMBIES processo(s) zombie encontrado(s):"
    ps aux | grep ' Z '
else
    echo "✅ Nenhum processo zombie"
fi

echo -e "\n🔄 Shells em diferentes estados:"
echo "Dormindo (normal): $(ps aux | grep -E '(bash|zsh|fish)' | grep -c ' S')"
echo "Executando: $(ps aux | grep -E '(bash|zsh|fish)' | grep -c ' R')"
echo "Parados: $(ps aux | grep -E '(bash|zsh|fish)' | grep -c ' T')"
echo "Zombies: $(ps aux | grep -E '(bash|zsh|fish)' | grep -c ' Z')"
