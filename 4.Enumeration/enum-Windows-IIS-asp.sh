#!/bin/bash
#author		: Manuel López Torrecillas
#description: Script para enumeración dirigida a un sistema Windows con un servidor web IIS.
#use: ./enum-Windows-IIS-asp.sh $domain

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

### Actualizamos el repositorio de SecLists antes #####

#git -C /opt/SecLists/ pull

### Buscamos directorios en el idioma de la página ###

wfuzz -c --hc=404 -Z -f common-and-spanish.txt -z file,/opt/SecLists/Discovery/Web-Content/common-and-spanish.txt https://$domain/FUZZ 2>/dev/null
#wfuzz -c --hc=404 -Z -f common-and-dutch.txt -z file,/opt/SecLists/Discovery/Web-Content/common-and-dutch.txt https://$domain/FUZZ 2>/dev/null
#wfuzz -c --hc=404 -Z -f common-and-portuguese.txt -z file,/opt/SecLists/Discovery/Web-Content/common-and-portuguese.txt https://$domain/FUZZ 2>/dev/null
#wfuzz -c --hc=404 -Z -f common-and-french.txt -z file,/opt/SecLists/Discovery/Web-Content/common-and-french.txt https://$domain/FUZZ 2>/dev/null
#wfuzz -c --hc=404 -Z -f common-and-italian.txt -z file,/opt/SecLists/Discovery/Web-Content/common-and-italian.txt https://$domain/FUZZ 2>/dev/null

### Para CGI en Windows ###

wfuzz -c --hc=404 -Z -f CGI-Microsoft.txt -z file,/opt/SecLists/Discovery/Web-Content/CGI-Microsoft.fuzz.txt https://$domain/FUZZ 2>/dev/null

### Para ficheros típicos ###

wfuzz -c --hc=404 -Z -f Randomfiles.txt -z file,/opt/SecLists/Discovery/Web-Content/Randomfiles.fuzz.txt https://$domain/FUZZ 2>/dev/null
wfuzz -c --hc=404 -Z -f Common-DB-Backups.txt -z file,/opt/SecLists/Discovery/Web-Content/Common-DB-Backups.txt https://$domain/FUZZ 2>/dev/null

### Para servidor de aplicaciones ###

wfuzz -c --hc=404 -Z -f IIS.txt -z file,/opt/SecLists/Discovery/Web-Content/IIS.fuzz.txt https://$domain/FUZZ 2>/dev/null

### Para directorios root por defecto ###

wfuzz -c --hc=404 -Z -f Default-web-root-directory-Windows.txt -z file,/opt/SecLists/Discovery/Web-Content/default-web-root-directory-windows.txt https://$domain/FUZZ 2>/dev/null

### Para comunes backdoors que pueda tener el target ##########

wfuzz -c --hc=404 -Z -f CommonBackdoors-ASP.txt -z file,/opt/SecLists/Discovery/Web-Content/CommonBackdoors-ASP.fuzz.txt https://$domain/FUZZ 2>/dev/null

### Para tecnologia del aplicativo ###

wfuzz -c --hc=404 -Z -f asp.txt -z file,/opt/SecLists/Discovery/Web-Content/SVNDigger/cat/Language/asp.txt https://$domain/FUZZ 2>/dev/null
wfuzz -c --hc=404 -Z -f aspx.txt -z file,/opt/SecLists/Discovery/Web-Content/SVNDigger/cat/Language/aspx.txt https://$domain/FUZZ 2>/dev/null