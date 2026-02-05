#! /bin/bash

export INFOLOGGER_MODE=stdout
export SCRIPTDIR=$(readlink -f $(dirname $0))
echo "SCRIPTDIR: ${SCRIPTDIR}"

export XRD_REQUESTTIMEOUT=1200

pull_ccdb_path="http://ccdb-test.cern.ch:8080"

ARGS_ALL="--session default --shm-segment-size 16000000000"

WORKFLOW="o2-raw-file-reader-workflow ${ARGS_ALL} --nocheck-missing-stop --nocheck-starts-with-tf --nocheck-packet-increment --nocheck-hbf-jump --nocheck-hbf-per-tf --detect-tf0 --input-conf readout.cfg | "
WORKFLOW+="o2-itsmft-stf-decoder-workflow ${ARGS_ALL} --runmft --digits --no-clusters --no-cluster-patterns --ignore-dist-stf --ignore-noise-map --condition-remap file://./TestCCDB=GLO/Config/GRPECS,MFT/Config/AlpideParam,MFT/Calib/NoiseMap --condition-backend ${pull_ccdb_path}| "
WORKFLOW+="o2-itsmft-digit-writer-workflow ${ARGS_ALL} --disable-mc --runmft | "

WORKFLOW+="o2-dpl-run ${ARGS_ALL} --batch --run"
#WORKFLOW+="o2-dpl-run ${ARGS_ALL} --batch --dump"

echo $WORKFLOW > workflow.txt
eval $WORKFLOW
