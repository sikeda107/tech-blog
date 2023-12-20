Cloud Monitoring では、アラートポリシーを作成して Slack へ通知させることができます。
通知先のチャンネルへ BOT を招待して、ポリシーの通知先として設定するだけですので非常に簡単です。
ただ、この通知メッセージにはいくつか改善したいポイントがあります。

- 通知がメッセージが縦に長いため、1 画面での表示件数が少なくなる
- 情報量が多く、ほとんど活用していない情報もメッセージに含まれる
- Markdown がそのままメッセージになってしまう

今回は、これらを改善するためにカスタム通知を作成したので、そのご紹介です。

# アーキテクチャ

アラートポリシーの通知先には、Cloud Pub/Sub を指定することができます。
Cloud Pub/Sub をトリガーとした Cloud Functions を作成し、Cloud Functions で通知内容をカスタマイズしてから Slack へ通知させる流れになります。

## Slack & Secret Manager

Slack BOT を作成します。作成方法は、公式サイトにわかりやすく書いてあるので割愛します。
[Bolt フレームワークを使って Slack Bot を作ろう Slack](https://api.slack.com/lang/ja-jp/hello-world-bolt)

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

## Cloud Monitoring で Cloud Pub/Sub を通知チャンネルとして設定する

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

Cloud Monitoring でアラートポリシーを作成して、通知チャンネルとして `projects/PROJECT_NUMBER/topics/notificationTopic` を設定したら準備完了です。

## Cloud Pub/Sub をトリガーとする Cloud Functions を作成する

[チュートリアル](https://cloud.google.com/functions/docs/tutorials/pubsub?hl=ja) を参考にして、Cloud Functions を作成します。

[jsarafajr/slackify-markdown](https://github.com/jsarafajr/slackify-markdown) というものを使って、Markdown から Slack の形式に変換をかけて、メッセージを投稿するようにしました

## 結果の比較

結果的に

- アラートポリシー名
- インシデント詳細へのリンク
- プロジェクトの Cloud Monitoring コンソール画面へのリンク
- インシデントの詳細

に落ち着きました。また、インシデントから回復した場合は、結果だけわかればいいので、さらに絞り込んで ポリシー名・各種リンクにしました。
もとの通知メッセージと比べるとだいぶスッキリしたんじゃないかと思います。

## さいごに

こういった小さな改善でもアラート疲れを軽減する効果があるかと思います。ぜひ通知内容の改善も実施してみてください！！

## 参考

- [通知チャンネルの作成と管理 Google Cloud](https://cloud.google.com/monitoring/support/notification-options?hl=ja#creating_channels)
- [Secret Manager を使用してシークレットを作成してアクセスする Google Cloud](https://cloud.google.com/secret-manager/docs/create-secret-quickstart?hl=ja)
- [Cloud Pub/Sub のチュートリアル（第 2 世代）Google Cloud Functions に関するドキュメント](https://cloud.google.com/functions/docs/tutorials/pubsub?hl=ja)
- [jsarafajr/slackify-markdown: Convert markdown into Slack-specific markdown](https://github.com/jsarafajr/slackify-markdown)
