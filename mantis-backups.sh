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
# Main
#

# Start logging
cat <<-EOF >>$LOGFILE
	------------------------------------------------------------------------
	$(date +"%F %T") Starting mantisbt.org server backup
EOF

if [ ! -d $DUMPS_DIR ]
then
	mkdir -p $DUMPS_DIR
fi
# Dumping databases
for DB in $DATABASES
do
	echo "$(date +'%F %T') Dumping database '$DB'" |tee -a $LOGFILE
	$MYSQLDUMP $DB 2>&1 >$DUMPS_DIR/$DB.sql |tee -a $LOGFILE
done

# Backup to Tarsnap
echo "$(date +'%F %T') Running Tarsnap" |tee -a $LOGFILE
tarsnap -c -f mantisbt_org_`date +"%F-%H-%M"` --exclude /srv/www/wiki/data/cache --exclude /srv/mysql --cachedir /var/cache/tarsnap/ /srv/ /home/ 2>&1 |tee -a $LOGFILE

# Delete old backups
# Keeping daily for 30 days, then monthly for a year and yearly for 5 years
echo "$(date +'%F %T') Removing old backups" |tee -a $LOGFILE
tarsnapper --target "mantisbt_org_\$date" --deltas 1d 30d 360d 1800d --dateformat "%Y-%m-%d-%H-%M" - expire 2>>$LOGFILE

# All done
echo "$(date +'%F %T') Backup complete" |tee -a $LOGFILE
echo "Review logfile in $LOGFILE"

