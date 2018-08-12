#!/bin/bash

###################################################################################################
#
# This script monitors that defined producers are producing the correct number of blocks in each
# round and it also detects negative latency
#
# It is intended to be used with Slack chatops but outputa to stdout by default
#
# Please refer to https://github.com/BlockMatrixNetwork/eos-bp-failover/tree/master/producer-validator
# for more info on how to set this up
#
# Example call:
#
# ./validate_producer.sh
#
# Update APIS to include the producers you want to monitor
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
declare -A APIS=( [pete]=blockmatrix1 [jaechung]=hkeoshkeosbp [ankh2054]=eos42freedom [mike]=eosdacserver [igorls]=eosriobrazil [xebb]=eosswedenorg )
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

# Grab the top 21
ACTIVE=$(curl -s "$ENDPOINT/v1/chain/get_producers" -X POST -d '{"json":true, "limit":21}' | jq '.rows')

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
    echo $1
    [[ ! -z $SLACK_WEBHOOK ]] && curl -s -X POST --data-urlencode "payload={\"channel\": \"$SLACK_CHANNEL\", \"username\": \"EOS Bot\", \"text\": \"@$2 $1\", \"icon_emoji\": \":ghost:\"}" $SLACK_WEBHOOK > /dev/null 2>&1
}

# Check each producer
for K in "${!APIS[@]}"
do
    PRODUCER=$(echo $ACTIVE | jq --arg prd "${APIS[$K]}" '.[] | select(.owner == $prd)')
    PASS=1

    if [ "$PRODUCER" == "" ]; then
        echo "${APIS[$K]} is not in the top 21"
        continue
    fi

    # First check is to check each producer hit their 6 second target
    COUNT=$(grep -c "${APIS[$K]}" $FILTER)
    if [[ "$COUNT" < "12" ]]; then
        notify "${APIS[$K]} has produced less than 12 blocks: $COUNT" $K
        PASS=0
    fi

    # Second check is to see if there has been any negative latency
    NEG=$(grep "${APIS[$K]}" $FILTER | grep "latency: -")
    if [ $? -eq 0 ]; then
        notify "${APIS[$K]} has negative latency: $NEG" $K
        PASS=0
    fi

    # Output if they passed all checks, the offending lines if not
    if [ $PASS -eq 1 ]; then
        echo "${APIS[$K]} has 12 healthy blocks and no negative latency"
    else
        LOG=$(grep -C 1 "${APIS[$K]}" $FILTER | sed 's/thread-0 producer_plugin.cpp:327 on_incoming_block \] //')
        echo "$LOG"
    fi
done