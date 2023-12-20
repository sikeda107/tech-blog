# はじめに

Cloud Monitoring では、アラートポリシーを作成して Slack へ通知させることができます。
通知先のチャンネルへ BOT を招待して、ポリシーの通知先として設定するだけですので非常に簡単です。
ただ、この通知メッセージにはいくつか改善したいポイントがあります。

- 通知がメッセージが縦に長いため、1 画面での表示件数が少なくなる
- 情報量が多く、ほとんど活用していない情報もメッセージに含まれる
- Markdown がそのままメッセージになってしまう

これらを改善するためにカスタム通知を作成したので、そのご紹介です。

# アーキテクチャ

アラートポリシーの通知先には、Cloud Pub/Sub を指定することができます。
Cloud Pub/Sub をトリガーとした Cloud Functions を作成し、Cloud Functions で通知内容をカスタマイズしてから Slack へ通知させる流れになります。
Cloud Functions のデプロイは、Cloud Build でおこないます。また、Slack への認証情報は Secret Manager に保存します。
![](https://storage.googleapis.com/zenn-user-upload/867b272bedf4-20231220.png)

# 構築

## 1. Slack & Secret Manager

Slack BOT を作成します。作成方法は公式サイトにわかりやすく書いてあるので割愛します。
https://api.slack.com/lang/ja-jp/hello-world-bolt
Slack BOT の Signing Secret と Bot User OAuth Access Token をそれぞれ、Secret Manager に登録します。

```bash
# Signing Secret の登録
echo -n "xxxxxxxxxxxxxxxxx" | gcloud secrets create slack-signing-secret \
    --replication-policy="automatic" \
    --data-file=-
# Bot User OAuth Access Token の登録
echo -n "xoxb-000000000000" | gcloud secrets create slack-bot-user-oauth-token \
    --replication-policy="automatic" \
    --data-file=-
```

## 2. Cloud Monitoring で Cloud Pub/Sub を通知チャンネルとして設定する

Cloud Monitoring の通知先となる Cloud Pub/Sub を作成します。

```bash
# トピックの作成
gcloud pubsub topics create notificationTopic
```

作成しただけですとメッセージを送信できないので、Cloud Monitoring のサービスアカウントへ `roles/pubsub.publisher` IAM ロールを付与します。
サービスアカウントのメールアドレスは、`service-${PROJECT_NUMBER}@gcp-sa-monitoring-notification.iam.gserviceaccount.com` の形式になります。
`PROJECT_NUMBER` は、gcloud コマンドで取得できます。

```bash
export YOUR_PROJECT_ID=xxxxxxxxxx
gcloud projects describe ${YOUR_PROJECT_ID} --format="value(project_number)"
```

Cloud Monitoring でアラートポリシーを作成して、通知チャンネルとして`projects/PROJECT_NUMBER/topics/notificationTopic`を設定したら準備完了です。

## 3. Cloud Pub/Sub をトリガーとする Cloud Functions を作成する

[チュートリアル](https://cloud.google.com/functions/docs/tutorials/pubsub?hl=ja) を参考にして、Cloud Functions を作成します。
受け取ったメッセージの `incident`に詳細[^1]がはいっています。今回は、６つの値を使います。

- documentation.content : アラートポリシーの Documentation
- policy_name : アラートポリシー名
- url: 発火したインシデントの Google Cloud Console URL
- scoping_project_id : 指標スコープをホストするプロジェクト ID
- state : インシデントの状態で `open` または `closed`
- severity : アラートポリシーの Severity Level

[^1]: その他のキーは [通知チャンネルを作成する - スキーマの例](https://cloud.google.com/monitoring/support/notification-options?hl=ja#schema-pubsub) をご確認ください。

https://github.com/sikeda107/tech-blog/blob/d6fa284b06aaaadfb5f8b7f22397424e98159dbf/MonitoringNotifier/src/index.ts#L40-L69

:::message
テスト通知を送信したときに state の文字列が大文字で、content は空の状態で送信されてきますので、その考慮が必要です
:::

必要な情報をメッセージから取り出して、Slack の Block Kit を組み立てて送信します。インシデントがオープンしたときと、クローズしたときでラインカラーを変えることで視認性をあげています。
また、[jsarafajr/slackify-markdown](https://github.com/jsarafajr/slackify-markdown) というものを使って、Markdown から Slack の形式に変換をかけて、メッセージを投稿するようにしました。

https://github.com/sikeda107/tech-blog/blob/d6fa284b06aaaadfb5f8b7f22397424e98159dbf/MonitoringNotifier/src/index.ts#L105-L134

コード全体は[こちら](https://github.com/sikeda107/tech-blog/blob/main/MonitoringNotifier/src/index.ts)にあげています。

## 4. Cloud Build で Cloud Functions を deploy する

Cloud Build をつかって、Cloud Functions を作成します。オプションで Cloud Pub/Sub をトリガーとして設定し作成済みの Secret Manager のシークレットを deploy 時に設定します。こうすることで、環境変数としてアクセスすることができます。

https://github.com/sikeda107/tech-blog/blob/d6fa284b06aaaadfb5f8b7f22397424e98159dbf/MonitoringNotifier/src/index.ts#L8-L11

ビルド構成ファイルを作成して、deploy を実行します。

```bash
# deployコマンド
gcloud builds submit --project=${YOUR_PROJECT_ID} --config ./cloudbuild.yaml
```

https://github.com/sikeda107/tech-blog/blob/main/MonitoringNotifier/cloudbuild.yaml

## 5. 通知をテストする

アラートポリシーを作成したあと、Cloud Pub/Sub のトピックを通知先に設定してください。Cloud Pub/Sub と Cloud Functions を挟んでいるため若干のタイムラグはありますが、正常にメッセージを受信できれば成功です 🎉
左が今回の通知メッセージで、右がもともとの通知メッセージです。画面の占有度がだいぶかわったことがわかると思います 😄
ドキュメントもきちんとフォーマットされているので、メッセージとしてもスッキリとした印象があります。
![](https://storage.googleapis.com/zenn-user-upload/328dcab15282-20231220.png)

# さいごに

こういった小さな改善でもアラート疲れを軽減する効果があるかと思います。ぜひ通知内容の改善も実施してみてください 🔔

# 参考

- [Cloud Monitoring と Cloud Run を使用したカスタム通知の作成 Google Cloud 公式ブログ](https://cloud.google.com/blog/ja/products/operations/write-and-deploy-cloud-monitoring-alert-notifications-to-third-party-services)
- [通知チャンネルの作成と管理 Google Cloud](https://cloud.google.com/monitoring/support/notification-options?hl=ja#creating_channels)
- [Secret Manager を使用してシークレットを作成してアクセスする Google Cloud](https://cloud.google.com/secret-manager/docs/create-secret-quickstart?hl=ja)
- [Cloud Pub/Sub のチュートリアル（第 2 世代）Google Cloud Functions に関するドキュメント](https://cloud.google.com/functions/docs/tutorials/pubsub?hl=ja)
- [jsarafajr/slackify-markdown: Convert markdown into Slack-specific markdown](https://github.com/jsarafajr/slackify-markdown)
