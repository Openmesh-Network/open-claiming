## Open Claiming

A smart contract that is used to mint OPEN to accounts, based on off-chain (compared to Ethereum mainnet) conditions.  
It requires a trusted entity to provide a signature how much this account is allowed to mint.  
The contract is limited in how much it can mint in a certain period (currently 1 week), to limit the damage in case of an exploit.  
A contract can be disabled by revoking its minting right.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
forge build
```

### Test

```shell
forge test
```

### Deploy

```shell
make deploy
```

## Local chain

```shell
anvil
make local-fund ADDRESS="YOURADDRESSHERE"
```

### Analyze

```shell
make slither
make mythril TARGET=Counter.sol
```

### Help

```shell
forge --help
anvil --help
cast --help
```
