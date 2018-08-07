#!/bin/bash

###################################################################################################
#
# This script attempts to backup the blocks data directory
#
# It is intended to be used with Slack chatops
#
# Please refer to https://github.com/BlockMatrixNetwork/eos-bp-failover/tree/master/blocks-backup
# for more info on how to set this up
#
# Example call:
#
# ./backup_blocks.sh
#
# Update the initial parameters for your node setup
#
# Update SLACK_WEBHOOK to your own incoming webhook
#
# Made with <3 by Pete @ Block Matrix
#
# See more EOS nerd shenanigans @ https://github.com/BlockMatrixNetwork
#
###################################################################################################

# Update these for your own purposes
START_SCRIPT="/path/to/start.sh"
STOP_SCRIPT="/path/to/stop.sh"
BLOCKS_DIR="/blocks"
BACKUP_DIR="/backups"
SLACK_WEBHOOK=https://hooks.slack.com/services/replace_me
SLACK_CHANNEL="#eos-alerts"

# Do not change below here

function notify()
{
    [[ ! -z $SLACK_WEBHOOK ]] && curl -s -X POST --data-urlencode "payload={\"channel\": \"$SLACK_CHANNEL\", \"username\": \"EOS Backup Bot\", \"text\": \"$1\", \"icon_emoji\": \":ghost:\"}" $SLACK_WEBHOOK > /dev/null 2>&1
}

DATE=`date -d "now" +'%Y-%m-%d-%H-%M'`

# First, we need to stop the nodeos process
/bin/bash $STOP_SCRIPT

if [ $? -ne 0 ]; then
    notify "There was a problem with stopping nodeos"
    exit 1
fi

# Now we can make the backup
tar -cvzf $BACKUP_DIR/blocks_$DATE.tar.gz -C $BLOCKS_DIR/blocks

if [ $? -ne 0 ]; then
    notify "There was a problem creating the blocks archive"
    exit 1
fi

# Restart nodeos
/bin/bash $START_SCRIPT

if [ $? -ne 0 ]; then
    notify "There was a problem with restarting nodeos"
    exit 1
fi

# Success
notify "Successfully created $BACKUP_DIR/blocks_$DATE.tar.gz archive"
