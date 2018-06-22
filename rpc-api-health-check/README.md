## RPC API Health Check

It's important to ensure all nodes are in sync with the network. It is not enough to just assume that if the `nodeos` process is alive, that everything is running smoothly.

This run through will demonstrate how you can use `bash` to ensure that the local chain is in sync, and how you can incorporate that into a monitoring solution such as Zabbix.

### Live Demo

Click on the preview image for a live demo video:

[![View on YouTube](https://blockmatrix.network/assets/img/head_block_delay.png?cb=123)](https://youtu.be/-0f0z1GfXAs "View on YouTube")

### Dependencies

Even though this a bash script, we use `jq` to make JSON parsing less painful.

```
sudo apt-get install jq
```

### Running

The bash script requires 2 parameters:

- The RPC API to request
- The delay, in seconds, that you deem acceptible

The idea is that you would use this to test you local `nodeos` instances, however you could call an external RPC API endpoint if you wanted to test your public cluster.

To call a local RPC instance, testing for a delay of no more than 30 seconds:

```
./nodeos_head_block.sh localhost:8888 30
```

To call a public RPC instance, testing for a delay of 10 seconds:

```
./nodeos_head_block.sh https://eosapi.blockmatrix.network 10
```

### Output

On success, the script will output the string `ok` and return an exit code of `0`.

On failure, there is no output, and an exit code of `1`.