# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json tsconfig.json ./
RUN npm ci

COPY . .
RUN npm run build

# Production stage
FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production

COPY package*.json ./
RUN npm ci --only=production

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/orchestrator/config.json ./orchestrator/
COPY --from=builder /app/saldoandmik/config.json ./saldoandmik/
COPY --from=builder /app/calc_arv_jaak/config.json ./calc_arv_jaak/
COPY --from=builder /app/getEarved/config.json ./getEarved/
COPY --from=builder /app/sendFinBitReport/config.json ./sendFinBitReport/
COPY --from=builder /app/lisa1_lisa5/config.json ./lisa1_lisa5/
COPY --from=builder /app/reporter/config.json ./reporter/

EXPOSE 8080

CMD ["node", "dist/index.js"]
