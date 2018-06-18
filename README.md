# EOS Block Producer Failover Scripts

It's extremely important for producers to ensure their producing nodes continue to process and sign blocks in the event of failure. This repo will pool well tested, and well documented methods of High Availability for EOS producers.

## Producing Node Failover via `keepalived`

### Live Demo

Click on the preview image for a live demo video:

[![View on YouTube](https://blockmatrix.network/assets/img/keepalived_bp_failover.png?cb=123)](https://www.youtube.com/watch?v=a4Ctvp3Bqzw "View on YouTube")

Keepalived provides simple and robust facilities for load-balancing and high-availability. The load-balancing framework relies on the well-known and widely used Linux Virtual Server (IPVS) kernel module providing Layer4 load-balancing. Keepalived implements a set of checkers to dynamically and adaptively maintain and manage a load-balanced server pool according to their health. Keepalived also implements the VRRPv2 and VRRPv3 protocols to achieve high-availability with director failover.

It can be used for simple monitoring, effectively checking the health of individual processes and performing actions based on defined roles.

`NOTE:` If you use AWS there are extra steps! There is an AWS specific section at the end of this run through.

### Setting Up for Nodeos

For a simple configuration, you can instruct `keepalived.conf` to check for the `nodeos` process:

```
vrrp_script chk_nodeos {
    script "pidof nodeos"
    interval 2
}
```

The idea is that you would set this up on two producing nodes, a `MASTER` and a `BACKUP`.

Here is an example config for a `MASTER` (this example does not focus on the networking, there are many tutorials out there on how to do this):

```
vrrp_instance ProducerVRRP {

    state MASTER
    interface eth0
    virtual_router_id 5
    priority 200
    advert_int 1

    virtual_ipaddress {
        192.168.1.1/32 dev eth0
    }

    track_script {
        chk_nodeos
    }

    notify /etc/keepalived/check_nodeos.sh
}
```

The two important sections here are `track_script` and `notify`.

`chk_nodeos` registers the `nodeos` process id checker.

`notify` is a link to the script which will be invoked as soon as the `track_script` returns a code other than `0`.

### The Producer HA Script

Check the script @ [check_nodes.sh](https://github.com/BlockMatrixNetwork/eos-bp-failover/blob/master/check_nodeos.sh)

`keepalived` will automatically pass the state to the script referenced in `notify`.

Using this state we can invoke the relevant `pause` or `resume` call to `nodeos` which works via the `eosio::producer_api_plugin` plugin which must be enabled in the `config.ini`.

The idea is that both producing nodes would use the same `signature-provider`, we keep both producers online but thanks to the producer api we can ensure that only 1 producing node is active at one time whilst the backup remains online keeping synced to the network.

Within the `check_nodes.sh` script, there is an optional Slack webhook that can be used to send a push notification on any update. This could be easily changed to drop in Pager Duty or some other service that will hook into your Ops alerting platform.
