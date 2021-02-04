#! /bin/bash
#author		: Manuel López Torrecillas
#description: Script para usar al inicio de cualquier auditoria para crear los directorios correspondientes.
#use: ./create-proyect.sh $domain

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
locationScripts=$(pwd)
cd ..
location=$(pwd)
#cd /root/auditoria

mkdir $(date +%m-%y) 2>/dev/null
cd $(date +%m-%y)
mkdir "$(date +%d-%m-%y) $domain"
cd "$(date +%d-%m-%y) $domain"
mkdir {availability,footprinting,burp,evidencias,cherry,nmap,enum,webscan,ssl,fingerprint}
sleep 3

#mkdir -p ./footprinting/{email,exiftool,subdomains,cache-content}
#sleep 3

## Copiar scripts a sus carpetas correspondientes dentro del proyecto

cp $locationScripts/nmap.sh $location/$(date +%m-%y)/"$(date +%d-%m-%y) $domain"/nmap/
cp $locationScripts/availability.sh $location/$(date +%m-%y)/"$(date +%d-%m-%y) $domain"/availability/
cp $locationScripts/footprinting.sh $location/$(date +%m-%y)/"$(date +%d-%m-%y) $domain"/footprinting/
cp $locationScripts/enum.sh $location/$(date +%m-%y)/"$(date +%d-%m-%y) $domain"/enum/
cp $locationScripts/enum-Linux-Apache-php.sh $location/$(date +%m-%y)/"$(date +%d-%m-%y) $domain"/enum/
cp $locationScripts/enum-Linux-nginx.sh $location/$(date +%m-%y)/"$(date +%d-%m-%y) $domain"/enum/
cp $locationScripts/toburpEnumCode200.sh $location/$(date +%m-%y)/"$(date +%d-%m-%y) $domain"/enum/
cp $locationScripts/enum-Windows-IIS-asp.sh $location/$(date +%m-%y)/"$(date +%d-%m-%y) $domain"/enum/
cp $locationScripts/fingerprint.sh $location/$(date +%m-%y)/"$(date +%d-%m-%y) $domain"/fingerprint/
cp $locationScripts/webscan.sh $location/$(date +%m-%y)/"$(date +%d-%m-%y) $domain"/webscan/