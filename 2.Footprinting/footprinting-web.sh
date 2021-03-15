#!/bin/bash
#author		: Manuel López Torrecillas
#description: Script para recopilación de información pasiva del activo.
#use: bash footprinting-web.sh $domain

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
    exit 1
}

# Fijamos los parámetros de entrada del script a 1.
let numarg=$(echo $#)
let totalarg=1
if [ $numarg -ne $totalarg ];then
    echo -e "\n\t[*] Usage: bash footprinting-web.sh www.example.com\n"
    exit
fi

#Definimos variables globales del script
domain=$1

###### Abrimos la web por el camino normal ############

firefox --new-tab https://$domain/ &>/dev/null &

###### Información del dominio via web ################
firefox --new-tab https://sitereport.netcraft.com/?url=$domain &>/dev/null &
sleep 2
firefox --new-tab https://sitereport.netcraft.com/?url=https://$domain &>/dev/null &
sleep 2
firefox --new-tab https://censys.io/domain?q=$domain &>/dev/null &
sleep 2
firefox --new-tab https://www.robtex.com/dns-lookup/$domain &>/dev/null &
sleep 2
firefox --new-tab https://www.virustotal.com/gui/domain/$domain/relations &>/dev/null &
sleep 2
firefox --new-tab https://www.shodan.io/search?query=$domain &>/dev/null &
sleep 2
firefox --new-tab http://ipv4info.com/search/$domain &>/dev/null &
sleep 2
### Para buscar en Buscadores de dispositivos:
firefox --new-tab https://www.shodan.io/search?query=ssl%3A+%22$domain%22 &>/dev/null &
sleep 2
firefox --new-tab https://www.zoomeye.org/searchResult?q=$domain &>/dev/null &
sleep 2
firefox --new-tab https://app.binaryedge.io/services/query?query=$domain&page=1 &>/dev/null &
sleep 2
firefox --new-tab https://fofa.so &>/dev/null &
sleep 2
##### Información del DNS ################
firefox --new-tab https://securitytrails.com/domain/$domain/history/a &>/dev/null &
sleep 2
#firefox --new-tab https://dnsspy.io/scan/$domain &>/dev/null &
#sleep 2
firefox --new-tab https://viewdns.info/iphistory/?domain=$domain &>/dev/null &
sleep 2
firefox --new-tab https://viewdns.info/reverseip/?host=$domain&t=1 &>/dev/null &
sleep 2
#### Información de dominios de correos ######
firefox --new-tab https://hunter.io/search/$domain &>/dev/null &
sleep 2

echo -e "\n\n${yellowColour}[*]${endColour}${grayColour} Para cerrar todos los procesos en background usar kill % ${endColour}\n"
