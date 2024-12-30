#!/bin/bash

NEEDS_CHOWN=0

if [ ${PGID} -ne 0 ] && [ $(id -g ubuntu) -ne ${PGID} ]; then
  groupmod -g ${PGID} ubuntu
  NEEDS_CHOWN=1
fi
if [ ${PUID} -ne 0 ] && [ $(id -u ubuntu) -ne ${PUID} ]; then
  usermod -g ${PGID} -u ${PUID} ubuntu
  NEEDS_CHOWN=1
fi

if [ ${NEEDS_CHOWN} -eq 1 ]; then
  chown -R ${PUID}:${PGID} /home/ubuntu
fi
