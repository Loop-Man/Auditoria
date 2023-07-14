#!/bin/bash
#author		: Manuel López Torrecillas
#description: Script para revisar rapidamente un dominio.
#use: getEndpoints.sh <domain>

#Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"


# trap ctrl-c and call ctrl_c()
trap ctrl_c INT

# Lo primero será crear la función ctrl_c() para crear una salida controlada del script
function ctrl_c(){
    # El -e para que no introduzca el echo el new line y tengamos que ponerlo nosotros manualmente (\n)
    echo -e "\n\n${yellowColour}[*]${endColour}${grayColour} Saliendo de manera controlada${endColour}\n"
    exit 0
}

# Fijamos los parámetros de entrada del script a 1.
let numarg=$(echo $#)
let totalarg=1
if [ $numarg -ne $totalarg ];then
    echo -e "\n\t[*] Usage: bash $0 <www.domain.com>\n"
    exit
fi

# Declare var

domain=$1
topdomain=$(echo $domain | awk -F'.' '{print $(NF-1)"."$NF}')
path="./.data/scans/$domain"
mkdir -p $path

function getEndpoints {
    echo "[!] Ejecutando waybackurls..."
    echo $2 | waybackurls --no-subs > $1/wayback > /dev/null
    echo "[!] Ejecutando gau..."
    echo "$2" | gau --threads 100 | anew $1/wayback2 > /dev/null
    cat $1/wayback* | grep $2 | anew > $1/wayback_final
    cat $1/wayback_final | grep "=" | grep "?" | qsreplace FUZZ | sort -u > $1/final_endpoints1.txt
    echo "[!] Elimininando archivos temporales..."
   # rm -f $1/wayback* > /dev/null

    gau --retries 15 --threads 100 --subs $topdomain > $1/wayback3
    curl -s "http://web.archive.org/cdx/search/cdx?url=$topdomain/*&output=text&fl=original&collapse=urlkey" > $1/wayback4

    cat $1/wayback3 | sort -u > $1/waybackdataDomain.tmp
    cat $1/wayback4 | sort -u >> $1/waybackdataDomain.tmp
    sort -u $1/waybackdataDomain.tmp | grep -i $domain > $1/final_endpoints2.txt
    rm -rf $1/waybackdataDomain.tmp
}



getEndpoints $path $domain
