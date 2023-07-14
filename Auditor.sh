#!/bin/bash
#author		: Manuel López Torrecillas
#use: bash Auditor.sh <domain>
#Herramientas necesarias a tener instaladas: proxychains, nmap, go (con la variable de entorno configurada), wafw00f, whatweb, dirsearch, tor, droopescan.
#Importante destacar que para dominios tipo domain.com.cu y similares introducir a mano la variable topdomain o habrá fases que seran muy largas porque buscaran subdominios de .com.co por ejemplo.

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
    echo -e "\n\t[*] Usage: bash $0 <www.domain.com>\n"
    exit
fi

# Declare var
domain=$1
topdomain=$(echo $domain | awk -F'.' '{print $(NF-1)"."$NF}')
#topdomain=$1
location="$(pwd)"
NS=$(curl -s -k -i -XGET "https://sitereport.netcraft.com/?url=$domain" | grep -i -A1 ">Nameserver<" | xargs | cut -d '>' -f 4 | cut -d '<' -f 1)
    if [ -z "$NS" ];then
        NS="8.8.8.8"
    fi
token_wordpress=""

# Obtenemos la ip del dominio
sudo cat /etc/hosts | grep $domain &>/dev/null
    if [ $? = 0 ];then
        IP=$(sudo cat /etc/hosts | grep $domain | awk '{print $1}') 
    else
        IP=$(sudo nmap -vvv -sn -PE -PP -PM -PS80,443,22,445,139,55 -PA80,443,22,445,139,55 -PU35349,45232 $domain 2>/dev/null | grep -m 1 $domain | awk '{print $3}' | tr -d '(' | tr -d ')') 
    fi

# Create Folders

if [ ! -d "$domain" ];then
	mkdir $domain
fi
if [ ! -d "$domain/1.DNS" ];then
	mkdir -p "$domain/1.DNS"
fi
if [ ! -d "$domain/2.Availability" ];then
	mkdir -p "$domain/2.Availability"
fi
if [ ! -d "$domain/3.Domain-Status" ];then
	mkdir -p "$domain/3.Domain-Status"
fi
if [ ! -d "$domain/4.Foot-Finger-printing" ];then
	mkdir -p "$domain/4.Foot-Finger-printing"
fi
if [ ! -d "$domain/5.Enumeration" ];then
	mkdir -p "$domain/5.Enumeration"
fi
if [ ! -d "$domain/6.Infraestructure" ];then
	mkdir -p "$domain/6.Infraestructure"
fi
if [ ! -d "$domain/7.Webscan" ];then
	mkdir -p "$domain/7.Webscan"
fi

# Print var

    echo "Doamin is $domain" | tee -a "$domain/.variables-scripts.debug"
    echo "Topdomain is $topdomain" | tee -a "$domain/.variables-scripts.debug"
    echo "Nameserver is $NS" | tee -a "$domain/.variables-scripts.debug"
    echo "IP is $IP" | tee -a "$domain/.variables-scripts.debug"

###### Abrimos la web por el camino normal ############
if [ ! -f "$location/$domain/4.Foot-Finger-printing/contador" ]; then
#    firefox --new-tab https://$domain/ &>/dev/null &

###### Información del dominio via web ################
#    firefox --new-tab https://sitereport.netcraft.com/?url=$domain &>/dev/null &
#    sleep 2
    firefox --new-tab https://sitereport.netcraft.com/?url=https://$domain &>/dev/null &
    sleep 2
    firefox --new-tab https://search.censys.io/search?resource=hosts&sort=RELEVANCE&per_page=25&virtual_hosts=EXCLUDE&q=$domain &>/dev/null &
    sleep 2
#    firefox --new-tab https://search.censys.io/search?resource=hosts&sort=RELEVANCE&per_page=25&virtual_hosts=EXCLUDE&q=$topdomain &>/dev/null &
#    sleep 2
    firefox --new-tab https://www.robtex.com/dns-lookup/$domain &>/dev/null &
    sleep 2
    firefox --new-tab https://www.virustotal.com/gui/domain/$domain/relations &>/dev/null &
    sleep 2
    firefox --new-tab https://www.shodan.io/search?query=$domain &>/dev/null &
    sleep 2
