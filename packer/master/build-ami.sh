#!/usr/bin/env bash
set -x
set -e

packer validate linux.json
packer build linux.json
