#!/bin/bash

set -e

THISDIR=$(pwd)
PATCHDIR="./patches"

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h          Display this help message"
    echo "  -c          Completely clear all previous cache and start"
    echo ""
}


# clear cache
clear_cache() {
    #echo -e "\033[33m[+] clear this category's caches\033[0m"
    rm -rf ./temp*
    return 1
}

# clean all 
clean() {
    rm -f $THISDIR/.success_record
    rm -f $THISDIR/.tmp_gitconfig
    rm -f $THISDIR/poetry*
}

# load status
update_status() {
    echo "$1" >> $THISDIR/.success_record
}

check_status() {
    if grep "$1" $THISDIR/.success_record; then
        echo -e "\033[32m[+] $1 is completed, skipping...\033[0m" 
        return 0
    else
        return 1
    fi
}

retry() {
#echo $THISDIR
    local max_retries=3
    local attempt=1
    local exec_name="${@:1}" # exec name
    while [ $attempt -le $max_retries ]; do
        echo -e "\033[34m[+] Running $exec_name...\033[0m (Attempts: $attempt/3)"
        if "$@"; then
            return 0
        else
            if [ $attempt -lt 3 ]; then 
                echo -e "\033[31m[x] Execute failed, retry after 3s\033[0m"
                sleep 3
            fi
        fi
        attempt=$((attempt+1))
    done
    echo -e "\033[31m[x] Reached the max retries number, execution failed\033[0m"
    return 1
}

set_temp_gitconfig() {
	if check_status $FUNCNAME; then return 0; fi
	echo -e "\033[33m[+] setting temp gitconfig\033[0m"
	# 创建一个临时的 .gitconfig 文件
	temp_git_config="./.tmp_gitconfig"

	# 使用临时的 .gitconfig 文件设置 git 配置
	git config -f "$temp_git_config" core.packedGitLimit 512m
	git config -f "$temp_git_config" core.packedGitWindowSize 512m
	git config -f "$temp_git_config" pack.deltaCacheSize 2047m
	git config -f "$temp_git_config" pack.packSizeLimit 2047m
	git config -f "$temp_git_config" pack.windowMemory 2047m
	git config -f "$temp_git_config" http.version HTTP/1.1	
	update_status $FUNCNAME
}

install_peda() {
    if check_status $FUNCNAME; then return 0; fi
    echo -e "\033[33m[+] cloning peda from github\033[0m"
    git clone https://github.com/longld/peda.git temp_peda
    rsync -avu -delete ./temp_peda/ ./peda/
    echo "[+] move ./peda to ~/peda"
    rm -rf ~/peda
    mv ./peda ~/
    update_status $FUNCNAME
}

install_Pwngdb() {
    if check_status $FUNCNAME; then return 0; fi
    echo -e "\033[33m[+] cloning Pwngdb from github\033[0m"
    git clone https://github.com/scwuaptx/Pwngdb.git temp_Pwngdb
    rsync -avu -delete ./temp_Pwngdb/ ./Pwngdb/ 
    echo "[+] move ./Pwngdb to ~/Pwngdb"
    rm -rf ~/Pwngdb
    mv ./Pwngdb ~/
    update_status $FUNCNAME
}

install_pwndbg() {
    if check_status $FUNCNAME; then return 0; fi
    echo -e "\033[33m[+] cloning pwndbg from github\033[0m"
    git clone https://github.com/pwndbg/pwndbg temp_pwndbg
    rsync -avu -delete ./temp_pwndbg/ ./pwndbg/
    echo "[+] move ./pwndbg to ~/pwndbg"
    rm -rf ~/pwndbg
    mv ./pwndbg ~/
    update_status $FUNCNAME
}

setup_pwndbg() {
    if check_status $FUNCNAME; then return 0; fi
    cd ~/pwndbg
    echo -e "\033[33m[+] run pwndbg setup\033[0m"
    if ~/pwndbg/setup.sh; then
        update_status $FUNCNAME
        cd $THISDIR
        return 0
    else
        return 1
    fi
}

update_gdbinit() {
    if check_status $FUNCNAME; then return 0; fi
    local gdbinit_file="$PATCHDIR/.gdbinit"
    echo -e "\033[33m[+] replace .gdbinit\033[0m"

    # 检查 .gdbinit 文件是否存在
    if [ -f "$gdbinit_file" ]; then
        rm -f ~/.gdbinit
    fi
    cp "$gdbinit_file" ~/
    update_status $FUNCNAME
}

# other needs
install_needs() {
    if check_status $FUNCNAME; then return 0; fi
    echo "[+] installing mktemp..."
    sudo apt-get install mktemp
    echo "[+] installing perl..."
    sudo apt-get install perl
    echo "[+] installing wget..."
    sudo apt-get install wget
    echo "[+] installing ar..."
    sudo apt-get install ar
    echo "[+] installing tar..."
    sudo apt-get install tar
    echo "[+] installing zstd"
    sudo apt-get install zstd
    # gcc
    echo "[+] installing gcc..."
    sudo apt-get install gcc
    #patchelf
    echo "[+] installing patchelf"
    sudo apt-get install patchelf
    # i386 support
    echo "[+] installing libc6-dev-i386"
    sudo apt-get install libc6-dev-i386
    update_status $FUNCNAME
}

install_one_gadget() {
    if check_status $FUNCNAME; then return 0; fi
    sudo apt -y install ruby
    sudo apt install gem
    gem sources --remove https://rubygems.org/
    gem sources --add https://mirrors.cloud.tencent.com/rubygems/
    sudo gem install one_gadget
    update_status $FUNCNAME
}

install_seccomp_tools() {
    if check_status $FUNCNAME; then return 0; fi
    sudo apt install ruby-dev
    sudo gem install seccomp-tools
    update_status $FUNCNAME
}

install_pwntools() {
    if check_status $FUNCNAME; then return 0; fi
    sudo apt-get install python3-pip libssl-dev libffi-dev build-essential
    python3 -m pip install --upgrade pip
    python3 -m pip install --upgrade pwntools
    update_status $FUNCNAME
}

install_LibcSearcher() {
    if check_status $FUNCNAME; then return 0; fi
    pip install LibcSearcher
    update_status $FUNCNAME
}

install_ROPgadget() {
    if check_status $FUNCNAME; then return 0; fi
    sudo apt-get install capstone
    git clone https://github.com/JonathanSalwan/ROPgadget.git
    sudo python3 ./ROPgadget/setup.py install 
    update_status $FUNCNAME
}

install_ropper() {
    if check_status $FUNCNAME; then return 0; fi
    sudo pip3 install filebytes
    sudo pip3 install keystone-engine
    sudo pip3 install ropper
    update_status $FUNCNAME
}

# install main
main() {
    cd $THISDIR
    set_temp_gitconfig
    retry install_peda
    retry install_Pwngdb
    retry update_gdbinit
    retry install_pwndbg
    retry setup_pwndbg
    retry install_needs
    retry install_one_gadget
    retry install_seccomp_tools
    retry install_pwntools
    retry install_LibcSearcher
    retry install_ROPgadget
    retry install_ropper
    
}

# 处理命令行参数
parse_options() {
    while getopts "ch" opt; do
        case "$opt" in
            c)
                clean
                ;;
                
            h)
                show_help
                if [ $# -eq 1 ]; then
                    exit 0
                fi
                ;;
            ?)
                echo "Invalid option: -$OPTARG" >&2
                show_help
                exit 1
                ;;
        esac
    done
    shift $((OPTIND - 1))
}

trap 'clear_cache' EXIT SIGINT SIGTERM

parse_options "$@"
main


