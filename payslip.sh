#!/bin/sh -eu

PROGNAME="$(basename ${0})"

usage() {
	echo "Download payslip pdf from ADP Freedon"
	echo
	echo "Usage: ${PROGNAME} -u <username> -e <employee code> [options]..."
	echo
	echo "Options:"
	echo
	echo "  -h, --help"
	echo "      This help text."
	echo
	echo "  -u <username>, --username <username>"
	echo "      username for payroll system (e.g. JBloggs@Mmarket)"
	echo
	echo "  -e <employee code>, --employee-code <employee code>"
	echo "      employee code for payroll system (e.g. 1234567)"
	echo
	echo "  -p <file>, --password-file <file>"
	echo "      file containing password. if unspecified, program will prompt for password"
	echo
}

PASSWORD_FILE='/dev/null'

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
	*)
		echo "Invalid option '${1}'. Use --help to see the valid options" >&2
		exit 1
		;;
	esac
	shift
done

if [ -f "${PASSWORD_FILE}" ]; then
  PASSWORD_ARG="--password=$(cat "${PASSWORD_FILE}")"
else
  PASSWORD_ARG='--ask-password'
fi

PAY_RUN_CODE='201709270001'
PAY_RUN_ENTRY_CODE='20170006'
EE_PAYROLL_CODE='001'
EE_SEPARATE_CHECK='0'

wget -q --user="${USERNAME}" "${PASSWORD_ARG}" \
  --save-cookies cookies.txt \
  --keep-session-cookies \
  --delete-after \
  'https://myfreedom.adp.com/essprotected/ukPortalLogin.asp'

TOKEN="$(wget -q -O - \
  --load-cookies cookies.txt \
  'https://fress2.adp.com/core/coreControl.asp?ProductType=0' \
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