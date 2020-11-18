# Build API
# This Dockerfile is very inefficient.  Convert this to a multi-stage docker build with a node12 container used as runtime.
# If done correctly the final image should be < 300 MB.
FROM node:12-alpine AS base
WORKDIR /app
COPY ./package.json ./

FROM base AS dependencies
RUN npm install

FROM base AS release
COPY --from=dependencies /app/node_modules ./node_modules
COPY . .
RUN npm run build
CMD ["npm", "run", "start:prod"]
