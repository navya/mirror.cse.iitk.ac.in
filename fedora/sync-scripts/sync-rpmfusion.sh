#!/bin/sh

#RSYNC_RPMFUSION_HOST="193.28.235.60"

RSYNC_RPMFUSION_HOST="ftp-stud.hs-esslingen.de"
#This is mirror.karneval.cz --edited by sbjoshi
#Mirror changed due to connection problem with the old server -- edited by rachitag
REMOTE_RPMFUSION_BASE="rpmfusion"

RPMFUSION_LOCAL_HOME="/mirror-root/mirrors/rpmfusion"

#log file
SYNC_LOG="/home/fedora/sync-scripts/rpmfusion-sync.log"

MAILTO=""

LOCK="/home/fedora/sync-scripts/RPMFusion-Archive-Update-in-Progress"

#   Removed --exclude testing/   since fedora 23 links to it.
#           --exclude development/  \

RPMFUSION_EXCLUDE=" \
		--exclude el/  \
		\
		--exclude ppc/  \
		--exclude ppc64/ \
		--exclude SRPMS/  \
		\
		--exclude 1/  \
		--exclude 2/  \
		--exclude 3/  \
		--exclude 4/  \
		--exclude 5/  \
		--exclude 6/  \
		--exclude 7/  \
		--exclude 8/  \
		\
		--exclude debug/  \
		"

##############################################################################################
# Check the lock

if [ -e $LOCK ]; then
	for x in $MAILTO ; do
	   echo "" | mail -s "rpmfusion repo sync SKIPPED! <EOM>" $x
	done
	exit 1
fi

touch $LOCK
echo "" > $SYNC_LOG



##############################################################################################
# start syncing

echo -e "\n\n\n>>> RPMFUSION" `date` >> $SYNC_LOG

#ssh -fN -L $LPORT:$RSYNC_RPMFUSION_HOST:873 $MIDDLE_USER@$MIDDLE_MACHINE >> $SYNC_LOG 2>&1

rsync -avH  --no-motd  \
	--timeout=360 \
	--delay-updates --delete-after --delete-excluded  \
	$RPMFUSION_EXCLUDE \
	$RSYNC_RPMFUSION_HOST::$REMOTE_RPMFUSION_BASE/  $RPMFUSION_LOCAL_HOME/ >> $SYNC_LOG 2>&1

if [ $? -ne 0 ] ; then
	echo "   !!! ERROR in RPMFUSION !!!" >> $SYNC_LOG
else
	python report_rpmfusion_mirror
fi

sleep 5
#pkill -f $LPORT:

##############################################################################################
echo -e "\n\n\n>>> "`date`" Sync Complete." >> $SYNC_LOG

for x in $MAILTO ; do
   mail -s "rpmfusion repo synced" $x < $SYNC_LOG
done

rm -f $LOCK
