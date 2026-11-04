#!/bin/sh
# Seal fork-CI helper, run as the Travis `after_script` of every leg.
#
# Travis archives job-log parts asynchronously, often many minutes behind the
# job itself, and the seal harness downloads each job's log the moment the
# build finishes. Without this wait the harvested log stops mid-install, before
# any test output. This script keeps the job open until the job's own public
# log (no auth needed on the public fork) already contains the line Travis
# echoed for this very after_script command, i.e. everything before it -
# including the test results - has been archived.
#
# after_script cannot change the build result, and this script always exits 0.

LOG_URL="https://api.travis-ci.com/v3/job/${TRAVIS_JOB_ID}/log.txt"
MARKER="sh test/seal-wait-for-log.sh"
MAX_SECONDS=1800
waited=0

if [ -z "$TRAVIS_JOB_ID" ]; then
	echo "seal-wait-for-log: TRAVIS_JOB_ID not set, nothing to wait for"
	exit 0
fi

while [ "$waited" -lt "$MAX_SECONDS" ]; do
	if curl -sfL "$LOG_URL" -o /tmp/seal-own-log.txt &&
		grep -qF "$MARKER" /tmp/seal-own-log.txt; then
		echo "seal-wait-for-log: job log archived up to after_script (waited ${waited}s)"
		exit 0
	fi
	sleep 20
	waited=$((waited + 20))
done

echo "seal-wait-for-log: gave up after ${MAX_SECONDS}s"
exit 0
