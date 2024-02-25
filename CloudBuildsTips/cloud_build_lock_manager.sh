#!/usr/bin/env bash
# set -euxo pipefail
set -euo pipefail
LOCKFILE_PATH="gs://${PROJECT_ID}_cloudbuild/$TRIGGER_NAME/"
INTERVAL=${INTERVAL:-5}
CREATE_TIME=$(gcloud builds describe "$CURRENT_BUILD_ID" --format="value(createTime)")
CREATE_TIMESTAMP=$(date --date="$CREATE_TIME" +%s)

# ロックファイルを作成する関数
function create_lockfile {
    date >"${CREATE_TIMESTAMP}_${CURRENT_BUILD_ID}.lock"
    gcloud storage cp "${CREATE_TIMESTAMP}_${CURRENT_BUILD_ID}.lock" "${LOCKFILE_PATH}" || echo "ERROR creating lock file"
    echo "Lock file ${CREATE_TIMESTAMP}_${CURRENT_BUILD_ID}.lock has been created"
}
# ロックファイルを削除する関数
function delete_lockfile {
    gcloud storage rm "${LOCKFILE_PATH}${CREATE_TIMESTAMP}_${CURRENT_BUILD_ID}.lock" || echo "ERROR removing lock file"
    echo "Lock file ${CREATE_TIMESTAMP}_${CURRENT_BUILD_ID}.lock has been removed"
}
# 条件に合致するロックファイルの数をカウントする関数
function lock_file_count {
    mapfile -t lock_files < <(gcloud storage ls "$LOCKFILE_PATH" | xargs -I VAR basename VAR .lock)
    local count=0
    for lock_file in "${lock_files[@]}"; do
        # tt = timestamp, bid = build id
        IFS='_' read -r tt bid <<<"$lock_file"
        # shellcheck disable=SC2053
        if [[ $tt -le $CREATE_TIMESTAMP && $bid != $CURRENT_BUILD_ID ]]; then
            ((count++))
        fi
    done
    echo $count
}
# ロックファイルがあれば待機する関数
function wait_build {
    while
        LOCK_COUNT=$(lock_file_count)
        ((LOCK_COUNT >= 1))
    do
        echo "Current number of ongoing builds: $LOCK_COUNT. Please wait a moment... Interval: $INTERVAL seconds."
        sleep "$INTERVAL"
    done
}
# ビルドをキャンセルする関数
function cancel_build {
    mapfile -t lock_files < <(gcloud storage ls "$LOCKFILE_PATH" | xargs -I VAR basename VAR .lock)
    for lock_file in "${lock_files[@]}"; do
        # tt = timestamp, bid = build id
        IFS='_' read -r tt bid <<<"$lock_file"
        # shellcheck disable=SC2053
        if [[ $tt -le $CREATE_TIMESTAMP && $bid != $CURRENT_BUILD_ID ]]; then
            gcloud builds cancel "$bid" >/dev/null || echo "ERROR canceling build $bid"
            echo "Build $bid has been canceled"
            gcloud storage rm "${LOCKFILE_PATH}${lock_file}.lock" || echo "ERROR removing lock file"
            echo "Lock file ${lock_file}.lock has been removed"
        fi
    done
}

# コマンドの引数に応じて関数を呼び出す
case "$1" in
post-process)
    delete_lockfile
    ;;
wait-process)
    create_lockfile
    wait_build
    ;;
cancel-process)
    create_lockfile
    cancel_build
    ;;
*)
    echo "Usage: $0 {post-process|wait-process|cancel-process}"
    exit 1
    ;;
esac
