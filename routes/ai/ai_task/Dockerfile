# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json tsconfig.json ./
RUN npm ci

COPY . .
RUN npm run build
RUN mkdir -p /configs && \
    find . -mindepth 2 -maxdepth 2 -name config.json \
      -exec sh -c 'mkdir -p /configs/$(dirname "$1") && cp "$1" /configs/$(dirname "$1")/' _ {} \;

# Production stage
FROM node:20-alpine AS runner

WORKDIR /app

RUN apk add --no-cache tzdata && \
    cp /usr/share/zoneinfo/Europe/Tallinn /etc/localtime && \
    echo "Europe/Tallinn" > /etc/timezone

ENV NODE_ENV=production
ENV TZ=Europe/Tallinn

COPY package*.json ./
RUN npm ci --only=production

COPY --from=builder /app/dist ./dist
COPY --from=builder /configs ./

EXPOSE 8080

CMD ["node", "dist/index.js"]
