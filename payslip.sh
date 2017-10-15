#!/bin/sh -eu

USERNAME='JSmith@Mmarket'
EMPLOYEE_CODE='1231231'

curl --location-trusted -ssL -b/dev/null -o/dev/null -D headers -u "${USERNAME}" 'https://myfreedom.adp.com/essprotected/ukPortalLogin.asp' >/dev/null
SESSION_TOKEN="$(curl -ss -b headers 'https://fress2.adp.com/core/coreControl.asp?ProductType=0' | sed -E '/.*sessionToken=\x27([^\x27]+).*/!d;s//\1/')"

echo "your session token is: ${SESSION_TOKEN}"

#curl -b headers -v "https://fress2.adp.com/eforms/PdfDisplay.aspx?emplcode=${EMPLOYEE_CODE}&payruncode=201709270001&payrunentrycode=20170006&eepayrollcode=001&eeseparatecheck=0&f=EPayslip&j=UK&y=2007&q=1&m=1&action=GenerateFirst&ed=20070101&title=ADP%20Freedom&SessionToken=${SESSION_TOKEN}" \

curl -b headers -v "https://fress2.adp.com/eforms/PdfBuilder.aspx?f=EPayslip&j=UK&y=2007&q=1&m=1&ed=20070101&e=${EMPLOYEE_CODE}&p=201709270001&pec=20170006&eepc=001&eesc=0&action=GenerateFirst&title=ADP+Freedom&SessionToken=${SESSION_TOKEN}" \
 -H "Referer: https://fress2.adp.com/eforms/PdfDisplay.aspx?emplcode=${EMPLOYEE_CODE}&payruncode=201709270001&payrunentrycode=20170006&eepayrollcode=001&eeseparatecheck=0&f=EPayslip&j=UK&y=2007&q=1&m=1&action=GenerateFirst&ed=20070101&title=ADP%20Freedom&SessionToken=${SESSION_TOKEN}" 

