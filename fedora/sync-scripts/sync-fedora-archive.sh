#!/bin/sh

#RSYNC_FEDORA_HOST="resource.cse.iitk.ac.in"
#Changed the mirror to mirrors1.kernel.org from mirrors4.kernel.org due to connection problem -- edited by rachitag
#RSYNC_FEDORA_HOST="archive.kernel.org"
#rsync://ftp-stud.hs-esslingen.de/fedora-archive
RSYNC_FEDORA_HOST="ftp-stud.hs-esslingen.de"
REMOTE_FEDORA_BASE="fedora-archive/fedora/linux"

FEDORA_LOCAL_HOME="/mirror-root/mirrors/fedora-archive"

#log file
SYNC_LOG="/home/fedora/sync-scripts/fedora-archive-sync.log"


#export RSYNC_CONNECT_PROG="ssh $MIDDLE_USER@$MIDDLE_MACHINE nc $RSYNC_FEDORA_HOST 873"

MAILTO=""

LOCK="/home/fedora/sync-scripts/Fedora-Archive-Archive-Update-in-Progress"

FEDORA_EXCLUDE=" \
		--exclude core/   \
		--exclude development/  \
		--exclude extras/  \
		\
		--exclude test/  \
		--exclude testing/  \
		--exclude source/  \
		--exclude debug/  \
		--exclude Live/ \
		--exclude iso/ \
		\
		--exclude ppc*/  \
		--exclude ppc64*/  \
		--exclude SRPMS*/  \
		\
		\
		--exclude 1/   \
		--exclude 2/   \
		--exclude 3/   \
		--exclude 4/   \
		--exclude 5/   \
		\
         "


##############################################################################################
# Check the lock

if [ -e $LOCK ]; then
	for x in $MAILTO ; do
	   echo "" | mail -s "fedora archive repo sync SKIPPED! <EOM>" $x
	done
	exit 1
fi

touch $LOCK
echo "" > $SYNC_LOG


##############################################################################################
# start syncing

echo -e "\n\n\n>>> Fedora " `date` >> $SYNC_LOG

#ssh -fN -L $LPORT:$RSYNC_FEDORA_HOST:873 $MIDDLE_USER@$MIDDLE_MACHINE >> $SYNC_LOG 2>&1

echo -e "rsync -avH  --no-motd  \
	--timeout=300 \
	--delay-updates  \
	$FEDORA_EXCLUDE  \
	$RSYNC_FEDORA_HOST::$REMOTE_FEDORA_BASE/   $FEDORA_LOCAL_HOME/  >> $SYNC_LOG 2>&1"


#echo -e "rsync -avH  --no-motd  \
#	--timeout=300 \
#	--delay-updates --delete-after --delete-excluded  \
#	$FEDORA_EXCLUDE  \
#	$RSYNC_FEDORA_HOST::$REMOTE_FEDORA_BASE/   $FEDORA_LOCAL_HOME/  >> $SYNC_LOG 2>&1"
#
rsync -avH  --no-motd  \
	--timeout=300 \
	--delay-updates  \
	$FEDORA_EXCLUDE  \
	$RSYNC_FEDORA_HOST::$REMOTE_FEDORA_BASE/   $FEDORA_LOCAL_HOME/  >> $SYNC_LOG 2>&1


#rsync -avH  --no-motd  \
#	--timeout=300 \
#	--delay-updates --delete-after --delete-excluded  \
#	$FEDORA_EXCLUDE  \
#	$RSYNC_FEDORA_HOST::$REMOTE_FEDORA_BASE/   $FEDORA_LOCAL_HOME/  >> $SYNC_LOG 2>&1
#
if [ $? -ne 0 ] ; then
	echo "   !!! ERROR in FEDORA !!!" >> $SYNC_LOG
else
	python report_fedora_archive_mirror
fi

sleep 5


#pkill -f $LPORT:

##############################################################################################

echo -e "\n\n\n>>> "`date`" Sync Complete." >> $SYNC_LOG

for x in $MAILTO ; do
   mail -s "fedora archive repo synced" $x < $SYNC_LOG
done

rm -f $LOCK
