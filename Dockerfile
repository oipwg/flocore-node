# Use a specific version of node on Alpine for better predictability
FROM node:22-alpine

# Install Python 2.7 and build dependencies necessary for native modules
# Make and g++ are required for node-gyp, git for packages that may need to pull via git
RUN apk --no-cache add \
    python3 \
    make \
    g++ \
    git \
    curl \
    tar

WORKDIR /app

# Copy package.json and package-lock.json (or npm-shrinkwrap.json) first for better cache utilization
COPY package.json ./
COPY yarn.lock ./

RUN yarn

RUN mkdir /data

# Copy the rest of the application
COPY . .
RUN mv flocore-node.json.sample flocore-node.json

# Expose used ports
EXPOSE 80 443 3001 7312 7313 17312 17313 17413 41289

CMD [ "/app/bin/start.sh" ]
