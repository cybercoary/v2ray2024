#!/bin/bash

author=233boy
# github=https://github.com/233boy/v2ray

# cores de fontes do bash
red='\e[31m'
yellow='\e[33m'
gray='\e[90m'
green='\e[92m'
blue='\e[94m'
magenta='\e[95m'
cyan='\e[96m'
none='\e[0m'
_red() { echo -e ${red}$@${none}; }
_blue() { echo -e ${blue}$@${none}; }
_cyan() { echo -e ${cyan}$@${none}; }
_green() { echo -e ${green}$@${none}; }
_yellow() { echo -e ${yellow}$@${none}; }
_magenta() { echo -e ${magenta}$@${none}; }
_red_bg() { echo -e "\e[41m$@${none}"; }

is_err=$(_red_bg Erro!)
is_warn=$(_red_bg Aviso!)

err() {
    echo -e "\n$is_err $@\n" && exit 1
}

warn() {
    echo -e "\n$is_warn $@\n"
}

# root
[[ $EUID != 0 ]] && err "Você não é o ${yellow}ROOT${none}."

# yum ou apt-get, ubuntu/debian/centos
cmd=$(type -P apt-get || type -P yum)
[[ ! $cmd ]] && err "Este script suporta apenas ${yellow}(Ubuntu ou Debian ou CentOS)${none}."

# systemd
[[ ! $(type -P systemctl) ]] && {
    err "Este sistema está faltando ${yellow}(systemctl)${none}, tente executar:${yellow} ${cmd} update -y;${cmd} install systemd -y ${none} para corrigir este erro."
}

# wget instalado ou não
is_wget=$(type -P wget)

# x64
case $(uname -m) in
amd64 | x86_64)
    is_jq_arch=amd64
    is_core_arch="64"
    ;;
*aarch64* | *armv8*)
    is_jq_arch=arm64
    is_core_arch="arm64-v8a"
    ;;
*)
    err "Este script suporta apenas sistemas de 64 bits..."
    ;;
esac

is_core=v2ray
is_core_name=V2Ray
is_core_dir=/etc/$is_core
is_core_bin=$is_core_dir/bin/$is_core
is_core_repo=v2fly/$is_core-core
is_conf_dir=$is_core_dir/conf
is_log_dir=/var/log/$is_core
is_sh_bin=/usr/local/bin/$is_core
is_sh_dir=$is_core_dir/sh
is_sh_repo=$author/$is_core
is_pkg="wget unzip"
is_config_json=$is_core_dir/config.json
tmp_var_lists=(
    tmpcore
    tmpsh
    tmpjq
    is_core_ok
    is_sh_ok
    is_jq_ok
    is_pkg_ok
)

# dir temporário
tmpdir=$(mktemp -u)
[[ ! $tmpdir ]] && {
    tmpdir=/tmp/tmp-$RANDOM
}

# configurar variáveis
for i in ${tmp_var_lists[*]}; do
    export $i=$tmpdir/$i
done

# carregar script bash
load() {
    . $is_sh_dir/src/$1
}

# wget adiciona --no-check-certificate
_wget() {
    [[ $proxy ]] && export https_proxy=$proxy
    wget --no-check-certificate $*
}

# imprimir uma mensagem
msg() {
    case $1 in
    warn)
        local color=$yellow
        ;;
    err)
        local color=$red
        ;;
    ok)
        local color=$green
        ;;
    esac

    echo -e "${color}$(date +'%T')${none}) ${2}"
}

# mostrar mensagem de ajuda
show_help() {
    echo -e "Uso: $0 [-f xxx | -l | -p xxx | -v xxx | -h]"
    echo -e "  -f, --core-file <path>          Caminho personalizado para o arquivo $is_core_name, por exemplo, -f /root/${is_core}-linux-64.zip"
    echo -e "  -l, --local-install             Obter o script de instalação localmente, usar o diretório atual"
    echo -e "  -p, --proxy <addr>              Usar proxy para download, por exemplo, -p http://127.0.0.1:2333 ou -p socks5://127.0.0.1:2333"
    echo -e "  -v, --core-version <ver>        Versão personalizada do $is_core_name, por exemplo, -v v5.4.1"
    echo -e "  -h, --help                      Exibir esta tela de ajuda\n"

    exit 0
}

# instalar pacotes dependentes
install_pkg() {
    cmd_not_found=
    for i in $*; do
        [[ ! $(type -P $i) ]] && cmd_not_found="$cmd_not_found,$i"
    done
    if [[ $cmd_not_found ]]; then
        pkg=$(echo $cmd_not_found | sed 's/,/ /g')
        msg warn "Instalando pacotes dependentes >${pkg}"
        $cmd install -y $pkg &>/dev/null
        if [[ $? != 0 ]]; then
            [[ $cmd =~ yum ]] && yum install epel-release -y &>/dev/null
            $cmd update -y &>/dev/null
            $cmd install -y $pkg &>/dev/null
            [[ $? == 0 ]] && >$is_pkg_ok
        else
            >$is_pkg_ok
        fi
    else
        >$is_pkg_ok
    fi
}

