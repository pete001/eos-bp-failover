#!/bin/bash

###################################################################################################
#
# This script monitors the top 21 producers to ensure they are producing the correct number of
# blocks in each round and it also detects negative latency
#
# It is intended to be used with Slack chatops but outputs to stdout by default
#
# Please refer to https://github.com/BlockMatrixNetwork/eos-bp-failover/tree/master/producer-validator
# for more info on how to set this up
#
# Example call:
#
# ./validate_producer_all.sh
#
# Update NODEOS_LOG to point to your local nodeos log file
#
# Update SLACK_WEBHOOK to your own incoming webhook
#
# Made with <3 by Pete @ Block Matrix
#
# See more EOS nerd shenanigans @ https://github.com/BlockMatrixNetwork
#
###################################################################################################

# Update these for your own settings
ENDPOINT="https://eosapi.blockmatrix.network"
NODEOS_LOG="/mnt/stderr.txt"

# Optional slack notifications add incoming webhook url to activate it
SLACK_WEBHOOK=
SLACK_CHANNEL="#monitoring"

# Dont modify below here
SEARCH="/tmp/search.txt"
FILTER="/tmp/filter.txt"
echo "" > $FILTER

# Create temp log, assume non debug nodeos log
tail -n 5000 $NODEOS_LOG | grep "Received block" > $SEARCH

# We only care about the last 2min 6sec
LAST=$(date --date="-126 sec" "+%Y-%m-%dT%H:%M:%S")
NOW=$(date "+%Y-%m-%dT%H:%M:%S")

# Create filtered log
while read line; do
    [[ $line > $LAST && $line < $NOW || $line =~ $NOW ]] && echo $line >> $FILTER
done < $SEARCH

# Handle notifications
function notify()
{
    echo "$1"
    [[ ! -z $SLACK_WEBHOOK ]] && curl -s -X POST --data-urlencode "payload={\"channel\": \"$SLACK_CHANNEL\", \"username\": \"EOS Bot\", \"text\": \"$1\", \"icon_emoji\": \":ghost:\"}" $SLACK_WEBHOOK > /dev/null 2>&1
}

# Check each producer
for PRODUCER in $(curl -s "https://eosapi.blockmatrix.network/v1/chain/get_producers" -X POST -d '{"json":true, "limit":21}' | jq '.rows[]' | jq -r .owner)
do
    PASS=1

    # First check is to check each producer hit their 6 second target
    COUNT=$(grep -c "$PRODUCER" $FILTER)
    if [[ "$COUNT" < "12" ]]; then
        notify "$PRODUCER has produced less than 12 blocks: $COUNT"
        PASS=0
    fi

    # Second check is to see if there has been any negative latency
    NEG=$(grep "$PRODUCER" $FILTER | grep "latency: -")
    if [ $? -eq 0 ]; then
        notify "$PRODUCER has negative latency"
        PASS=0
    fi

    # Output if they passed all checks, the offending lines if not
    if [ $PASS -eq 1 ]; then
        echo "$PRODUCER has 12 healthy blocks and no negative latency"
    else
        LOG=$(grep -C 1 "$PRODUCER" $FILTER | sed 's/thread-0 producer_plugin.cpp:327 on_incoming_block \] //')
        echo "$LOG"
        [[ ! -z $SLACK_WEBHOOK ]] && curl -s -X POST --data-urlencode "payload={\"channel\": \"$SLACK_CHANNEL\", \"username\": \"EOS Bot\", \"text\": \"\`\`\`\n$LOG\n\`\`\`\", \"icon_emoji\": \":ghost:\"}" $SLACK_WEBHOOK > /dev/null 2>&1
    fi
done