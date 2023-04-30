#!/bin/env bash
#
#
# Usage ./run-with-env.bash make -f openlane.mk freq_mul_x8
set -x
dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

export OPENLANE_ROOT=$HOME/work/OpenLane
export PDK_ROOT=$HOME/work/pdk
export PDK=sky130A
export OPENLANE_IMAGE_NAME=efabless/openlane:0d205c619229eb3ba227e4a7fc042d344b8b6d07-amd64
export OPENLANE_TAG=0d205c619229eb3ba227e4a7fc042d344b8b6d07-amd64
export PROJECT_ROOT=$dir

eval "$@"

