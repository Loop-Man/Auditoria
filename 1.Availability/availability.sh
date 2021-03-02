#!/bin/bash
#author		: Manuel López Torrecillas
#description: Script para comprobar disponibilidad del activo.
#use: ./availability.sh $domain

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

if [ ! -d "$domain" ];then
	mkdir $domain
fi

ping -c 1 $domain | tee -a $domain/ping.txt
host -a $domain | tee -a $domain/host.txt
dig @8.8.8.8 any $domain | tee -a $domain/dig.txt
sudo nmap -sP -PE -PP -PM -PS80,443,22,445,139 -PA80,443,22,445,139 -PU35349,45232 -n --send-ip --min-rate 5000 $domain | tee -a $domain/nmapAvailability.txt
sudo nmap -Pn --reason -p 80,443 -sV -v $domain | tee -a $domain/nmapWeb.txt
sudo nmap -Pn --reason --open -p- -sS --min-rate 5000 -v $domain | tee -a $domain/nmapALLPORTS.txt

curl -iXGET -k -L -v -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36 Edge/12.246" -H "Referer: https://$1" http://$domain/ | tee -a $domain/curlHTTP.txt

curl -iXGET -k -L -v -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36 Edge/12.246" -H "Referer: https://$1" https://$domain/ | tee -a $domain/curlHTTPS.txt


