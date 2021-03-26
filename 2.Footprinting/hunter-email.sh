#!/bin/bash
#author		: Manuel López Torrecillas
#description: Script para obtener emails del dominio que le pasemos usando la api de hunter.io
#use: bash hunter-email.sh <domain>
#Obtener el dominio de la empresa del registro SOA del dns del dominio que estemos auditando.

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
    echo -e "\n\t[*] Usage: bash hunter-email.sh gmail.com\n"
    exit
fi

# Declaramos variables del script
API_KEY=""
if [ -z "$API_KEY" ];then
	echo -e "\n\t[*] Error: NOT API_KEY FOUND\n"
	exit
fi
domain=$1
topdomain=$(echo $domain | awk -F'.' '{print $(NF-1)"."$NF}')

# Crear carpeta contenedora de resultados

if [ ! -d "emails-$domain" ];then
	mkdir "emails-$domain"
fi

# Peticiones a la API de hunter.io

curl -s -XGET -k "https://api.hunter.io/v2/domain-search?domain=$topdomain&api_key=$API_KEY" | jq '.data.emails[] .value' | tr -d '"' > "emails-$domain/emails.txt"
