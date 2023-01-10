# pylint: disable=invalid-name
from starkware.starknet.compiler.compile import get_selector_from_name
from starknet_py.net.models.chains import StarknetChainId
from starknet_py.net.udc_deployer.deployer import Deployer
from starknet_py.net import AccountClient, KeyPair
from starknet_py.net.gateway_client import GatewayClient
import asyncio
import json
import sys

argv = sys.argv

deployer_account_addr = (
    0x072D4F3FA4661228ed0c9872007fc7e12a581E000FAd7b8f3e3e5bF9E6133207
)
deployer_account_private_key = int(argv[1])
naming_contract = 0x003bab268e932d2cecd1946f100ae67ce3dff9fd234119ea2f6da57d16d29fce
starknetid_contract = 0x0783a9097b26eae0586373b2ce0ed3529ddc44069d1e0fbc4f66d42b69d6850d
admin = 0x072D4F3FA4661228ed0c9872007fc7e12a581E000FAd7b8f3e3e5bF9E6133207
# MAINNET: https://alpha-mainnet.starknet.io/
# TESTNET: https://alpha4.starknet.io/
# TESTNET2: https://alpha4-2.starknet.io/
network_base_url = "https://alpha4.starknet.io/"
chainid: StarknetChainId = StarknetChainId.TESTNET
max_fee = int(1e16)
# deployer_address=0x072D4F3FA4661228ed0c9872007fc7e12a581E000FAd7b8f3e3e5bF9E6133207
deployer = Deployer()

async def main():
    client: GatewayClient = GatewayClient(
        net={
            "feeder_gateway_url": network_base_url + "feeder_gateway",
            "gateway_url": network_base_url + "gateway",
        }
    )
    account: AccountClient = AccountClient(
        client=client,
        address=deployer_account_addr,
        key_pair=KeyPair.from_private_key(deployer_account_private_key),
        chain=chainid,
        supported_tx_version=1,
    )
    impl_file = open("./build/main.json", "r")
    declare_contract_tx = await account.sign_declare_transaction(
        compiled_contract=impl_file.read(), max_fee=max_fee
    )
    impl_file.close()
    impl_declaration = await client.declare(transaction=declare_contract_tx)
    impl_contract_class_hash = impl_declaration.class_hash
    print("implementation class hash:", hex(impl_contract_class_hash))

    proxy_file = open("./build/proxy.json", "r")
    proxy_content = proxy_file.read()

    declare_contract_tx = await account.sign_declare_transaction(
        compiled_contract=proxy_content, max_fee=max_fee
    )
    proxy_file.close()
    proxy_declaration = await client.declare(transaction=declare_contract_tx)
    proxy_contract_class_hash = proxy_declaration.class_hash
    print("proxy class hash:", hex(proxy_contract_class_hash))

    proxy_json = json.loads(proxy_content)
    abi = proxy_json["abi"]
    deploy_call, address = deployer.create_deployment_call(
        class_hash=proxy_contract_class_hash,
        abi=abi,
        calldata={
            "implementation_hash": impl_contract_class_hash,
            "selector": get_selector_from_name("initializer"),
            "calldata": [admin, starknetid_contract, naming_contract],
        },
    )

    resp = await account.execute(deploy_call, max_fee=int(1e16))
    print("deployment txhash:", hex(resp.transaction_hash))
    print("proxied contract address:", hex(address))


if __name__ == "__main__":
    loop = asyncio.get_event_loop()
    loop.run_until_complete(main())
