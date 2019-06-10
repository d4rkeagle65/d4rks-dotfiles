mkdir /srv/backups
mkdir /srv/backups/stagingdir
rsync -aAXv --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"} / /srv/backups/stagingdir
cd /srv/backups/stagingdir
tar -cvpzf backup.tar.gz --exclude=./backup.tar.gz ./
cd ../
hostname=`hostname`
timestamp=`date -Is`
filename="sysBackup-${hostname}-${timestamp}.tar.gz"
mv stargingdir/backup.tar.gz ./$filename
rm -Rf /srv/backups/stagingdir/*
