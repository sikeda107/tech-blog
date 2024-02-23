#!/usr/bin/env bash
set -eux

GOOGLE_CLOUD_PROJECT=${PROJECT_ID:-$(gcloud config list --format 'get(core.project)')}
QUERY_BUILD=$(gcloud builds describe "$CURRENT_BUILD_ID" --project="$GOOGLE_CLOUD_PROJECT" --format="csv[no-heading](createTime, buildTriggerId)")
IFS="," read -r BUILD_CREATE_TIME BUILD_TRIGGER_ID <<<"$QUERY_BUILD"

FILTERS="id!=$CURRENT_BUILD_ID AND createTime<$BUILD_CREATE_TIME AND buildTriggerId=$BUILD_TRIGGER_ID"
echo "Waiting for all builds to finish $FILTERS"
while
  BUILDS_COUNT=$(gcloud builds list --ongoing --filter="$FILTERS" --format="value(id)" | wc -l)
  (( BUILDS_COUNT >= 1 ))
do
  echo "Current number of ongoing builds: $BUILDS_COUNT. Please wait a moment..."
  sleep 5
done
