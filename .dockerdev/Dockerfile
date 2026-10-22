# Development image — local only; the root ./Dockerfile builds the production image.
#
# Public, multi-arch Node base. docker-compose.yml overrides the CMD with a watch command and
# bind-mounts the source, so editing code does not need a rebuild.
FROM node:24-alpine

WORKDIR /home/node/app

# Dependencies as their own layer, so editing source does not reinstall them.
COPY package.json package-lock.json ./
RUN npm ci

# The app runs as `node` and writes to node_modules (the watch command runs `npm i`).
RUN chown -R node:node /home/node/app

USER node