#    firefox --new-tab http://ipv4info.com/search/$domain &>/dev/null &
#    sleep 2
### Para buscar en Buscadores de dispositivos:
#    firefox --new-tab https://www.shodan.io/search?query=ssl%3A+%22$domain%22 &>/dev/null &
#    sleep 2
#    firefox --new-tab https://www.zoomeye.org/searchResult?q=$domain &>/dev/null &
#    sleep 2
#    firefox --new-tab https://app.binaryedge.io/services/query?query=$domain&page=1 &>/dev/null &
#    sleep 2
#    firefox --new-tab https://fofa.so &>/dev/null &
#    sleep 2
##### Información del DNS ################
#    firefox --new-tab https://securitytrails.com/domain/$domain/history/a &>/dev/null &
#    sleep 2
#     firefox --new-tab https://dnsspy.io/scan/$domain &>/dev/null &
#    sleep 2
    firefox --new-tab https://viewdns.info/iphistory/?domain=$domain &>/dev/null &
    sleep 2
#    firefox --new-tab https://viewdns.info/reverseip/?host=$domain&t=1 &>/dev/null &
#    sleep 2
#### Información de dominios de correos ######
#    firefox --new-tab https://hunter.io/search/$domain &>/dev/null &
#    sleep 2
fi


# 1. DNS

    if [ ! -f "$domain/1.DNS/Banner-DNS-Nameserver.txt" ]; then
        
    
        # Usando el nameserver del resolv.conf
        host $domain | tee -a "$domain/1.DNS/hostDomain.txt"
        host -a $topdomain | tee -a "$domain/1.DNS/hostTopDomain.txt"
        
        # Usando el nameserver de google 8.8.8.8
        dig @8.8.8.8 $domain | tee -a "$domain/1.DNS/digGoogle-Domain.txt"
        dig @8.8.8.8 any $topdomain | tee -a "$domain/1.DNS/digGoogle-TopDomain.txt"
        
        # Usando el nameserver del dominio a consultar
        if [[ ! -z "$NS" && ! $NS = "8.8.8.8" ]];then
            dig @"$NS" $domain | tee -a "$domain/1.DNS/digNameServerTarget-Domain.txt"
            dig @"$NS" any $topdomain | tee -a "$domain/1.DNS/digNameServerTarget-TopDomain.txt"
            
            #Para obtener el banner del dns nameserver:
            dig version.bind CHAOS TXT @"$NS" | tee -a "$domain/1.DNS/Banner-DNS-Nameserver.txt"
            
            #Para probar transferencia de zona: Ojo de lanzarlo desde la vpn.
            dig axfr $topdomain @"$NS" | tee -a "$domain/1.DNS/zone-transfer-with-domain.txt"
            dig axfr @"$NS" | tee -a "$domain/1.DNS/zone-transfer-without-domain.txt"
        fi
    fi

# 2. Availability

    if [ ! -f "$domain/2.Availability/ping.txt" ]; then
        nmap -Pn --reason -p 80,443 -sV -vvv $domain | tee -a "$domain/2.Availability/nmapWeb.txt"
        sudo nmap -Pn --reason --open --top-ports 50 -sT -oN "$domain/2.Availability/nmapTopPorts" -vvv $domain
        ping -c 1 $domain | tee -a "$domain/2.Availability/ping.txt"
    fi

