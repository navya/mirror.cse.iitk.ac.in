#!/bin/bash

source ${HOME}/sync/sync-source.conf

DATE="date --rfc-3339=seconds"

[ -d ${LOGDIR} ] || mkdir -p ${LOGDIR}
LASTLOG="${LOGDIR}/sync-source-last.log"
LOG="${LOGDIR}/sync-source-`date +%F`.log"
SKIPLOG="${LOGDIR}/sync-source-skip-`date +%F`.log"
LOCK="${HOME}/sync/sync-source.lock"

unset URGENCY

if [ -f ${LOCK} ] ; then
    echo "Skipped source sync at `${DATE}`" >> ${SKIPLOG} 2>&1
    # Setting urgency here causes false alarms
    URGENCY=""
else
    touch ${LOCK}
    echo "Started sync at `${DATE}`" > ${LASTLOG} 2>&1
    ${RSYNC} ${OPTS} ${SRC} ${DST} >> ${LASTLOG} 2>&1
    [ $? -ne 0 ] && URGENCY="error"
    echo "Finished sync at `${DATE}`" >> ${LASTLOG} 2>&1
    cat ${LASTLOG} >> ${LOG}
    rm -f ${LOCK}
fi

if [ x${URGENCY} != x ]; then
    for x in "${MAILTO[@]} "; do
        mail -s "[${URGENCY:-info}] [mirror][source] Gentoo mirror sync log" ${x} < ${LASTLOG}
    done
fi
