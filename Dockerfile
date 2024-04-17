# Use a specific version of node on Alpine for better predictability
FROM node:10.24.1-alpine3.11

# Install Python 2.7 and build dependencies necessary for native modules
# Make and g++ are required for node-gyp, git for packages that may need to pull via git
RUN apk --no-cache add \
    python2 \
    make \
    g++ \
    git \
    && npm install -g node-gyp@latest

WORKDIR /app

# Copy package.json and package-lock.json (or npm-shrinkwrap.json) first for better cache utilization
COPY package*.json ./

# Ensure npm uses Python 2.7 for compatibility with older gyp files
RUN npm config set python /usr/bin/python2 \
    && npm install 

# Copy the rest of the application
COPY . .
RUN mv flocore-node.json.sample flocore-node.json

# Expose used ports
EXPOSE 80 443 3001 7312 7313 17312 17313 17413 41289

CMD [ "/app/bin/start.sh" ]
