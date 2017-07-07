#!/bin/sh

#RSYNC_FEDORA_HOST="resource.cse.iitk.ac.in"
#Changed the mirror to mirrors1.kernel.org from mirrors4.kernel.org due to connection problem -- edited by rachitag
#RSYNC_FEDORA_HOST="mirrors.servercentral.net"
#Changed to ftp.linux.cz from mirrors.servercentral.net since the latter was not in sync tier1 mirrors 
#Changed by tgandhi
RSYNC_FEDORA_HOST="ftp.linux.cz"
REMOTE_FEDORA_BASE="pub/linux/fedora/linux"

FEDORA_LOCAL_HOME="/mirror-root/mirrors/fedora/linux"

#log file
SYNC_LOG="/home/fedora/sync-scripts/fedora-sync.log"


#export RSYNC_CONNECT_PROG="ssh $MIDDLE_USER@$MIDDLE_MACHINE nc $RSYNC_FEDORA_HOST 873"

# adarshaj only fixes sync errors, doesnt use fedora personally
MAILTO=""

LOCK="/home/fedora/sync-scripts/Fedora-Archive-Update-in-Progress"

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
		--exclude releases/1/   \
		--exclude releases/2/   \
		--exclude releases/3/   \
		--exclude releases/4/   \
		--exclude releases/5/   \
		--exclude releases/6/   \
		--exclude releases/7/   \
		--exclude releases/8/   \
		\
         "


##############################################################################################
# Check the lock

if [ -e $LOCK ]; then
	for x in $MAILTO ; do
	   echo "" | mail -s "fedora repo sync SKIPPED! <EOM>" $x
	done
	exit 1
fi

touch $LOCK
echo "" > $SYNC_LOG


##############################################################################################
# start syncing

echo -e "\n\n\n>>> Fedora " `date` >> $SYNC_LOG

#ssh -fN -L $LPORT:$RSYNC_FEDORA_HOST:873 $MIDDLE_USER@$MIDDLE_MACHINE >> $SYNC_LOG 2>&1

rsync -avH  --no-motd  \
	--numeric-ids \
	--timeout=300 \
	--delay-updates --delete-after --delete-excluded  \
	$FEDORA_EXCLUDE  \
	$RSYNC_FEDORA_HOST::$REMOTE_FEDORA_BASE/   $FEDORA_LOCAL_HOME/  >> $SYNC_LOG 2>&1

if [ $? -ne 0 ] ; then
	echo "   !!! ERROR in FEDORA !!!" >> $SYNC_LOG
else
	python report_mirror
fi

sleep 5


#pkill -f $LPORT:

##############################################################################################

echo -e "\n\n\n>>> "`date`" Sync Complete." >> $SYNC_LOG

for x in $MAILTO ; do
   mail -s "fedora repo synced" $x < $SYNC_LOG
done

rm -f $LOCK