#3. Original-Status
#   Ante futuros cambios en la web siempre podemos compararlos con la petición del momento de la auditoria.

    if [ ! -f "$domain/3.Domain-Status/curl-IP-withBody-HTTPS.txt" ]; then

        curl -I -k -L -v --max-time 30 --connect-timeout 30 -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36" -H "Referer: https://$domain/" http://$domain/ | tee -a "$domain/3.Domain-Status/curl-Domain-onlyheaders-HTTP.txt"
        curl -I -k -L -v --max-time 30 --connect-timeout 30 -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36" -H "Referer: https://$domain/" https://$domain/ | tee -a "$domain/3.Domain-Status/curl-Domain-onlyheaders-HTTPS.txt"

        curl -i -k -L -v --max-time 30 --connect-timeout 30 -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36" -H "Referer: https://$domain/" http://$domain/ | tee -a "$domain/3.Domain-Status/curl-Domain-withBody-HTTP.txt"
        curl -i -k -L -v --max-time 30 --connect-timeout 30 -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36" -H "Referer: https://$domain/" https://$domain/ | tee -a "$domain/3.Domain-Status/curl-Domain-withBody-HTTPS.txt"

        curl -I -k -L -v --max-time 30 --connect-timeout 30 -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36" -H "Referer: https://$domain/" http://$IP/ | tee -a "$domain/3.Domain-Status/curl-IP-onlyheaders-HTTP.txt"
        curl -I -k -L -v --max-time 30 --connect-timeout 30 -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36" -H "Referer: https://$domain/" https://$IP/ | tee -a "$domain/3.Domain-Status/curl-IP-onlyheaders-HTTPS.txt"

        curl -i -k -L -v --max-time 30 --connect-timeout 30 -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36" -H "Referer: https://$domain/" http://$IP/ | tee -a "$domain/3.Domain-Status/curl-IP-withBody-HTTP.txt"
        curl -i -k -L -v --max-time 30 --connect-timeout 30 -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36" -H "Referer: https://$domain/" https://$IP/ | tee -a "$domain/3.Domain-Status/curl-IP-withBody-HTTPS.txt"
      
    fi

