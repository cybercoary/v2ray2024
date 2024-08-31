_open_bbr() {
    # Remove configurações antigas de congestionamento e enfileiramento do arquivo sysctl.conf
    sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
    sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
    
    # Adiciona configurações para habilitar o BBR
    echo "net.ipv4.tcp_congestion_control = bbr" >> /etc/sysctl.conf
    echo "net.core.default_qdisc = fq" >> /etc/sysctl.conf
    
    # Aplica as novas configurações
    sysctl -p &>/dev/null
    
    # Mensagem de confirmação
    echo
    _green "..BBR otimização ativada com sucesso...."
    echo
}

_try_enable_bbr() {
    # Obtém a versão do kernel
    local _test1=$(uname -r | cut -d\. -f1)
    local _test2=$(uname -r | cut -d\. -f2)
    
    # Verifica se a versão do kernel é compatível com o BBR
    if [[ $_test1 -eq 4 && $_test2 -ge 9 ]] || [[ $_test1 -ge 5 ]]; then
        _open_bbr
    else
        err "Não é possível ativar a otimização BBR."
    fi
}

