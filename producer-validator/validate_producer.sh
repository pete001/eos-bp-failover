#!/bin/bash

###################################################################################################
#
# This script monitors that defined producers are producing the correct number of blocks in the schedule
#
# It is intended to be used with Slack chatops
#
# Please refer to https://github.com/BlockMatrixNetwork/eos-bp-failover/tree/master/external-rpc-api-monitor
# for more info on how to set this up
#
# Example call:
#
# ./validate_producer.sh
#
# Update APIS to include the producers you want to monitor
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
LOG_LOC="/mnt/stderr.txt"
SEARCH="/tmp/search.txt"
FILTER="/tmp/filter.txt"
SLACK_WEBHOOK=https://hooks.slack.com/services/replace_me
SLACK_CHANNEL="#monitoring"

# Create temp log
tail -n 5000 $LOG_LOC | grep "Received block" > $SEARCH

# Grab the top 21
ACTIVE=$(curl -s "$ENDPOINT/v1/chain/get_producers" -X POST -d '{"json":true, "limit":21}' | jq '.rows')

# We only care about the last 2min 6sec
LAST=$(date --date="-126 sec" "+%Y-%m-%dT%H:%M:%S")
NOW=$(date "+%Y-%m-%dT%H:%M:%S")

# Create filtered log
while read line; do
    [[ $line > $LAST && $line < $NOW || $line =~ $NOW ]] && echo $line >> $FILTER
done < $SEARCH

# Check each producer
for K in "${!APIS[@]}"
do
    PRODUCER=$(echo $ACTIVE | jq --arg prd "${APIS[$K]}" '.[] | select(.owner == $prd)')

    if [ "$PRODUCER" == "" ]; then
        echo "${APIS[$K]} is not in the top 21"
        continue
    fi

    # First check is to check each producer hit their 6 second target
    COUNT=$(grep -c "${APIS[$K]}" $FILTER)
    if [ "$COUNT" != "12" ]; then
        echo "${APIS[$K]} has produced an abnormal number of blocks: $COUNT"
    fi

    # Second check is to see if there has been any negative latency
    NEG=$(grep "${APIS[$K]}" $FILTER | grep "latency: -")
    if [ $? -eq 0 ]; then
        echo "${APIS[$K]} has negative latency: $NEG"
    fi

    echo "${APIS[$K]} has 12 healthy blocks and no negative latency"
done

rm $FILTER $SEARCH