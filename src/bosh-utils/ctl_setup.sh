#!/bin/bash -eu

# Setup env vars and folders for the ctl script
# This helps keep the ctl script as readable
# as possible

# Usage options:
# source /var/vcap/packages/ctl-helpers/ctl_setup.sh myJob [myProcessName ["$ADD_BIN_PATH" ["$ADD_LIB_PATH"]]]

export JOB_NAME="$1"
export PROCESS_NAME="${2:-${JOB_NAME}}"

export PATH="$PATH:${3:-}"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-''}:${4:-}"
export HOME=${HOME:-/home/vcap}
export JOB_DIR="/var/vcap/jobs/$JOB_NAME"
chmod 755 "$JOB_DIR" # to access file via symlink

# Setup log, run and tmp folders
export RUN_DIR="/var/vcap/sys/run/$JOB_NAME"
export LOG_DIR="/var/vcap/sys/log/$JOB_NAME"
export TMP_DIR="/var/vcap/sys/tmp/$JOB_NAME"
export STORE_DIR="/var/vcap/store/$JOB_NAME"

mkdir -p "$LOG_DIR"
exec 1>>"$LOG_DIR/${PROCESS_NAME}.stdout.log"
exec 2> >(tee -a "$LOG_DIR/${PROCESS_NAME}.stderr.log" >&1)

for dir in "$RUN_DIR" "$LOG_DIR" "$TMP_DIR" "$STORE_DIR"
do
  mkdir -p "${dir}"
  chown vcap:vcap "${dir}"
  chmod 775 "${dir}"
done
export TMPDIR="$TMP_DIR"

export CTL_PIDFILE="$RUN_DIR/${PROCESS_NAME}.pid"

# echo "ctl_setup configuration: \$HOME=$HOME, \$JOB_DIR=$JOB_DIR, \$RUN_DIR=$RUN_DIR, \$LOG_DIR=$LOG_DIR, \$TMP_DIR=$TMP_DIR, \$STORE_DIR=$STORE_DIR, \$PATH=$PATH, \$LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
