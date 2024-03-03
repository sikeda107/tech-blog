#!/usr/bin/env bash
# set -euxo pipefail
set -euo pipefail

SOURCE_INSTANCE="main"
TARGET_INSTANCE="main-clone"
BUCKET_NAME="gs://${PROJECT_ID}_export-sql"
DATABASE="world"

function clone_instance {
  local COUNT
  COUNT=$(gcloud sql instances list --filter="name=$TARGET_INSTANCE" --format=json | jq 'length')
  if [ "$COUNT" -gt 0 ]; then
    echo "$TARGET_INSTANCE already exists. Deleting it."
    gcloud sql instances delete $TARGET_INSTANCE
  fi
  echo "Cloning Start... Please wait about 10 minutes..."
  gcloud sql instances clone $SOURCE_INSTANCE $TARGET_INSTANCE
  echo "Cloned $SOURCE_INSTANCE to $TARGET_INSTANCE"
}

function export_sql {
  local SERVICE_ACCOUNT
  local FILE_NAME
  local YEAR
  SERVICE_ACCOUNT="$(gcloud sql instances describe $TARGET_INSTANCE --format="json(serviceAccountEmailAddress)" | jq -r '.serviceAccountEmailAddress')"
  gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$SERVICE_ACCOUNT" --role=roles/storage.objectCreator --condition=None
  echo "Added roles/storage.objectCreator to $SERVICE_ACCOUNT"
  FILE_NAME="$(date +"%Y%m%d").sql.gz"
  YEAR=$(date +"%Y")
  gcloud sql export sql $TARGET_INSTANCE "$BUCKET_NAME/$DATABASE/$YEAR/$FILE_NAME" --database=$DATABASE
  echo "Exported $DATABASE from $TARGET_INSTANCE to $BUCKET_NAME/$DATABASE/$YEAR/$FILE_NAME"
}

# コマンドの引数に応じて関数を呼び出す
case "$1" in
clone_instance)
  clone_instance
  ;;
export_sql)
  export_sql
  ;;
*)
  echo "Usage: $0 {clone_instance|export_sql}"
  exit 1
  ;;
esac
