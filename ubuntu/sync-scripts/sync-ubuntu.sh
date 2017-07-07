#! /bin/sh
# set -e

# This script originates from http://www.debian.org/mirror/anonftpsync

# CVS: cvs.debian.org:/cvs/webwml - webwml/english/mirror/anonftpsync
# Version: $Id: anonftpsync,v 1.43 2008-06-15 18:16:04 spaillar Exp $ 

# Note: You MUST have rsync 2.6.4 or newer, which is available in sarge
# and all newer Debian releases, or at http://rsync.samba.org/

# Don't forget:
# chmod u+x anonftpsync

# Set the variables below to fit your site. You can then use cron to have
# this script run daily to automatically update your copy of the archive.

# TO is the destination for the base of the Debian mirror directory
# (the dir that holds dists/ and ls-lR).
# (mandatory)

TO="/mirror-root/mirrors/ubuntu"

# RSYNC_HOST="rsync.oss.eznetsols.org"
# RSYNC_DIR="ftp/linux/ubuntu"

# RSYNC_HOST="ftp.heanet.ie"
# RSYNC_DIR="ubuntu"

# RSYNC_HOST="ubuntu.mirror.tudos.de"
# RSYNC_DIR="ubuntu"

# RSYNC_HOST="ftp.acc.umu.se"
# RSYNC_DIR="ubuntu"

# RSYNC_HOST="ubuntu.mirror.tudos.de"
# RSYNC_DIR="ubuntu"

#RSYNC_HOST="mirrors.neterra.net"
#RSYNC_DIR="ubuntu"

#tgandhi: Changed to this since mirrors.neterra.net is not responding since past couple of days.

RSYNC_HOST="ftp.icm.edu.pl"
RSYNC_DIR="pub/Linux/ubuntu"

#RSYNC_HOST="ftp.halifax.rwth-aachen.de"
#RSYNC_DIR="ubuntu"

# LOGDIR is the directory where the logs will be written to
# (mandatory)

LOGDIR=/home/ubuntu/sync-scripts

# ARCH_EXCLUDE can be used to exclude a complete architecture from
# mirrorring. Please use as space seperated list.
# Possible values are:
# alpha, amd64, arm, armel, hppa, hurd-i386, i386, ia64, m68k, mipsel, mips, powerpc, s390, sh and sparc
#
# There is one special value: source
# This is not an architecture but will exclude all source code in /pool
#
# eg.
# ARCH_EXCLUDE="alpha amd64 arm armel hppa hurd-i386 ia64 m68k mipsel mips s390 sparc"
# 
# With a blank ARCH_EXCLUDE you will mirror all available architectures
# (optional)

ARCH_EXCLUDE="alpha  arm  armel  hppa  hurd-i386   ia64  m68k  mipsel  mips  powerpc  s390  sh and sparc "
### RP: If you want to exclude 'source', add that to the above line. 


# EXCLUDE is a list of parameters listing patterns that rsync will exclude, in
# addition to the architectures excluded by ARCH_EXCLUDE.
#
# Use ARCH_EXCLUDE to exclude specific architectures or all sources
#
# --exclude stable, testing, unstable options DON'T remove the packages of
# the given distribution. If you want do so, use debmirror instead.
#
# The following example would exclude mostly everything:
#EXCLUDE="\
#  --exclude stable/ --exclude testing/ --exclude unstable/ \
#  --exclude source/ \
#  --exclude *.orig.tar.gz --exclude *.diff.gz --exclude *.dsc \
#  --exclude /contrib/ --exclude /non-free/ \
# "

# With a blank EXCLUDE you will mirror the entire archive, except the
# architectures excluded by ARCH_EXCLUDE.
# (optional)

EXCLUDE=

# MAILTO is the address to send logfiles to;
# if it is not defined, no mail will be sent
# (optional)

MAILTO=""


# LOCK_TIMEOUT is a timeout in minutes.  Defaults to 360 (6 hours).
# This program creates a lock to ensure that only one copy
# of it is mirroring any one archive at any one time.
# Locks held for longer than the timeout are broken, unless
# a running rsync process appears to be connected to $RSYNC_HOST.

LOCK_TIMEOUT=360

# You may establish the connection via a web proxy by setting the environment
# variable RSYNC_PROXY to a hostname:port pair pointing to your web proxy.  Note
# that your web proxyâ€™s configuration must support proxy connections to port 873.
#
# RSYNC_PROXY="IP:PORT"
# export RSYNC_PROXY=$RSYNC_PROXY

# There should be no need to edit anything below this point, unless there
# are problems.

#-----------------------------------------------------------------------------#

# If you are accessing a rsync server/module which is password-protected,
# uncomment the following lines (and edit the other file).

# . ftpsync.conf
# export RSYNC_PASSWORD
# RSYNC_HOST=$RSYNC_USER@$RSYNC_HOST

#-----------------------------------------------------------------------------#

# Check for some environment variables
if [ -z "$TO" ] || [ -z "$RSYNC_HOST" ] || [ -z "$RSYNC_DIR" ] || [ -z "$LOGDIR" ]; then
	echo "One of the following variables seems to be empty:"
	echo "TO, RSYNC_HOST, RSYNC_DIR or LOGDIR"
	exit 2
