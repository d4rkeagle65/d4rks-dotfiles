backupsDir="/srv/backups"
backupsStagingDir="${backupsDir}/stagingdir"
owncloudDir="/home/dhardin/.ownCloud"
gitDir="/srv/git"

hostname=`hostname`
timestamp=`date -Is`
filename="sysBackup-${hostname}-${timestamp}.tar.gz"

mkdir -p $backupsStagingDir
rsync -aAXv --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found",$backupsDir,$owncloudDir,$gitDir} / $backupsStagingDir
tar -cvpzf "${backupsDir}/${filename}.tar.gz" --exclude="${backupsDir}/${filename}.tar.gz" $backupsStagingDir
rm -Rf "${backupsStagingDir}"
