#!/bin/bash
PROJECT_ID=XXXXXXX
gcloud run deploy client-node --source . \
     --project $PROJECT_ID \
     --region asia-northeast1 \
     --set-env-vars=DOMAIN=server-node-XXXXXXX-an.a.run.app \
     --ingress=all \
     --allow-unauthenticated