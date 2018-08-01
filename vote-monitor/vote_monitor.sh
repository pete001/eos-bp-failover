#!/bin/bash

###################################################################################################
#
# This script can monitor vote movements for multiple BPs
#
# It is intended to be used with Slack chatops
#
# Please refer to https://github.com/BlockMatrixNetwork/eos-bp-failover/tree/master/external-rpc-api-monitor
# for more info on how to set this up
#
# Example call:
#
# ./vote_monitor.sh
#
# Update PRODUCERS to include the BPs you want to monitor
#
# Update SLACK_WEBHOOK to your own incoming webhook
#
# Update the MIN_VOTES to set a threshold for the vote movement to reduce noise
#
# Made with <3 by Pete @ Block Matrix
#
# See more EOS nerd shenanigans @ https://github.com/BlockMatrixNetwork
#
###################################################################################################

# Update these for your own purposes
PRODUCERS=( "blockmatrix1" "hkeoshkeosbp" "eos42freedom" "eosdacserver" "eosriobrazil" "eosswedenorg" "eostribeprod" )
SLACK_WEBHOOK=https://hooks.slack.com/services/replace_me
SLACK_CHANNEL="#eos-alerts"
MIN_VOTES=1000

# Do not change below here
for PRODUCER in "${PRODUCERS[@]}"
do
    FILE="/tmp/$PRODUCER-votes.log"
    if [ ! -f $FILE ]; then
        echo "0" > $FILE
    fi

    # The sorted vote object
    VOTES=$(curl -s "https://eosapi.blockmatrix.network/v1/chain/get_producers" -X POST -d '{"json":true, "limit":200}' | jq '.rows' | jq '[keys[] as $k | .[$k] | .rank=$k+1]' | jq --arg prd "$PRODUCER" '.[] | select(.owner == $prd)')

    # Producer votes
    PROD_VOTES=$(echo $VOTES | jq -r .total_votes)
    PROD_POS=$(echo $VOTES | jq -r .rank)

    # Total vote weight
    TOTAL=$(curl -s "https://eosapi.blockmatrix.network/v1/chain/get_table_rows" -X POST -d '{"scope":"eosio", "code": "eosio", "table": "global", "json": true}' | jq '.rows[0]' | jq -r .total_producer_vote_weight)

    # Calculate the vote %
    PERCENT1=$(echo ${PROD_VOTES%\.*})
    PERCENT2=$(echo ${TOTAL%\.*})
    PERCENT=$(bc -l <<< "$PERCENT1/$PERCENT2*100")
    PERCENT=$(printf '%.3g\n' $PERCENT)

    # Calculate the vote number in EOS, this is intentionally verbose
    NOW=$(date +%s)
    MILL=$(echo "$NOW-946684800" | bc)
    WEEK=$(echo "($MILL/604800) / 1" | bc)
    YEAR=$(bc -l <<< "scale=10; $WEEK / 52")
    POW=$(awk -v num=$YEAR 'BEGIN{print 2^num}')
    WEIGHT=$(echo "$POW*10000" | bc)
    ADJUSTED=$(echo "$PERCENT1/$WEIGHT" | bc)
    PRETTY=$(printf "%'d" $ADJUSTED)

    # Notify
    if [[ $(< $FILE) != "$ADJUSTED" ]]; then
        DIFF_TOTAL=$(bc -l <<< "$ADJUSTED-$(< $FILE)")
        DIFF_PRETTY=$(printf "%'d" $DIFF_TOTAL)
        ABS=${DIFF_TOTAL#-}
        if [[ "$ABS" -gt "$MIN_VOTES" ]]; then
            curl -X POST --data-urlencode "payload={\"channel\": \"$SLACK_CHANNEL\", \"username\": \"EOS Bot\", \"text\": \"Votes changed for \`$PRODUCER\`:\n\`\`\`\nRank #: $PROD_POS\nVote %: $PERCENT\nVote #: $PRETTY ($DIFF_PRETTY)\n\`\`\`\", \"icon_emoji\": \":ghost:\"}" $SLACK_WEBHOOK
        fi
        echo "Votes changed from $(< $FILE) to $ADJUSTED"
        echo $ADJUSTED > $FILE
    else
        echo "Votes remained on $(< $FILE)"
    fi
done