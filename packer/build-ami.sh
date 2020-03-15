#!/usr/bin/env bash
set -x
set -e

packer validate linux/linux.json
packer build linux/linux.json
