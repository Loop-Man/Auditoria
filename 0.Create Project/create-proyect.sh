#!/bin/bash
#author		: Manuel López Torrecillas
#description: Script para usar al inicio de cualquier auditoria para crear los directorios correspondientes.
#use: bash create-proyect.sh <domain>

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

# Para establecer variables numericas lo haremos con let, en este caso fijamos los parámetros de entrada del script a 1.
let numarg=$(echo $#)
let totalarg=1
if [ $numarg -ne $totalarg ];then
    echo -e "\n\t[*] Usage: bash create-proyect.sh www.example.com\n"
    exit
fi

domain=$1
locationScripts="$(cd .. && pwd)"


if [ ! -d "$HOME/Auditoria" ];then
	mkdir "$HOME/Auditoria" 
fi

location="$HOME/Auditoria"

# Se crea el directorio del proyecto.
mkdir -p "$location/$(date +%m-%y)/$(date +%d-%m-%y)_$domain"/{1.Availability,2.Footprinting,3.Fingerprinting,4.Enumeration,5.Webscan,6.SSL-TLS,7.Burpsuite,8.Cherrytree,9.Evidencias}
#mkdir -p ./footprinting/{email,exiftool,subdomains,cache-content}

## Se copian scripts a sus carpetas correspondientes dentro del proyecto.

cp $locationScripts/1.Availability/availability.sh $location/$(date +%m-%y)/$(date +%d-%m-%y)_$domain/1.Availability/

cp $locationScripts/2.Footprinting/footprinting-web.sh $location/$(date +%m-%y)/$(date +%d-%m-%y)_$domain/2.Footprinting/
cp $locationScripts/2.Footprinting/footprinting.sh $location/$(date +%m-%y)/$(date +%d-%m-%y)_$domain/2.Footprinting/
cp $locationScripts/2.Footprinting/hunter-email.sh $location/$(date +%m-%y)/$(date +%d-%m-%y)_$domain/2.Footprinting/

cp $locationScripts/3.Fingerprinting/fingerprint.sh $location/$(date +%m-%y)/$(date +%d-%m-%y)_$domain/3.Fingerprinting/
cp $locationScripts/3.Fingerprinting/nmap.sh $location/$(date +%m-%y)/$(date +%d-%m-%y)_$domain/3.Fingerprinting/

cp $locationScripts/4.Enumeration/enum.sh $location/$(date +%m-%y)/$(date +%d-%m-%y)_$domain/4.Enumeration/

cp $locationScripts/5.Webscan/webscan.sh $location/$(date +%m-%y)/$(date +%d-%m-%y)_$domain/5.Webscan/
