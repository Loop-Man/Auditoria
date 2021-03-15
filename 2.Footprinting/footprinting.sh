#!/bin/bash
#author		: Manuel López Torrecillas
#description: Script para recopilación de información pasiva del activo.
#use: bash footprinting.sh $domain

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

function showhelp(){
	echo -e "\n${yellowColour}[*]${endColour}${grayColour} Menú de ayuda ${endColour}\n"
	#echo -e "\t${grayColour} -f: Información del dominio via web (bajo demanda) ${endColour}\n"
	#echo -e "\t${grayColour} -h: Muestra este menu de ayuda ${endColour}\n"
	#echo -e "\t${grayColour} -d: Indica el dominio objetivo ${endColour}\n"
	echo -e "${yellowColour}[*]${endColour}${grayColour} Ejemplo de uso: bash footprinting.sh www.example.com ${endColour}\n"
	exit 0
}

# Fijamos los parámetros de entrada del script a 1.
let numarg=$(echo $#)
let totalarg=1
if [ $numarg -ne $totalarg ];then
    showhelp
    exit
fi

#Definimos variables globales del script
domain=$1
location="$(pwd)"

sudo cat /etc/hosts | grep $domain &>/dev/null
if [ $? = 0 ];then
	IP=$(sudo cat /etc/hosts | grep $domain | awk '{print $1}') 
else
	IP=$(sudo nmap -sP -PE -PP -PM -PS80,443,22,445,139 -PA80,443,22,445,139 -PU35349,45232  --send-ip $domain | grep $domain | awk '{print $6}' | tr -d '(' | tr -d ')') 
fi

topdomain="$(echo $domain | awk -F'.' '{print $(NF-1)"."$NF}')"


#### Creo la carpeta del activo si no existe #####

if [ ! -d "$location/$domain" ];then
	mkdir $domain
fi

# Instalamos go, configuramos la variable de entorno $GOPATH y actualizamos los paquetes y dependencias de go.

sudo apt install golang -y  || sudo pacman -S --noconfirm --needed go 

if [ ! -d "$HOME/go" ];then
	mkdir "$HOME/go" 
fi

if [ -f "$HOME/.zshrc" ];then

	cat ~/.zshrc | grep GOPATH 
	if [ $? != 0 ];then
		echo 'export GOPATH=$HOME/go' >> ~/.zshrc
		echo 'export PATH=$PATH:$GOPATH/bin' >> ~/.zshrc
	fi
fi

if [ -f "$HOME/.bashrc" ];then
	cat ~/.bashrc | grep GOPATH  
	if [ $? != 0 ];then
		echo 'export GOPATH=$HOME/go' >> ~/.bashrc
		echo 'export PATH=$PATH:$GOPATH/bin' >> ~/.bashrc
	fi
fi

#Para actualizar los paquetes pero tarda la vida.

#go get -u all 

#### Whois ######

sudo rm -rf /etc/whois.conf
sudo wget https://gist.githubusercontent.com/thde/3890aa48e03a2b551374/raw/138589bfcae4d24b31ddd61ac7886ab568a8fc28/whois.conf -O "/etc/whois.conf" 

whois $domain > "$location/$domain/whoisDomain.txt" 
whois $IP > "$location/$domain/whoisIP.txt" 

### Para hacer busqueda rápida con google dorks mas comunes #####

if [ ! -d "/opt/Fast-Google-Dorks-Scan" ]; then
	sudo git clone https://github.com/IvanGlinkin/Fast-Google-Dorks-Scan.git /opt/Fast-Google-Dorks-Scan/ 
else
	sudo git -C /opt/Fast-Google-Dorks-Scan/ pull 
fi
sleep 3

bash /opt/Fast-Google-Dorks-Scan/FGDS.sh $domain | tee -a "$location/$domain/google-dorks-domain.txt"

### Para buscar contenido indexado por los buscadores y otras fuentes de información #######

if [ ! -f "$GOPATH/bin/gau" ]; then
	go get -u -v github.com/lc/gau
fi

sleep 3

gau --retries 15 -subs -random-agent -o "$location/$domain/gauDomain.txt" $topdomain 
curl -s "http://web.archive.org/cdx/search/cdx?url=$topdomain/*&output=text&fl=original&collapse=urlkey" > "$location/$domain/webarchiveDomain.txt" 


cat "$location/$domain/gauDomain.txt" | sort -u > "$location/$domain/waybackdataDomain.tmp"
cat "$location/$domain/webarchiveDomain.txt" | sort -u >> "$location/$domain/waybackdataDomain.tmp"
sort -u "$location/$domain/waybackdataDomain.tmp" | grep -i $domain > "$location/$domain/waybackdataDomain.txt"
#rm -rf $domain/waybackdataDomain.tmp

#### Crawler con la información obtenida de gau para el burp ######
#for url in $(cat gauDomain.txt); do firefox —new-tab $url & sleep 3; done   &
#for url in $(cat "$domain/waybackdataDomain.txt");do curl -IXGET -k -L -v -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36 Edge/12.246" -H "Referer: https://$domain" --proxy 127.0.0.1:8080 $url;done  &

#### Pulling and compiling all possible params found in wayback data... #####

cat "$location/$domain/waybackdataDomain.txt" | grep '?*=' | cut -d '=' -f 1 | sort -u >> "$location/$domain/waybackdataDomain_params.txt"
#for line in $(cat $domain/waybackdataDomain_params.txt);do echo $line'=';done

#### Pulling and compiling js/php/aspx/jsp/json files from wayback output... ####

for line in $(cat "$location/$domain/waybackdataDomain.txt");do
	ext="${line##*.}"
	if [[ "$ext" == "js" ]]; then
		echo $line >> "$location/$domain/js1.txt" 
		sort -u "$location/$domain/js1.txt" >> "$location/$domain/waybackdataDomain-js.txt"
		rm "$location/$domain/js1.txt"
	fi
	if [[ "$ext" == "html" ]];then
		echo $line >> "$location/$domain/jsp1.txt" 
		sort -u "$location/$domain/jsp1.txt" >> "$location/$domain/waybackdataDomain-jsp.txt"
		rm $location/$domain/jsp1.txt
	fi
	if [[ "$ext" == "json" ]];then
		echo $line >> "$location/$domain/json1.txt"
		sort -u "$location/$domain/json1.txt" >> "$location/$domain/waybackdataDomain-json.txt"
		rm "$location/$domain/json1.txt"
	fi
	if [[ "$ext" == "php" ]];then
		echo $line >> "$location/$domain/php1.txt"
		sort -u "$location/$domain/php1.txt" >> "$location/$domain/waybackdataDomain-php.txt"
		rm "$location/$domain/php1.txt"
	fi
	if [[ "$ext" == "aspx" ]];then
		echo $line >> "$location/$domain/aspx1.txt"
		sort -u "$location/$domain/aspx1.txt" >> "$location/$domain/waybackdataDomain-aspx.txt"
		rm "$location/$domain/aspx1.txt"
	fi
done


##### Obtención de subdominios ############

if [ ! -f "$GOPATH/bin/assetfinder" ]; then
	go get -u github.com/tomnomnom/assetfinder 
fi

if [ ! -f "$GOPATH/bin/amass" ]; then
	export GO111MODULE=on 
    go get -v github.com/OWASP/Amass/v3/... 
fi

if [ ! -f "/usr/bin/findomain-linux" ]; then
	wget https://github.com/Edu4rdSHL/findomain/releases/latest/download/findomain-linux 
	sudo chmod +x findomain-linux
	sudo mv findomain-linux /usr/bin/findomain-linux 
fi

if [ ! -f "$GOPATH/bin/subfinder" ]; then
	GO111MODULE=on go get -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder
fi

#subfinder --set-config PassivetotalUsername='USERNAME',PassivetotalKey='KEY'
#subfinder --set-config RiddlerEmail="EMAIL",RiddlerPassword="PASSWORD"
#subfinder --set-config CensysUsername="USERNAME",CensysSecret="SECRET"
#subfinder --set-config SecurityTrailsKey='KEY'

if [ ! -d "/opt/subbrute" ]; then
	sudo git clone https://github.com/TheRook/subbrute /opt/subbrute/
else
	sudo git -C /opt/subbrute/ pull 
fi

if [ ! -d "/opt/knock" ]; then
	sudo git clone https://github.com/guelfoweb/knock /opt/knock/ 
	sudo python2.7 /opt/knock/setup.py install
else
	sudo git -C /opt/knock/ pull
fi

if [ ! -d "/opt/SecLists" ]; then
	sudo git clone https://github.com/danielmiessler/SecLists.git /opt/SecLists/
else
	sudo git -C /opt/SecLists/ pull
fi

if [ ! -d "/opt/Sublist3r" ]; then
	sudo git clone https://github.com/aboul3la/Sublist3r.git /opt/Sublist3r/ 
	sudo pip3 install -r /opt/Sublist3r/requirements.txt
else
	sudo git -C /opt/Sublist3r/ pull
fi

### A probar ###
#https://github.com/swisskyrepo/PayloadsAllTheThings/blob/master/Methodology%20and%20Resources/Subdomains%20Enumeration.md#enumerate-all-subdomains-only-if-the-scope-is-domainext

#python3 /opt/subbrute/subbrute.py $domain -o "$domain/subbrute.txt"
#knockpy $domain -w /opt/SecLists/Discovery/DNS/subdomains-top1million-110000.txt | tee "$domain/knockpy.txt"
#python3 /opt/Sublist3r/sublist3r.py -b -d $domain -p 80,443 -o "$domain/sublist3r.py"


### Seguros ###

assetfinder --subs-only $topdomain > "$location/$domain/subdomain.tmp"
amass enum -d $topdomain >> "$location/$domain/subdomain.tmp"
findomain-linux -q -t $topdomain >> "$location/$domain/subdomain.tmp"
subfinder -d $topdomain --silent >> "$location/$domain/subdomain.tmp"
curl -s "https://sonar.omnisint.io/subdomains/$topdomain" | jq '.[]' | tr -d '"' >> "$location/$domain/subdomain.tmp"
curl -s "https://dns.bufferover.run/dns?q=$topdomain" | grep -i "\.$topdomain" | cut -d ',' -f2 | tr -d '"' | sort -u >> "$location/$domain/subdomain.tmp"
cat "$location/$domain/waybackdataDomain.txt" | sed 's/\/\//\//g' | cut -d '/' -f 2 | cut -d ':' -f 1 | sort -u >> "$location/$domain/subdomain.tmp"


cat "$location/$domain/subdomain.tmp" | grep -i $topdomain | sort -u >> "$location/$domain/subdomain.txt"
#rm -rf "$location/$domain/subdomain.tmp"

amass enum -v -src -ip -brute -d $topdomain >> "$location/$domain/subdomain-brute-force.txt"
cat "$location/$domain/subdomain-brute-force.txt" | cut -d ']' -f 2 | sed 's/  */ /g' | cut -d ' ' -f 2 | sort -u > "$location/$domain/subdomain-final.tmp"
sort -u "$location/$domain/subdomain.txt" >> "$location/$domain/subdomain-final.tmp"
sort -u "$location/$domain/subdomain-final.tmp" > "$location/$domain/subdomain-final.txt"
#rm -rf "$location/$domain/subdomain-final.tmp"


#### Probing for alive domains #########

if [ ! -f "$GOPATH/bin/httprobe" ]; then
	go get -u github.com/tomnomnom/httprobe 
fi

cat "$location/$domain/subdomain-final.txt" | httprobe -s -p https:443 | sed 's/https\?:\/\///' | tr -d ':443' | tee -a "$location/$domain/subdomain-alive443.txt"
cat "$location/$domain/subdomain-final.txt" | httprobe -s -p http:80 | sed 's/http\?:\/\///' | tr -d ':80' | tee -a "$location/$domain/subdomain-alive80.txt"

cat "$location/$domain/subdomain-final.txt" | httprobe -s -p https:443 | sed 's/:443//g' > "$location/$domain/url-alive443.txt"
cat "$location/$domain/subdomain-final.txt" | httprobe -s -p http:80 | sed 's/:80//g' > "$location/$domain/url-alive80.txt"

#### Running gowitness against all compiled domains... ####

if [ ! -f "$GOPATH/bin/gowitness" ]; then
	go get -u github.com/sensepost/gowitness
fi

if [ ! -d "$location/$domain/screenshots" ]; then
	mkdir "$location/$domain/screenshots"
fi

gowitness file -f "$location/$domain/url-alive443.txt" -P "$location/$domain/screenshots"
gowitness file -f "$location/$domain/url-alive80.txt" -P "$location/$domain/screenshots"

## Subdomain take-over

if [ ! -f "$GOPATH/bin/subjack" ]; then
	go get github.com/haccer/subjack
fi

#subjack -w assetfinder.txt -t 100 -timeout 30 -o subjack.txt -ssl  &
subjack -w "$location/$domain/subdomain-final.txt" -t 100 -timeout 30 -ssl -o "$location/$domain/potential_takeovers.txt"


##### Fuga de usuarios usando el toplevel del subdomain #########

sudo systemctl start tor
sleep 5
#pwndb.sh '' "$topdomain" | tee -a $domain/user-pass.$domain.txt
REQUEST=`curl -s --socks5-hostname localhost:9050 'http://pwndb2am4tzkvold.onion/' -H 'Connection: keep-alive' -H 'Cache-Control: max-age=0' -H 'Origin: http://pwndb2am4tzkvold.onion' -H 'Upgrade-Insecure-Requests: 1' -H 'Content-Type: application/x-www-form-urlencoded' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.120 Safari/537.36' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3' -H 'Referer: http://pwndb2am4tzkvold.onion/' -H 'Accept-Encoding: gzip, deflate' -H 'Accept-Language: en-US,en;q=0.9' --data "luser=&domain=$topdomain&luseropr=1&domainopr=1&submitform=em" --compressed --insecure`
echo "$REQUEST" | egrep "\[luser\] => |\[domain\] => |\[password\] => " | tr '\n' ' ' | sed 's/\[luser\]/\n\[luser\]/g' | awk '{print $3 "@" $6 ":" $9}' | tail -n +3 > "$domain/pwndb.$domain.txt"

if echo $REQUEST | grep -q "2000 Array" ; then
	  echo "2000 Limit reached"
fi

sudo systemctl stop tor

echo -e "\n\n${yellowColour}[*]${endColour}${grayColour} Para cerrar todos los procesos en background usar kill % ${endColour}\n"
