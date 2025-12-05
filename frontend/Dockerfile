# ==============================================================================
# Knowsee Platform - Frontend Dockerfile
# ==============================================================================
# Multi-stage build for Next.js 15 chatbot frontend using pnpm
# Target: Google Cloud Run (linux/amd64)
#
# IMPORTANT: Runtime environment variables required for production:
#   AUTH_SECRET         - Auth.js encryption secret (required)
#   AUTH_TRUST_HOST     - Set to "true" for Cloud Run
#   AUTH_URL            - Public URL (e.g., https://app.knowsee.com)
#   AUTH_SECURE_COOKIES - Set to "true" for HTTPS (omit for local HTTP)
#   BACKEND_URL         - Backend API URL
# ==============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Install dependencies
# -----------------------------------------------------------------------------
FROM node:20-alpine AS deps

# Enable corepack for pnpm
RUN corepack enable && corepack prepare pnpm@9.12.3 --activate

WORKDIR /app

# Copy package files
COPY package.json pnpm-lock.yaml ./

# Install dependencies
RUN pnpm install --frozen-lockfile

# -----------------------------------------------------------------------------
# Stage 2: Build the application
# -----------------------------------------------------------------------------
FROM node:20-alpine AS builder

RUN corepack enable && corepack prepare pnpm@9.12.3 --activate

WORKDIR /app

# Copy dependencies from deps stage
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Set build-time environment variables
# These are baked into the client bundle at build time
ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_ENV=production

# Build the application
RUN pnpm build

# -----------------------------------------------------------------------------
# Stage 3: Production runtime
# -----------------------------------------------------------------------------
FROM node:20-alpine AS runtime

WORKDIR /app

# Set production environment
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Cloud Run uses PORT environment variable
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

# Copy public assets
COPY --from=builder /app/public ./public

# Copy standalone build output
# Next.js standalone mode creates a minimal node_modules
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:${PORT}/ || exit 1

# Expose port
EXPOSE ${PORT}

# Run the standalone server
CMD ["node", "server.js"]
