# Copilot Instructions for `foundry-dao-cyfrin`

This document provides guidance for AI coding agents working on the `foundry-dao-cyfrin` project. It outlines the architecture, workflows, and conventions specific to this codebase.

## Project Overview

`foundry-dao-cyfrin` is a Solidity-based implementation of a decentralized autonomous organization (DAO). The project uses Foundry for development and testing, and OpenZeppelin libraries for governance and token standards.

### Key Components

1. **Governance Contracts**:
   - `GovToken.sol`: ERC20 token with voting functionality.
   - `MyGovernor.sol`: Implements governance logic, including voting and proposal mechanisms.
   - `TimeLock.sol`: Enforces a delay between proposal approval and execution.

2. **Testing**:
   - Foundry tests are located in the `test/` directory.
   - Example: `MyGovernorTest.t.sol` tests the governance flow, including proposal creation, voting, and execution.

3. **Utilities**:
   - External libraries (e.g., OpenZeppelin) are in the `lib/` directory.
   - Foundry remappings are configured in `foundry.toml`.

## Developer Workflows

### Build and Test

- **Compile Contracts**:
  ```bash
  forge build
  ```

- **Run Tests**:
  ```bash
  forge test -vvv
  ```

- **Check Formatting**:
  ```bash
  forge fmt --check
  ```

### Linting and Formatting

- **Lint Solidity Files**:
  ```bash
  npm run lint
  ```

- **Format Solidity Files**:
  ```bash
  npm run format
  ```

### CI Pipeline

- The GitHub Actions workflow (`.github/workflows/test.yml`) runs the following steps:
  - Install Foundry.
  - Check formatting.
  - Build contracts.
  - Run tests.

## Project-Specific Conventions

1. **Governance Roles**:
   - `PROPOSER_ROLE`: Assigned to the `MyGovernor` contract.
   - `EXECUTOR_ROLE`: Assigned to `address(0)` (anyone can execute proposals).
   - `DEFAULT_ADMIN_ROLE`: Revoked from the deployer to decentralize control.

2. **Proposal Lifecycle**:
   - `Pending` -> `Active` -> `Succeeded` -> `Queued` -> `Executed`.
   - Use `vm.warp` and `vm.roll` in tests to simulate time and block progression.

3. **Testing Patterns**:
   - Use `vm.prank` to simulate `msg.sender`.
   - Encode function calls with `abi.encodeWithSignature` for governance proposals.

4. **External Dependencies**:
   - OpenZeppelin contracts (e.g., `Governor`, `ERC20Votes`).
   - Foundry Standard Library (`forge-std`).

## Key Files and Directories

- `src/`: Contains Solidity contracts.
- `test/`: Contains Foundry tests.
- `lib/`: Contains external libraries.
- `foundry.toml`: Configures remappings and build settings.
- `.solhint.json`: Configures Solidity linting rules.
- `.prettierrc`: Configures code formatting rules.

## Examples

### Proposing a Governance Action

```solidity
bytes memory encodedFunctionCall = abi.encodeWithSignature(
    "store(uint256)",
    777
);
address[] memory targets = [address(box)];
uint256[] memory values = [0];
bytes[] memory calldatas = [encodedFunctionCall];
string memory description = "Store 777 in Box";

governor.propose(targets, values, calldatas, description);
```

### Testing Proposal Execution

```solidity
vm.warp(block.timestamp + VOTING_PERIOD + 1);
vm.roll(block.number + VOTING_PERIOD + 1);

governor.execute(targets, values, calldatas, keccak256(abi.encodePacked(description)));
assertEq(box.getNumber(), 777);
```

## Notes

- Ensure all governance actions are routed through the `MyGovernor` contract.
- Use the `TimeLock` contract to enforce delays and decentralize control.
- Follow the proposal lifecycle strictly in tests to ensure correctness.

For additional details, refer to the `README.md` and the test files in the `test/` directory.