# baixar arquivo
download() {
    case $1 in
    core)
        link=https://github.com/${is_core_repo}/releases/latest/download/${is_core}-linux-${is_core_arch}.zip
        [[ $is_core_ver ]] && link="https://github.com/${is_core_repo}/releases/download/${is_core_ver}/${is_core}-linux-${is_core_arch}.zip"
        name=$is_core_name
        tmpfile=$tmpcore
        is_ok=$is_core_ok
        ;;
    sh)
        link=https://github.com/cybercoary/v2ray2024/releases/latest/download/code.zip
        name="$is_core_name Script"
        tmpfile=$tmpsh
        is_ok=$is_sh_ok
        ;;
    jq)
        link=https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-$is_jq_arch
        name="jq"
        tmpfile=$tmpjq
        is_ok=$is_jq_ok
        ;;
    esac

    msg warn "Baixando ${name} > ${link}"
    if _wget -t 3 -q -c $link -O $tmpfile; then
        mv -f $tmpfile $is_ok
    fi
}

# obter IP do servidor
get_ip() {
    export "$(_wget -4 -qO- https://one.one.one.one/cdn-cgi/trace | grep ip=)" &>/dev/null
    [[ -z $ip ]] && export "$(_wget -6 -qO- https://one.one.one.one/cdn-cgi/trace | grep ip=)" &>/dev/null
}

# verificar status das tarefas em segundo plano
check_status() {
    # falha na instalação do pacote dependente
    [[ ! -f $is_pkg_ok ]] && {
        msg err "Falha na instalação dos pacotes dependentes"
        is_fail=1
    }

    # status de download dos arquivos
    if [[ $is_wget ]]; then
        [[ ! -f $is_core_ok ]] && {
            msg err "Falha ao baixar ${is_core_name}"
            is_fail=1
        }
        [[ ! -f $is_sh_ok ]] && {
            msg err "Falha ao baixar o script ${is_core_name}"
            is_fail=1
        }
        [[ ! -f $is_jq_ok ]] && {
            msg err "Falha ao baixar jq"
            is_fail=1
        }
    else
        [[ ! $is_fail ]] && {
            is_wget=1
            [[ ! $is_core_file ]] && download core &
            [[ ! $local_install ]] && download sh &
            [[ $jq_not_found ]] && download jq &
            get_ip
            wait
            check_status
        }
    fi

    # encontrou falha, remove dir temporário e sai.
    [[ $is_fail ]] && {
        exit_and_del_tmpdir
    }
}

# verificar parâmetros
pass_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
        online)
            err "Se deseja instalar uma versão antiga, acesse: https://github.com/cybercoary/v2ray2024/v2ray/tree/old"
            ;;
        -f | --core-file)
            [[ -z $2 ]] && {
                err "($1) Falta o parâmetro necessário, exemplo correto: [$1 /root/$is_core-linux-64.zip]"
            } || [[ ! -f $2 ]] && {
                err "($2) Não é um arquivo regular."
            }
            is_core_file=$2
            shift 2
            ;;
        -l | --local-install)
            [[ ! -f ${PWD}/src/core.sh || ! -f ${PWD}/$is_core.sh ]] && {
                err "O diretório atual (${PWD}) não é um diretório de script completo."
            }
            local_install=1
            shift 1
            ;;
        -p | --proxy)
            [[ -z $2 ]] && {
                err "($1) Falta o parâmetro necessário, exemplo correto: [$1 http://127.0.0.1:2333 ou -p socks5://127.0.0.1:2333]"
            }
            proxy=$2
            shift 2
            ;;
        -v | --core-version)
            [[ -z $2 ]] && {
                err "($1) Falta o parâmetro necessário, exemplo correto: [$1 v1.8.1]"
            }
            is_core_ver=v${2#v}
            shift 2
            ;;
        -h | --help)
            show_help
            ;;
        *)
            echo -e "\n${is_err} ($@) é um parâmetro desconhecido...\n"
            show_help
            ;;
        esac
    done
    [[ $is_core_ver && $is_core_file ]] && {
        err "Não é possível definir ao mesmo tempo a versão e o arquivo do ${is_core_name}."
    }
}

