#!/usr/bin/env bash
set -x
set -e

buildbot checkconfig master.cfg
docker build -t "buildbot" .
docker tag "buildbot:latest" "${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/buildbot:latest"
docker push "${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/buildbot:latest"
