#!/bin/bash

source ${HOME}/sync/sync-packages.conf

DATE="date --rfc-3339=seconds"

[ -d ${LOGDIR} ] || mkdir -p ${LOGDIR}
LASTLOG="${LOGDIR}/sync-packages-last.log"
LOG="${LOGDIR}/sync-packages-`date +%F`.log"
LOCK="${HOME}/sync/sync-packages.lock"

if [ -f ${LOCK} ] ; then
    echo "Skipped sync at `${DATE}`" > ${LASTLOG} 2>&1
    URGENCY="warn"
else
    touch ${LOCK}
    echo "Started sync at `${DATE}`" > ${LASTLOG} 2>&1
    ${RSYNC} ${OPTS} ${SRC} ${DST} >> ${LASTLOG} 2>&1
    [ $? -ne 0 ] && URGENCY="error"
    echo "Finished sync at `${DATE}`" >> ${LASTLOG} 2>&1
    cat ${LASTLOG} >> ${LOG}
    rm -f ${LOCK}
fi


if [ x${URGENCY} != x -o x${DEBUG} != x0 ]; then
    for x in "${MAILTO[@]} "; do
        mail  -a "From: mirror@cse.iitk.ac.in" -s "[${URGENCY:-info}] [mirror] Linux CentOS packages mirror sync log" ${x} < ${LASTLOG}
    done
fi
