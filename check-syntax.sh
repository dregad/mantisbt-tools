#!/bin/bash
#------------------------------------------------------------------------------
#
# check-syntax.sh
#
# This script will perform a global syntax-check (lint) on all the files in
# the GIT repository
#
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# Parameters (edit variables as appropriate)
#

# Space-delimited list of PHP files to check
#FILE_SPEC_PHP='*.php strings_*.txt'
FILE_SPEC_PHP='adm*.php strings_en*.txt'


#------------------------------------------------------------------------------
# Initialization
#

echo "Perform global Syntax Check (lint) of MantisBT source code"

# Abort if Credits file not found
if [ ! -f 'core.php' ]
then
	echo "ERROR: '$PWD' does not appear to be the MantisBT root"
	exit 1
fi

# Temp file for error output
TMPFILE=$(mktemp)
trap "rm -f $TMPFILE" EXIT ERR TERM INT HUP

# Disable globbing
[[ $- = *f* ]]; BAK_F=$?
set -f

# Build find expression for file spec
for spec in $FILE_SPEC_PHP
do
	FILE_LIST_PHP="$FILE_LIST_PHP -name $spec -o "
done
# Use a bash array, needed for find command
FILE_LIST_PHP=( ${FILE_LIST_PHP%% -o } )

# Reset globbing to previous state if needed
(( $BAK_F )) && set +f



#------------------------------	------------------------------------------------
# Main
#

echo This may take a while...

# Get the list of files, and check syntax with php -l
# Suppress output, store errors in temp file for error handling later
find . \( "${FILE_LIST_PHP[@]}" \) -print0 |
	xargs -0 -n 1 -I file sh -c "php -l file >/dev/null || true" 2>&1 |
	tee $TMPFILE

# Error handling
err_count=$(wc -l $TMPFILE |cut -d" " -f1)
if [ $err_count -gt 0 ]
then
	echo "ERROR: some files failed the syntax check"
	exit 1
fi

echo "Done"