#4. Footprinting y fingerprinting

    ### 1.Whois ###

    if [ ! -f "$location/$domain/4.Foot-Finger-printing/1.whoisDomain.txt" ]; then
        cat /etc/whois.conf | grep whois.nic.aarp &>/dev/null
        if [ $? = 1 ];then
            sudo rm -rf /etc/whois.conf
            sudo wget https://gist.githubusercontent.com/thde/3890aa48e03a2b551374/raw/138589bfcae4d24b31ddd61ac7886ab568a8fc28/whois.conf -O "/etc/whois.conf"
        fi

        whois $domain > "$location/$domain/4.Foot-Finger-printing/1.whoisDomain.txt" 
        whois $IP > "$location/$domain/4.Foot-Finger-printing/1.whoisIP.txt" 
    fi

    ### 2.Google Dorks ####
    # Añadir nuevos --> Pendiente y hacer un fork a mi github.

    if [ ! -f "$location/$domain/4.Foot-Finger-printing/2.google-dorks-domain.txt" ]; then
        
        if [ ! -d "/opt/Fast-Google-Dorks-Scan" ]; then
            sudo git clone https://github.com/IvanGlinkin/Fast-Google-Dorks-Scan.git /opt/Fast-Google-Dorks-Scan/ 
        else
            sudo git -C /opt/Fast-Google-Dorks-Scan/ pull 
        fi
        sleep 2
        bash /opt/Fast-Google-Dorks-Scan/FGDS.sh $domain | tee -a "$location/$domain/4.Foot-Finger-printing/2.google-dorks-domain.txt"
    fi

    ### 3.Footprinting spiders (gau y archive.org) ###

    if [ ! -f "$GOPATH/bin/gau" ]; then
        go install github.com/lc/gau/v2/cmd/gau@latest
        sleep 5
    fi


    if [ ! -f "$location/$domain/4.Foot-Finger-printing/3.waybackdataDomain.txt" ]; then  
	
    #Para evitar problemas de compatibilidad con el alias gau del plugin git de zsh lo renombramos:
        #grep -i 'gau=' $(locate git.plugin.zsh) &>/dev/null
        #if [ $? = 0 ];then
            #sed -i 's/gau/gauu/' $(locate git.plugin.zsh)
            #reset
        #fi

        gau --retries 15 --subs -o "$location/$domain/4.Foot-Finger-printing/3.gauDomain.txt" $topdomain 
        curl -s "http://web.archive.org/cdx/search/cdx?url=$topdomain/*&output=text&fl=original&collapse=urlkey" > "$location/$domain/4.Foot-Finger-printing/3.webarchiveDomain.txt" 

        cat "$location/$domain/4.Foot-Finger-printing/3.gauDomain.txt" | sort -u > "$location/$domain/4.Foot-Finger-printing/3.waybackdataDomain.tmp"
        cat "$location/$domain/4.Foot-Finger-printing/3.webarchiveDomain.txt" | sort -u >> "$location/$domain/4.Foot-Finger-printing/3.waybackdataDomain.tmp"
        sort -u "$location/$domain/4.Foot-Finger-printing/3.waybackdataDomain.tmp" | grep -i $domain > "$location/$domain/4.Foot-Finger-printing/3.waybackdataDomain.txt"
        rm -rf "$domain/4.Foot-Finger-printing/3.waybackdataDomain.tmp"
        
        # Para no pasarlo por burp descomentar
        echo "NOT CRAWLWER" > "$location/$domain/4.Foot-Finger-printing/contador"
        
        # Pulling and compiling js/php/aspx/jsp/json files from wayback output...

        for line in $(cat "$location/$domain/4.Foot-Finger-printing/3.waybackdataDomain.txt");do
            ext="${line##*.}"
            if [[ "$ext" == "js" ]]; then
                echo $line >> "$location/$domain/4.Foot-Finger-printing/3.js1.txt" 
                sort -u "$location/$domain/4.Foot-Finger-printing/3.js1.txt" >> "$location/$domain/4.Foot-Finger-printing/3.waybackdataDomain-js.txt"
                rm "$location/$domain/4.Foot-Finger-printing/3.js1.txt"
            fi
            if [[ "$ext" == "html" ]];then
                echo $line >> "$location/$domain/4.Foot-Finger-printing/3.jsp1.txt" 
                sort -u "$location/$domain/4.Foot-Finger-printing/3.jsp1.txt" >> "$location/$domain/4.Foot-Finger-printing/3.waybackdataDomain-jsp.txt"
                rm "$location/$domain/4.Foot-Finger-printing/3.jsp1.txt"
            fi
            if [[ "$ext" == "json" ]];then
                echo $line >> "$location/$domain/4.Foot-Finger-printing/3.json1.txt"
                sort -u "$location/$domain/4.Foot-Finger-printing/3.json1.txt" >> "$location/$domain/4.Foot-Finger-printing/3.waybackdataDomain-json.txt"
                rm "$location/$domain/4.Foot-Finger-printing/3.json1.txt"
            fi
            if [[ "$ext" == "php" ]];then
                echo $line >> "$location/$domain/4.Foot-Finger-printing/3.php1.txt"
                sort -u "$location/$domain/4.Foot-Finger-printing/3.php1.txt" >> "$location/$domain/4.Foot-Finger-printing/3.waybackdataDomain-php.txt"
                rm "$location/$domain/4.Foot-Finger-printing/3.php1.txt"
            fi
            if [[ "$ext" == "aspx" ]];then
                echo $line >> "$location/$domain/4.Foot-Finger-printing/3.aspx1.txt"
                sort -u "$location/$domain/4.Foot-Finger-printing/3.aspx1.txt" >> "$location/$domain/4.Foot-Finger-printing/3.waybackdataDomain-aspx.txt"
                rm "$location/$domain/4.Foot-Finger-printing/3.aspx1.txt"
            fi
        done
    fi
    ### Crawler with compiling info ###
    ##Burp###
    if [ ! -f "$location/$domain/4.Foot-Finger-printing/contador" ]; then
        for url in $(cat "$location/$domain/4.Foot-Finger-printing/3.waybackdataDomain.txt" | grep -i "$domain");do curl -i -k -L -v --max-time 90 --connect-timeout 90 -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36" -H "Referer: https://$domain" --proxy 127.0.0.1:8080 $url;done
        echo "NOT CRAWLWER" > "$location/$domain/4.Foot-Finger-printing/contador"
    fi

    ### 4.Subdomains ###

    if [ ! -f "$location/$domain/4.Foot-Finger-printing/4.subdomain.txt" ]; then

        if [ ! -f "/usr/bin/findomain" ]; then
            wget https://github.com/Findomain/Findomain/releases/download/8.2.1/findomain-linux.zip
            unzip findomain-linux.zip
            sudo chmod +x findomain
            sudo mv findomain /usr/bin/findomain
            rm -rf findomain-linux.zip
        fi

        if [ ! -f "$GOPATH/bin/subfinder" ]; then
            go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
        fi

        findomain -q -t $topdomain | tee -a "$location/$domain/4.Foot-Finger-printing/4.subdomain.tmp"
        subfinder -d $topdomain --silent | tee -a "$location/$domain/4.Foot-Finger-printing/4.subdomain.tmp"
        curl --connect-timeout 60 -s "https://sonar.omnisint.io/subdomains/$topdomain" | jq '.[]' | tr -d '"' >> "$location/$domain/4.Foot-Finger-printing/4.subdomain.tmp"
        curl --connect-timeout 60 -s "https://dns.bufferover.run/dns?q=$topdomain" | grep -i "\.$topdomain" | cut -d ',' -f2 | tr -d '"' | sort -u >> "$location/$domain/4.Foot-Finger-printing/4.subdomain.tmp"
        cat "$location/$domain/4.Foot-Finger-printing/3.waybackdataDomain.txt" | sed 's/\/\//\//g' | cut -d '/' -f 2 | cut -d ':' -f 1 | sort -u >> "$location/$domain/4.Foot-Finger-printing/4.subdomain.tmp"
        cat "$location/$domain/4.Foot-Finger-printing/4.subdomain.tmp" | grep -i $topdomain | sort -u >> "$location/$domain/4.Foot-Finger-printing/4.subdomain.txt"
        rm -rf "$location/$domain/4.Foot-Finger-printing/4.subdomain.tmp"
    fi
    ### 5.LEAK USER of toplevel domain ###

