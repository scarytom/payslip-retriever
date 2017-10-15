#!/bin/sh -eu
USERNAME="JBloggs@Mmarket"
PASSWORD="you_wish"
EMPLOYEE_CODE='1234567'

wget -q --user="${USERNAME}" --password="${PASSWORD}" \
  --save-cookies cookies.txt \
  --keep-session-cookies \
  --delete-after \
  'https://myfreedom.adp.com/essprotected/ukPortalLogin.asp'

TOKEN="$(wget -q -O - --user="${USERNAME}" --password="${PASSWORD}" \
  --save-cookies cookies.txt \
  --keep-session-cookies \
  --load-cookies cookies.txt \
  "https://fress2.adp.com/core/coreControl.asp?ProductType=0" \
  | grep sessionToken | cut -d "'" -f2)"

wget -q --user="${USERNAME}" --password="${PASSWORD}" \
  --save-cookies cookies.txt \
  --keep-session-cookies \
  --load-cookies cookies.txt \
  --output-document='payslip.pdf' \
  --header="Referer: https://fress2.adp.com/eforms/PdfDisplay.aspx?emplcode=${EMPLOYEE_CODE}&payruncode=201709270001&payrunentrycode=20170006&eepayrollcode=001&eeseparatecheck=0&f=EPayslip&j=UK&y=2007&q=1&m=1&action=GenerateFirst&ed=20070101&title=ADP%20Freedom&SessionToken=${TOKEN}" \
  "https://fress2.adp.com/eforms/PdfBuilder.aspx?f=EPayslip&j=UK&y=2007&q=1&m=1&ed=20070101&e=${EMPLOYEE_CODE}&p=201709270001&pec=20170006&eepc=001&eesc=0&action=GenerateFirst&title=ADP+Freedom&SessionToken=${TOKEN}"

rm cookies.txt
