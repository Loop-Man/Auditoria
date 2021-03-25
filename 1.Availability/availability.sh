#!/bin/bash
#author		: Manuel López Torrecillas
#description: Script para comprobar disponibilidad del activo.
#use: bash availability.sh <domain>

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
    echo -e "\n\t[*] Usage: bash availability.sh www.example.com\n"
    exit
fi

# Creamos carpetas necesarias en caso de no existir

if [ ! -d "$domain" ];then
	mkdir $domain
fi
if [ ! -d "$domain/DNS" ];then
	mkdir -p "$domain/DNS"
fi
if [ ! -d "$domain/Availability" ];then
	mkdir -p "$domain/Availability"
fi
if [ ! -d "$domain/Domain-Status" ];then
	mkdir -p "$domain/Domain-Status"
fi

# Declaramos variables del script
domain=$1
topdomain=$(echo $domain | awk -F'.' '{print $(NF-1)"."$NF}')
NS=$(curl -s -k -i -XGET "https://sitereport.netcraft.com/?url=$domain" | grep -i -A1 ">Nameserver<" | xargs | cut -d '>' -f 4 | cut -d '<' -f 1)

sudo cat /etc/hosts | grep $domain &>/dev/null
if [ $? = 0 ];then
	IP=$(sudo cat /etc/hosts | grep $domain | awk '{print $1}') 
else
	IP=$(sudo nmap -sP -PE -PP -PM -PS80,443,22,445,139 -PA80,443,22,445,139 -PU35349,45232 -oN "$domain/Availability/nmapAvailability.txt" --send-ip $domain | grep $domain | awk '{print $6}' | tr -d '(' | tr -d ')') 
fi

# Imprimimos las variables del script

echo "Doamin is $domain" | tee -a "$domain/.variables-scripts.debug"
echo "Topdomain is $topdomain" | tee -a "$domain/.variables-scripts.debug
echo "Nameserver is $NS" | tee -a "$domain/.variables-scripts.debug
echo "IP is $IP" | tee -a "$domain/.variables-scripts.debug


# Estudiamos la disponibilidad del activo
ping -c 1 $domain | tee -a "$domain/Availability/ping.txt"
sudo nmap -Pn --reason -p 80,443 -sV -vvv $domain | tee -a "$domain/Availability/nmapWeb.txt"
sudo nmap -Pn --reason --open -sS -oA "$domain/Availability/nmapTopPorts" -vvv $domain


# Estudiamos los registros DNS
# Usando el nameserver del resolv.conf
host $domain | tee -a "$domain/DNS/hostDomain.txt"
host -a $topdomain | tee -a "$domain/DNS/hostTopDomain.txt"
# Usando el nameserver de google 8.8.8.8
dig @8.8.8.8 $domain | tee -a "$domain/DNS/digGoogle-Domain.txt"
dig @8.8.8.8 any $topdomain | tee -a "$domain/DNS/digGoogle-TopDomain.txt"
# Usando el nameserver del dominio a consultar
if [ -z "$NS" ];then
	dig @"$NS" $domain | tee -a "$domain/DNS/digNameServerTarget-Domain.txt"
	dig @"$NS" any $topdomain | tee -a "$domain/DNS/digNameServerTarget-TopDomain.txt"
fi

#Establecemos el estado original en la auditoria presente del target, por ip y por dominio. 
#Ante futuros cambios en la web siempre podemos compararlos con la petición del momento de la auditoria.

curl -iXGET -k -I -L -v -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36 Edge/12.246" -H "Referer: https://$1" http://$domain/ | tee -a "$domain/Domain-Status/curl-Domain-HTTP-onlyheaders.txt"
curl -iXGET -k -I -L -v -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36 Edge/12.246" -H "Referer: https://$1" https://$domain/ | tee -a "$domain/Domain-Status/curl-Domain-HTTPS-onlyheaders.txt"

curl -iXGET -k -L -v -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36 Edge/12.246" -H "Referer: https://$1" http://$domain/ | tee -a "$domain/Domain-Status/curl-Domain-HTTP-Headers-Body.txt"
curl -iXGET -k -L -v -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36 Edge/12.246" -H "Referer: https://$1" https://$domain/ | tee -a "$domain/Domain-Status/curl-Domain-HTTPS-Headers-Body.txt"

curl -iXGET -k -I -L -v -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36 Edge/12.246" -H "Referer: https://$IP" http://$IP/ | tee -a "$domain/Domain-Status/curl-IP-HTTP-onlyheaders.txt"
curl -iXGET -k -I -L -v -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36 Edge/12.246" -H "Referer: https://$IP" https://$IP/ | tee -a "$domain/Domain-Status/curl-IP-HTTPS-onlyheaders.txt"

curl -iXGET -k -L -v -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36 Edge/12.246" -H "Referer: https://$IP" http://$IP/ | tee -a "$domain/Domain-Status/curl-IP-HTTP-Headers-Body.txt"
curl -iXGET -k -L -v -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36 Edge/12.246" -H "Referer: https://$IP" https://$IP/ | tee -a "$domain/Domain-Status/curl-IP-HTTPS-Headers-Body.txt"
