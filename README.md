# Subdomain Delegation Contract Template

This contract is a template for the distribution of subdomain and the creation of subdomain clubs. Every domain owner could use it to give subdomains to it's community and will connect this contract with [this front end.](https://github.com/starknet-id/og.starknet.id).

## How to deploy ?

_First step:_ Clone this repo `git clone https://github.com/starknet-id/subdomain-distribution`

_Second step:_ Install the dependencies installed using `nix-shell` or pip. Then you can type `protostar install` and `protostar build`

_Third step:_ To deploy this contract you simply need to type `python ./tools/deploy.py [your*wallet*private*key]`. It's possible that your transaction does not have the right nonce and will fail. In order to change it you'll need to change the `_make_invoke_by_version` function of the `account_client.py`. Make the nonce attribute equals to `nonce + 1` instead of `nonce`.

If you have questions concerning this deployment you can ask [Fricoben](https://twitter.com/fricoben).
