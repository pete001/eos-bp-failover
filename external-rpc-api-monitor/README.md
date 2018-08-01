## External RPC API Monitor

Keep track of your external EOS Full nodes, this will check that the node is contactable and that the head block time isnt too far behind.

You can check multiple nodes, or even your friendly neighbourhood BP's. Everything is configurable.

### What You Get

You need to reference a [Slack Incoming Webook URL](https://slack.com/apps/A0F7XDUAZ-incoming-webhooks) so you get shiny notifications to a channel of your choice:

![Vote update](https://blockmatrix.network/assets/img/github/external-api-monitor.png)

### Dependencies

We use `jq` to make JSON parsing less painful.

```
sudo apt-get install jq
```

### Running

Just update the params in the script and run this in crontab or via `watch`:

```
./api_monitor.sh
```

To check every 30 seconds:

```
watch -n 30 ./api_monitor.sh
```