echo "Backing up mantisbt.org"

echo "Updating MantisBT database dump"
/usr/bin/mysqldump bugs --host=localhost --user=bugs --password=XXXX > /srv/db_backups/bugs.sql

echo "Updating MantisBT demo database dump"
/usr/bin/mysqldump demo --host=localhost --user=demo --password=XXXX > /srv/db_backups/bugs_demo.sql

echo "Updating phpBB database dump"
/usr/bin/mysqldump forums --host=localhost --user=forums --password=XXXX > /srv/db_backups/forums.sql

echo "Updating wordpress blog database dump"
/usr/bin/mysqldump blog --host=localhost --user=blog --password=XXXX > /srv/db_backups/blog.sql

/usr/local/bin/tarsnap -c -f mantisbt_org_`date +"%F-%H-%M"` --keyfile /root/tarsnap.key --exclude /srv/www/wiki/data/cache --cachedir /var/cache/tarsnap/ /srv/ /home/
