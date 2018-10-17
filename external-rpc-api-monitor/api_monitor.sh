#!/bin/bash

###################################################################################################
#
# This script can monitor multiple BP RPC API endpoints
#
# It is intended to be used with Slack chatops
#
# Please refer to https://github.com/BlockMatrixNetwork/eos-bp-failover/tree/master/external-rpc-api-monitor
# for more info on how to set this up
#
# Example call:
#
# ./api_monitor.sh
#
# Update APIS to include the nodes you want to monitor
#
# Update SLACK_WEBHOOK to your own incoming webhook
#
# Update the DELAY to something other than 1 minute if you want to tweak the head block check
#
# Made with <3 by Pete @ Block Matrix
#
# See more EOS nerd shenanigans @ https://github.com/BlockMatrixNetwork
#
###################################################################################################

# Update these for your own settings
declare -A APIS=( [blockmatrix1]=https://eosapi.blockmatrix.network [hkeoshkeosbp]=http://api.hkeos.com [eos42freedom]=https://nodes.eos42.io [eosdacserver]=https://eu.eosdac.io [eosriobrazil]=https://api.eosrio.io [eosswedenorg]=https://api.eossweden.se [eostribeprod]=https://api2.eostribe.io )
SLACK_WEBHOOK=https://hooks.slack.com/services/replace_me
SLACK_CHANNEL="#monitoring"
DELAY=60

# Do not change below here
for K in "${!APIS[@]}"
do
    # Check the endpoint
    JSON=$(curl -s ${APIS[$K]}/v1/chain/get_info)

    # Fail if curl was unsuccessful
    if [ $? -ne 0 ]; then
        curl -s -X POST --data-urlencode "payload={\"channel\": \"$SLACK_CHANNEL\", \"username\": \"EOS Bot\", \"text\": \"\`$K\` API node cannot be accessed @ ${APIS[$K]}\", \"icon_emoji\": \":ghost:\"}" $SLACK_WEBHOOK
        continue
    fi

    # Calculate the diff
    HEAD=$(echo $JSON | jq -r .head_block_time)

    # Fail if jq was unsuccessful
    if [ $? -ne 0 ] || [ $HEAD == "null" ]; then
        OUTPUT=$(sed 's/"/\\"/g' <<< $JSON)
        curl -s -X POST --data-urlencode "payload={\"channel\": \"$SLACK_CHANNEL\", \"username\": \"EOS Bot\", \"text\": \"\`$K\` your API node @ ${APIS[$K]} returned invalid JSON:\n\`\`\`\n$OUTPUT\n\`\`\`\", \"icon_emoji\": \":ghost:\"}" $SLACK_WEBHOOK
        continue
    fi

    BLOCK=$(date --date=$HEAD +"%s")
    NOW=$(date +"%s")
    DIFF="$(($NOW-$BLOCK))"

    # Fail if head block is older than acceptable delay
    if [[ $DIFF -gt $DELAY ]]; then
        curl -s -X POST --data-urlencode "payload={\"channel\": \"$SLACK_CHANNEL\", \"username\": \"EOS Bot\", \"text\": \"\`$K\` API head block time @ ${APIS[$K]}/v1/chain/get_info is lagging more than $DELAY seconds: $HEAD\", \"icon_emoji\": \":ghost:\"}" $SLACK_WEBHOOK
    fi
done