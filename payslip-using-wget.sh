#!/bin/sh -eu
USERNAME="JBloggs@Mmarket"
EMPLOYEE_CODE='1234567'

PAY_RUN_CODE='201709270001'
PAY_RUN_ENTRY_CODE='20170006'
EE_PAYROLL_CODE='001'
EE_SEPARATE_CHECK='0'

wget -q --user="${USERNAME}" --ask-password \
  --save-cookies cookies.txt \
  --keep-session-cookies \
  --delete-after \
  'https://myfreedom.adp.com/essprotected/ukPortalLogin.asp'

TOKEN="$(wget -q -O - \
  --load-cookies cookies.txt \
  "https://fress2.adp.com/core/coreControl.asp?ProductType=0" \
  | grep sessionToken | cut -d "'" -f2)"

wget -q \
  --load-cookies cookies.txt \
  --output-document='payslip.pdf' \
  --header="Referer: https://fress2.adp.com/eforms/PdfDisplay.aspx" \
"https://fress2.adp.com/eforms/PdfBuilder.aspx?\
f=EPayslip&\
j=UK&\
y=2007&\
q=1&\
m=1&\
ed=20070101&\
e=${EMPLOYEE_CODE}&\
p=${PAY_RUN_CODE}&\
pec=${PAY_RUN_ENTRY_CODE}&\
eepc=${EE_PAYROLL_CODE}&\
eesc=${EE_SEPARATE_CHECK}&\
action=GenerateFirst&\
title=ADP+Freedom&\
SessionToken=${TOKEN}"

rm cookies.txt
