# First DAO

This project demonstrates the implementation of a decentralized autonomous organization (DAO) using Solidity and Foundry. The DAO is governed by token-based voting, where every transaction must be approved through a voting process.

## Features

1. **DAO Governance**: A contract controlled by a DAO, ensuring decentralized decision-making.
2. **Voting Mechanism**: Transactions are subject to approval through token-based voting.
3. **ERC20 Voting Tokens**: Utilizes ERC20 tokens for voting (note: this is a basic model, and there are more advanced governance models available).

## Project Structure

- **Contracts**: Solidity contracts are located in the `src/` directory.
- **Libraries**: External libraries, such as OpenZeppelin, are located in the `lib/` directory.
- **Remappings**: Foundry remappings are configured in `foundry.toml` to resolve imports like `@openzeppelin/contracts`.

## Linting and Formatting

This project uses **Prettier** and **Solhint** to ensure consistent code style and enforce best practices.

### Formatting

To format Solidity files:
```bash
npx prettier --write "src/**/*.sol"
npm run format
```

### Linting

To lint Solidity files:
```bash
npm run lint
```

### Notes
- **Prettier**: Configured with `prettier-plugin-solidity` for Solidity-specific formatting.
- **Solhint**: Configured with rules in `.solhint.json` to enforce coding standards and best practices.
- **Import Paths**: Ensure that `@openzeppelin/contracts` resolves correctly using the remappings in `foundry.toml`.

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/wmachaca/foundry-dao-cyfrin.git
   ```
2. Install dependencies:
   ```bash
   npm install
   ```
3. Compile the contracts:
   ```bash
   forge build
   ```
4. Run tests:
   ```bash
   forge test
   ```

## License

This project is licensed under the MIT License.
