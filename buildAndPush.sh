#!/bin/bash
if [[ -z "$1" ]]; then
    echo "Must provide new version tag when running the script! i.e. ./buildAndPush.sh 5.3.0" 1>&2
    exit 1
fi

docker build -t oipwg/flo-explorer:$1 .

docker tag oipwg/flo-explorer:$1 oipwg/flo-explorer:latest
docker tag oipwg/flo-explorer:$1 mediciland/flo-explorer:$1
docker tag oipwg/flo-explorer:$1 mediciland/flo-explorer:latest

docker push oipwg/flo-explorer:$1
docker push oipwg/flo-explorer:latest
docker push mediciland/flo-explorer:$1
docker push mediciland/flo-explorer:latest