# sair e remover tmpdir
exit_and_del_tmpdir() {
    rm -rf $tmpdir
    [[ ! $1 ]] && {
        msg err "Oh não.."
        msg err "Ocorreu um erro durante o processo de instalação..."
        echo -e "Reporte o problema) https://github.com/${is_sh_repo}/issues"
        echo
        exit 1
    }
    exit
}

# principal
main() {

    # verificar versão antiga
    [[ -f $is_sh_bin && -d $is_core_dir/bin && -d $is_sh_dir && -d $is_conf_dir ]] && {
        err "Detectado que o script já está instalado, para reinstalar use o comando${green} ${is_core} reinstall ${none}."
    }

    # verificar parâmetros
    [[ $# -gt 0 ]] && pass_args $@

    # mostrar mensagem de boas-vindas
    clear
    echo
    echo "........... $is_core_name script by $author .........."
    echo

    # começar a instalação...
    msg warn "Iniciando a instalação..."
    [[ $is_core_ver ]] && msg warn "Versão do $is_core_name: ${yellow}$is_core_ver${none}"
    [[ $proxy ]] && msg warn "Usando proxy: ${yellow}$proxy${none}"
    # criar tmpdir
    mkdir -p $tmpdir
    # se is_core_file, copiar o arquivo
    [[ $is_core_file ]] && {
        cp -f $is_core_file $is_core_ok
        msg warn "${yellow}Arquivo do $is_core_name em uso > $is_core_file${none}"
    }
    # instalar script do diretório local
    [[ $local_install ]] && {
        >$is_sh_ok
        msg warn "${yellow}Obtendo script de instalação localmente > $PWD ${none}"
    }

    timedatectl set-ntp true &>/dev/null
    [[ $? != 0 ]] && {
        msg warn "${yellow}\e[4mAviso!!! Não foi possível definir sincronização automática de tempo, o que pode afetar o uso do protocolo VMess.${none}"
    }

    # instalar pacotes dependentes
    install_pkg $is_pkg &

    # jq
    if [[ $(type -P jq) ]]; then
        >$is_jq_ok
    else
        jq_not_found=1
    fi
    # se wget estiver instalado. baixar core, sh, jq, obter ip
    [[ $is_wget ]] && {
        [[ ! $is_core_file ]] && download core &
        [[ ! $local_install ]] && download sh &
        [[ $jq_not_found ]] && download jq &
        get_ip
    }

    # esperar que as tarefas em segundo plano sejam concluídas
    wait

    # verificar status das tarefas em segundo plano
    check_status

    # testar $is_core_file
    if [[ $is_core_file ]]; then
        unzip -qo $is_core_ok -d $tmpdir/testzip &>/dev/null
        [[ $? != 0 ]] && {
            msg err "O arquivo ${is_core_name} não passou no teste."
            exit_and_del_tmpdir
        }
        for i in ${is_core} geoip.dat geosite.dat; do
            [[ ! -f $tmpdir/testzip/$i ]] && is_file_err=1 && break
        done
        [[ $is_file_err ]] && {
            msg err "O arquivo ${is_core_name} não passou no teste."
            exit_and_del_tmpdir
        }
    fi

    # obter IP do servidor
    [[ ! $ip ]] && {
        msg err "Falha ao obter o IP do servidor."
        exit_and_del_tmpdir
    }

    # criar diretório sh...
    mkdir -p $is_sh_dir

    # copiar arquivo sh ou descompactar arquivo zip sh.
    if [[ $local_install ]]; then
        cp -rf $PWD/* $is_sh_dir
    else
        unzip -qo $is_sh_ok -d $is_sh_dir
    fi

    # criar diretório bin do core
    mkdir -p $is_core_dir/bin
    # copiar arquivo core ou descompactar arquivo zip core
    if [[ $is_core_file ]]; then
        cp -rf $tmpdir/testzip/* $is_core_dir/bin
    else
        unzip -qo $is_core_ok -d $is_core_dir/bin
    fi

    # adicionar alias
    echo "alias $is_core=$is_sh_bin" >>/root/.bashrc

    # comando core
    ln -sf $is_sh_dir/$is_core.sh $is_sh_bin

    # jq
    [[ $jq_not_found ]] && mv -f $is_jq_ok /usr/bin/jq

    # chmod
    chmod +x $is_core_bin $is_sh_bin /usr/bin/jq

    # criar diretório de logs
    mkdir -p $is_log_dir

    # mostrar mensagem de dica
    msg ok "Gerando arquivo de configuração..."

    # criar serviço systemd
    load systemd.sh
    is_new_install=1
    install_service $is_core &>/dev/null

    # criar diretório de configuração
    mkdir -p $is_conf_dir

    load core.sh
    # criar uma configuração tcp
    add tcp
    # remover diretório temporário e sair.
    exit_and_del_tmpdir ok
}

# iniciar
main $@
