#!/bin/bash

############################################################################################
#
# This script will request the chain info from an EOS RPC server
#
# It will compare the head block time to the current time and compute the diff
#
# If the diff is greater than an acceptable limit in seconds, it fails
#
# There is a dependency on `jq` because grepping would be ugly
#
# Example call:
#
# ./nodeos_head_block.sh https://eosapi.blockmatrix.network 30
#
# Made with <3 by Pete @ Block Matrix
#
# See more EOS nerd shenanigans @ https://github.com/BlockMatrixNetwork
#
############################################################################################

API="$1/v1/chain/get_info"
DELAY=$2

if [ $# -ne 2 ]; then
    echo "You must pass 2 parameters, the RPC API and the acceptable delay in seconds"
    exit 1
fi

# Calculate the diff
HEAD=$(curl -s $API | jq .head_block_time | tr -d '"')
BLOCK=$(date --date=$HEAD +"%s")
NOW=$(date +"%s")
DIFF="$(($NOW-$BLOCK))"

# Fail if head block is older than acceptable delay
[[ $DIFF -gt $DELAY ]] && exit 1 || echo "ok"
