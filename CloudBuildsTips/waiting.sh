#!/usr/bin/env bash
# set -euxo pipefail
set -euo pipefail

GOOGLE_CLOUD_PROJECT=${PROJECT_ID:-$(gcloud config list --format 'get(core.project)')}
QUERY_BUILD=$(gcloud builds describe "$CURRENT_BUILD_ID" --project="$GOOGLE_CLOUD_PROJECT" --format="csv[no-heading](createTime, buildTriggerId)")
IFS="," read -r BUILD_CREATE_TIME BUILD_TRIGGER_ID <<<"$QUERY_BUILD"

FILTERS="id!=$CURRENT_BUILD_ID AND createTime<$BUILD_CREATE_TIME AND buildTriggerId=$BUILD_TRIGGER_ID"
echo "Waiting for all builds to finish $FILTERS"
INTERVALS=${INTERVALS:-5}
while
  BUILDS_COUNT=$(gcloud builds list --ongoing --filter="$FILTERS" --format="value(id)" | wc -l)
  (( BUILDS_COUNT >= 1 ))
do
  echo "Current number of ongoing builds: $BUILDS_COUNT. Please wait a moment... Interval: $INTERVALS seconds."
  sleep $INTERVALS
done
