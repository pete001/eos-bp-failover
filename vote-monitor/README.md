## Vote Monitor

It's good to keep track of your BP votes! This will monitor your votes, inform you of changes and relay your current position and total
vote percentage to Slack.

If you want to keep track of other BP's, then you simply add their BP name into the array.

### What You Get

You need to reference a [Slack Incoming Webook URL](https://slack.com/apps/A0F7XDUAZ-incoming-webhooks) so you get shiny notifications to a channel of your choice:

![Vote update](https://blockmatrix.network/assets/img/github/vote-monitor.png)

### Dependencies

We use `jq` to make JSON parsing less painful, and `bc` to make the arithmetic less annoying.

```
sudo apt-get install jq bc
```

### Running

Just update the params in the script and run this in crontab or via `watch`:

```
./vote_monitor.sh
```

To check every 10 seconds:

```
watch -n 10 ./vote_monitor.sh
```