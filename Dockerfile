# Build Stage

FROM node:18-alpine AS builder

# cd into working directory
WORKDIR /usr/src/app

# Copy over the the package, lock file, and local .npmrc
COPY package*.json ./
COPY /*.npmrc ./

# Use docker secrets to install all dependencies
RUN --mount=type=secret,id=npm,target=/root/.npmrc npm ci --ignore-scripts

# Copy over everything else and build the project
COPY . .
RUN npm run build

# Remove build info from the compiled output
RUN rm build/.tsbuildinfo

# Remove all development dependencies and install only dependencies required to run in production
RUN rm -rf node_modules
RUN --mount=type=secret,id=npm,target=/root/.npmrc npm ci --production --ignore-scripts

# Production stage

FROM node:18-alpine as base

# cd into working directory
WORKDIR /usr/src/app

# Chown the directory
RUN chown node:node .

# Switch to service user
USER node

# IMPORTANT. The following code ONLY copies over:
#  1. The `build` folder, the compiled version of `src`
#  2. The `node_modules` with production dependencies only
#  3. All `.env` files in the root of the project
# This is to keep our images nice and clean.
# If this service requires additional code or configuration, make sure to add it here

# Copy over package.json
COPY package.json ./

# Copy the build from the first stage
COPY --from=builder /usr/src/app/build/ build/

# Copy the production node_modules from the first stage
COPY --from=builder /usr/src/app/node_modules/ node_modules/

# Copy over all configuration files we need to run
COPY .env* ./

# Expose the port
EXPOSE 8080

# Start the service, exposing the node process directly to Kubernetes
CMD [ "node", "--experimental-specifier-resolution=node", "--enable-source-maps", "build/index.js" ]
