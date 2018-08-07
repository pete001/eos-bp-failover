## Blocks Backup

It's a good idea to regularly backup your blocks data directory. This can assist with node recovery, help facilitate rollbacks and acts as a good resource for those who wish to get started on the chain.

This script will stop the `nodeos` process, take a backup, compress, restart `nodeos` and send a slack message to report on the status.

This script assumes you have a start and stop script for `nodeos` already available on the node.

### What You Get

You need to reference a [Slack Incoming Webook URL](https://slack.com/apps/A0F7XDUAZ-incoming-webhooks) so you get shiny notifications to a channel of your choice:

![Vote update](https://blockmatrix.network/assets/img/github/backup-blocks.png)

### Dependencies

No special commands used here, a vanilla linux install should handle this just fine.

### Running

Just update the params in the script and run this in crontab:

```
./backup_blocks.sh
```