# Pin exact stable Node.js 18 LTS base image
FROM node:18.20.4-slim

# Add curl for healthcheck and tini for PID 1 signal handling
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl tini && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /usr/local/app

# Install nodemon for development
RUN npm install -g nodemon

COPY package*.json ./

RUN npm ci && \
    npm cache clean --force && \
    mv /usr/local/app/node_modules /node_modules && \
    chown -R node:node /node_modules

COPY . .

# Set ownership of app directory to unprivileged node user
RUN chown -R node:node /usr/local/app

USER node

ENV PORT=80
EXPOSE 80

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["node", "server.js"]
