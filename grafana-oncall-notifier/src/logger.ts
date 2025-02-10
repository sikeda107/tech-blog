import { LoggingWinston } from '@google-cloud/logging-winston'
import * as winston from 'winston'

const loggingWinston = new LoggingWinston()
const severity = winston.format((info) => {
  info.severity = info.level.toUpperCase()
  return info
})
const errorReport = winston.format((info) => {
  if (info instanceof Error) {
    info.err = {
      name: info.name,
      message: info.message,
      stack: info.stack,
    }
  }
  return info
})

export const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(severity(), errorReport(), winston.format.json()),
  transports: [new winston.transports.Console(), loggingWinston],
})