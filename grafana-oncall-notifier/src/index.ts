import type { MessagePublishedData } from "@google/events/cloud/pubsub/v1/MessagePublishedData";
import { logger } from "./logger";
import { type CloudEvent, cloudEvent } from "@google-cloud/functions-framework";

const url = process.env.GRAFANA_WEBHOOK_URL;

cloudEvent(
  "grafanaOncallNotifier",
  async (cloudEvent: CloudEvent<MessagePublishedData>) => {
    const base64data = cloudEvent.data?.message?.data;
    const jsonData = base64data
      ? Buffer.from(base64data, "base64").toString()
      : "{}";
    const parsedData = JSON.parse(jsonData);
    logger.info("[grafanaOncallNotifier]", parsedData);

    if (!url) throw new Error("GRAFANA_WEBHOOK_URL is not set");

    const incident = parsedData.incident;

    if (incident.state === "open" || incident.state === "OPEN") {
      const data = {
        title: `【${incident.severity}】${incident.policy_name}`,
        message: incident.documentation ? incident.documentation.content : '',
        severity: incident.severity,
      };

      const response = await fetch(url, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(data),
      });
      logger.info("[response.status]", response.status);
    }
  },
);
