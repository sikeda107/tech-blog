#!/bin/bash
PROJECT_ID=XXXXXXX
gcloud run deploy server-node --source . \
     --project $PROJECT_ID \
     --region asia-northeast1 \
     --ingress=all \
     --allow-unauthenticated