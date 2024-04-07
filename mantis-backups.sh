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
DATABASES="bugs forums blog"

# Target directory for DB dumps
DUMPS_DIR=/srv/backups/db

# Path to MySQL db dump tool
# NOTE: we assume that the user running the script has setup MySQL credentials
# in .my.cnf file's [client] section
MYSQLDUMP=/usr/bin/mysqldump

# Log file - set to /dev/null for no log
LOGFILE=/var/log/$(basename $0 .sh).log


#------------------------------------------------------------------------------
# Helper functions
#

function log() {
	echo "$(date +'%F %T') $*" |tee -a "$LOGFILE"
}


#------------------------------------------------------------------------------
# Main
#

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
	$MYSQLDUMP $DB 2>&1 >$DUMPS_DIR/$DB.sql |tee -a "$LOGFILE"
done

# Backup to Tarsnap
log "Running Tarsnap"
tarsnap -c -f mantisbt_org_`date +"%F-%H-%M"` --exclude /srv/www/wiki/data/cache --exclude /srv/mysql --cachedir /var/cache/tarsnap/ /srv/ /home/ 2>&1 |tee -a "$LOGFILE"

# Delete old backups
# Keeping daily for 30 days, then monthly for a year and yearly for 5 years
log "Removing old backups"
tarsnapper --target "mantisbt_org_\$date" --deltas 1d 30d 360d 1800d --dateformat "%Y-%m-%d-%H-%M" - expire 2>>"$LOGFILE"

# All done
log "Backup complete"
echo "Review logfile in $LOGFILE"

