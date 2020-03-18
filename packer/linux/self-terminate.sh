#!/usr/bin/env bash
set -x
set -e

aws ec2 terminate-instances --instance-ids `curl -s http://169.254.169.254/latest/meta-data/instance-id`
