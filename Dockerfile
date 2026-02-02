# Build stage
FROM --platform=linux/amd64 node:20-alpine AS builder
WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

# Ensure public folder exists
RUN mkdir -p public

RUN npm run build

# Verify standalone was created
RUN ls -la .next/standalone/

# Production stage
FROM --platform=linux/amd64 node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Copy public folder
COPY --from=builder /app/public ./public

# Copy standalone build
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

# Use sh -c to set hostname at runtime
CMD ["sh", "-c", "HOSTNAME=0.0.0.0 node server.js"]
