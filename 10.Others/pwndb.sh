#! /bin/bash
# Requiere tor, acordarse de usarlo

USER=$1
DOMAIN=$2

echo "$0 'user' 'domain'"

# echo "curl --socks5-hostname localhost:9050 'http://pwndb2am4tzkvold.onion/' -H 'Connection: keep-alive' -H 'Cache-Control: max-age=0' -H 'Origin: http://pwndb2am4tzkvold.onion' -H 'Upgrade-Insecure-Requests: 1' -H 'Content-Type: application/x-www-form-urlencoded' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.120 Safari/537.36' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3' -H 'Referer: http://pwndb2am4tzkvold.onion/' -H 'Accept-Encoding: gzip, deflate' -H 'Accept-Language: en-US,en;q=0.9' --data 'luser=$USER&domain=$DOMAIN&luseropr=1&domainopr=1&submitform=em' --compressed --insecure"

REQUEST=`curl -s --socks5-hostname localhost:9050 'http://pwndb2am4tzkvold.onion/' -H 'Connection: keep-alive' -H 'Cache-Control: max-age=0' -H 'Origin: http://pwndb2am4tzkvold.onion' -H 'Upgrade-Insecure-Requests: 1' -H 'Content-Type: application/x-www-form-urlencoded' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.120 Safari/537.36' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3' -H 'Referer: http://pwndb2am4tzkvold.onion/' -H 'Accept-Encoding: gzip, deflate' -H 'Accept-Language: en-US,en;q=0.9' --data "luser=$USER&domain=$DOMAIN&luseropr=1&domainopr=1&submitform=em" --compressed --insecure`
echo "$REQUEST" | egrep "\[luser\] => |\[domain\] => |\[password\] => " | tr '\n' ' ' | sed 's/\[luser\]/\n\[luser\]/g' | awk '{print $3 "@" $6 ":" $9}' | tail -n +3

if echo $REQUEST | grep -q "2000 Array" ; then
	  echo "2000 Limit reached"
fi
