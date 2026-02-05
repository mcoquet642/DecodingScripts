#!/bin/bash

set -euo pipefail

# generating config file for the raw file reader
DEFAULT_FILEPATH="/home/mft/data/data-1.raw"
CFG_FILE="readout.cfg"

# use first argument if provided, otherwise default
INPUT_FILEPATH="${1:-$DEFAULT_FILEPATH}"

cat > "${CFG_FILE}" <<EOF
[input-MFT-0]
dataOrigin = MFT
dataDescription = RAWDATA
readoutCard = CRU
filePath = ${INPUT_FILEPATH}
EOF
echo "Generated ${CFG_FILE} with filePath=${INPUT_FILEPATH}"


export INFOLOGGER_MODE=stdout
export SCRIPTDIR=$(readlink -f "$(dirname "$0")")
export XRD_REQUESTTIMEOUT=1200

# local ccdb adress must be provided
pull_ccdb_path="http://localhost:8888"

ARGS_ALL="--session default --shm-segment-size 16000000000"

# raw file reader, disabling many errors
WORKFLOW="o2-raw-file-reader-workflow ${ARGS_ALL} \
  --nocheck-missing-stop \
  --nocheck-starts-with-tf \
  --nocheck-packet-increment \
  --nocheck-hbf-jump \
  --nocheck-hbf-per-tf \
  --detect-tf0 \
  --nocheck-tf-start-mismatch \
  --input-conf ${CFG_FILE} | "

# the decoder, configured to produce digits, and subscribes to dummy CCDB objects
WORKFLOW+="o2-itsmft-stf-decoder-workflow ${ARGS_ALL} \
  --runmft \
  --digits \
  --no-clusters \
  --no-cluster-patterns \
  --ignore-dist-stf \
  --ignore-noise-map \
  --condition-remap file://./TestCCDB=GLO/Config/GRPECS,MFT/Config/AlpideParam,MFT/Calib/NoiseMap,MFT/Calib/NoiseMapSingle,CTP/Calib/OrbitReset \
  --condition-backend ${pull_ccdb_path} | "

# the noise map builder. produces both nerged and single map objects, based on the previous maps already populated in the local ccdb
WORKFLOW+="o2-calibration-mft-calib-workflow ${ARGS_ALL} \
  --useDigits \
  --prob-threshold 1e-3 \
  --send-to-server CCDB \
  --path-CCDB \"/MFT/Calib/NoiseMap\" \
  --path-CCDB-single \"/MFT/Calib/NoiseMapSingle\" \
  --condition-remap file://./TestCCDB=MFT/Calib/NoiseMap,MFT/Calib/NoiseMapSingle \
  --configKeyValues \"NameConf.mCCDBServer=${pull_ccdb_path}\" | "

# ccdb populator
WORKFLOW+="o2-calibration-ccdb-populator-workflow ${ARGS_ALL} \
  --ccdb-path=${pull_ccdb_path} | "

WORKFLOW+="o2-dpl-run ${ARGS_ALL} --batch --run"

echo "${WORKFLOW}" > workflow.txt
eval "${WORKFLOW}"


