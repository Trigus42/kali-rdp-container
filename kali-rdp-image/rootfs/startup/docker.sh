#!/usr/bin/env bash

if [[ ${DIND_ENABLE} == 'true' ]]
then
	dockerd --host=unix:///var/run/docker.sock --storage-driver=fuse-overlayfs
else
    echo "DIND_ENABLE is not set to 'true'. Skipping Docker daemon startup."
fi

exit 0