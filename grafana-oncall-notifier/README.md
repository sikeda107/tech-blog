# README

```bash
PROJECT_ID='YOUR PROJECT ID'
gcloud config set project $PROJECT_ID

SERVICE_ACCOUNT='pubsub-grafana-oncall-notifier'
SECRET_ID='grafana-webhook-url'
GRAFANA_WEBHOOK_URL='https://oncall-prod-us-central-0.grafana.net/oncall/integrations/v1/webhook/xxxxxxxxxxxxxxxx/'
TRIGGER_TOPIC='grafana-oncall-notifier'
SERVICE='pubsub-grafana-oncall-notifier'

# Cloud Run Functions で使うサービスアカウント
gcloud iam service-accounts create $SERVICE_ACCOUNT

# Webhook URL を格納する Secret Manager
echo -n "$GRAFANA_WEBHOOK_URL" | gcloud secrets create  $SECRET_ID \
    --replication-policy="automatic" \
    --data-file=-

# Alert 通知先の PubSub Topic
gcloud pubsub topics create $TRIGGER_TOPIC

# サービスアカウントから、シークレットに対してアクセス権限を付与
gcloud secrets add-iam-policy-binding $SECRET_ID \
    --member="serviceAccount:${SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role='roles/secretmanager.secretAccessor'

# サービスアカウントから、ログを記録する権限を付与
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role='roles/logging.logWriter'

# Docker レジストリを作成
gcloud artifacts repositories create gcf-artifacts \
    --repository-format=docker \
    --location=asia-northeast1

# Cloud Run Functions のデプロイ
npm run deploy --project=$PROJECT_ID

# PuSub Subscription から Cloud Run Functions へのアクセス権を付与
gcloud run services add-iam-policy-binding $SERVICE \
    --region=asia-northeast1 \
    --member="serviceAccount:${SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role='roles/run.servicesInvoker'

PROJECT_NUMBER=$(gcloud projects list --filter="$(gcloud config get-value project)" --format="value(PROJECT_NUMBER)")

# Alert から PubSub Topic に対してメッセージを送るための権限を付与
gcloud pubsub topics add-iam-policy-binding $TRIGGER_TOPIC \
    --member="serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-monitoring-notification.iam.gserviceaccount.com" \
    --role='roles/pubsub.publisher'

# ログサンプル
gcloud logging write my-test-log "A simple entry Warn"
gcloud logging write my-test-log "A simple entry Critical"

```