#    if [ ! -f "$domain/4.Foot-Finger-printing/5.pwndb.$domain.txt" ]; then
#        sudo systemctl start tor
#        sleep 5
#        pwndb.sh '' "$topdomain" | tee -a $domain/user-pass.$domain.txt
#        REQUEST=`curl -s --socks5-hostname localhost:9050 'http://pwndb2am4tzkvold.onion/' -H 'Connection: keep-alive' -H 'Cache-Control: max-age=0' -H 'Origin: http://pwndb2am4tzkvold.onion' -H 'Upgrade-Insecure-Requests: 1' -H 'Content-Type: application/x-www-form-urlencoded' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.120 Safari/537.36' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3' -H 'Referer: http://pwndb2am4tzkvold.onion/' -H 'Accept-Encoding: gzip, deflate' -H 'Accept-Language: en-US,en;q=0.9' --data "luser=&domain=$topdomain&luseropr=1&domainopr=1&submitform=em" --compressed --insecure`
#        echo "$REQUEST" | egrep "\[luser\] => |\[domain\] => |\[password\] => " | tr '\n' ' ' | sed 's/\[luser\]/\n\[luser\]/g' | awk '{print $3 "@" $6 ":" $9}' | tail -n +3 > "$domain/4.Foot-Finger-printing/5.pwndb.$domain.txt"
#
#        if echo $REQUEST | grep -q "2000 Array" ; then
#            echo "2000 Limit reached"
#        fi
#        sudo systemctl stop tor
#	sleep 5
#    fi

    ### 6.Detección de WAF ###
    ##Burp###
    
    if [ ! -f "$domain/4.Foot-Finger-printing/6.wafw00f.txt" ]; then
        wafw00f -p http://127.0.0.1:8080 -a https://$domain | tee -a $domain/4.Foot-Finger-printing/6.wafw00f.txt
    fi
    
    ### 7.Certificate-HTTP_HEADERS-Robots-Sitemap ###
    
    if [ ! -f "$domain/4.Foot-Finger-printing/7.SitemapHTTPS.txt" ]; then
        sudo nmap -Pn --disable-arp -f --reason -p 443 -oN "$domain/4.Foot-Finger-printing/7.Certificate-website" -vvv --script ssl-cert $domain
        curl -I -XGET -k -L -v -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36" -H "Referer: https://$domain" http://$domain/ | tee -a $domain/4.Foot-Finger-printing/7.HTTP_HEADERS.txt
        curl -I -XGET -k -L -v -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36" -H "Referer: https://$domain" https://$domain/ | tee -a $domain/4.Foot-Finger-printing/7.HTTPS_HEADERS.txt
        curl -i -XGET -k -L -v -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36" -H "Referer: https://$domain" http://$domain/robots.txt | tee -a $domain/4.Foot-Finger-printing/7.RobotsHTTP.txt
        curl -i -XGET -k -L -v -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36" -H "Referer: https://$domain" http://$domain/sitemap.xml | tee -a $domain/4.Foot-Finger-printing/7.SitemapHTTP.txt
        curl -i -XGET -k -L -v -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36" -H "Referer: https://$domain" https://$domain/robots.txt | tee -a $domain/4.Foot-Finger-printing/7.RobotsHTTPS.txt
        curl -i -XGET -k -L -v -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36" -H "Referer: https://$domain" https://$domain/sitemap.xml | tee -a $domain/4.Foot-Finger-printing/7.SitemapHTTPS.txt  
    fi

    ### 8.Fingerprint-SO-Webserver-Webapplication.
    
    if [ ! -f "$domain/4.Foot-Finger-printing/8.Fingerprint-Webapplication.txt" ]; then
        #sudo nmap --script-updatedb
        whatweb https://$domain/ -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36" | tee -a "$domain/4.Foot-Finger-printing/8.Fingerprint-Webapplication.txt"
        whatweb https://$domain/ -v --follow-redirect=always --open-timeout 120 --read-timeout 120 --max-redirects=30 --aggression=3 -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36" | tee -a "$domain/4.Foot-Finger-printing/8.Fingerprint-Webapplication-complete.txt"
        sudo nmap -Pn -vvv --disable-arp -f --reason -p 443,80,8080 -sV -oN "$domain/4.Foot-Finger-printing/8.Fingerprint-WebServer" $domain
        #sudo nmap -Pn -vvv --disable-arp -f --reason -O -oN "$domain/4.Foot-Finger-printing/8.Fingerprint-SO" $domain
    fi

