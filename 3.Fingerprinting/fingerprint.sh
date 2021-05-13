#!/bin/bash
#author		: Manuel López Torrecillas
#description: Script para obtener información de manera activa del dominio elegido.
#use: bash fingerprint.sh $domain

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
    echo -e "\n\t[*] Usage: bash fingerprint.sh www.example.com\n"
    exit
fi

domain=$1
#topdomain="$(echo $domain | cut -d "." -f2-3)"
topdomain="$(echo $domain | awk -F'.' '{print $(NF-1)"."$NF}')"
location="$(pwd)"

if [ ! -d "$domain" ];then
	mkdir $domain
fi

####### Detección de WAF ########

wafw00f https://$domain | tee -a $domain/wafw00f.txt
#python3 /opt/WhatWaf/whatwaf -u https://$domain | tee -a $domain/whatwaf.txt

###### Obtención del certificado usado por la página #####

sudo nmap -Pn --disable-arp -f --reason -p 443 -oN "$domain/nmapCertificate" -vvv --script ssl-cert $domain

##### Cabeceras y conectividad HTTP y HTTPS #######

curl -IXGET -k -L -v -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36 Edge/12.246" -H "Referer: https://$domain" http://$domain/ | tee -a $domain/curlHTTP.txt
curl -IXGET -k -L -v -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36 Edge/12.246" -H "Referer: https://$domain" https://$domain/ | tee -a $domain/curlHTTPS.txt

#### Robots y sitemap para HTTP y HTTPS #######

curl -IXGET -k -L -v -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36 Edge/12.246" -H "Referer: https://$domain" http://$domain/robots.txt | tee -a $domain/curlRobotsHTTP.txt
curl -IXGET -k -L -v -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36 Edge/12.246" -H "Referer: https://$domain" http://$domain/sitemap.xml | tee -a $domain/curlSitemapHTTP.txt

curl -IXGET -k -L -v -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36 Edge/12.246" -H "Referer: https://$domain" https://$domain/robots.txt | tee -a $domain/curlRobotsHTTPS.txt
curl -IXGET -k -L -v -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36 Edge/12.246" -H "Referer: https://$domain" https://$domain/sitemap.xml | tee -a $domain/curlSitemapHTTPS.txt

#### Actualizar BBDD scripts de nmap ####

sudo nmap --script-updatedb

#### Fingerprint SO ######

sudo nmap -Pn -vvv --disable-arp --reason -f -D 104.83.26.43,200.61.38.216 --top-ports 5000 -sV -p- -O -oN "$domain/nmapSystemOperative" $domain

#### Fingerprint WebServer ####

sudo wget https://raw.githubusercontent.com/scipag/httprecon-nse/master/httprecon.nse -O /usr/share/nmap/scripts/httprecon.nse

sudo nmap -Pn --disable-arp -f --reason -p 443,80,8080 -oN "$domain/nmapWebServerFingerprint" -vvv -sV --script httprecon.nse $domain

#### Fingerprint Web Application  #####

whatweb http://$domain/ -v --follow-redirect=always --max-redirects=10 --aggression=3 --user-agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36 Edge/12.246" | tee -a $domain/whatwebHTTP.txt
whatweb https://$domain/ -v --follow-redirect=always --max-redirects=10 --aggression=3 --user-agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36 Edge/12.246" | tee -a $domain/whatwebHTTPS.txt

#### Fingerprint Web technology #####

#webtech -u http://$domain | tee -a $domain/webtechHTTP.txt
#webtech -u https://$domain | tee -a $domain/webtechHTTPS.txt

### Probar todos los métodos HTTP ####


### Crawler del dominio #### 

#gospider -s "https://$domain" -c 10 -d 10 -o "$domain/crawler.txt" -p http://127.0.0.1:8080
	##Ojo se puede usar con cookies de sesión o incluso directamente cogiendo de una petición guardada de burp para crawlear contenido con usuario###
		#gospider -s "https://$domain/PATH-AUTH" -o output -c 10 -d 10 --other-source --burp burp_req.txt (Para pillar todas las cabeceras de la petición)

## Ejemplo para pasar el fichero generado por curl a burpsuite.
#cat crawler.txt |  parallel -j50 -q curl -x http://127.0.0.1:8080 -w 'Status:%{http_code}\t Size:%{size_download}\t %{url_effective}\n' -o /dev/null -sk

#### Compruebo si el fichero tiene contenido y si es así lanza los crawlers #####
#if [ -s "../2.Footprinting/$domain/waybackdataDomain.txt" ];then  
#
#	for url in $(cat "../2.Footprinting/$domain/waybackdataDomain.txt");do
#
#		gospider -s "$url" -c 10 -d 10 >> $domain/crawler.tmp
#		hakrawler -url $domain -depth 300 -plain >> $domain/crawler.tmp
#		sort -u $domain/crawler.tmp | grep $domain >> $domain/crawler.tmp2
#		rm -rf $domain/crawler.tmp
#		
#	done
#sort -u $domain/crawler.tmp2 > $domain/crawler.txt
#rm -rf $domain/crawler.tmp*
#	
#fi


### ParamSpider ###

#python3 /opt/ParamSpider/paramspider.py --domain $domain --exclude svg,jpg,css,js --output "$domain/domainParam.txt"

#### Cosas a realizar a mano #######

echo -e "\n\n${yellowColour}[*]${endColour}${grayColour} Investigar código fuente de la página y de sus tecnologías usadas %${endColour}\n"
