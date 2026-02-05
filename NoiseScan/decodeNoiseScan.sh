#! /bin/bash

export INFOLOGGER_MODE=stdout
export SCRIPTDIR=$(readlink -f $(dirname $0))
echo "SCRIPTDIR: ${SCRIPTDIR}"

export XRD_REQUESTTIMEOUT=1200

pull_ccdb_path="http://localhost:8888"
export ALL_EXTRA_CONFIG="$ALL_EXTRA_CONFIG;NameConf.mCCDBServer=${pull_ccdb_path};"

ARGS_ALL="--session default --shm-segment-size 16000000000"

WORKFLOW="o2-raw-file-reader-workflow ${ARGS_ALL} --nocheck-missing-stop --nocheck-starts-with-tf --nocheck-packet-increment --nocheck-hbf-jump --nocheck-hbf-per-tf --detect-tf0 --nocheck-tf-start-mismatch --input-conf readout.cfg | "
WORKFLOW+="o2-itsmft-stf-decoder-workflow ${ARGS_ALL} --runmft --digits --no-clusters --no-cluster-patterns --ignore-dist-stf --ignore-noise-map --condition-remap file://./TestCCDB=GLO/Config/GRPECS,MFT/Config/AlpideParam,MFT/Calib/NoiseMap,MFT/Calib/NoiseMapSingle,CTP/Calib/OrbitReset --condition-backend ${pull_ccdb_path} | "
WORKFLOW+="o2-calibration-mft-calib-workflow ${ARGS_ALL} --useDigits --prob-threshold 1e-5 --send-to-server CCDB  --path-CCDB \"/MFT/Calib/NoiseMap\" --path-CCDB-single \"/MFT/Calib/NoiseMapSingle\" --condition-backend ${pull_ccdb_path} --condition-remap file://./TestCCDB=MFT/Calib/NoiseMap,MFT/Calib/NoiseMapSingle --configKeyValues \"NameConf.mCCDBServer=http://localhost:8888\" | "
WORKFLOW+="o2-calibration-ccdb-populator-workflow ${ARGS_ALL} --ccdb-path=${pull_ccdb_path} | "
WORKFLOW+="o2-dpl-run ${ARGS_ALL} --batch --run"

echo $WORKFLOW > workflow.txt
eval $WORKFLOW
