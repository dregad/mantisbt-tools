#!/bin/bash
#------------------------------------------------------------------------------
#
# backup.sh
#
# This script is intended to be scheduled for daily execution in cron, and
# will first dump the specified MySQL databases, then backup the system to
# Tarsnap.
#
#------------------------------------------------------------------------------

# Space-separated list of databases to backup
DATABASES="bugtracker adodb"

# Target directory for DB dumps
DUMPS_DIR=/tmp/backups

# MySQL db dump tool
# NOTE: we assume that the user running the script has setup MySQL credentials
# in .my.cnf file's [client] section
MYSQLDUMP=mysqldump

# Log file - set to /dev/null for no log
LOGFILE=/tmp/backups/$(basename $0 .sh).log

# Date format for database dump files
DATE_FORMAT="%FT%T"

# Program to use to compress database dump files (gzip or bzip2)
# Leave blank for no compression
COMPRESS=bzip2

# Backup rotation strategy script
GFS_SCRIPT=$(dirname $0)/gfs.py/gfs.py


#------------------------------------------------------------------------------
# Helper functions
#

function log() {
	echo "$(date +'%F %T') $*" |tee -a "$LOGFILE"
}

function abort() {
  log "Aborting"
  exit 1
}


#------------------------------------------------------------------------------
# Main
#

# Error handling
set -o pipefail
trap abort ERR

# Start logging
cat <<-EOF >>"$LOGFILE"
	------------------------------------------------------------------------
EOF
log "Starting mantisbt.org server backup"

if [ ! -d $DUMPS_DIR ]
then
	mkdir -p $DUMPS_DIR
fi

# Dumping databases
for DB in $DATABASES
do
	log "Dumping database '$DB'"
	DUMP_FILENAME="$DUMPS_DIR/${DB}_$(date +"$DATE_FORMAT").sql"
	$MYSQLDUMP $DB 2>&1 >"$DUMP_FILENAME" |tee -a "$LOGFILE"
	if [ -n "$COMPRESS" ]
	then
		log "Compressing dump '$(basename "$DUMP_FILENAME")' with $COMPRESS"
		$COMPRESS "$DUMP_FILENAME" 2>&1 |tee -a "$LOGFILE"
	fi
done

# Delete old backups
# Grandfather-father-son strategy - keep 7 daily, 4 weekly, 12 monthly,
# Keeping daily for 30 days, then monthly for a year and yearly for 5 years
log "Removing old backups"


# All done
log "Backup complete"
echo "Review logfile in $LOGFILE"
