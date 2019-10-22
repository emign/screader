#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/home/pi

# DATA FOR AQUAREA SERVICE PORTAL
# The deviceID is a unique identifier and NOT the ID shown in the portal. Find it from the website source
deviceID=""
# The userID can be found from the website source
userID=""

# The regular login-name for the service portal
username=""
# The password is a hashed and probably salted string. Find it from the website Source
password=""


# DATA FOR INFLUX DB
dbname=geisha
dbuser=
dbpassword=

curl --cookie-jar cookie https://aquarea-service.panasonic.com/ | grep -Eoi "shiesuahruefutohkun = '(.*?)'" | cut -d \' -f 2 > shiesuahruefutohkun
shiesuahruefutohkun="`cat shiesuahruefutohkun`"
curl --cookie-jar cookie -H "Origin: https://aquarea-service.panasonic.com" --referer https://aquarea-service.panasonic.com/ -d "var.loginId=${username}&var.password=${password}&var.inputOmit=false&shiesuahruefutohkun=${shiesuahruefutohkun}" -X POST https://aquarea-service.panasonic.com/installer/api/auth/login
curl --cookie cookie https://aquarea-service.panasonic.com/installer/home | grep -Eoi "shiesuahruefutohkun = '(.*?)'" | cut -d \' -f 2 > shiesuahruefutohkun
shiesuahruefutohkun="`cat shiesuahruefutohkun`"
curl --cookie cookie -d "var.functionSelectedGwUid=${userID}" -X POST https://aquarea-service.panasonic.com/installer/functionUserInformation | grep -Eoi "shiesuahruefutohkun = '(.*?)'" | cut -d \' -f 2 > shiesuahruefutohkun
shiesuahruefutohkun="`cat shiesuahruefutohkun`"
curl --cookie cookie -o aquareadata.json -d "var.deviceId=${deviceID}&shiesuahruefutohkun=${shiesuahruefutohkun}" -X POST https://aquarea-service.panasonic.com/installer/api/function/status

i=0
for row in $(cat zuordnung.json | jq -r '.[] | @base64'); do
    _jq() {
     echo ${row} | base64 --decode | jq -r ${1}
    }    
    description=$(_jq '.desc')
    fstext=$(_jq '.fstext')   
    textID=$(_jq '.textID')
 	measurementValue=$(cat aquareadata.json | jq '.statusDataInfo["'${fstext}'"]' | jq '.value')
 	textValue=$(cat aquareadata.json | jq -r '.statusDataInfo["'${fstext}'"]' | jq '.textValue')
 	measurementType=$(cat aquareadata.json | jq -r '.statusDataInfo["'${fstext}'"]' | jq '.type')
	trimmedValue=$(sed -e 's/^"//' -e 's/"$//' <<<"$measurementValue")
	trimmedDesc=$(sed -e 's/^"//' -e 's/"$//' <<<"$description")


	# INTEGER VALUE
 	re='^[0-9]+$'
	if  [[ $trimmedValue =~ $re ]] ; then

			curl -i -XPOST -u $dbuser:$dbpassword 'http://192.168.178.39:8086/write?db='${dbname}'' --data-binary ''${trimmedDesc}' value='${trimmedValue}''
	fi

 	i=$((i+1))
done
