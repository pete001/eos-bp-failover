#!/bin/bash

###################################################################################################
#
# This script will auto claim BP rewards
#
# The premise is based on a safe "claim" only account permission
#
# Please refer to https://github.com/BlockMatrixNetwork/eos-bp-failover/tree/master/claim-rewards
# for more info on how to set this up
#
# Example call:
#
# ./claim_rewards.sh PW5JfDojLFSmMTJfDLwQE5zvE4mjSBDwUpfuZWmws5Ecm4AF2StjW
#
# Update SLACK_WEBHOOK if you want to be notified via an incoming webhook
#
# Made with <3 by Pete @ Block Matrix
#
# See more EOS nerd shenanigans @ https://github.com/BlockMatrixNetwork
#
###################################################################################################

# Update these params for your system
CLEOS=/opt/eos/build/programs/cleos/cleos
API=http://127.0.0.1:8888
WALLET=http://127.0.0.1:55554
PRODUCER=blockmatrix

# Pass in the password so you arent checking it into a repo
CLAIM_WALLET_PASS=$1

# Only update these params if you know what you are doing
SLACK_WEBHOOK=https://hooks.slack.com/services/replace_me
SLACK_CHANNEL="#eos-alerts"
CLAIM_PERMISSION=claims
DIFF_CHECK=86400
EXEC="$CLEOS -u $API --wallet-url $WALLET"

# Optional slack notification
function notify()
{
    [[ ! -z $SLACK_WEBHOOK ]] && curl -s -X POST --data-urlencode "payload={\"channel\": \"$SLACK_CHANNEL\", \"username\": \"EOS Bot\", \"text\": \"$1\", \"icon_emoji\": \":ghost:\"}" $SLACK_WEBHOOK > /dev/null 2>&1
}

# Validate the password format
if [[ ! $CLAIM_WALLET_PASS =~ ^PW5.* ]]; then
    echo "Invalid wallet password"
    exit 1
fi

# Fetch the last claim time for the producer and validate
LAST_CLAIM=$(curl -sX POST "$API/v1/chain/get_table_rows" -d '{"scope":"eosio", "code":"eosio", "table":"producers", "json":true, "limit":10000}' | jq --arg prd "$PRODUCER" -r '.rows[] | select(.owner==$prd) | .last_claim_time')

if [[ $? -ne 0 ]]; then
    echo "Invalid last claim time, claim manually to set a relevant time"
    exit 1
fi

# Calculate diff
CLAIM_TIME=$(date -d "$LAST_CLAIM" +"%s")
NOW=$(date +"%s")
DIFF="$(($NOW-$CLAIM_TIME))"

# Check if the diff exceeds our target
if [ $DIFF -lt $DIFF_CHECK ]; then
    echo "Not claiming rewards as $DIFF is less than $DIFF_CHECK"
    exit 1
fi

# Now we can claim rewards
$EXEC wallet lock_all > /dev/null 2>&1
$EXEC wallet unlock -n $CLAIM_PERMISSION --password $CLAIM_WALLET_PASS > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "Incorrect wallet password"
    exit 1
fi

RESULT=$(($EXEC push action eosio claimrewards "[\"$PRODUCER\"]" -p $PRODUCER@$CLAIM_PERMISSION -x 1000) 2>&1)

# Notify via slack
if [ $? -eq 0 ]; then
    BPAY=$(echo "$RESULT" | grep "$PRODUCER <= eosio.token::transfer" | grep "eosio.bpay" | grep -Eo "[0-9]+\.[0-9]+ EOS")
    VPAY=$(echo "$RESULT" | grep "$PRODUCER <= eosio.token::transfer" | grep "eosio.vpay" | grep -Eo "[0-9]+\.[0-9]+ EOS")
    notify "Successfully claimed rewards for \`$PRODUCER\`: \`\`\`Block Pay: $BPAY\nVote Pay: $VPAY\`\`\`"
else
    notify "$(echo "Claim rewards for \`$PRODUCER\` failed: \`\`\`$RESULT\`\`\`" | sed 's/\x1B\[[0-9;]\+[A-Za-z]//g')"
fi

# Raw output
echo "$RESULT"