fi
# Note: on some non-Debian systems, hostname doesn't accept -f option.
# If that's the case on your system, make sure hostname prints the full
# hostname, and remove the -f option. If there's no hostname command,
# explicitly replace `hostname -f` with the hostname.

HOSTNAME=`hostname -f`

# The hostname must match the "Site" field written in the list of mirrors.
# If hostname doesn't returns the correct value, fill and uncomment below 
# HOSTNAME=mirror.domain.tld
 
LOCK="${TO}/Archive-Update-in-Progress-${HOSTNAME}"

# The temp directory used by rsync --delay-updates is not
# world-readable remotely. It must be excluded to avoid errors. 
TMP_EXCLUDE=" --exclude=.~tmp~/ "

# Exclude architectures defined in $ARCH_EXCLUDE
for ARCH in $ARCH_EXCLUDE; do
	if [ "$ARCH" = "source" ]; then
		SOURCE_EXCLUDE="--exclude=source/ --exclude=*.tar.gz --exclude=*.diff.gz --exclude=*.dsc "
	else
		EXCLUDE=$EXCLUDE" --exclude=binary-$ARCH/ --exclude=disks-$ARCH/ --exclude=installer-$ARCH/ --exclude=Contents-$ARCH.gz --exclude=Contents-$ARCH.diff/ --exclude=arch-$ARCH.files --exclude=arch-$ARCH.list.gz --exclude=*_$ARCH.deb --exclude=*_$ARCH.udeb --exclude=*_$ARCH.changes "
	fi
done

# Logfile
LOGFILE=$LOGDIR/ubuntu-mirror-main.log

#echo $SOURCE_EXCLUDE >> $LOGFILE
#echo "" >> $LOGFILE
#echo $TMP_EXCLUDE >> $LOGFILE
#echo "" >> $LOGFILE
#echo $EXCLUDE >> $LOGFILE

# optionally, use the rsync module name in the log file name:
# LOGFILE=$LOGDIR/$(echo $RSYNC_DIR | tr / _)-mirror.log
# LOGFILE=$LOGDIR/${RSYNC_DIR/\//_}-mirror.log

# Get in the right directory and set the umask to be group writable
# 
# cd $HOME
# umask 002

# If we are running mirror script for the first time, create the
# destination directory and the trace directory underneath it
if [ ! -d "${TO}/project/trace/" ]; then
  mkdir -p ${TO}/project/trace
fi

#set +e

#check the lock file

if [ -e $LOCK ] ; then
	for x in $MAILTO ; do 
		echo "" | mail -s "Ubuntu archive sync SKIPPED!!! <EOM>" $x
		sleep 1
	done
	exit 1
fi

touch $LOCK
echo "" > $LOGFILE
date >> $LOGFILE

# First sync /pool

#export RSYNC_CONNECT_PROG="ssh $MIDDLE_USER@$MIDDLE_MACHINE nc $RSYNC_HOST 873"
#ssh -fN -L $LPORT:$RSYNC_HOST:873 $MIDDLE_USER@$MIDDLE_MACHINE



# check for the sanity of mirror
testPath=$RSYNC_DIR/pool/main/j
fieldID=4
jSize=`rsync --timeout=120 --list-only -av $RSYNC_HOST::$testPath 2>/dev/null | tail -n 1 | awk -v fieldID=$fieldID '{print $(fieldID)}' `
if [ $jSize -eq 0 ]; then
	echo "" >> $LOGFILE
	echo "" >> $LOGFILE
	echo "" >> $LOGFILE
	echo "Mirror not sane. ABORT." >> $LOGFILE
	for x in $MAILTO ; do 
		mail -s "Ubuntu main archive PROBLEM!!!" $x < $LOGFILE
	done
#	pkill -f $LPORT:
	rm -f $LOCK
	exit 1
fi

sleep 5

# Sync the pool first


rsync -av  --timeout=300 --delay-updates $TMP_EXCLUDE $EXCLUDE $SOURCE_EXCLUDE $RSYNC_HOST::$RSYNC_DIR/pool/ $TO/pool >> $LOGFILE 2>&1

result=$?

echo "" >> $LOGFILE
echo "" >> $LOGFILE
echo "" >> $LOGFILE
echo "" >> $LOGFILE
echo "" >> $LOGFILE
date >> $LOGFILE

sleep 5

if [ "$result" = 0 ]; then
	touch $LOCK
	# Now sync the remaining stuff
	echo "Sync Ubuntu...." >> $LOGFILE
	echo "" >> $LOGFILE
	
	rsync -av --timeout=300 --delay-updates --delete-after --delete-excluded \
		$TMP_EXCLUDE $EXCLUDE $SOURCE_EXCLUDE \
		$RSYNC_HOST::$RSYNC_DIR/ $TO >> $LOGFILE 2>&1

	sleep 5

	echo "Sync Complete." >> $LOGFILE

	LANG=C date -u > "${TO}/project/trace/${HOSTNAME}"
else
	echo "ERROR: Help, something weird happened" | tee -a $LOGFILE
	echo "mirroring /pool exited with exitcode" $result | tee -a $LOGFILE
fi

for x in $MAILTO ; do 
	mail -s "Ubuntu archive synced" $x < $LOGFILE
done

#pkill -f $LPORT:
rm -f $LOCK
