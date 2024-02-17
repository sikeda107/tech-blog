FROM node:18-alpine
RUN apk add --no-cache bind-tools
WORKDIR /app
COPY index.js .
EXPOSE 8080
CMD ["node", "index.js"]