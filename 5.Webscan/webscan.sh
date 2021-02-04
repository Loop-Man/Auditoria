#!/bin/bash
#author		: Manuel López Torrecillas
#description: Script para lanzar escaneres de vulnerabilidades de manera automatica.
#use: ./fingerprint.sh $domain

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
topdomain="$(echo $domain | cut -d "." -f2-3)"
location="$(pwd)"

if [ ! -d "$domain" ];then
	mkdir $domain
fi

#### Nikto (NADA) ####
	
	### Sencillo ###
	#nikto -h $domain -C all -port 80,443 -o "$domain/nikto.html" -vhost $domain -useragent 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36' | tee $domain/nikto.txt
	nikto -h https://$domain/ -C all -o "$location/$domain/niktoHTTPS.html" -vhost $domain -useragent 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36' | tee $location/$domain/niktoHTTPS.txt
	nikto -h http://$domain/ -C all -o "$location/$domain/niktoHTTP.html" -vhost $domain -useragent 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36' | tee $location/$domain/niktoHTTP.txt
	
	### Con ofuscación y mas complejo ###
	#nikto -host $domain -port 80,443 -useproxy http://127.0.0.1:8080/ -o "$domain/nikto-avanzado.html" -Display 1234 -vhost $domain -Cgidirs all -useragent 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36' -Pause 1 -timeout 30 -evasion 1234567 -Tuning 012345789abc | tee $domain/nikto-avanzado.txt
	#nikto -host $domain -port 80,443 -o nikto-avanzado.html -Display 1234 -vhost $domain -Cgidirs all -useragent 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36' -timeout 30 -evasion 1234567 -Tuning 012345789abc | tee $domain/nikto-avanzado.txt
	
	
#### Whatweb ###

whatweb https://$domain -v --follow-redirect=always --max-redirects=10 --aggression=3 --user-agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36" | tee $domain/whatweb.txt

#### Use nuclei to scan for vulnerabilities against all the live subdomains

nuclei -update-templates
#nuclei -l "../footprinting/$domain/subdomain.txt" -t cves/ -t files/ -t vulnerabilities/ -t security-misconfiguration/ -t subdomain-takeover/ -o "$domain/nuclei-report" -stats -retries 5 -timeout 7 | tee -a $domain/nuclei.txt
#nuclei -target https://$domain -t cves/ -t files/ -t vulnerabilities/ -t security-misconfiguration/ -t subdomain-takeover/ -o "$domain/nuclei-report" -stats -retries 5 -timeout 7 | tee -a $domain/nuclei.txt

nuclei -target https://$domain -t cves/ -t default-credentials/ -t dns/ -t files/ -t fuzzing/ -t generic-detections/ -t misc/ -t panels/ -t security-misconfiguration/ -t subdomain-takeover/ -t technologies/ -t tokens/ -t vulnerabilities/ -t wordlists/ -o "$domain/nuclei-report" -stats -retries 5 -timeout 7 | tee -a $domain/nuclei.txt


#### Use jaeles to scan for vulnerabilities against all the live subdomains

#jaeles scan -s cves,common,passive -U "$(cat ../footprinting/$domain/subdomain.txt | httprobe -s -p https:443)" -L 50 -v -G --html "$domain/jaeles-report.html" | tee -a $domain/jaeles.txt 
jaeles scan -s cves,common,passive -u https://$domain/ -L 50 -v -G --html "$domain/jaeles-report.html" | tee -a $domain/jaeles.txt


#### Use to sqliv to scan sql vulnerabilities ####

sqliv -t $domain | tee -a $domain/sqliv.txt



