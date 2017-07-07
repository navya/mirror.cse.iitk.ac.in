#!/bin/bash

source ${HOME}/sync/sync-portage.conf

DATE="date --rfc-3339=seconds"

[ -d ${LOGDIR} ] || mkdir -p ${LOGDIR}
LASTLOG="${LOGDIR}/sync-portage-last.log"
LOG="${LOGDIR}/sync-portage-`date +%F`.log"
SKIPLOG="${LOGDIR}/sync-portage-skip-`date +%F`.log"
LOCK="${HOME}/sync/sync-portage.lock"

unset URGENCY

if [ -f ${LOCK} ] ; then
    echo "Skipped portage sync at `${DATE}`" >> ${SKIPLOG} 2>&1
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
        mail -s "[${URGENCY:-info}] [mirror][portage] Gentoo mirror sync log ${URGENCY}" ${x} < ${LASTLOG}
    done
fi
