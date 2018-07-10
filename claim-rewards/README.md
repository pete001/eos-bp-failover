## Automating `claimrewards`

If you are in the fortunate position of being a paid EOS BP, you have to manually request the BP rewards every 24 hours + 1 second `¯\_(ツ)_/¯`

This poses problems on many levels so we need to automate it. However, to perform a `claimrewards` you need to have access to an unlocked wallet, and that requires a plaintext password!

Thankfully, with the fancy EOS permission system, we can create a subaccount with a sole purpose of claiming rewards - if the key is compromised its not a big deal.

This implementation is the best known mix between security and automation. It is not perfect, but its the best we've got!

### What You Get

If you reference a [Slack Incoming Webook URL](https://slack.com/apps/A0F7XDUAZ-incoming-webhooks) then you will get shiny notifications to a channel of your choice.

#### Success

A successful `claimrewards` will detail your BP payout:

![Successful claimrewards](https://blockmatrix.network/assets/img/github/claim-rewards-success.png)

#### Failure

If `claimrewards` failed, it will relay the error output:

![Failed claimrewards](https://blockmatrix.network/assets/img/github/claim-rewards-fail.png)

**NOTE**: Use `--verbose-http-errors` with your `nodeos` to get verbose error output like the above.

### Dependencies

None, just sexy bash.

### Create your claimer account

As an added layer of security, we can create a separate subaccount and wallet just for actioning the `claimrewards`. The worst thing that could happen if this was compromised would be that a kind hacker could claim the rewards for you `ಠ‿ಠ`.

In these examples, replace `blockmatrix` for your own producer name.

- Create a new public/private key pair:

```
cleos create key
```

- Create a new wallet and save the wallet password:

```
cleos wallet create -n claims
```

- Import the private key created earlier:

```
cleos wallet import CLAIM_PRIVATE_KEY -n claims
```

- Activate the `claimrewards` action for this new account:

```
cleos set account permission blockmatrix claims '{"threshold":1,"keys":[{"key":"CLAIM_PUBLIC_KEY","weight":1}]}' "active" -p blockmatrix@active
cleos set action permission blockmatrix eosio claimrewards claims
```

### Running

Pass the wallet password as a parameter to the script, just so you arent checking that into version control.

Update the parameters at the top of the script, and there are some optional parameters which you might want to change so that you can receive a shiny Slack alert detailing your rewards payout.

To run the daemon, simply execute:

```
./claim_rewards.sh PW5JfDojLFSmMTJfDLwQE5zvE4mjSBDwUpfuZWmws5Ecm4AF2StjX
```

### Automating via `crontab`

You can make this run every minute via `crontab` with:

```
(crontab -l ; echo "* * * * * /path/to/claim_rewards.sh PW5JfDojLFSmMTJfDLwQE5zvE4mjSBDwUpfuZWmws5Ecm4AF2StjX")| crontab -
```