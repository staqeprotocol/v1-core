# Staqe Protocol

<div style="text-align:center" align="center">
    <img src="https://raw.githubusercontent.com/staqeprotocol/v1-core/master/image.svg" width="600">
</div>

Staqe Protocol is a comprehensive and flexible staking solution built on the Ethereum blockchain. It enables users to stake ERC20 or ERC721 tokens across various pools to earn rewards in ERC20 tokens. Staqe Protocol is designed to cater to a wide range of staking strategies, providing versatility and robustness in its approach to decentralized finance (DeFi) staking mechanisms.

## Key Features

- **Multiple Staking Pools**: Users can choose from various pools to stake their assets, each with distinct configurations and reward mechanisms.
- **ERC20 and ERC721 Staking**: Staqe supports staking of both ERC20 and ERC721 tokens, offering a diverse range of staking opportunities.
- **Dynamic Reward System**: Earn rewards in ERC20 tokens with a system that accommodates different reward structures per pool.
- **EIP-2612 Permit Support**: Streamlined interactions through permit functions, allowing users to approve and stake in a single transaction.
- **Comprehensive Interfaces**: Utilizes a set of interfaces for clear contract interaction, error handling, and event logging.
- **Modular Design**: Extensible architecture, allowing for future enhancements and integration with other DeFi protocols.
- **Security First**: Built with security in mind, including protections against reentrancy attacks and adhering to industry-standard best practices.

## Components

### Staqe Contract

The core contract manages the logic for staking, unstaking, reward distribution, and pool management. Key functionalities include:

- `launchPool`: Create a new staking pool with specified parameters.
- `editPool`: Modify the metadata of an existing pool.
- `stake`: Stake ERC20 or ERC721 tokens in a chosen pool.
- `addReward`: Add a reward to a pool, specifying the reward token and amount.
- `unstake`: Withdraw staked tokens from a pool.
- `claimRewards`: Claim earned rewards from one or multiple pools.

### StaqePermit Extension

This extension adds permit-based functions to the core Staqe contract, leveraging EIP-2612 permits:

- `stakeWithPermit`: Approve and stake ERC20 tokens in a single transaction.
- `addRewardWithPermit`: Approve and add a reward in a single transaction.

### StaqeProtocol Contract

A concrete implementation that brings together the Staqe core functionalities and the permit extensions, serving as the primary interface for users.

## Interfaces and Inheritance

Staqe Protocol leverages multiple interfaces and inherits from well-established contracts to ensure robustness and interoperability:

- Interfaces like `IStaqeEvents`, `IStaqeErrors`, and `IStaqeStructs` define the contract's events, error handling, and data structures.
- Inherits from OpenZeppelin's `ERC721` for NFT functionality and `Ownable` for ownership management.

## Security and Best Practices

Security is paramount in the Staqe Protocol design, incorporating features like:

- `nonReentrant` modifier from OpenZeppelin's `ReentrancyGuard` to prevent reentrancy attacks.
- Explicit and descriptive error messages to enhance contract readability and debugging.
- Adherence to smart contract development best practices and community standards.

## Conclusion

Staqe Protocol represents a sophisticated and secure approach to staking in the DeFi ecosystem, providing users with a versatile platform for earning rewards through staking. Its modular design and adherence to best practices make it a solid choice for developers and users looking for a reliable staking solution on the Ethereum blockchain.
