#!/usr/bin/env bash
set -x
set -e

aws ecr get-login-password \
    --region $REGION \
| docker login \
    --username AWS \
    --password-stdin "${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com"
