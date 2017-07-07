#!/bin/bash
#
# The script to sync a local mirror of the Arch Linux repositories and ISOs
#
# Copyright (C) 2007 Woody Gilk <woody@archlinux.org>
# Modifications by Dale Blount <dale@archlinux.org>
# and Roman Kyrylych <roman@archlinux.org>
# Licensed under the GNU GPL (version 2)

# Filesystem locations for the sync operations

SYNC_HOME="/mirror-root/mirrors/archlinux"
SYNC_LOGS="/home/archlinux/sync-scripts/log"

SYNC_FILES="$SYNC_HOME"
SYNC_LOCK="$SYNC_LOGS/mirrorsync.lck"

SYNC_TIMEOUT=600 # Time out for sync operation in secs
# Select which repositories to sync
# Valid options are: core, extra, unstable, testing, community, iso
# Leave empty to sync a complete mirror
# SYNC_REPO=(core extra unstable testing community iso)
# SYNC_REPO=(core extra community testing iso)

# Set the rsync server to use
# Only official public mirrors are allowed to use rsync.archlinux.org
# SYNC_SERVER=rsync.archlinux.org::ftp



# Trier 1 mirrors are


#SYNC_SERVER=rsync://mirrors.kernel.org/archlinux/
SYNC_SERVER=rsync://mirrors.lug.mtu.edu/archlinux/
# SYNC_SERVER="rsync://mirror.aarnet.edu.au/archlinux/"
# SYNC_SERVER="rsync://ftp5.gwdg.de/pub/linux/archlinux/"
# SYNC_SERVER="rsync://mirrors.uk2.net/archlinux/"
#SYNC_SERVER="rsync://ftp5.gwdg.de/pub/linux/archlinux/"
#SYNC_SERVER="rsync://ftp.tku.edu.tw/archlinux/"
# SYNC_SERVER="rsync.las.ic.unicamp.br/pub/archlinux/"

# Set the format of the log file name
# This example will output something like this: sync_20070201-8.log

LOG_FILE="pkgsync_$(date +%Y.%m.%d-%H).log"


#LOG_FILE="arch-mirror-sync.log"
#mail will be sent to the following

MAILTO=""

# if a sync is going on, inform and skip

if [ -e $SYNC_LOCK ] ; then
	for x in $MAILTO ; do
		echo "" | mail -s "archlinux archive sync SKIPPED!! <EOM>" $x
	done
	exit 1
fi

touch "$SYNC_LOCK"

#export RSYNC_CONNECT_PROG="ssh $MIDDLE_USER@$MIDDLE_MACHINE nc $REMOTE_MACHINE 873 "
#ssh -fN -L $LPORT:$REMOTE_MACHINE:873 $MIDDLE_USER@$MIDDLE_MACHINE

################################################################################################

# Do not edit the following lines, they protect the sync from running more than
# one instance at a time

if [ ! -d $SYNC_HOME ]; then
  echo "$SYNC_HOME does not exist, please create it, then run this script again."
  exit 1
fi

# End of non-editable lines
# Create the log file and insert a timestamp

touch "$SYNC_LOGS/$LOG_FILE"
echo "" > "$SYNC_LOGS/$LOG_FILE"
echo "=============================================" >> "$SYNC_LOGS/$LOG_FILE"
echo ">> Starting sync on $(date --rfc-3339=seconds) from $SYNC_SERVER" >> "$SYNC_LOGS/$LOG_FILE"
echo ">> ---" >> "$SYNC_LOGS/$LOG_FILE"

if [ -z $SYNC_REPO ]; then
  # Sync a complete mirror
  rsync --timeout="$SYNC_TIMEOUT" -avl\
        --safe-links\
        --delete-after\
        --delay-updates \
       $SYNC_SERVER/ "$SYNC_FILES" >> "$SYNC_LOGS/$LOG_FILE" 2>&1
else
  # Sync each of the repositories set in $SYNC_REPO
  for repo in ${SYNC_REPO[@]}; do
    repo=$(echo $repo | tr [:upper:] [:lower:])
    echo -e "\n\n\n>> Syncing $repo to $SYNC_FILES/$repo" >> "$SYNC_LOGS/$LOG_FILE"

    # If you only want to mirror i686 packages, you can add
    # " --exclude=os/x86_64" after "--delete-after"
    #
    # If you only want to mirror x86_64 packages, use "--exclude=os/i686"
    # If you want both i686 and x86_64, leave the following line as it is
    #
    rsync --timeout="$SYNC_TIMEOUT" \
          -avl \
	  --safe-links \
	  --delete-after \
          --delay-updates \
          $SYNC_SERVER/$repo\
          "$SYNC_FILES" >> "$SYNC_LOGS/$LOG_FILE" 2>&1

	if [ $? -ne 0 ] ; then
		echo "  !!! Error in "$repo" !!!" >> "$SYNC_LOGS/$LOG_FILE"
	fi

    # Create $repo.lastsync file with timestamp like "2007-05-02 03:41:08+03:00"
    # which may be useful for users to know when the repository was last updated

    date --rfc-3339=seconds > "$SYNC_FILES/$repo.lastsync"

    # Sleep 5 seconds after each repository to avoid too many concurrent connections
    # to rsync server if the TCP connection does not close in a timely manner
    sleep 5
  done
fi

# Insert another timestamp and close the log file
echo -e "\n\n>> ---" >> "$SYNC_LOGS/$LOG_FILE"
echo ">> Finished sync on $(date --rfc-3339=seconds)" >> "$SYNC_LOGS/$LOG_FILE"
echo "=============================================" >> "$SYNC_LOGS/$LOG_FILE"
echo "" >> "$SYNC_LOGS/$LOG_FILE"


# mail the log file
for x in $MAILTO ; do
    mail -s "archlinux archive synced" $x < "$SYNC_LOGS/$LOG_FILE"
done

#pkill -f $LPORT:
# Remove the lock file and exit
rm -f "$SYNC_LOCK"
exit 0
