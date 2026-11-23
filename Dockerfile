# Stage 1: Build & Dependencies
FROM node:20-alpine AS builder
WORKDIR /app
RUN apk add --no-cache libc6-compat python3 make g++ git
COPY package*.json pnpm-lock.yaml* yarn.lock* ./
RUN npm ci --legacy-peer-deps || npm install --legacy-peer-deps
COPY . .
RUN if grep -q '"build":' package.json; then npm run build; fi

# Stage 2: Production Runner
FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV PORT=3000
RUN apk add --no-cache libc6-compat
COPY --from=builder /app ./
EXPOSE 3000
CMD ["npm", "start"]
