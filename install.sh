#!/bin/bash
#author		: Manuel López Torrecillas
#description: Script para instalar todas las herramientas utilizadas en pestenting en combinación con scritps.
#use: bash install.sh $domain

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
	echo -e "${yellowColour}[*]${endColour}${grayColour} Ejemplo de uso: bash install.sh ${endColour}\n"
	exit 0
}

# Instalamos go, configuramos la variable de entorno $GOPATH y actualizamos los paquetes y dependencias de go.

sudo apt install golang -y &>/dev/null || sudo pacman -S --noconfirm --needed go &>/dev/null

if [ ! -d "$HOME/go" ];then
	mkdir "$HOME/go" &>/dev/null
fi

if [ -f "$HOME/.zshrc" ];then

	cat ~/.zshrc | grep GOPATH &>/dev/null
	if [ $? != 0 ];then
		echo 'export GOPATH=$HOME/go' >> ~/.zshrc
		echo 'export PATH=$PATH:$GOPATH/bin' >> ~/.zshrc
	fi
fi

if [ -f "$HOME/.bashrc" ];then
	cat ~/.bashrc | grep GOPATH &>/dev/null &>/dev/null
	if [ $? != 0 ];then
		echo 'export GOPATH=$HOME/go' >> ~/.bashrc
		echo 'export PATH=$PATH:$GOPATH/bin' >> ~/.bashrc
	fi
fi
# Instalamos herramientas en go:

if [ ! -f "$GOPATH/bin/gau" ]; then
	go get -u -v github.com/lc/gau
fi

if [ ! -f "$GOPATH/bin/assetfinder" ]; then
	go get -u github.com/tomnomnom/assetfinder 
fi

if [ ! -f "$GOPATH/bin/amass" ]; then
	export GO111MODULE=on 
    go get -v github.com/OWASP/Amass/v3/...
fi

if [ ! -f "$GOPATH/bin/subfinder" ]; then
	GO111MODULE=on go get -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder
fi

if [ ! -f "$GOPATH/bin/httprobe" ]; then
	go get -u github.com/tomnomnom/httprobe 
fi

if [ ! -f "$GOPATH/bin/gowitness" ]; then
	go get -u github.com/sensepost/gowitness
fi

if [ ! -f "$GOPATH/bin/subjack" ]; then
	go get github.com/haccer/subjack
fi

# Instalamos herramientas de github:

if [ ! -d "/opt/Fast-Google-Dorks-Scan" ]; then
	sudo git clone https://github.com/IvanGlinkin/Fast-Google-Dorks-Scan.git /opt/Fast-Google-Dorks-Scan/ 
else
	sudo git -C /opt/Fast-Google-Dorks-Scan/ pull 
fi

if [ ! -f "/usr/bin/findomain-linux" ]; then
	wget https://github.com/Edu4rdSHL/findomain/releases/latest/download/findomain-linux 
	sudo chmod +x findomain-linux
	sudo mv findomain-linux /usr/bin/findomain-linux 
fi

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