## Extra Steps for AWS

So why doesn't `keepalived` work in AWS? Well, it's a good question, but it's down to their walled garden. AWS already has their own flavour of services that they would rather you use for this, however it's not always extensible enough to give us the full range of flexibility that a tool like `keepalived` can give us. Thankfully there is a way around their unicast hurdle using `GRE`.

What the hell is `GRE`? Another valid question! `GRE` tunnels are IP-over-IP tunnels which can encapsulate IPv4/IPv6 and unicast/multicast traffic. To create a `GRE` tunnel on Linux, you need the `ip_gre` kernel module, which is `GRE` over IPv4 tunneling driver.

### Changes You Need To Make

In your `keepalived` config, you need to change the following:

```
    unicast_src_ip {{ src_ip }}
    unicast_peer {
        {{ dst_ip }}
    }
```

To use `vrrp_unicast` bind and peer:

```
    vrrp_unicast_bind {{ src_ip_gre }}
    vrrp_unicast_peer {{ dst_ip_gre }}
```

### iptables

Check out [iptables.rules](https://github.com/BlockMatrixNetwork/eos-bp-failover/blob/master/aws/iptables.rules) for example iptables rules to ensure both nodes can communicate with each other.

```
-A INPUT -d 224.0.0.0/8 -p vrrp -j ACCEPT
-A INPUT -s 224.0.0.0/8 -j ACCEPT
-A INPUT -p gre -j ACCEPT
```

### GRE Config

Check out [gre.cfg](https://github.com/BlockMatrixNetwork/eos-bp-failover/blob/master/aws/gre.cfg) for an example `GRE` config.

```
auto gre1
iface gre1 inet static
address {{ gre_ip }} # inside side a address
netmask 255.255.255.0
pre-up ip tunnel add gre1 mode gre remote {{ dst_ip }} local {{ src_ip }} # remote external ip local external ip
post-down ip tunnel del gre1
```

### Does It Work?

Yes, the video linked in the main readme of this repo is demoing the implementation on AWS nodes.