show_help() {
    case $1 in
    api | convert | tls | run | uuid | version)
        $is_core_bin help $1 ${@:2}
        ;;
    *)
        [[ $1 ]] && warn "Opção desconhecida '$1'"
        msg "$is_core_name script $is_sh_ver por $author"
        msg "Uso: $is_core [opções]... [args]... "
        msg
        help_info=(
            "Básico:"
            "   v, version                                      Mostra a versão atual"
            "   ip                                              Retorna o IP da máquina atual"
            # "   pbk                                             Equivalente a $is_core x25519"
            "   get-port                                        Retorna uma porta disponível\n"
            # "   ss2022                                          Retorna uma senha para Shadowsocks 2022\n"
            "Geral:"
            "   a, add [protocol] [args... | auto]              Adiciona configuração"
            "   c, change [name] [option] [args... | auto]      Altera configuração"
            "   d, del [name]                                   Remove configuração**"
            "   i, info [name]                                  Visualiza configuração"
            "   qr [name]                                       Informações em código QR"
            "   url [name]                                      Informações URL"
            "   log                                             Visualiza logs"
            "   logerr                                          Visualiza logs de erro\n"
            "Alterar:"
            "   dp, dynamicport [name] [start | auto] [end]     Altera porta dinâmica"
            "   full [name] [...]                               Altera múltiplos parâmetros"
            "   id [name] [uuid | auto]                         Altera UUID"
            "   host [name] [domain]                            Altera domínio"
            "   port [name] [port | auto]                       Altera porta"
            "   path [name] [path | auto]                       Altera caminho"
            "   passwd [name] [password | auto]                 Altera senha"
            # "   key [name] [Private key | atuo] [Public key]    Altera chave"
            "   type [name] [type | auto]                       Altera tipo de camuflagem"
            "   method [name] [method | auto]                   Altera método de criptografia"
            # "   sni [name] [ ip | domain]                       Altera serverName"
            "   seed [name] [seed | auto]                       Altera mKCP seed"
            "   new [name] [...]                                Altera protocolo"
            "   web [name] [domain]                             Altera site de camuflagem\n"
            "Avançado:"
            "   dns [...]                                       Configura DNS"
            "   dd, ddel [name...]                              Remove múltiplas configurações**"
            "   fix [name]                                      Corrige uma configuração"
            "   fix-all                                         Corrige todas as configurações"
            "   fix-caddyfile                                   Corrige Caddyfile"
            "   fix-config.json                                 Corrige config.json\n"
            "Gerenciamento:"
            "   un, uninstall                                   Desinstalar"
            "   u, update [core | sh | dat | caddy] [ver]       Atualizar"
            "   U, update.sh                                    Atualizar script"
            "   s, status                                       Status"
            "   start, stop, restart [caddy]                    Iniciar, parar, reiniciar"
            "   t, test                                         Testar execução"
            "   reinstall                                       Reinstalar script\n"
            "Teste:"
            "   client [name]                                   Mostra JSON para cliente, apenas para referência"
            "   debug [name]                                    Mostra informações de depuração, apenas para referência"
            "   gen [...]                                       Equivalente a add, mas apenas exibe JSON, não cria arquivos, para teste"
            "   genc [name]                                     Mostra parte do JSON para cliente, apenas para referência"
            "   no-auto-tls [...]                               Equivalente a add, mas desativa configuração automática de TLS, útil para *TLS relacionados"
            "   xapi [...]                                      Equivalente a $is_core api, mas o backend API usa o serviço $is_core_name em execução\n"
            "Outros:"
            "   bbr                                             Habilita BBR, se suportado"
            "   bin [...]                                       Executa comandos $is_core_name, por exemplo: $is_core bin help"
            "   api, convert, tls, run, uuid  [...]             Compatível com comandos $is_core_name"
            "   h, help                                         Mostra esta tela de ajuda\n"
        )
        for v in "${help_info[@]}"; do
            msg "$v"
        done
        msg "Use com cautela del, ddel, essas opções irão remover configurações diretamente; sem confirmação"
        msg "Relate problemas em: $(msg_ul https://github.com/${is_sh_repo}/issues)"
        msg "Documentação: $(msg_ul https://233boy.com/$is_core/$is_core-script/)"
        ;;
    esac
}

about() {
    ####### Modifique apenas os links #######
    unset c n m s b
    msg
    msg "Site: $(msg_ul https://233boy.com)"
    msg "Canal: $(msg_ul https://t.me/tg2333)"
    msg "Grupo: $(msg_ul https://t.me/tg233boy)"
    msg "Github: $(msg_ul https://github.com/${is_sh_repo})"
    msg "Twitter: $(msg_ul https://twitter.com/ai233boy)"
    msg "$is_core_name site: $(msg_ul https://www.v2fly.org)"
    msg "$is_core_name core: $(msg_ul https://github.com/${is_core_repo})"
    msg
    ####### Modifique apenas os links #######
}
