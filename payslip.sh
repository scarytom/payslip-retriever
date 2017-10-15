#!/bin/sh -eu

PROGNAME="$(basename "${0}")"

usage() {
	echo "Download payslip pdf from ADP Freedom"
	echo
	echo "Usage: ${PROGNAME} -u <username> -e <employee code> [options]..."
	echo
	echo "Options:"
	echo
	echo "  -h, --help"
	echo "      This help text."
	echo
	echo "  -u <username>, --username <username>"
	echo "      username for payroll system (e.g. JBloggs@Company)"
	echo
	echo "  -e <employee code>, --employee-code <employee code>"
	echo "      employee code for payroll system (e.g. 1234567)"
	echo
	echo "  -p <file>, --password-file <file>"
	echo "      file containing password. if unspecified, program will prompt for password"
	echo
	echo "  -o <file>, --output <file>"
	echo "      location to write the payslip pdf. if unspecified, program will default to payslip.pdf"
	echo
}

fail() {
        echo "Error: ${1}" >&2
        exit 1
}

PASSWORD_FILE='/dev/null'
OUT_FILE='payslip.pdf'

while [ "${#}" -gt 0 ]
do
	case "${1}" in
	-h|--help)
		usage
		exit 0
		;;
	-u|--username)
		USERNAME="${2}"
		shift
		;;
	-e|--employee-code)
		EMPLOYEE_CODE="${2}"
                shift
		;;
	-p|--password-file)
		PASSWORD_FILE="${2}"
                shift
		;;
	-o|--output)
		OUT_FILE="${2}"
                shift
		;;
	*)
		fail "Invalid option '${1}'. Use --help to see the valid options"
		;;
	esac
	shift
done

[ -z "${USERNAME+x}" ] && fail "username is unset. Use --help for usage instructions"
[ -z "${EMPLOYEE_CODE+x}" ] && fail "employee code is unset. Use --help for usage instructions"

if [ -f "${PASSWORD_FILE}" ]; then
  PASSWORD_ARG="--password=$(cat "${PASSWORD_FILE}")"
else
  PASSWORD_ARG='--ask-password'
fi

PAY_RUN_DATE='20170927'   # for August, set to '20170825'
PAY_RUN_CODE="${PAY_RUN_DATE}0001"
PAY_RUN_ENTRY_CODE='20170006' # this is tax year offset (Apr2017 is '20170001' and Mar2018 is '20170012' I guess)
EE_PAYROLL_CODE='001'
EE_SEPARATE_CHECK='0'

wget -q --user="${USERNAME}" "${PASSWORD_ARG}" \
  --save-cookies 'cookies.txt' \
  --keep-session-cookies \
  --delete-after \
  'https://myfreedom.adp.com/essprotected/ukPortalLogin.asp'

TOKEN="$(wget -q -O - \
  --load-cookies 'cookies.txt' \
  'https://fress2.adp.com/core/coreControl.asp?ProductType=0' \
  | grep sessionToken | cut -d "'" -f2)"

JURISDICTION='UK'
FUNCTION='EPayslip' # for P60 set to 'EP60'
E_DATE='20070101'   # for P60 set to '20160406' say
YEAR='2007'         # for P60 set to '2016' say
QUARTER='1'         # for P60 set to '2'
MONTH='1'           # for P60 set to '4'

# need to find out what happens to these (for P60)
#TaxOffice=384
#PayeRef=XX12345

wget -q \
  --load-cookies 'cookies.txt' \
  --output-document="${OUT_FILE}" \
  --header='Referer: https://fress2.adp.com/eforms/PdfDisplay.aspx' \
"https://fress2.adp.com/eforms/PdfBuilder.aspx?\
f=${FUNCTION}&\
j=${JURISDICTION}&\
y=${YEAR}&\
q=${QUARTER}&\
m=${MONTH}&\
ed=${E_DATE}&\
e=${EMPLOYEE_CODE}&\
p=${PAY_RUN_CODE}&\
pec=${PAY_RUN_ENTRY_CODE}&\
eepc=${EE_PAYROLL_CODE}&\
eesc=${EE_SEPARATE_CHECK}&\
action=GenerateFirst&\
title=ADP+Freedom&\
SessionToken=${TOKEN}"

rm cookies.txt

if strings "${OUT_FILE}" | grep -q "${EMPLOYEE_CODE}"; then
  echo "Success! Output ${OUT_FILE}"
  exit 0
else
  fail 'PDF appears to be malformed. Likely wrong employee code or payroll date?'
fi
