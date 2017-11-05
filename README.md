Automatically retrieve payslip PDFs from [ADP Freedom](https://myfreedom.adp.com), which ironically despite the name only works in Internet Explorer by default.

See `./payslip.sh -h` for usage instructions.

Requires `gdate` aka GNU date on macOS. You can obtain this with `brew install coreutils` if running Homebrew.
Requires `wget` You can obtain this with `brew install wget` if running Homebrew.

Assumptions:
 - You're in the UK and paid only once a month.
 - You're paid on the 27th.
 - You have registered for an account on myfreedom.adp.com and logged in and accepted the terms

Patches welcome.
