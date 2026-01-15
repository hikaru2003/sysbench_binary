#!/bin/bash
# INSERT_YOUR_CODE
SERVER_NAME="c220g5-120116.wisc.cloudlab.us"
USER_NAME="Morisaki"
REMOTE_PATH="/users/${USER_NAME}/sysbench_binary"

RESULT_PATH_PREFIX="${SERVER_NAME%%-*}"
RESULT_PATH="result/${RESULT_PATH_PREFIX}"
mkdir -p "${RESULT_PATH}"
scp "${USER_NAME}@${SERVER_NAME}:${REMOTE_PATH}/power_log_spin_busy.csv" "${RESULT_PATH}"
scp "${USER_NAME}@${SERVER_NAME}:${REMOTE_PATH}/power_log_spin_pause.csv" "${RESULT_PATH}"
scp "${USER_NAME}@${SERVER_NAME}:${REMOTE_PATH}/power_log_spin_busy_watts.csv" "${RESULT_PATH}"
scp "${USER_NAME}@${SERVER_NAME}:${REMOTE_PATH}/power_log_spin_pause_watts.csv" "${RESULT_PATH}"