#5.Enumeration

    if [ ! -f "$domain/5.Enumeration/dirsearch" ]; then
        
        #sudo dirsearch -F --max-rate=5 -b --random-agent --proxy=localhost:8080 -r --deep-recursive --force-recursive --url https://$domain/ -e txt,php,xml,conf,zip,gz,tar.gz,sql --timeout=60 --max-rate=5 -o "$domain/5.Enumeration/dirsearch"
        #sudo dirsearch -F --max-rate=5 -b --random-agent --proxy=localhost:8080 -r --deep-recursive --url https://$domain/ -e txt,php,xml,conf,zip,gz,tar.gz,sql --timeout=60 --max-rate=5 -o "$domain/5.Enumeration/dirsearch"
        #sudo dirsearch -F -b --random-agent --proxy=localhost:8080 --url https://$domain/ -e txt,php,xml,conf,zip,gz,tar.gz,sql --timeout=60 --max-rate=5 -o "$domain/5.Enumeration/dirsearch"
        sudo dirsearch -F -b --user-agent="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36" --url https://$domain/ -e txt,php,xml,conf,zip,gz,tar.gz,sql --timeout=40 --max-rate=5
        sudo cp /root/.dirsearch/reports/$domain/* ./$domain/5.Enumeration/dirsearch
        #proxychains -q sudo dirsearch -F -b --random-agent --url https://$domain/ --timeout=40 --max-rate=5 -o "$domain/5.Enumeration/dirsearch"

    fi

#6.Infraestructure

    if [ ! -f "$domain/6.Infraestructure/3.nmapVersion-CVE" ]; then

        sudo nmap -Pn -vvv --disable-arp --reason -f -sSV -p 80,443 -oN "$domain/6.Infraestructure/1.nmapFullHTTP" --script http-backup-finder,http-config-backup,http-errors,http-headers,http-iis-webdav-vuln,http-internal-ip-disclosure,http-methods,http-php-version,http-qnap-nas-info,http-robots.txt,http-shellshock,http-slowloris-check,http-waf-detect,"http-vuln*" $domain
        sudo nmap -Pn -sSV -f -sC -p 80,443,8080 --script safe,version,vuln -oN "$domain/6.Infraestructure/2.nmapScript-Safe-Default-version-vuln" $domain
        sudo nmap -Pn -sSV -f --top-ports 300 --script vulners -oN "$domain/6.Infraestructure/3.nmapVersion-CVE" $domain

    fi

#7.Webscan

    ### Nuclei ###
    if [ ! -f "$domain/7.Webscan/7.Nuclei-File" ]; then

        if [ ! -f "$GOPATH/bin/nuclei" ]; then
        GO111MODULE=on go get -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei
        nuclei -update-templates
        fi

        #nuclei -u https://$domain/ -t cves/ -rl 5 -proxy http://127.0.0.1:8080 -timeout 90 -stats -o "$domain/7.Webscan/1.Nuclei-CVE"
        nuclei -u https://$domain/ -t cves/ -rl 5 -timeout 90 -stats | tee "$domain/7.Webscan/1.Nuclei-CVE"
        #nuclei -u https://$domain/ -t vulnerabilities/ -rl 5 -proxy http://127.0.0.1:8080 -timeout 90 -stats -o "$domain/7.Webscan/2.Nuclei-Vulnerabilities"
        nuclei -u https://$domain/ -t vulnerabilities/ -rl 5 -timeout 90 -stats | tee "$domain/7.Webscan/1.Nuclei-Vulnerabilities"
        #nuclei -u https://$domain/ -t misconfiguration/ -rl 5 -proxy http://127.0.0.1:8080 -timeout 90 -stats -o "$domain/7.Webscan/3.Nuclei-Misconfiguration"
        nuclei -u https://$domain/ -t misconfiguration/ -rl 5 -timeout 90 -stats | tee "$domain/7.Webscan/1.Nuclei-Misconfiguration"
        #nuclei -u https://$domain/ -t exposed-panels/ -rl 5 -proxy http://127.0.0.1:8080 -timeout 90 -stats -o "$domain/7.Webscan/4.Nuclei-Exposed-panels"
        nuclei -u https://$domain/ -t exposed-panels/ -rl 5 -timeout 90 -stats | tee "$domain/7.Webscan/1.Nuclei-Exposed-panels"
        #nuclei -u https://$domain/ -t exposures/ -rl 5 -proxy http://127.0.0.1:8080 -timeout 90 -stats -o "$domain/7.Webscan/5.Nuclei-Exposures"
        nuclei -u https://$domain/ -t exposures/ -rl 5 -timeout 90 -stats | tee "$domain/7.Webscan/1.Nuclei-Exposures"
        #nuclei -u https://$domain/ -t default-logins/ -rl 5 -proxy http://127.0.0.1:8080 -timeout 90 -stats -o "$domain/7.Webscan/6.Nuclei-Default-logins"
        nuclei -u https://$domain/ -t default-logins/ -rl 5 -timeout 90 -stats | tee "$domain/7.Webscan/1.Nuclei-Default-logins"
        #nuclei -u https://$domain/ -t file/ -rl 5 -proxy http://127.0.0.1:8080 -timeout 90 -stats -o "$domain/7.Webscan/7.Nuclei-File"
        nuclei -u https://$domain/ -t cnvd/ -rl 5 -timeout 90 -stats | tee "$domain/7.Webscan/1.Nuclei-cnvd"

    fi

    ### Wordpress ###
    
    if [ ! -f "$domain/7.Webscan/2.Wpscan-enumerate" ]; then
        cat $domain/4.Foot-Finger-printing/8.Fingerprint-Webapplication.txt | grep -i "WordPress" &>/dev/null
        if [ $? = 0 ];then
            if [ -z "$token_wordpress" ];then
                
                echo -e "${yellowColour}[*]${endColour}${grayColour} Introducir token de api de wordpress para mejores resultados % ${endColour}\n"
                wpscan --update
                wpscan --rua --throttle 200 --connect-timeout 60 --user-agent "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36" --url https://$domain/ -v -o "$domain/7.Webscan/2.Wpscan-basic" -f cli --disable-tls-checks
                wpscan --rua --throttle 200 --connect-timeout 60 --user-agent "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36" --url https://$domain/ -v -o "$domain/7.Webscan/2.Wpscan-enumerate" -f cli --disable-tls-checks -e u,vp,vt
                droopescan scan wordpress --user-agent "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36" -u https://$domain | tee "$domain/7.Webscan/2.droopescan-wordpress"
            else
                
                wpscan --update
                wpscan --rua --throttle 200 --connect-timeout 60 --user-agent "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36" --url https://$domain/ -v -o "$domain/7.Webscan/2.Wpscan-basic" -f cli --disable-tls-checks --api-token $token_wordpress
                wpscan --rua --throttle 200 --connect-timeout 60 --user-agent "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36" --url https://$domain/ -v -o "$domain/7.Webscan/2.Wpscan-enumerate" -f cli --disable-tls-checks -e u,vp,vt --api-token $token_wordpress
                droopescan scan wordpress --user-agent "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36" -u https://$domain | tee "$domain/7.Webscan/2.droopescan-wordpress"
            fi    
        fi
    fi
    ### Moodle ###
    if [ ! -f "$domain/7.Webscan/3.droopescan-moodle" ]; then
        cat $domain/4.Foot-Finger-printing/8.Fingerprint-Webapplication.txt | grep -i "moodle" &>/dev/null
        if [ $? = 0 ];then
            droopescan scan moodle --user-agent "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36" -u https://$domain | tee "$domain/7.Webscan/3.droopescan-moodle"
        fi
    fi

    ### Drupal ###
    if [ ! -f "$domain/7.Webscan/4.droopescan-drupal" ]; then
        cat $domain/4.Foot-Finger-printing/8.Fingerprint-Webapplication.txt | grep -i "drupal" &>/dev/null
        if [ $? = 0 ];then
            droopescan scan drupal --user-agent "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36" -u https://$domain | tee "$domain/7.Webscan/4.droopescan-drupal"
        fi
    fi

    ### joomla ###
    if [ ! -f "$domain/7.Webscan/5.droopescan-joomla" ]; then
        cat $domain/4.Foot-Finger-printing/8.Fingerprint-Webapplication.txt | grep -i "joomla" &>/dev/null
        if [ $? = 0 ];then
            droopescan scan joomla --user-agent "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36" -u https://$domain | tee "$domain/7.Webscan/5.droopescan-joomla"
        fi
    fi

    ### silverstripe ###
    if [ ! -f "$domain/7.Webscan/6.droopescan-silverstripe" ]; then
        cat $domain/4.Foot-Finger-printing/8.Fingerprint-Webapplication.txt | grep -i "silverstripe" &>/dev/null
        if [ $? = 0 ];then
            droopescan scan silverstripe --user-agent "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36" -u https://$domain | tee "$domain/7.Webscan/6.droopescan-silverstripe"
        fi
    fi

echo -e "\n\n [+] Fin del script satisfactorio"
#echo -e "\n\n${yellowColour}[*]${endColour}${grayColour} Para cerrar todos los procesos en background usar kill % ${endColour}\n"
