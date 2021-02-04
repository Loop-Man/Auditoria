#!/bin/bash
#author		: Manuel López Torrecillas
#description: Script para enumeración inicial del activo.
#use: ./enum.sh $domain

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

domain=$1

### Actualizamos el repositorio de SecLists antes #####

sudo git -C /opt/SecLists/ pull

### Empezamos con dirsearch para buscar por extensiones mas comunes #####

sudo python3 /opt/dirsearch/dirsearch.py --url https://$domain/ -e txt,php,xml,conf,zip,gz,tar.gz,sql 2>/dev/null
sudo cp -r /opt/dirsearch/reports/$domain .

### Para proxies o reverse proxies ###

wfuzz -c --hc=404 -Z -f reverse-proxy-inconsistencies.txt -z file,/opt/SecLists/Discovery/Web-Content/reverse-proxy-inconsistencies.txt https://$domain/FUZZ 2>/dev/null
wfuzz -c --hc=404 -Z -f proxy-conf.fuzz.txt -z file,/opt/SecLists/Discovery/Web-Content/proxy-conf.fuzz.txt https://$domain/FUZZ 2>/dev/null

### Vamos a enumerar con diccionarios comunes para una primera aproximación #####

wfuzz -c --hc=404 -Z -f wfuzzLogins.txt -z file,/opt/SecLists/Discovery/Web-Content/Logins.fuzz.txt https://$domain/FUZZ 2>/dev/null
wfuzz -c --hc=404 -Z -f wfuzzCommon.txt -z file,/usr/share/dirb/wordlists/common.txt https://$domain/FUZZ 2>/dev/null
wfuzz -c --hc=404 -Z -f wfuzzBig.txt -z file,/usr/share/dirb/wordlists/big.txt https://$domain/FUZZ 2>/dev/null
wfuzz -c --hc=404 -Z -f wfuzzRaft.txt -z file,/opt/SecLists/Discovery/Web-Content/raft-medium-directories.txt https://$domain/FUZZ 2>/dev/null
wfuzz -c --hc=404 -Z -f wfuzzDirbuster.txt -z file,/usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt https://$domain/FUZZ 2>/dev/null

#wait
echo "\n\n[*]Para cerrar todos los procesos en background usar kill %"


