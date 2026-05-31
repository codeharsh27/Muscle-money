FROM node:22-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json* turbo.json ./
COPY apps/api/package.json apps/api/package.json
COPY packages packages
RUN npm ci

FROM deps AS build
COPY apps/api apps/api
RUN npm --workspace @muscle-money/api run prisma:generate
RUN npm --workspace @muscle-money/api run build

FROM node:22-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
COPY --from=build /app/node_modules node_modules
COPY --from=build /app/apps/api/dist apps/api/dist
COPY --from=build /app/apps/api/prisma apps/api/prisma
CMD ["node", "apps/api/dist/main.js"]
