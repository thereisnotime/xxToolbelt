#!/bin/bash 
function xxnet-iptables-ls () {
    local version="1.1"
    function _xxiptables () {
        local ip_vers="$1"
        local table="$2"
        BRed='\e[1;31m'         # Red
        BGreen='\e[1;32m'       # Green
        On_Black='\e[40m'       # Black
        NC="\e[m"               # Color Reset
        local spacing="| cut -f -9 | column -t | sed 's/^Chain/\n&/g'| sed '/^Chain/ s/[ \t]\{1,\}/ /g'| sed '/^[0-9]/ s/[ \t]\{1,\}/ /10g'"
        local colors="|\
        sed -E 's/^Chain.*$/\x1b[4m&\x1b[0m/' |\
        sed -E 's/^num.*/\x1b[33m&\x1b[0m/' |\
        sed -E '/([^y] )((REJECT|DROP))/s//\1\x1b[31m\3\x1b[0m/' |\
        sed -E '/([^y] )(ACCEPT)/s//\1\x1b[32m\2\x1b[0m/' |\
        sed -E '/([ds]pt[s]?:)([[:digit:]]+(:[[:digit:]]+)?)/s//\1\x1b[33;1m\2\x1b[0m/' |\
        sed -E '/([[:digit:]]{1,3}\.){3}[[:digit:]]{1,3}(\/([[:digit:]]){1,3}){0,1}/s//\x1b[36;1m&\x1b[0m/g' |\
        sed -E '/([^n] )(LOGDROP)/s//\1\x1b[33;1m\2\x1b[0m/'|\
        sed -E 's/ LOG /\x1b[36;1m&\x1b[0m/'"
        _IPv="4"
        if [[ $1 == *"6"* ]]; then
            _IPv="6"
        fi
        if [ -z "$2" ]; then
            echo -e "${BRed}${On_Black}\n========== IPv$_IPv - All applied rules:${NC}"
            eval "$ip_vers -S -v $colors"
        else
            echo -e "${BRed}${On_Black}\n========== IPv$_IPv - Table: $table:${NC}"
            eval "$ip_vers $table --line-numbers -vnL $spacing $colors"
        fi
    }
    function _xxiptables-modules () {
        local _module="$1"
        _MODULE_STATUS="$(lsmod | awk '{if (NR != 1) print $1}' | grep "$_module")"
        if [[ $_MODULE_STATUS == *"$_module"* ]]; then
            echo -e "$_module: ${BGreen}Loaded${NC}"
        else
            echo -e "$_module: ${BRed}Not loaded${NC}"
        fi
    }
    # IPv4
    local _tables=("filter" "nat" "mangle" "raw" "security")
    for element in "${_tables[@]}" ; do 
        _xxiptables "iptables" "-t $element"
        _xxiptables "ip6tables" "-t $element"
    done
    # Kernel mods
    echo -e "${BRed}${On_Black}\n========== Kernel Modules:${NC}"
    local _modules=("ip_tables" "ip6_tables" "x_tables" "iptable_security" "iptable_raw" "iptable_mangle" "iptable_nat" "iptable_filter" "ip6table_security" "ip6table_raw" "ip6table_mangle" "ip6table_nat" "ip6table_filter")
    for element in "${_modules[@]}" ; do 
        _xxiptables-modules "$element"
    done
    echo -e "${BRed}${On_Black}\n========== All active rules IPv6:${NC}"
    _xxiptables "iptables"
    _xxiptables "ip6tables"
    echo -e "${BRed}${On_Black}\n========== Routes:${NC}"
    echo -n "=== "
    route -n
    echo "=== Detailed:"
    ip route show table all
    echo -e "${BRed}${On_Black}\n========== Adapters:${NC}"
    ip -c -h -s -t a
    echo -e "${BRed}${On_Black}\n========== End xxiptablesls $version:${NC}"
}
xxnet-iptables-ls