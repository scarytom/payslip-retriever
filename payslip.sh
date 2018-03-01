#!/bin/sh -eu
PAY_DATE='27'

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
  echo "  -d <date>, --payslip-date <date>"
  echo "      date of the payslip"
  echo "      if you specify 'yyyy-mm' only, the day will be calculated best effort"
  echo "      if unspecified, will use retrieve payslip for the current month, or last month if not yet ${PAY_DATE} of the month"
  echo
  echo "  -p <file>, --password-file <file>"
  echo "      file containing password. if unspecified, program will prompt for password"
  echo
  echo "  -o <file>, --output <file>"
  echo "      location to write the payslip pdf. if unspecified, program will default to payslip.pdf"
  echo
  echo "  -v, --verbose"
  echo "      be verbose, show the HTTP calls being made"
  echo
}

fail() {
  echo "Error: ${1}" >&2
  exit 1
}

if [ "$(uname)" = 'Darwin' ]; then
  if which gdate >/dev/null; then
    date='gdate'
  else
    fail 'Missing gdate command. Perhaps brew install coreutils?'
  fi
else
  date='date'
fi

if [ "$($date -d 'now' '+%-d')" -lt "${PAY_DATE}" ]; then
  PAYSLIP_DATE="$($date -d '-1 month' '+%Y-%m')"
else
  PAYSLIP_DATE="$($date -d 'now' '+%Y-%m')"
fi

PASSWORD_FILE='/dev/null'
OUT_FILE='payslip.pdf'
VERBOSE='-q'

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
    -d|--payslip-date)
      PAYSLIP_DATE="${2}"
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
    -v|--verbose)
      VERBOSE=''
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

calc_payroll_date() {
  # first weekday on-or-before $PAY_DATE of the month
  YEARMONTH="$($date -d "${1}" '+%Y-%m')"
  TWENTYSEVENTH="${YEARMONTH}-${PAY_DATE}"
  case "$($date -d "${TWENTYSEVENTH}" '+%a')" in
    Sat)
      echo "${YEARMONTH}-26"
      ;;
    Sun)
      echo "${YEARMONTH}-25"
      ;;
    *)
      echo "${TWENTYSEVENTH}"
      ;;
  esac
}

calc_run_entry_code() {
  # this is tax year offset (Apr2017 is '20170001' and Mar2018 is '20170012' I guess)
  MONTH="$($date -d "${1}" '+%-m')"
  YEAR="$($date -d "${1}" '+%Y')"

  if [ "${MONTH}" -lt '4' ]; then
    echo "$((YEAR - 1))00$((MONTH + 9))"
  else
    echo "${YEAR}000$((MONTH - 3))"
  fi
}

if [ "${#PAYSLIP_DATE}" -le '7' ]; then
  PAYSLIP_DATE="$(calc_payroll_date "${PAYSLIP_DATE}-01")"
fi

PAY_RUN_CODE="$($date -d "${PAYSLIP_DATE}" '+%Y%m%d')0001"
PAY_RUN_ENTRY_CODE="$(calc_run_entry_code "${PAYSLIP_DATE}")"
EE_PAYROLL_CODE='001'
EE_SEPARATE_CHECK='0'
JURISDICTION='UK'
FUNCTION='EPayslip' # for P60 set to 'EP60'
E_DATE='20070101'   # for P60 set to '20160406' say
YEAR='2007'         # for P60 set to '2016' say
QUARTER='1'         # for P60 set to '2'
MONTH='1'           # for P60 set to '4'

# required for P60 generation only.
TAX_OFFICE='384'
PAYEE_REF='XX12345' # is this per employee or per employer?

echo 'Logging in...'
wget ${VERBOSE} --user="${USERNAME}" "${PASSWORD_ARG}" \
  --save-cookies 'cookies.txt' \
  --keep-session-cookies \
  --delete-after \
  'https://myfreedom.adp.com/essprotected/ukPortalLogin.asp'

echo 'Obtaining session token...'
TOKEN="$(wget ${VERBOSE} -O - \
  --load-cookies 'cookies.txt' \
  'https://fress1.adp.com/core/coreControl.asp?ProductType=0' \
  | grep sessionToken | cut -d "'" -f2)"

if [ -z "${TOKEN}" ]; then
   fail 'sessionToken not found in repsonse from ADP.'
fi

echo 'Downloading payslip...'
wget ${VERBOSE} \
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
t=${TAX_OFFICE}&\
pr=${PAYEE_REF}&\
action=GenerateFirst&\
title=ADP+Freedom&\
SessionToken=${TOKEN}"

rm cookies.txt

if which strings >/dev/null; then
  if strings "${OUT_FILE}" | grep -q "${EMPLOYEE_CODE}"; then
    echo "Success! Output ${OUT_FILE}"
    exit 0
  else
    fail 'PDF appears to be malformed. Likely wrong employee code or payroll date?'
  fi
else
  echo 'PDF generated but strings command unavailable so unable to validate, suggest you do so manually'
fi

# vim :set ts=2 sw=2 sts=2 et :
