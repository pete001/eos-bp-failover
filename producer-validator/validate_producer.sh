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
ACTIVE=$(curl -s "https://eosapi.blockmatrix.network/v1/chain/get_producers" -X POST -d '{"json":true, "limit":21}' | jq '.rows')
LOG_LOC="/mnt/stderr.txt"
SEARCH="/tmp/search.txt"
FILTER="/tmp/filter.txt"
SLACK_WEBHOOK=https://hooks.slack.com/services/replace_me
SLACK_CHANNEL="#monitoring"

# Create temp log
tail -n 5000 $LOG_LOC | grep "Received block" > $SEARCH

# We only care about the last 2min 6sec
LAST=$(date --date="-126 sec" "+%Y-%m-%dT%H:%M:%S")
NOW=$(date "+%Y-%m-%dT%H:%M:%S")

# Create filtered log
while read line; do
    [[ $line > $LAST && $line < $NOW || $line =~ $NOW ]] && echo $line >> $FILTER
done < $SEARCH

# Do not change below here
for K in "${!APIS[@]}"
do
    PRODUCER=$(echo $ACTIVE | jq --arg prd "${APIS[$K]}" '.[] | select(.owner == $prd)')

    if [ "$PRODUCER" == "" ]; then
        echo "${APIS[$K]} is not in the top 21"
        continue
    fi

    COUNT=$(grep -c "${APIS[$K]}" $FILTER)
    echo "${APIS[$K]} is a top 21 baller, count of blocks: $COUNT"
done

rm $FILTER $SEARCH