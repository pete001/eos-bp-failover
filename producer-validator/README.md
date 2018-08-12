## Producer Validation

These monitor scripts use a local `nodeos` log to highlight whether any producer has missed blocks in a round and/or find any negative latencies.

There are 2 scripts:

- [validate_producer.sh](/validate_producer.sh) allows you to keep track of a defined list of BPs.
- [validate_producers_all.sh](/validate_producers_all.sh) allows you to dynamically track the top 21 BPs.

### What You Get

It echo's to `stdout` by default, you will see this on a clean run:

```
./validate_producers_all.sh
starteosiobp has 12 healthy blocks and no negative latency
eosnewyorkio has 12 healthy blocks and no negative latency
eoshuobipool has 12 healthy blocks and no negative latency
zbeosbp11111 has 12 healthy blocks and no negative latency
bitfinexeos1 has 12 healthy blocks and no negative latency
libertyblock has 12 healthy blocks and no negative latency
eos42freedom has 12 healthy blocks and no negative latency
eosfishrocks has 12 healthy blocks and no negative latency
eoslaomaocom has 12 healthy blocks and no negative latency
eosswedenorg has 12 healthy blocks and no negative latency
eosisgravity has 12 healthy blocks and no negative latency
eosbixinboot has 12 healthy blocks and no negative latency
eosbeijingbp has 12 healthy blocks and no negative latency
eosauthority has 12 healthy blocks and no negative latency
eosriobrazil has 12 healthy blocks and no negative latency
eosasia11111 has 12 healthy blocks and no negative latency
argentinaeos has 12 healthy blocks and no negative latency
eosdacserver has 12 healthy blocks and no negative latency
helloeoscnbp has 12 healthy blocks and no negative latency
teamgreymass has 12 healthy blocks and no negative latency
eoscannonchn has 12 healthy blocks and no negative latency
```

For more fancy output, you need to reference a [Slack Incoming Webook URL](https://slack.com/apps/A0F7XDUAZ-incoming-webhooks) to get shiny notifications delivered to a channel of your choice.

When an issue is found, the matching log lines are sent with the surrounding line before and after:

![Validation update](https://blockmatrix.network/assets/img/github/bp-monitor.png)

### Dependencies

We use `jq` to make JSON parsing less painful

```
sudo apt-get install jq
```

### Running

Just update the params in the script and run this in crontab or via `watch`:

```
./validate_producer.sh
```

To check every 126 seconds:

```
watch -n 126 ./validate_producer.sh
```
