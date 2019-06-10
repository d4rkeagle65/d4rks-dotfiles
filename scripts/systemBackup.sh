$backupsDir=/srv/backups
$backupsStagingDir=${backupsDir}/stagingdir

hostname=`hostname`
timestamp=`date -Is`
filename="sysBackup-${hostname}-${timestamp}.tar.gz"

mkdir -p $backupsStagingDir
rsync -aAXv --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found","$backupsStagingDir"} / $backupsStagingDir
tar -cvpzf ${$filename}.tar.gz --exclude="${backupsDir}/${filename}.tar.gz" $backupsStagingDir
rm -Rf $backupsStagingDir
