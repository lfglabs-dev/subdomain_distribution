# Subdomain distribution templates 🌴

This repository contains two starknet contracts for the distribution of subdomain and the creation of subdomain clubs. Every domain owner could use it to give subdomains to it's community and could connect the deployed contract with [this front end](https://github.com/starknet-id/og.starknet.id).

- The contract `simple.cairo` is a template for the distribution to everyone.
- The contract `whitelist.cairo` is a template for the distribution whitelisted members (with a small signature).

### How to deploy ? 🌴

_First step:_ Clone this repo `git clone https://github.com/starknet-id/subdomain-distribution`

_Second step:_ Install the dependencies installed using `nix-shell` or pip. Then you can type `protostar install` and `protostar build`

_Third step:_ To deploy this contract you simply need to type `python ./tools/deploy-[the*contract*you*want].py [your*wallet*private*key]`. It's possible that your transaction does not have the right nonce and will fail. In order to change it you'll need to change the `_make_invoke_by_version` function of the `account_client.py`. Make the nonce attribute equals to `nonce + 1` instead of `nonce`.

_Fourth step:_ Once contracts are deployed you need to transfer the root domain you want to distribute subdomains on, to the recently deployed contract address.

Here is an example, if you have og.stark and you want to give subdomains like `mbappe.og.stark`, then you'll need to transfer the NFT `og.stark` to the contract address you just deployed (you can do it directly with your wallet).

If you have questions concerning this deployment you can ask [Fricoben](https://twitter.com/fricoben).

### License 🌴

This project is licensed under the terms of the MIT license.
