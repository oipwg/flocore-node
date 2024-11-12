#!/bin/sh
docker build -t flo-explorer:dev .
docker run -it flo-explorer:dev # start attached

# OR, directly connect to nodes using `ADDNODE` environment variable!
# docker run -it -e ADDNODE='34.171.98.65' flo-explorer:dev