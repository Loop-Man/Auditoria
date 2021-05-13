#!/bin/bash
#author		: Manuel López Torrecillas
#description: Script para lanzar los nmap básicos de reconocimiento.
#use: bash nmap.sh $domain

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
    echo -e "\n\t[*] Usage: bash nmap.sh www.example.com\n"
    exit
fi

domain=$1

if [ ! -d "$domain" ];then
	mkdir $domain
fi

sudo nmap -Pn -vvv --disable-arp --reason -f -D 216.58.215.142 -sSV -O -sC -p 80,443 -oN "$domain/nmapDefault" $domain
sudo nmap -Pn -vvv --disable-arp --reason -f -D 216.58.215.142 -sSV -O -p 80,443 --script safe,version,vuln -oN "$domain/nmapSafe-Version-Vuln" $domain
sudo nmap -Pn -vvv --disable-arp --reason -f -D 216.58.215.142 -sSV -p 80,443 -oN "$domain/nmapFullHTTP" --script http-backup-finder,http-config-backup,http-errors,http-headers,http-iis-webdav-vuln,http-internal-ip-disclosure,http-methods,http-php-version,http-qnap-nas-info,http-robots.txt,http-shellshock,http-slowloris-check,http-waf-detect,"http-vuln*" $domain

sudo nmap -Pn -vvv --disable-arp --reason -f -sSV -p 80,443 --script http-slowloris-check -oN "$domain/nmapCheckSlowloris" $domain
sudo nmap -Pn -vvv --disable-arp --reason -f -sSV -p 443 --script ssl-cert -oN "$domain/nmapCertificate" $domain
sudo nmap -Pn -vvv --disable-arp --reason -f -sV --top-ports 10000 -O -oN "$domain/nmapSystemOperative" $domain
