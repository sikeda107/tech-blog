import * as functions from '@google-cloud/functions-framework';
import * as winston from 'winston';
import { LoggingWinston } from '@google-cloud/logging-winston';
import { App } from '@slack/bolt';
// cspell:disable-next-line
import slackifyMarkdown from 'slackify-markdown';

const app = new App({
  token: process.env.SLACK_BOT_TOKEN,
  signingSecret: process.env.SLACK_SIGNING_SECRET,
});

const loggingWinston = new LoggingWinston();
const severity = winston.format((info) => {
  info['severity'] = info.level.toUpperCase();
  return info;
});
const errorReport = winston.format((info) => {
  if (info instanceof Error) {
    info.err = {
      name: info.name,
      message: info.message,
      stack: info.stack,
    };
  }
  return info;
});

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    severity(),
    errorReport(),
    winston.format.json()
  ),
  transports: [new winston.transports.Console(), loggingWinston],
});
// Register a CloudEvent callback with the Functions Framework that will
// be executed when the Pub/Sub trigger topic receives a message.
functions.cloudEvent('monitoringNotifier', (cloudEvent: any) => {
  try {
    // The Pub/Sub message is passed as the CloudEvent's data payload.
    const base64data = cloudEvent.data.message.data;
    const jsonData = base64data
      ? Buffer.from(base64data, 'base64').toString()
      : '{}';
    logger.info(JSON.parse(jsonData));
    const incident = JSON.parse(jsonData)['incident'];
    const content = incident['documentation']
      ? incident['documentation']['content']
      : '';
    // postMessage specification
    // https://api.slack.com/methods/chat.postMessage
    app.client.chat.postMessage({
      text: incident['policy_name'],
      channel: '#google-cloud-notification',
      attachments: createAttachments(
        incident['url'],
        content,
        incident['scoping_project_id'],
        incident['state'],
        incident['severity']
      ),
    });
  } catch (e) {
    logger.error(e);
    throw e;
  }
});

/**
 * Create attachments for slack notification
 * @see {@link https://api.slack.com/reference/messaging/attachments|attachments specification}
 */
function createAttachments(
  url: string,
  document: string,
  project: string,
  state: string,
  severity: string
) {
  const colors = {
    green: '#00FF00',
    orange: '#ee7800',
    red: '#FF0000',
    gray: '#333333',
  };
  if (state === 'CLOSED' || state === 'closed') {
    return [
      {
        color: colors.green,
        blocks: [
          {
            type: 'section',
            fields: [
              {
                type: 'mrkdwn',
                text: `project: <https://console.cloud.google.com/monitoring/alerting?project=${project}|${project}>`,
              },
            ],
          },
        ],
      },
    ];
  } else if (state === 'OPEN' || state === 'open') {
    return [
      {
        color: severity === 'Critical' ? colors.red : colors.orange,
        blocks: [
          {
            type: 'section',
            fields: [
              {
                type: 'mrkdwn',
                text: `project: <https://console.cloud.google.com/monitoring/alerting?project=${project}|${project}>`,
              },
              {
                type: 'mrkdwn',
                text: `<${url}|Incident details>`,
              },
            ],
          },
          {
            type: 'section',
            text: {
              type: 'mrkdwn',
              // cspell:disable-next-line
              text: slackifyMarkdown(document) || 'No description',
            },
          },
        ],
      },
    ];
  }
  return [
    {
      color: colors.gray,
      blocks: [
        {
          type: 'section',
          fields: [
            {
              type: 'mrkdwn',
              text: `project: <https://console.cloud.google.com/monitoring/alerting?project=${project}|${project}>`,
            },
          ],
        },
      ],
    },
  ];
}
