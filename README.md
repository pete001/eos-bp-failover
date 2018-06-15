# EOS Block Producer Failover Scripts

This is a collection of failover methods to ensure EOS producing node High Availability.

## Keepalived

`keepalived` provides simple and robust facilities for load-balancing and high-availability. The load-balancing framework relies on the well-known and widely used Linux Virtual Server (IPVS) kernel module providing Layer4 load-balancing. `keepalived` implements a set of checkers to dynamically and adaptively maintain and manage a load-balanced server pool according to their health. Keepalived also implements the VRRPv2 and VRRPv3 protocols to achieve high-availability with director failover.

It can be used for simple monitoring, effectively checking the health of individual processes and performing actions based on defined roles.

### Setting Up for Nodeos

For a simple configuration, you can instruct `keepalived.conf` to check for the `nodeos` process:

```
vrrp_script chk_nodeos {
    script "pidof nodeos"
    interval 2
}
```

The idea is that you would set this up on two producing nodes, a `MASTER` and a `BACKUP`.

Here is an example config for a `MASTER`:

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

`chk_nodeos` registers the `nodeos` pid checker.

`notify` is a link to the script which will be invoked as soon as the `track_script` returns a code other than `0`.

### The Producer HA Script

`keepalived` will automatically pass the state to the script referenced in `notify`. Using this state we can invoke the relevant `pause` or `resume` call to `nodeos` which works via the `eosio::producer_api_plugin` plugin which must be enabled in the `config.ini`.

There is an optional Slack webhook that can be used to send a push notification, this could be easily changed to drop in Pager Duty or some other service that will hook into your Ops alerting platform.